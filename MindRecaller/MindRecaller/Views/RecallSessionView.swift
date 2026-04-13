import SwiftUI
import SwiftData

// MARK: - 画面4: アクティブリコール実行画面
struct RecallSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let material: Material

    @State private var recallText = ""
    @State private var isSubmitting = false
    @State private var showResult = false
    @State private var resultLog: StudyLog?
    @State private var appear = false
    @State private var seconds = 0
    @State private var timer: Timer?
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert = false

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    hintCard.opacity(appear ? 1 : 0).offset(y: appear ? 0 : 20)
                    timerBadge.opacity(appear ? 1 : 0)
                    inputArea.opacity(appear ? 1 : 0).offset(y: appear ? 0 : 20)
                    submitBtn.opacity(appear ? 1 : 0)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16).padding(.bottom, 40)
            }
            if isSubmitting { scoringOverlay }
        }
        .navigationTitle("リコール")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showResult) {
            if let log = resultLog {
                AnalysisResultView(studyLog: log, material: material)
            }
        }
        .onAppear {
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in seconds += 1 }
            withAnimation(.easeOut(duration: 0.6)) { appear = true }
        }
        .onDisappear { timer?.invalidate() }
        .alert("AI採点エラー", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "サーバー通信中にエラーが発生しました。")
        }
    }

    private var hintCard: some View {
        VStack(spacing: 14) {
            HStack {
                Image(systemName: "lightbulb.fill").font(.system(size: 16)).foregroundColor(AppColors.warning)
                Text("ヒント：タイトルのみ").font(.system(size: 13, weight: .semibold)).foregroundColor(AppColors.textSecondary)
                Spacer()
            }
            Text(material.title)
                .font(.system(size: 22, weight: .bold)).foregroundColor(AppColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading).lineSpacing(4)
            Text("この教材の内容を思い出して、\nできるだけ詳しく書き出してください")
                .font(.system(size: 13)).foregroundColor(AppColors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading).lineSpacing(3)
        }.softCard()
    }

    private var timerBadge: some View {
        HStack {
            Image(systemName: "clock").font(.system(size: 14)).foregroundColor(AppColors.textSecondary)
            Text(String(format: "%02d:%02d", seconds / 60, seconds % 60))
                .font(.system(size: 16, weight: .medium, design: .monospaced)).foregroundColor(AppColors.textPrimary)
        }
        .padding(.vertical, 8).padding(.horizontal, 16)
        .background(AppColors.surface).clipShape(Capsule())
        .overlay(Capsule().stroke(AppColors.border, lineWidth: 1))
    }

    private var inputArea: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("想起入力").font(.system(size: 14, weight: .semibold)).foregroundColor(AppColors.textSecondary)
                Spacer()
                Text("\(recallText.count) 文字").font(.system(size: 12, weight: .medium)).foregroundColor(AppColors.textSecondary.opacity(0.7))
            }
            TextEditor(text: $recallText)
                .font(.system(size: 16)).foregroundColor(AppColors.textPrimary)
                .scrollContentBackground(.hidden).padding(14).frame(minHeight: 280)
                .background(AppColors.surface).clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppColors.border, lineWidth: 1))
                .overlay(alignment: .topLeading) {
                    if recallText.isEmpty {
                        Text("ここに覚えている内容を書き出してください...")
                            .font(.system(size: 16)).foregroundColor(AppColors.textSecondary.opacity(0.5))
                            .padding(18).allowsHitTesting(false)
                    }
                }
        }
    }

    private var submitBtn: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            submit()
        } label: {
            HStack(spacing: 10) { Image(systemName: "sparkle.magnifyingglass"); Text("AIで解析する") }
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(recallText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
        .opacity(recallText.isEmpty ? 0.5 : 1.0)
    }

    private var scoringOverlay: some View {
        ZStack {
            Color.black.opacity(0.3).ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView().scaleEffect(1.2).tint(AppColors.primary)
                Text("AIが採点中...").font(.system(size: 15, weight: .medium)).foregroundColor(AppColors.textPrimary)
            }.padding(32).background(AppColors.surface).clipShape(RoundedRectangle(cornerRadius: 16)).shadow(color: .black.opacity(0.1), radius: 20)
        }
    }

    private func submit() {
        isSubmitting = true; timer?.invalidate()
        Task {
            do {
                let r = try await APIService.shared.scoreRecall(sourceText: material.sourceText, recallText: recallText)
                let log = StudyLog(material: material, logicScore: r.logicScore, termScore: r.termScore, recallText: recallText, logicFeedback: r.logicFeedback, missingKeywords: r.missingKeywords, missingConcepts: r.missingConcepts)
                await MainActor.run { modelContext.insert(log); resultLog = log; isSubmitting = false; UINotificationFeedbackGenerator().notificationOccurred(.success); showResult = true }
            } catch {
                await MainActor.run { 
                    isSubmitting = false
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
}
