import Foundation
import SwiftData

@Model
final class Material {
    var id: UUID
    var title: String
    var sourceText: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \StudyLog.material)
    var logs: [StudyLog]

    var tags: [String] = []

    init(
        id: UUID = UUID(),
        title: String = "",
        sourceText: String = "",
        createdAt: Date = Date(),
        logs: [StudyLog] = [],
        tags: [String] = []
    ) {
        self.id = id
        self.title = title
        self.sourceText = sourceText
        self.createdAt = createdAt
        self.logs = logs
        self.tags = tags
    }

    /// 最新の学習ログ
    var latestLog: StudyLog? {
        logs.sorted { $0.createdAt > $1.createdAt }.first
    }

    /// 平均スコア (0-100)
    var averageScore: Int? {
        guard !logs.isEmpty else { return nil }
        let total = logs.reduce(0) { $0 + ($1.logicScore + $1.termScore) / 2 }
        return total / logs.count
    }

    /// 最高スコア (0-100)
    var highestScore: Int? {
        guard !logs.isEmpty else { return nil }
        return logs.map { ($0.logicScore + $0.termScore) / 2 }.max()
    }

    /// 学習回数
    var studyCount: Int {
        logs.count
    }
}
