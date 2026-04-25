"""
MindRecaller Backend API
========================
Gemini 2.0 Flash を活用した教材解析・想起採点APIサーバー。
"""

import base64
import json
import os
import re

from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from google import genai
from google.genai.errors import APIError
from pydantic import BaseModel
import asyncio
from openai import AsyncOpenAI

# .env 読み込み
load_dotenv()

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")
GEMINI_MODEL = os.getenv("GEMINI_MODEL", "gemini-2.0-flash")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "")
OPENAI_MODEL = os.getenv("OPENAI_MODEL", "gpt-5.4-mini")
HOST = os.getenv("HOST", "0.0.0.0")
PORT = int(os.getenv("PORT", "8000"))
CORS_ORIGINS = os.getenv("CORS_ORIGINS", "*").split(",")

if not GEMINI_API_KEY or GEMINI_API_KEY == "your_gemini_api_key_here":
    print("⚠️  WARNING: GEMINI_API_KEY が設定されていません。.env ファイルを確認してください。")

# Gemini クライアント初期化
client = genai.Client(api_key=GEMINI_API_KEY)

# OpenAI クライアント初期化
openai_client = AsyncOpenAI(api_key=OPENAI_API_KEY)

# FastAPI アプリ
app = FastAPI(
    title="MindRecaller API",
    description="アクティブリコール学習アプリのバックエンドAPI",
    version="1.0.0",
)

# CORS 設定
app.add_middleware(
    CORSMiddleware,
    allow_origins=CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ============================================================
# リクエスト / レスポンス モデル
# ============================================================

class AnalyzeRequest(BaseModel):
    """インプット解析リクエスト"""
    image: str  # Base64エンコードされた画像データ
    lang: str = "ja"  # 言語パラメータ


class AnalyzeResponse(BaseModel):
    """インプット解析レスポンス"""
    title: str
    sourceText: str


class ScoreRequest(BaseModel):
    """想起採点リクエスト"""
    sourceText: str
    recallText: str
    lang: str = "ja"  # 言語パラメータ


class ScoreResponse(BaseModel):
    """想起採点レスポンス"""
    logicScore: int
    termScore: int
    logicFeedback: str
    highlightedSegments: list[dict]


# ============================================================
# ヘルスチェック
# ============================================================

@app.get("/")
async def root():
    return {"status": "ok", "service": "MindRecaller API", "version": "1.0.0"}


@app.get("/health")
async def health():
    return {"status": "healthy"}


# ============================================================
# 4.1 インプット解析エンドポイント
# ============================================================

def get_analyze_prompt(lang: str) -> str:
    if lang.startswith("en"):
        return """You are an educational text extraction expert.
From the given image, extract and structure text suitable for study material.

Respond ONLY with the following JSON format (no markdown, no explanations):
{
    "title": "A concise title (under 15 words) IN ENGLISH",
    "sourceText": "The extracted text preserving bullet points and paragraphs. IF EXTRACTED TEXT IS NOT IN ENGLISH, TRANSLATE IT TO ENGLISH."
}

Notes:
- Accurately extract all text from the image.
- If there are charts or diagrams, explain their contents in text.
- The title must represent the content clearly in English.
- The sourceText should be translated to English if the original image is in another language.
- Ensure the output strictly uses English.
"""
    return """あなたは教材テキスト抽出の専門家です。
与えられた画像から、学習教材として利用できるテキストを構造化して抽出してください。

以下のJSON形式で回答してください（JSONのみ出力、マークダウンや説明文は不要）:
{
    "title": "教材のタイトル（15文字以内で簡潔に）",
    "sourceText": "抽出したテキスト全文（箇条書きや段落構造を保持）"
}

注意事項:
- 画像に含まれるテキストを正確に読み取ること
- 図表やグラフがある場合はその内容も文章で説明すること
- タイトルは内容を端的に表すものにすること
- sourceTextは学習に使える詳細な内容にすること
"""


@app.post("/api/analyze", response_model=AnalyzeResponse)
async def analyze_input(req: AnalyzeRequest):
    """画像からテキストを抽出し、タイトルと詳細テキストを返す"""
    try:
        # Base64 → バイナリ
        image_bytes = base64.b64decode(req.image)

        contents=[
            {
                "role": "user",
                "parts": [
                    {"text": get_analyze_prompt(req.lang)},
                    {
                        "inline_data": {
                            "mime_type": "image/jpeg",
                            "data": req.image,
                        }
                    },
                ],
            }
        ]

        response_text = await _generate_with_retry(
            model_name=GEMINI_MODEL,
            contents=contents,
        )

        # レスポンステキストからJSONを抽出
        raw = response_text.strip()
        parsed = _extract_json(raw)

        return AnalyzeResponse(
            title=parsed.get("title", "無題"),
            sourceText=parsed.get("sourceText", raw),
        )

    except json.JSONDecodeError:
        raise HTTPException(status_code=500, detail="AI応答のJSON解析に失敗しました")
    except Exception as e:
        error_str = str(e)
        if "429" in error_str or "UNAVAILABLE" in error_str or "EXHAUSTED" in error_str:
            return AnalyzeResponse(
                title="【エラー】API制限",
                sourceText="現在、AIの利用限界（分間アクセス上限、あるいは1日の無料枠上限）を超過しています。しばらく時間を置いてから再度お試しください。\n\nエラー詳細: " + error_str[:150]
            )
        raise HTTPException(status_code=500, detail=f"解析エラー: {error_str}")


# ============================================================
# 4.2 想起採点エンドポイント
# ============================================================

def get_score_prompt(lang: str, source_text: str, recall_text: str) -> str:
    if lang.startswith("en"):
        return f"""You are an expert in evaluating learning effectiveness.
Evaluate the user's recalled text against the original source text and provide a detailed score and analysis.

[Original Source Text]
{source_text}

[User's Recalled Text]
{recall_text}

Evaluate based on the following criteria and respond in JSON format ONLY:

1. logicScore: Calculate the "pure coverage rate (%)" (0-100) of how many semantic/logic elements from the source are covered in the user's text. Do not be overly generous. If they missed half, output 50.
2. termScore: Calculate the "pure coverage rate (%)" (0-100) of how many specific keywords/terms/proper nouns from the source are included in the user's text.
3. logicFeedback: Provide overall feedback IN ENGLISH ONLY. Briefly mention what was done well and what needs improvement in about 20-30 words.
4. highlightedSegments: Split the original text into short semantic segments (phrases or short sentences). Array of objects indicating if each segment was covered.

highlightedSegments Rules:
- The entire original text must be divided into contiguous segments.
- Each segment should be a meaningful chunk.
- Include newline characters ("\\n") as standalone segments where appropriate.
- "recalled": true if the user covered the concept, false otherwise.
- Completely reassembling all segment text values must perfectly match the original text.

Format:
{{
    "logicScore": 75,
    "termScore": 60,
    "logicFeedback": "Feedback text...",
    "highlightedSegments": [
        {{"text": "Segment 1 text", "recalled": true}},
        {{"text": "Segment 2 text", "recalled": false}},
        {{"text": "\\n", "recalled": true}}
    ]
}}
"""
    return f"""あなたは学習効果の評価専門家です。
ユーザーが教材の内容を記憶から想起した結果を、元のテキストと比較して詳細に採点・分析してください。

【元のテキスト（正解）】
{source_text}

【ユーザーの想起テキスト】
{recall_text}

以下の観点で採点し、JSON形式で回答してください（JSONのみ出力）:

1. logicScore（論理スコア）: 原文が持つ「意味・論理・主張の全要素」をリストアップしたとき、ユーザーのテキストがその要素をいくつカバーしているかの「純粋なカバー率（%）」を算出して0〜100の値にしてください。絶対に点数のおまけ（忖度）はせず、半分しか書いていなければ50、10%しか書いていなければ10を出力してください。
2. termScore（用語スコア）: 原文に含まれる「全ての専門用語・キーワード・固有名詞」をリストアップしたとき、ユーザーのテキストがそれらのうち何個を含んでいるかの「純粋なカバー率（%）」を算出して0〜100の値にしてください。数学的な計算（拾えたキーワード数 ÷ 全キーワード数 × 100）を行い、そのまま出力してください。
3. logicFeedback: 全体的なフィードバック。できている点と今後の課題を100文字程度で、要点を絞って簡潔に記述。
4. highlightedSegments: 元のテキストを意味のある短いフレーズ・文節単位で分割し、それぞれがユーザーの想起テキストでカバーされているかを判定した配列。

highlightedSegmentsのルール:
- 元のテキスト全体を、連続するセグメントに分割する（テキストが途切れないこと）
- 各セグメントは意味的なまとまり（単語〜短い文程度）にする
- 改行文字もセグメントとして含めること（"\\n"）
- ユーザーがそのセグメントの内容を想起できていれば "recalled": true、できていなければ "recalled": false
- 完全一致でなくても、意味的に同じ内容を書けていればrecalled: trueとする
- すべてのセグメントを連結すると元のテキストと完全一致すること

出力形式:
{{
    "logicScore": 75,
    "termScore": 60,
    "logicFeedback": "フィードバック文...",
    "highlightedSegments": [
        {{"text": "セグメント1のテキスト", "recalled": true}},
        {{"text": "セグメント2のテキスト", "recalled": false}},
        {{"text": "\\n", "recalled": true}},
        {{"text": "セグメント3のテキスト", "recalled": true}}
    ]
}}
"""


@app.post("/api/score", response_model=ScoreResponse)
async def score_recall(req: ScoreRequest):
    """sourceText と recallText を比較し、セマンティックマッチングで採点"""
    if not req.sourceText.strip():
        raise HTTPException(status_code=400, detail="sourceTextが空です")
    if not req.recallText.strip():
        raise HTTPException(status_code=400, detail="recallTextが空です")

    try:
        prompt = get_score_prompt(
            lang=req.lang,
            source_text=req.sourceText,
            recall_text=req.recallText,
        )

        # OpenAIを使用して採点
        response = await openai_client.chat.completions.create(
            model=OPENAI_MODEL,
            messages=[
                {"role": "system", "content": "あなたは学習効果の評価専門家です。指定されたJSONフォーマットでのみ出力してください。"},
                {"role": "user", "content": prompt}
            ],
            response_format={ "type": "json_object" }
        )

        response_text = response.choices[0].message.content
        raw = response_text.strip()
        parsed = _extract_json(raw)

        # highlightedSegments のバリデーション
        segments = parsed.get("highlightedSegments", [])
        validated_segments = []
        for seg in segments:
            if isinstance(seg, dict) and "text" in seg and "recalled" in seg:
                validated_segments.append({
                    "text": str(seg["text"]),
                    "recalled": bool(seg["recalled"])
                })

        # セグメントが空の場合、元テキスト全体を未リコールとしてフォールバック
        if not validated_segments:
            validated_segments = [{"text": req.sourceText, "recalled": False}]

        return ScoreResponse(
            logicScore=_clamp(parsed.get("logicScore", 50), 0, 100),
            termScore=_clamp(parsed.get("termScore", 50), 0, 100),
            logicFeedback=parsed.get("logicFeedback", "採点結果を取得できませんでした。"),
            highlightedSegments=validated_segments,
        )

    except json.JSONDecodeError:
        raise HTTPException(status_code=500, detail="AI応答のJSON解析に失敗しました")
    except Exception as e:
        error_str = str(e)
        if "429" in error_str or "UNAVAILABLE" in error_str or "EXHAUSTED" in error_str or "Rate limit" in error_str:
            return ScoreResponse(
                logicScore=0,
                termScore=0,
                logicFeedback="【API利用上限・高負荷エラー】現在、AIの利用枠を超過しているか、サーバーが高負荷です。時間を置いてからお試しください。",
                highlightedSegments=[{"text": req.sourceText, "recalled": False}],
            )
        if "api_key" in error_str.lower():
            return ScoreResponse(
                logicScore=0,
                termScore=0,
                logicFeedback="【設定エラー】OPENAI_API_KEYが設定されていないか無効です。.envファイルを確認してください。",
                highlightedSegments=[{"text": req.sourceText, "recalled": False}],
            )
        raise HTTPException(status_code=500, detail=f"採点エラー: {error_str}")


# ============================================================
# ユーティリティ
# ============================================================

def _extract_json(text: str) -> dict:
    """AI応答からJSON部分を抽出してパース"""
    # ```json ... ``` ブロックを除去
    cleaned = re.sub(r"```json\s*", "", text, flags=re.IGNORECASE)
    cleaned = re.sub(r"```\s*", "", cleaned)
    cleaned = cleaned.strip()
    return json.loads(cleaned)

async def _generate_with_retry(model_name: str, contents: list | str, retries: int = 5, delay: float = 3.0) -> str:
    """API呼び出しをリトライとフォールバック付きで実行"""
    current_model = model_name
    fallback_model = "gemini-2.5-flash"
    
    for attempt in range(retries):
        try:
            response = client.models.generate_content(
                model=current_model,
                contents=contents,
            )
            return response.text
        except APIError as e:
            error_status = getattr(e, 'status', None)
            if error_status == 503 or error_status == 429 or "503" in str(e) or "429" in str(e) or "RESOURCE_EXHAUSTED" in str(e) or "UNAVAILABLE" in str(e):
                print(f"⚠️ API Limit/High Demand ({error_status}). Attempt {attempt + 1}/{retries}.")
                if attempt == 1:
                   print(f"Fallback to {fallback_model} for next attempt.")
                   current_model = fallback_model
                
                if attempt < retries - 1:
                    await asyncio.sleep(delay * (attempt + 1)) # Exponential backoff
                    continue
            raise e
        except Exception as e:
           raise e
    raise Exception("Max retries exceeded.")


def _clamp(value: int, min_val: int, max_val: int) -> int:
    """値を指定範囲にクランプ"""
    try:
        return max(min_val, min(max_val, int(value)))
    except (TypeError, ValueError):
        return 50


# ============================================================
# エントリーポイント
# ============================================================

if __name__ == "__main__":
    import uvicorn
    print(f"🧠 MindRecaller API starting on http://{HOST}:{PORT}")
    print(f"📖 API Docs: http://{HOST}:{PORT}/docs")
    uvicorn.run("main:app", host=HOST, port=PORT, reload=True)
