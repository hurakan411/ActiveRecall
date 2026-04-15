import Foundation
import SwiftData

@Model
final class StudyLog {
    var id: UUID
    var material: Material?
    var logicScore: Int
    var termScore: Int
    var recallText: String
    var logicFeedback: String
    var highlightedSegmentsData: Data = Data()
    var createdAt: Date

    // レガシー互換（マイグレーション用に残す）
    var missingKeywords: [String] = []
    var missingConcepts: [String] = []

    init(
        id: UUID = UUID(),
        material: Material? = nil,
        logicScore: Int = 0,
        termScore: Int = 0,
        recallText: String = "",
        logicFeedback: String = "",
        highlightedSegments: [APIService.HighlightedSegment] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.material = material
        self.logicScore = logicScore
        self.termScore = termScore
        self.recallText = recallText
        self.logicFeedback = logicFeedback
        self.highlightedSegmentsData = (try? JSONEncoder().encode(highlightedSegments)) ?? Data()
        self.createdAt = createdAt
    }

    /// デコード済みハイライトセグメント
    var highlightedSegments: [APIService.HighlightedSegment] {
        (try? JSONDecoder().decode([APIService.HighlightedSegment].self, from: highlightedSegmentsData)) ?? []
    }

    /// 総合スコア (0-100)
    var overallScore: Int {
        (logicScore + termScore) / 2
    }

    /// スコアレベル
    var scoreLevel: ScoreLevel {
        switch overallScore {
        case 80...100: return .excellent
        case 60..<80: return .good
        case 40..<60: return .fair
        default: return .needsWork
        }
    }

    enum ScoreLevel: String {
        case excellent = "素晴らしい"
        case good = "良い"
        case fair = "まずまず"
        case needsWork = "もう少し"

        var icon: String {
            switch self {
            case .excellent: return "face.smiling.inverse"
            case .good: return "hand.thumbsup.fill"
            case .fair: return "circle.dotted.circle"
            case .needsWork: return "arrow.up.heart.fill"
            }
        }

        var color: String {
            switch self {
            case .excellent: return "success"
            case .good: return "secondary"
            case .fair: return "warning"
            case .needsWork: return "primary"
            }
        }
    }
}
