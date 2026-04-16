import Foundation

/// .env から環境変数を読み込むユーティリティ
/// Info.plist 経由（xcconfig）とフォールバックの .env ファイル直読みの両方に対応
enum AppEnvironment {

    // 開発環境と本番環境の切り替え用フラグ
    static let useRenderBackend = true
    
    // ⚠️ここにRenderから発行された自分のアプリのURLを貼り付けてください！
    // 例: "https://mindrecaller-backend.onrender.com"
    static let renderApiBaseURL = "https://activerecall.onrender.com" // ←※このURLは仮ですので、ご自身のURLに変更してください
    static let localApiBaseURL = "http://localhost:8000"

    /// API ベース URL
    static var apiBaseURL: String {
        return useRenderBackend ? renderApiBaseURL : localApiBaseURL
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
