import SwiftUI
import SwiftData

// MARK: - 画面1: ホーム画面
struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Material.createdAt, order: .reverse) private var materials: [Material]

    @State private var showNewMaterial = false
    @State private var appearAnimation = false

    private var todayStudyCount: Int {
        let calendar = Calendar.current
        return materials.flatMap { $0.logs }.filter {
            calendar.isDateInToday($0.createdAt)
        }.count
    }

    private var totalStudyCount: Int {
        materials.flatMap { $0.logs }.count
    }

    private var recentMaterials: [Material] {
        Array(materials.prefix(5))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // ヘッダーカード
                    headerCard
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : 15)

                    // 統計カード
                    statsSection
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : 15)

                    // クイックスタート
                    quickStartSection
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : 15)

                    // 最近の教材
                    if !recentMaterials.isEmpty {
                        recentSection
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : 15)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(AppColors.background)
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("MindRecaller")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                }
            }
            .sheet(isPresented: $showNewMaterial) {
                InputRegistrationView()
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) {
                    appearAnimation = true
                }
            }
        }
    }

    // MARK: - Header Card
    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(greetingText)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                    Text("今日の学習を\n始めましょう")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                        .lineSpacing(4)
                }
                Spacer()
                ZStack {
                    Circle()
                        .fill(AppColors.primary.opacity(0.1))
                        .frame(width: 64, height: 64)
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 28))
                        .foregroundColor(AppColors.primary)
                }
            }
        }
        .softCard()
    }

    // MARK: - Stats
    private var statsSection: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "今日",
                value: "\(todayStudyCount)",
                unit: "回",
                icon: "flame.fill",
                color: AppColors.warning
            )
            StatCard(
                title: "教材数",
                value: "\(materials.count)",
                unit: "件",
                icon: "book.closed.fill",
                color: AppColors.secondary
            )
            StatCard(
                title: "総学習",
                value: "\(totalStudyCount)",
                unit: "回",
                icon: "chart.line.uptrend.xyaxis",
                color: AppColors.primary
            )
        }
    }

    // MARK: - Quick Start
    private var quickStartSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("学習を始める")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(AppColors.textPrimary)

            Button {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                showNewMaterial = true
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(AppColors.secondary.opacity(0.15))
                            .frame(width: 48, height: 48)
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(AppColors.secondary)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("新しい教材を登録")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)
                        Text("写真を撮って学習教材を追加")
                            .font(.system(size: 13))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .softCard()

            if let randomMaterial = materials.randomElement() {
                NavigationLink {
                    RecallSessionView(material: randomMaterial)
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(AppColors.primary.opacity(0.15))
                                .frame(width: 48, height: 48)
                            Image(systemName: "brain")
                                .font(.system(size: 22))
                                .foregroundColor(AppColors.primary)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text("ランダムに復習")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppColors.textPrimary)
                            Text(randomMaterial.title)
                                .font(.system(size: 13))
                                .foregroundColor(AppColors.textSecondary)
                                .lineLimit(1)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .softCard()
            }
        }
    }

    // MARK: - Recent
    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("最近の教材")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(AppColors.textPrimary)

            ForEach(recentMaterials) { material in
                NavigationLink {
                    RecallSessionView(material: material)
                } label: {
                    MaterialRow(material: material)
                }
            }
        }
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "おはようございます ☀️"
        case 12..<17: return "こんにちは 🌤"
        case 17..<21: return "こんばんは 🌙"
        default: return "お疲れさまです 🌟"
        }
    }
}

// MARK: - Stat Card Component
struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                Text(unit)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
            }

            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .softCard()
    }
}

// MARK: - Material Row
struct MaterialRow: View {
    let material: Material

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppColors.primary.opacity(0.08))
                    .frame(width: 44, height: 44)
                Image(systemName: "doc.text")
                    .font(.system(size: 18))
                    .foregroundColor(AppColors.primary)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(material.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text("\(material.studyCount)回学習")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textSecondary)

                    if let score = material.averageScore {
                        Text("平均 \(score)点")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.secondary)
                    }
                }
            }

            Spacer()

            Text(material.createdAt.shortFormatted)
                .font(.system(size: 12))
                .foregroundColor(AppColors.textSecondary)
        }
        .softCard()
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Material.self, StudyLog.self], inMemory: true)
}
