import SwiftUI
import SwiftData

// MARK: - 画面2: 教材ライブラリ画面
struct MaterialLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Material.createdAt, order: .reverse) private var materials: [Material]

    @State private var searchText = ""
    @State private var showNewMaterial = false
    @State private var materialToDelete: Material?
    @State private var showDeleteConfirm = false
    @State private var editingMaterial: Material?

    private var filteredMaterials: [Material] {
        if searchText.isEmpty { return materials }
        return materials.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.sourceText.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                if materials.isEmpty {
                    emptyState
                } else {
                    ScrollView {
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
                MaterialEditView(material: material)
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

                Menu {
                    Button {
                        onEdit()
                    } label: {
                        Label("編集", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("削除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.textSecondary)
                        .frame(width: 32, height: 32)
                }
            }

            // Preview Text
            Text(material.sourceText)
                .font(.system(size: 13))
                .foregroundColor(AppColors.textSecondary)
                .lineLimit(2)
                .lineSpacing(3)

            // Stats Row
            HStack(spacing: 16) {
                Label("\(material.studyCount)回学習", systemImage: "arrow.clockwise")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)

                if let score = material.averageScore {
                    Label("平均 \(score)点", systemImage: "chart.bar.fill")
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
}

#Preview {
    MaterialLibraryView()
        .modelContainer(for: [Material.self, StudyLog.self], inMemory: true)
}
