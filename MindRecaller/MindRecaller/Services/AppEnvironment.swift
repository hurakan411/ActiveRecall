import Foundation

/// .env から環境変数を読み込むユーティリティ
/// Info.plist 経由（xcconfig）とフォールバックの .env ファイル直読みの両方に対応
enum AppEnvironment {

    /// API ベース URL
    static var apiBaseURL: String {
        // バンドル内の .env ファイルから読み込みフォールバック
        if let envURL = Bundle.main.url(forResource: ".env", withExtension: nil),
           let content = try? String(contentsOf: envURL, encoding: .utf8) {
            let values = parseEnv(content)
            
            let useRender = (values["USE_RENDER_BACKEND"]?.lowercased() == "true")
            let localUrl = values["LOCAL_API_BASE_URL"] ?? "http://localhost:8000"
            let renderUrl = values["RENDER_API_BASE_URL"] ?? "https://your-render-app.onrender.com"
            
            return useRender ? renderUrl : localUrl
        }

        // デフォルト（ローカル開発用）
        return "http://localhost:8000"
    }

    /// .env ファイルのパース
    private static func parseEnv(_ content: String) -> [String: String] {
        var result: [String: String] = [:]
        for line in content.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            // コメントと空行をスキップ
            if trimmed.isEmpty || trimmed.hasPrefix("#") || trimmed.hasPrefix("//") {
                continue
            }
            let parts = trimmed.split(separator: "=", maxSplits: 1)
            if parts.count == 2 {
                let key = String(parts[0]).trimmingCharacters(in: .whitespaces)
                let value = String(parts[1]).trimmingCharacters(in: .whitespaces)
                result[key] = value
            }
        }
        return result
    }
}
