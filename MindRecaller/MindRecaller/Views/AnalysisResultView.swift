import SwiftUI
import SwiftData

// MARK: - 画面5: 解析結果画面
struct AnalysisResultView: View {
    @Environment(\.dismiss) private var dismiss
    let studyLog: StudyLog
    let material: Material
    @State private var appear = false

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
                if !studyLog.missingKeywords.isEmpty {
                    missingKeywordsCard
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 20)
                }
                if !studyLog.missingConcepts.isEmpty {
                    missingConceptsCard
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 20)
                }
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
                Button { dismiss() } label: {
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
                Text(studyLog.scoreLevel.rawValue)
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

    // MARK: - Missing Keywords
    private var missingKeywordsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(AppColors.warning)
                Text("不足キーワード")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
            }
            FlowLayout(spacing: 8) {
                ForEach(studyLog.missingKeywords, id: \.self) { keyword in
                    Text(keyword)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppColors.warning)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(AppColors.warning.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
        .softCard()
    }

    // MARK: - Missing Concepts
    private var missingConceptsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "puzzlepiece.extension.fill")
                    .foregroundColor(AppColors.primary)
                Text("不足概念")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
            }
            ForEach(studyLog.missingConcepts, id: \.self) { concept in
                HStack(spacing: 10) {
                    Circle().fill(AppColors.primary.opacity(0.3)).frame(width: 6, height: 6)
                    Text(concept)
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textPrimary)
                }
            }
        }
        .softCard()
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
            Button { dismiss() } label: {
                Text("ホームに戻る")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }
}

// MARK: - Score Bar
struct ScoreBar: View {
    let title: String; let score: Int; let color: Color
    var body: some View {
        VStack(spacing: 10) {
            Text(title).font(.system(size: 13, weight: .semibold)).foregroundColor(AppColors.textSecondary)
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
