import SwiftUI
import SwiftData
import Lottie

// MARK: - Jellyfish Particle Model
struct JellyfishParticle: Identifiable {
    let id = UUID()
    let xRatio: CGFloat      // 水平位置 (0.0〜1.0)
    let size: CGFloat         // フレームサイズ
    let duration: Double      // 浮上にかかる秒数
    let delay: Double         // 初回開始までの遅延
    let opacity: Double       // 透明度
    let animationSpeed: Double // Lottieアニメーション速度
    let horizontalSway: CGFloat // 左右の揺れ幅
}

// MARK: - Single Jellyfish View
struct FloatingJellyfishView: View {
    let particle: JellyfishParticle

    @State private var posY: CGFloat = 0
    @State private var swayOffset: CGFloat = 0
    @State private var hasStarted = false

    // UIScreenから確実な画面サイズを取得
    private var fullHeight: CGFloat { UIScreen.main.bounds.height }
    private var fullWidth: CGFloat { UIScreen.main.bounds.width }

    // 画面外の開始・終了位置（クラゲサイズ分の余裕を含む）
    private var startY: CGFloat { fullHeight + particle.size }
    private var endY: CGFloat { -particle.size }

    var body: some View {
        LottieView {
            try await DotLottieFile.named("Jellyfish")
        }
        .playbackMode(.playing(.toProgress(1, loopMode: .loop)))
        .animationSpeed(particle.animationSpeed)
        .frame(width: particle.size, height: particle.size)
        .opacity(hasStarted ? particle.opacity : 0)
        .position(
            x: fullWidth * particle.xRatio + swayOffset,
            y: posY
        )
        .onAppear {
            // 初期位置: 画面下端の外
            posY = startY

            // 遅延後に上昇開始
            DispatchQueue.main.asyncAfter(deadline: .now() + particle.delay) {
                hasStarted = true
                // 左右の揺れ
                withAnimation(
                    .easeInOut(duration: Double.random(in: 3.0...5.0))
                    .repeatForever(autoreverses: true)
                ) {
                    swayOffset = particle.horizontalSway
                }
                // 下から上へ繰り返し浮上
                withAnimation(
                    .linear(duration: particle.duration)
                    .repeatForever(autoreverses: false)
                ) {
                    posY = endY
                }
            }
        }
    }
}

// MARK: - Jellyfish Background
struct JellyfishBackgroundView: View {
    let particles: [JellyfishParticle]

    init() {
        // サイズのバリエーション: 各カテゴリから最低1匹ずつ出す
        let sizePresets: [ClosedRange<CGFloat>] = [
            40...55,    // 小さいクラゲ
            65...85,    // 中くらいのクラゲ
            95...120,   // 大きいクラゲ
            130...160,  // とても大きいクラゲ
        ]
        var generated: [JellyfishParticle] = []

        // まず各サイズカテゴリから1匹ずつ確保
        for (i, range) in sizePresets.enumerated() {
            let size = CGFloat.random(in: range)
            let duration = Double(size) / 5.0 + Double.random(in: 8...14)
            generated.append(
                JellyfishParticle(
                    xRatio: CGFloat.random(in: 0.05...0.95),
                    size: size,
                    duration: duration,
                    delay: Double(i) * Double.random(in: 1.5...3.0),
                    opacity: Double.random(in: 0.4...0.7),
                    animationSpeed: Double.random(in: 0.35...0.65),
                    horizontalSway: CGFloat.random(in: 5...16)
                )
            )
        }
        // 追加で2匹ランダムサイズ
        for i in 4..<6 {
            let range = sizePresets[Int.random(in: 0..<sizePresets.count)]
            let size = CGFloat.random(in: range)
            let duration = Double(size) / 5.0 + Double.random(in: 8...14)
            generated.append(
                JellyfishParticle(
                    xRatio: CGFloat.random(in: 0.05...0.95),
                    size: size,
                    duration: duration,
                    delay: Double(i) * Double.random(in: 1.5...3.0),
                    opacity: Double.random(in: 0.4...0.7),
                    animationSpeed: Double.random(in: 0.35...0.65),
                    horizontalSway: CGFloat.random(in: 5...16)
                )
            )
        }
        self.particles = generated.shuffled()
    }

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                FloatingJellyfishView(particle: particle)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// MARK: - 画面1: ホーム画面
struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appRouter: AppRouter
    @Query(sort: \Material.createdAt, order: .reverse) private var materials: [Material]

    @State private var showNewMaterial = false
    @State private var appearAnimation = false
    @State private var dailyTip: String = ""
    @State private var selectedRecallMaterial: Material?

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

    private let studyTips = [
        "何も見ずに思い出すことが、記憶を最も強くします。",
        "間違えても大丈夫！それが脳の成長のサインです。",
        "復習は「読む」のではなく、「思い出す」のがコツ。",
        "エビングハウスの忘却曲線に打ち勝とう！",
        "5分のリコールは、1時間の受動的な読書より効果的です。",
        "「思い出そうとする時の負荷」が記憶を脳に定着させます。",
        "少し忘れた頃に思い出すのが、最高のアクティブリコールです。",
        "インプット3割、アウトプット7割。これが学習の黄金比。",
        "完璧でなくてもOK。言葉を絞り出した数だけ定着します。",
        "昨日の自分を超えるために、今日のリコールを始めましょう！",
        "思い出す時に脳神経がつながります。頑張りどころです！"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                // 背景クラゲアニメーション
                JellyfishBackgroundView()

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
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("MindRecaller")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
            .sheet(isPresented: $showNewMaterial) {
                InputRegistrationView()
            }
            .sheet(isPresented: $appRouter.showLibrarySheet) {
                MaterialLibraryView(isPresentedAsSheet: true)
            }
            .sheet(item: $selectedRecallMaterial) { material in
                NavigationStack {
                    RecallSessionView(material: material)
                }
            }
            .id(appRouter.homeResetID)
            .onAppear {
                if dailyTip.isEmpty {
                    dailyTip = studyTips.randomElement() ?? studyTips[0]
                }
                withAnimation(.easeOut(duration: 0.8)) {
                    appearAnimation = true
                }
            }
        }
    }

    // MARK: - Header Card
    private var headerCard: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "quote.opening")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundColor(AppColors.primary.opacity(0.6))
                    Text("TIP OF THE DAY")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppColors.primary)
                        .tracking(1.2)
                }
                
                Text(dailyTip)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 16)
            ZStack {
                Circle()
                    .fill(AppColors.primary.opacity(0.1))
                    .frame(width: 56, height: 56)
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 24))
                    .foregroundColor(AppColors.primary)
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
                        Text("新しい教材を登録して学習")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)
                        Text("写真や動画から教材を登録して学習")
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

            Button {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                appRouter.showLibrarySheet = true
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(AppColors.primary.opacity(0.15))
                            .frame(width: 48, height: 48)
                        Image(systemName: "books.vertical.fill")
                            .font(.system(size: 22))
                            .foregroundColor(AppColors.primary)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("登録済みの教材を選択して学習")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)
                        Text("ライブラリから教材を選んで復習")
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
                Button {
                    selectedRecallMaterial = randomMaterial
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
                Button {
                    selectedRecallMaterial = material
                } label: {
                    MaterialRow(material: material)
                }
            }
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

                    if let score = material.highestScore {
                        Text("最高 \(score)点")
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
