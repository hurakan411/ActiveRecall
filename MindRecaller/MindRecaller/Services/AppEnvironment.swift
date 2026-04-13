import Foundation

/// .env から環境変数を読み込むユーティリティ
/// Info.plist 経由（xcconfig）とフォールバックの .env ファイル直読みの両方に対応
enum AppEnvironment {

    /// API ベース URL
    static var apiBaseURL: String {
        // 1. Info.plist (xcconfig経由) から読み込み
        if let url = Bundle.main.infoDictionary?["API_BASE_URL"] as? String,
           !url.isEmpty, url != "$(API_BASE_URL)" {
            return url
        }

        // 2. バンドル内の .env ファイルから読み込み
        if let envURL = Bundle.main.url(forResource: ".env", withExtension: nil),
           let content = try? String(contentsOf: envURL, encoding: .utf8) {
            let values = parseEnv(content)
            if let url = values["API_BASE_URL"] {
                return url
            }
        }

        // 3. デフォルト（ローカル開発用）
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
