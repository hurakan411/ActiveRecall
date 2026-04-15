import SwiftUI
import SwiftData
import PhotosUI

// MARK: - 画面3: インプット選択・登録画面
struct InputRegistrationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var materials: [Material]

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var title = ""
    @State private var sourceText = ""
    @State private var tags: [String] = []
    @State private var newTag = ""
    @State private var isAnalyzing = false
    @State private var showCamera = false
    @State private var inputMode: InputMode = .selection
    @State private var errorMessage: String?

    enum InputMode {
        case selection
        case editor
    }

    private var allTags: [String] {
        let all = materials.flatMap { $0.tags }
        return Array(Set(all)).sorted()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                switch inputMode {
                case .selection:
                    selectionView
                case .editor:
                    editorView
                }

                if isAnalyzing {
                    analyzingOverlay
                }
            }
            .navigationTitle(inputMode == .selection ? "教材を追加" : "内容を確認")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.textSecondary)
                }

                if inputMode == .editor {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("保存") {
                            saveMaterial()
                        }
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.primary)
                        .disabled(title.isEmpty || sourceText.isEmpty)
                    }
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraView { image in
                    selectedImage = image
                    analyzeImage(image)
                }
            }
            .onChange(of: selectedPhoto) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImage = image
                        analyzeImage(image)
                    }
                }
            }
        }
    }

    // MARK: - Selection View
    private var selectionView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(AppColors.primary.opacity(0.08))
                    .frame(width: 100, height: 100)
                Image(systemName: "doc.viewfinder")
                    .font(.system(size: 40))
                    .foregroundColor(AppColors.primary)
            }

            Text("教材の登録方法を選択")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppColors.textPrimary)

            Text("写真から自動でテキストを抽出し、\n学習教材として登録します")
                .font(.system(size: 14))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            VStack(spacing: 14) {
                // カメラ
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    showCamera = true
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(AppColors.primary.opacity(0.12))
                                .frame(width: 44, height: 44)
                            Image(systemName: "camera.fill")
                                .font(.system(size: 18))
                                .foregroundColor(AppColors.primary)
                        }
                        Text("カメラで撮影")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .softCard()

                // フォトライブラリ
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(AppColors.secondary.opacity(0.12))
                                .frame(width: 44, height: 44)
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 18))
                                .foregroundColor(AppColors.secondary)
                        }
                        Text("写真から選択")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .softCard()

                // 手動入力
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    withAnimation(.easeInOut(duration: 0.3)) {
                        inputMode = .editor
                    }
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(AppColors.warning.opacity(0.12))
                                .frame(width: 44, height: 44)
                            Image(systemName: "keyboard")
                                .font(.system(size: 18))
                                .foregroundColor(AppColors.warning)
                        }
                        Text("テキストを直接入力")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .softCard()
            }
            .padding(.horizontal, 20)

            Spacer()
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Editor View (自動入力エディタ)
    private var editorView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // プレビュー画像
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppColors.border, lineWidth: 1)
                        )
                }

                // タイトル
                VStack(alignment: .leading, spacing: 8) {
                    Text("タイトル")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppColors.textSecondary)
                    TextField("タイトルを入力", text: $title)
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.textPrimary)
                        .padding(14)
                        .background(AppColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppColors.border, lineWidth: 1)
                        )
                }

                // ソーステキスト
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("ソーステキスト")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppColors.textSecondary)
                        Spacer()
                        if selectedImage != nil {
                            Text("AI抽出済み・編集可能")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(AppColors.success)
                        }
                    }
                    TextEditor(text: $sourceText)
                        .font(.system(size: 15))
                        .foregroundColor(AppColors.textPrimary)
                        .scrollContentBackground(.hidden)
                        .padding(12)
                        .frame(minHeight: 250)
                        .background(AppColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppColors.border, lineWidth: 1)
                        )
                }

                // タグ
                VStack(alignment: .leading, spacing: 8) {
                    Text("タグ (最大3つまで)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppColors.textSecondary)
                    
                    HStack {
                        TextField("タグを入力", text: $newTag)
                            .font(.system(size: 16))
                            .foregroundColor(AppColors.textPrimary)
                            .padding(14)
                            .background(AppColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppColors.border, lineWidth: 1)
                            )
                            .onSubmit { addTag() }
                        
                        Button(action: { addTag() }) {
                            Text("追加")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(tags.count >= 3 || newTag.trimmingCharacters(in: .whitespaces).isEmpty ? AppColors.secondary.opacity(0.5) : AppColors.secondary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(tags.count >= 3 || newTag.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    
                    if !tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(tags, id: \.self) { tag in
                                    HStack(spacing: 4) {
                                        Text(tag)
                                            .font(.system(size: 13, weight: .medium))
                                        Button(action: { tags.removeAll { $0 == tag } }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 12))
                                                .foregroundColor(AppColors.primary)
                                        }
                                    }
                                    .foregroundColor(AppColors.primary)
                                    .padding(.horizontal, 12).padding(.vertical, 6)
                                    .background(AppColors.primary.opacity(0.1))
                                    .clipShape(Capsule())
                                }
                            }
                        }
                    }
                    
                    let availableTags = allTags.filter { !tags.contains($0) }
                    if tags.count < 3 {
                        Menu {
                            if availableTags.isEmpty {
                                Button("追加できる既存タグがありません") {}
                                    .disabled(true)
                            } else {
                                ForEach(availableTags, id: \.self) { tag in
                                    Button(tag) {
                                        if tags.count < 3 {
                                            tags.append(tag)
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "tag.fill")
                                Text("既存のタグから追加")
                                Spacer()
                                Image(systemName: "chevron.down")
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(availableTags.isEmpty ? AppColors.secondary.opacity(0.5) : AppColors.secondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(AppColors.secondary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .disabled(availableTags.isEmpty)
                    }
                }

                if let error = errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(AppColors.warning)
                        Text(error)
                            .font(.system(size: 13))
                            .foregroundColor(AppColors.warning)
                    }
                    .padding(12)
                    .background(AppColors.warning.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(20)
        }
    }

    // MARK: - Analyzing Overlay
    private var analyzingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(AppColors.primary)
                Text("AIがテキストを抽出中...")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
            }
            .padding(32)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.1), radius: 20)
        }
    }

    // MARK: - Actions
    private func analyzeImage(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }

        isAnalyzing = true
        errorMessage = nil

        Task {
            do {
                let result = try await APIService.shared.analyzeInput(imageData: imageData)
                await MainActor.run {
                    title = result.title
                    sourceText = result.sourceText
                    isAnalyzing = false
                    withAnimation(.easeInOut(duration: 0.3)) {
                        inputMode = .editor
                    }
                }
            } catch {
                await MainActor.run {
                    isAnalyzing = false
                    errorMessage = "AI解析に失敗しました。テキストを手動で入力してください。"
                    withAnimation(.easeInOut(duration: 0.3)) {
                        inputMode = .editor
                    }
                }
            }
        }
    }

    private func saveMaterial() {
        let material = Material(
            title: title,
            sourceText: sourceText,
            tags: tags
        )
        modelContext.insert(material)

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        dismiss()
    }

    private func addTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && tags.count < 3 && !tags.contains(trimmed) {
            tags.append(trimmed)
            newTag = ""
        }
    }
}

// MARK: - Camera View (AVFoundation)
struct CameraView: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (UIImage) -> Void

        init(onCapture: @escaping (UIImage) -> Void) {
            self.onCapture = onCapture
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                onCapture(image)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

#Preview {
    InputRegistrationView()
        .modelContainer(for: [Material.self, StudyLog.self], inMemory: true)
}
