import Foundation

// MARK: - API Service (Backend通信)
class APIService {
    static let shared = APIService()

    /// 環境変数から API ベース URL を取得
    private let baseURL: String

    private init() {
        self.baseURL = AppEnvironment.apiBaseURL
        print("🌐 APIService initialized with baseURL: \(self.baseURL)")
    }

    // MARK: - インプット解析 (画像 → テキスト + タイトル)
    struct InputAnalysisResponse: Codable {
        let title: String
        let sourceText: String
    }

    func analyzeInput(imageData: Data) async throws -> InputAnalysisResponse {
        let url = URL(string: "\(baseURL)/api/analyze")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60 // Gemini解析に時間がかかる可能性

        let savedLang = UserDefaults.standard.string(forKey: "appLanguage") ?? "system"
        let languageCode = (savedLang == "system") ? (Locale.current.language.languageCode?.identifier ?? "ja") : savedLang
        let body: [String: String] = [
            "image": imageData.base64EncodedString(),
            "lang": languageCode
        ]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError
        }

        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ Analyze API error (\(httpResponse.statusCode)): \(errorBody)")
            throw APIError.serverError
        }

        return try JSONDecoder().decode(InputAnalysisResponse.self, from: data)
    }

    // MARK: - ハイライトセグメント
    struct HighlightedSegment: Codable {
        let text: String
        let recalled: Bool
    }

    // MARK: - 想起採点
    struct RecallScoringResponse: Codable {
        let logicScore: Int
        let termScore: Int
        let logicFeedback: String
        let highlightedSegments: [HighlightedSegment]
    }

    func scoreRecall(sourceText: String, recallText: String) async throws -> RecallScoringResponse {
        let url = URL(string: "\(baseURL)/api/score")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60

        let savedLang = UserDefaults.standard.string(forKey: "appLanguage") ?? "system"
        let languageCode = (savedLang == "system") ? (Locale.current.language.languageCode?.identifier ?? "ja") : savedLang
        let body: [String: String] = [
            "sourceText": sourceText,
            "recallText": recallText,
            "lang": languageCode
        ]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError
        }

        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ Score API error (\(httpResponse.statusCode)): \(errorBody)")
            throw APIError.serverError
        }

        return try JSONDecoder().decode(RecallScoringResponse.self, from: data)
    }

    // MARK: - ヘルスチェック
    func healthCheck() async -> Bool {
        guard let url = URL(string: "\(baseURL)/health") else { return false }
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }

    enum APIError: LocalizedError {
        case serverError
        case networkError

        var errorDescription: String? {
            switch self {
            case .serverError: return "サーバーとの通信に失敗しました"
            case .networkError: return "ネットワーク接続を確認してください"
            }
        }
    }
}
