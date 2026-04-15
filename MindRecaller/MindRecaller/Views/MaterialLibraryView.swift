import SwiftUI
import SwiftData

// MARK: - 画面2: 教材ライブラリ画面
struct MaterialLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appRouter: AppRouter
    @Query(sort: \Material.createdAt, order: .reverse) private var materials: [Material]

    @State private var searchText = ""
    @State private var showNewMaterial = false
    @State private var materialToDelete: Material?
    @State private var showDeleteConfirm = false
    @State private var editingMaterial: Material?
    @State private var selectedTagFilter: String? = nil

    var isPresentedAsSheet: Bool = false

    private var allTags: [String] {
        let all = materials.flatMap { $0.tags }
        return Array(Set(all)).sorted()
    }

    private var filteredMaterials: [Material] {
        var result = materials
        if let tagFilter = selectedTagFilter {
            result = result.filter { $0.tags.contains(tagFilter) }
        }
        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.sourceText.localizedCaseInsensitiveContains(searchText) ||
                $0.tags.contains { tag in tag.localizedCaseInsensitiveContains(searchText) }
            }
        }
        return result
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                if materials.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        // Tag filter
                        if !allTags.isEmpty {
                            Menu {
                                Button("すべて") { selectedTagFilter = nil }
                                ForEach(allTags, id: \.self) { tag in
                                    Button(tag) { selectedTagFilter = tag }
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "line.3.horizontal.decrease.circle")
                                    Text(selectedTagFilter ?? "タグで絞り込み")
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                }
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(selectedTagFilter == nil ? AppColors.textSecondary : AppColors.primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(AppColors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppColors.border, lineWidth: 1)
                                )
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                        }

                        LazyVStack(spacing: 12) {
                            ForEach(filteredMaterials) { material in
                                LibraryMaterialCard(
                                    material: material,
                                    onRecall: {},
                                    onEdit: { editingMaterial = material },
                                    onDelete: {
                                        materialToDelete = material
                                        showDeleteConfirm = true
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                    }
                    .searchable(text: $searchText, prompt: "教材を検索")
                }
            }
            .navigationTitle("ライブラリ")
            .toolbar {
                if isPresentedAsSheet {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        showNewMaterial = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
            .sheet(isPresented: $showNewMaterial) {
                InputRegistrationView()
            }
            .sheet(item: $editingMaterial) { material in
                MaterialEditView(material: material, allTags: allTags)
            }
            .alert("教材を削除", isPresented: $showDeleteConfirm) {
                Button("削除", role: .destructive) {
                    if let material = materialToDelete {
                        withAnimation(.easeOut(duration: 0.3)) {
                            modelContext.delete(material)
                        }
                    }
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("「\(materialToDelete?.title ?? "")」を削除しますか？学習ログも全て削除されます。")
            }
        }
        .id(appRouter.libraryResetID)
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(AppColors.primary.opacity(0.08))
                    .frame(width: 100, height: 100)
                Image(systemName: "books.vertical")
                    .font(.system(size: 40))
                    .foregroundColor(AppColors.primary.opacity(0.5))
            }

            Text("まだ教材がありません")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(AppColors.textPrimary)

            Text("写真を撮って最初の教材を\n登録しましょう")
                .font(.system(size: 14))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Button {
                showNewMaterial = true
            } label: {
                Label("教材を登録", systemImage: "plus")
            }
            .buttonStyle(SoftButtonStyle(color: AppColors.primary))
        }
        .padding(40)
    }
}

// MARK: - Library Material Card
struct LibraryMaterialCard: View {
    let material: Material
    let onRecall: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Title & Date
            HStack {
                Text(material.title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(2)

                Spacer()

                HStack(spacing: 12) {
                    Button {
                        onEdit()
                    } label: {
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(AppColors.secondary)
                    }
                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "trash.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(AppColors.warning)
                    }
                }
            }

            // Preview Text
            Text(material.sourceText)
                .font(.system(size: 13))
                .foregroundColor(AppColors.textSecondary)
                .lineLimit(2)
                .lineSpacing(3)

            // Tags
            if !material.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(material.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(AppColors.primary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AppColors.primary.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            // Stats Row
            HStack(spacing: 16) {
                Label("\(material.studyCount)回学習", systemImage: "arrow.clockwise")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)

                if let score = material.highestScore {
                    Label("最高 \(score)点", systemImage: "medal.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppColors.secondary)
                }

                Spacer()

                Text(material.createdAt.fullFormatted)
                    .font(.system(size: 11))
                    .foregroundColor(AppColors.textSecondary.opacity(0.7))
            }

            // Action Button
            NavigationLink {
                RecallSessionView(material: material)
            } label: {
                HStack {
                    Spacer()
                    Label("リコール開始", systemImage: "brain")
                        .font(.system(size: 14, weight: .semibold))
                    Spacer()
                }
            }
            .buttonStyle(SoftButtonStyle(color: AppColors.primary))
        }
        .softCard()
    }
}

// MARK: - Material Edit View
struct MaterialEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var material: Material
    let allTags: [String]
    @State private var newTag = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("タイトル")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppColors.textSecondary)
                        TextField("タイトルを入力", text: $material.title)
                            .font(.system(size: 16))
                            .foregroundColor(AppColors.textPrimary)
                            .padding(14)
                            .background(AppColors.background)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppColors.border, lineWidth: 1)
                            )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("ソーステキスト")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppColors.textSecondary)
                        TextEditor(text: $material.sourceText)
                            .font(.system(size: 15))
                            .foregroundColor(AppColors.textPrimary)
                            .scrollContentBackground(.hidden)
                            .padding(12)
                            .frame(minHeight: 300)
                            .background(AppColors.background)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppColors.border, lineWidth: 1)
                            )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("タグ (最大3つまで)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppColors.textSecondary)
                        
                        HStack {
                            TextField("タグを入力", text: $newTag)
                                .font(.system(size: 16))
                                .foregroundColor(AppColors.textPrimary)
                                .padding(14)
                                .background(AppColors.background)
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
                                    .background(material.tags.count >= 3 || newTag.trimmingCharacters(in: .whitespaces).isEmpty ? AppColors.secondary.opacity(0.5) : AppColors.secondary)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .disabled(material.tags.count >= 3 || newTag.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                        
                        if !material.tags.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(material.tags, id: \.self) { tag in
                                        HStack(spacing: 4) {
                                            Text(tag)
                                                .font(.system(size: 13, weight: .medium))
                                            Button(action: { material.tags.removeAll { $0 == tag } }) {
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
                        
                        let availableTags = allTags.filter { !material.tags.contains($0) }
                        if material.tags.count < 3 {
                            Menu {
                                if availableTags.isEmpty {
                                    Button("追加できる既存タグがありません") {}
                                        .disabled(true)
                                } else {
                                    ForEach(availableTags, id: \.self) { tag in
                                        Button(tag) {
                                            if material.tags.count < 3 {
                                                material.tags.append(tag)
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
                }
                .padding(20)
            }
            .background(AppColors.background)
            .navigationTitle("教材を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.primary)
                }
            }
        }
    }

    private func addTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && material.tags.count < 3 && !material.tags.contains(trimmed) {
            material.tags.append(trimmed)
            newTag = ""
        }
    }
}

#Preview {
    MaterialLibraryView()
        .modelContainer(for: [Material.self, StudyLog.self], inMemory: true)
}
