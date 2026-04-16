import SwiftUI
import SwiftData

// MARK: - V字型シェイプ
struct NordicVShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: .zero)
        p.addLine(to: CGPoint(x: rect.width, y: 0))
        p.addLine(to: CGPoint(x: rect.width, y: rect.height - 45))
        p.addLine(to: CGPoint(x: rect.width / 2, y: rect.height))
        p.addLine(to: CGPoint(x: 0, y: rect.height - 45))
        p.closeSubpath()
        return p
    }
}

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
    
    // 音声入力用
    @State private var speechRecognizer = SpeechRecognizer()
    @State private var previousRecallText = ""

    var body: some View {
        ZStack(alignment: .top) {
            AppColors.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    headerSection
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : -20)
                        .zIndex(1)
                    
                    VStack(spacing: 24) {
                        timerBadge
                            .padding(.top, 8)
                            .opacity(appear ? 1 : 0)
                            .offset(y: appear ? 0 : 10)
                        
                        inputArea
                            .opacity(appear ? 1 : 0)
                            .offset(y: appear ? 0 : 20)
                        
                        submitBtn
                            .opacity(appear ? 1 : 0)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .ignoresSafeArea(edges: .top)
            
            if isSubmitting { scoringOverlay }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        // ナビゲーションバーの背景を透明にしてV字シェイプを活かす
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationDestination(isPresented: $showResult) {
            if let log = resultLog {
                AnalysisResultView(studyLog: log, material: material)
            }
        }
        .onAppear {
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in seconds += 1 }
            withAnimation(.easeOut(duration: 0.6)) { appear = true }
        }
        .onDisappear { 
            timer?.invalidate()
            if speechRecognizer.isRecording {
                speechRecognizer.stopRecording()
            }
        }
        .onChange(of: speechRecognizer.transcript) { _, newTranscript in
            if speechRecognizer.isRecording {
                let separator = previousRecallText.isEmpty ? "" : (previousRecallText.hasSuffix("\n") ? "" : " ")
                recallText = previousRecallText + separator + newTranscript
            }
        }
        .alert("AI採点エラー", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "サーバー通信中にエラーが発生しました。")
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.85))
                Text("ACTIVE RECALL")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
                    .tracking(1.5)
                Spacer()
            }
            .padding(.top, 8)
            
            Text(material.title)
                .font(.system(size: 26, weight: .heavy))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineSpacing(4)
                .padding(.bottom, 2)
            
            Text("この教材の内容を記憶から呼び起こし、\nできるだけ詳しく書き出してください。")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineSpacing(4)
        }
        .padding(.horizontal, 24)
        .padding(.top, 60) // Safe Area を考慮して上部余白を大きめにとる
        .padding(.bottom, 48) // 下部にも少し余白を持たせてV字に余裕を作る
        .background(
            NordicVShape()
                .fill(
                    LinearGradient(
                        colors: [AppColors.primary, Color(hex: "023E8A")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: AppColors.primary.opacity(0.4), radius: 15, x: 0, y: 10)
        )
    }

    private var timerBadge: some View {
        HStack {
            Image(systemName: "clock")
                .font(.system(size: 14))
                .foregroundColor(AppColors.textSecondary)
            Text(String(format: "%02d:%02d", seconds / 60, seconds % 60))
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(AppColors.textPrimary)
        }
        .padding(.vertical, 10).padding(.horizontal, 20)
        .background(AppColors.surface)
        .clipShape(Capsule())
        .shadow(color: AppColors.primary.opacity(0.1), radius: 8, x: 0, y: 4)
    }

    private var inputArea: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("入力")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppColors.textSecondary)
                Spacer()
                
                // 音声入力ボタン
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    
                    if speechRecognizer.isRecording {
                        speechRecognizer.stopRecording()
                    } else {
                        speechRecognizer.checkPermission { granted in
                            if granted {
                                previousRecallText = recallText
                                speechRecognizer.startRecording()
                            } else {
                                errorMessage = "マイクと音声認識へのアクセスを許可してください。"
                                showErrorAlert = true
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: speechRecognizer.isRecording ? "stop.circle.fill" : "mic.fill")
                            .font(.system(size: 14))
                        Text(speechRecognizer.isRecording ? "完了" : "音声で入力")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(speechRecognizer.isRecording ? .red : AppColors.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(speechRecognizer.isRecording ? Color.red.opacity(0.12) : AppColors.primary.opacity(0.12))
                    .clipShape(Capsule())
                }
                .padding(.trailing, 2)
                
                if !recallText.isEmpty {
                    Button {
                        // 少しアニメーションをつけて削除する
                        withAnimation(.easeOut(duration: 0.2)) {
                            recallText = ""
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                                .font(.system(size: 12))
                            Text("全削除")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppColors.textSecondary.opacity(0.1))
                        .clipShape(Capsule())
                    }
                    .padding(.trailing, 4)
                }
                Text("\(recallText.count) 文字")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppColors.primary)
            }
            TextEditor(text: $recallText)
                .font(.system(size: 16))
                .foregroundColor(AppColors.textPrimary)
                .scrollContentBackground(.hidden)
                .padding(16)
                .frame(minHeight: 320)
                .background(AppColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.border, lineWidth: 1))
                .shadow(color: AppColors.primary.opacity(0.04), radius: 10, x: 0, y: 4)
                .overlay(alignment: .topLeading) {
                    if recallText.isEmpty && !speechRecognizer.isRecording {
                        Text("学習したキーワードや概念、流れなどを\n思い出して自由に書き出しましょう...")
                            .font(.system(size: 16))
                            .foregroundColor(AppColors.textSecondary.opacity(0.5))
                            .padding(20)
                            .allowsHitTesting(false)
                            .lineSpacing(6)
                    } else if speechRecognizer.isRecording && recallText.isEmpty {
                        Text("聞き取っています...")
                            .font(.system(size: 16))
                            .foregroundColor(.red.opacity(0.6))
                            .padding(20)
                            .allowsHitTesting(false)
                    }
                }
        }
    }

    private var submitBtn: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            submit()
        } label: {
            HStack(spacing: 10) { Image(systemName: "sparkles"); Text("AIで解析する") }
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(recallText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
        .opacity(recallText.isEmpty ? 0.5 : 1.0)
        .padding(.top, 8)
    }

    private var scoringOverlay: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            VStack(spacing: 20) {
                ProgressView().scaleEffect(1.2).tint(AppColors.primary)
                Text("AIが採点中...")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
            }
            .padding(32)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.2), radius: 30)
        }
    }

    private func submit() {
        isSubmitting = true; timer?.invalidate()
        Task {
            do {
                let r = try await APIService.shared.scoreRecall(sourceText: material.sourceText, recallText: recallText)
                let log = StudyLog(material: material, logicScore: r.logicScore, termScore: r.termScore, recallText: recallText, logicFeedback: r.logicFeedback, highlightedSegments: r.highlightedSegments)
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
