import SwiftUI
import SwiftData
import StoreKit

// MARK: - 画面5: 解析結果画面
struct AnalysisResultView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview
    @EnvironmentObject var appRouter: AppRouter
    let studyLog: StudyLog
    let material: Material
    @State private var appear = false

    /// レビュー催促対象のリコール回数
    private static let reviewMilestones: Set<Int> = [1, 5, 10]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                scoreHeader
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 20)
                detailScores
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 20)
                feedbackCard
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 20)
                highlightedSourceCard
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 20)
                actionButtons
                    .opacity(appear ? 1 : 0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .background(AppColors.background)
        .navigationTitle("解析結果")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { requestReviewIfNeeded(); dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.7)) { appear = true }
        }
    }

    // MARK: - Score Header
    private var scoreHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(AppColors.border, lineWidth: 6)
                    .frame(width: 120, height: 120)
                Circle()
                    .trim(from: 0, to: appear ? CGFloat(studyLog.overallScore) / 100 : 0)
                    .stroke(
                        AppColors.scoreColor(studyLog.scoreLevel),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 1.2), value: appear)
                VStack(spacing: 2) {
                    Text("\(studyLog.overallScore)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                    Text("/ 100")
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            HStack(spacing: 6) {
                Image(systemName: studyLog.scoreLevel.icon)
                    .foregroundColor(AppColors.scoreColor(studyLog.scoreLevel))
                Text(LocalizedStringKey(studyLog.scoreLevel.rawValue))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppColors.scoreColor(studyLog.scoreLevel))
            }
        }
        .frame(maxWidth: .infinity)
        .softCard()
    }

    // MARK: - Detail Scores
    private var detailScores: some View {
        HStack(spacing: 12) {
            ScoreBar(title: "論理スコア", score: studyLog.logicScore, color: AppColors.primary)
            ScoreBar(title: "用語スコア", score: studyLog.termScore, color: AppColors.secondary)
        }
    }

    // MARK: - Feedback
    private var feedbackCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "text.bubble.fill")
                    .foregroundColor(AppColors.primary)
                Text("フィードバック")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
            }
            Text(studyLog.logicFeedback)
                .font(.system(size: 14))
                .foregroundColor(AppColors.textPrimary)
                .lineSpacing(5)
        }
        .softCard()
    }

    // MARK: - Highlighted Source Text
    private var highlightedSourceCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "doc.text.magnifyingglass")
                    .foregroundColor(AppColors.primary)
                Text("元のテキスト")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
            }

            // 凡例
            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.green.opacity(0.25))
                        .frame(width: 16, height: 16)
                    Text("想起できた")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                }
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.red.opacity(0.20))
                        .frame(width: 16, height: 16)
                    Text("想起できなかった")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .padding(.bottom, 4)

            // ハイライトされたテキスト表示
            let segments = studyLog.highlightedSegments
            if segments.isEmpty {
                // フォールバック: セグメントがない場合は元テキストをそのまま表示
                Text(material.sourceText)
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textPrimary)
                    .lineSpacing(5)
            } else {
                buildHighlightedText(segments: segments)
                    .lineSpacing(5)
            }
        }
        .softCard()
    }

    /// セグメント配列からAttributedStringを構築して色分け表示
    private func buildHighlightedText(segments: [APIService.HighlightedSegment]) -> some View {
        var attributedString = AttributedString()

        for segment in segments {
            var part = AttributedString(segment.text)
            if segment.recalled {
                part.foregroundColor = Color(hex: "1B5E20") // 濃い緑
                part.backgroundColor = Color.green.opacity(0.18)
            } else {
                part.foregroundColor = Color(hex: "B71C1C") // 濃い赤
                part.backgroundColor = Color.red.opacity(0.15)
            }
            part.font = .system(size: 14)
            attributedString.append(part)
        }

        return Text(attributedString)
    }

    // MARK: - Actions
    private var actionButtons: some View {
        VStack(spacing: 12) {
            NavigationLink {
                RecallSessionView(material: material)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text("もう一度リコール")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            Button { 
                requestReviewIfNeeded()
                appRouter.resetToHome()
            } label: {
                Text("ホームに戻る")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.top, 4)
        }
    }

    // MARK: - In-App Review
    /// リコール回数がマイルストーンに達していたらレビューを催促する
    private func requestReviewIfNeeded() {
        let totalRecalls = UserDefaults.standard.integer(forKey: "totalRecallCount")
        if Self.reviewMilestones.contains(totalRecalls) {
            // 同じマイルストーンで重複しないよう記録
            let key = "reviewRequested_\(totalRecalls)"
            guard !UserDefaults.standard.bool(forKey: key) else { return }
            UserDefaults.standard.set(true, forKey: key)
            
            // 少し遅延させてシートが閉じる前にポップアップが出るようにする
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                requestReview()
            }
        }
    }
}

// MARK: - Score Bar
struct ScoreBar: View {
    let title: String; let score: Int; let color: Color
    var body: some View {
        VStack(spacing: 10) {
            Text(LocalizedStringKey(title)).font(.system(size: 13, weight: .semibold)).foregroundColor(AppColors.textSecondary)
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6).fill(AppColors.border).frame(height: 10)
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 6).fill(color)
                        .frame(width: geo.size.width * CGFloat(score) / 100)
                }.frame(height: 10)
            }
            Text("\(score) 点").font(.system(size: 18, weight: .bold)).foregroundColor(AppColors.textPrimary)
        }
        .softCard()
    }
}

// MARK: - Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: ProposedViewSize(width: bounds.width, height: bounds.height), subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []; var x: CGFloat = 0; var y: CGFloat = 0; var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 { x = 0; y += rowHeight + spacing; rowHeight = 0 }
            positions.append(CGPoint(x: x, y: y)); rowHeight = max(rowHeight, size.height); x += size.width + spacing
        }
        return (positions, CGSize(width: maxWidth, height: y + rowHeight))
    }
}
