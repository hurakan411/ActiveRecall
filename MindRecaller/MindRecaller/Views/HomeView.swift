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
    
    // オンボーディング
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var onboardingStep = 1

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
                            .anchorPreference(key: OnboardingAnchorKey.self, value: .bounds, transform: { [1: $0] })

                        // 統計カード
                        statsSection
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : 15)
                            .anchorPreference(key: OnboardingAnchorKey.self, value: .bounds, transform: { [2: $0] })

                        // クイックスタート
                        quickStartSection
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : 15)
                            .anchorPreference(key: OnboardingAnchorKey.self, value: .bounds, transform: { [3: $0] })

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
                InputRegistrationView(onRegistered: { material in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.selectedRecallMaterial = material
                    }
                })
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
        .overlayPreferenceValue(OnboardingAnchorKey.self) { anchors in
            if !hasCompletedOnboarding {
                GeometryReader { geo in
                    coachMarkOverlay(anchors: anchors, geo: geo)
                }
                .ignoresSafeArea()
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
            LottieView {
                try await DotLottieFile.named("Seaweed")
            }
            .playing(loopMode: .loop)
            .frame(width: 80, height: 80)
            .offset(y: 16)
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

// MARK: - Animatable Spotlight Shape
struct SpotlightShape: Shape {
    var holeX: CGFloat
    var holeY: CGFloat
    var holeWidth: CGFloat
    var holeHeight: CGFloat
    var cornerRadius: CGFloat = 16
    
    var animatableData: AnimatablePair<AnimatablePair<CGFloat, CGFloat>, AnimatablePair<CGFloat, CGFloat>> {
        get { AnimatablePair(AnimatablePair(holeX, holeY), AnimatablePair(holeWidth, holeHeight)) }
        set {
            holeX = newValue.first.first
            holeY = newValue.first.second
            holeWidth = newValue.second.first
            holeHeight = newValue.second.second
        }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(rect)
        if holeWidth > 0 && holeHeight > 0 {
            let hole = CGRect(
                x: holeX - 6, y: holeY - 6,
                width: holeWidth + 12, height: holeHeight + 12
            )
            path.addRoundedRect(in: hole, cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
        }
        return path
    }
}

// MARK: - Onboarding Overlay & Anchor
struct OnboardingAnchorKey: PreferenceKey {
    static var defaultValue: [Int: Anchor<CGRect>] = [:]
    static func reduce(value: inout [Int: Anchor<CGRect>], nextValue: () -> [Int: Anchor<CGRect>]) {
        value.merge(nextValue()) { _, new in new }
    }
}

extension HomeView {
    
    private func advanceOnboarding() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        if onboardingStep < 3 {
            onboardingStep += 1
        } else {
            hasCompletedOnboarding = true
        }
    }
    
    @ViewBuilder
    func coachMarkOverlay(anchors: [Int: Anchor<CGRect>], geo: GeometryProxy) -> some View {
        let rect = anchors[onboardingStep].map { geo[$0] } ?? .zero
        let isAboveCenter = rect.midY < geo.size.height * 0.4
        let tooltipY = isAboveCenter ? rect.maxY + 50 : rect.minY - 50
        
        ZStack {
            // 1. スポットライト（くり抜き）
            SpotlightShape(
                holeX: rect.minX,
                holeY: rect.minY,
                holeWidth: rect.width,
                holeHeight: rect.height
            )
            .fill(Color.black.opacity(0.65), style: FillStyle(eoFill: true))
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .animation(.easeInOut(duration: 0.3), value: onboardingStep)
            
            // 2. 白枠
            if rect != .zero {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.9), lineWidth: 2.5)
                    .frame(width: rect.width + 12, height: rect.height + 12)
                    .position(x: rect.midX, y: rect.midY)
                    .allowsHitTesting(false)
                    .animation(.easeInOut(duration: 0.3), value: onboardingStep)
            }
            
            // 3. 吹き出しメッセージ
            if rect != .zero {
                VStack(spacing: 4) {
                    if !isAboveCenter {
                        tooltipBubble(message: onboardingMessage(for: onboardingStep))
                        
                        Image(systemName: "arrowtriangle.down.fill")
                            .foregroundColor(AppColors.surface)
                            .font(.system(size: 16))
                            .offset(y: -4)
                    } else {
                        Image(systemName: "arrowtriangle.up.fill")
                            .foregroundColor(AppColors.surface)
                            .font(.system(size: 16))
                            .offset(y: 4)
                        
                        tooltipBubble(message: onboardingMessage(for: onboardingStep))
                    }
                }
                .position(x: geo.size.width / 2, y: tooltipY)
                .allowsHitTesting(false)
                .animation(.easeInOut(duration: 0.3), value: onboardingStep)
            }
            
            // 4. 全画面タップで次へ進む
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { advanceOnboarding() }
            
            // 5. ステップ表示（上部ドット）
            VStack {
                HStack(spacing: 6) {
                    ForEach(1...3, id: \.self) { i in
                        Circle()
                            .fill(i == onboardingStep ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, geo.safeAreaInsets.top + 20)
                Spacer()
            }
            .allowsHitTesting(false)
        }
    }
    
    private func tooltipBubble(message: String) -> some View {
        Text(message)
            .font(.system(size: 15, weight: .bold))
            .multilineTextAlignment(.center)
            .foregroundColor(AppColors.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AppColors.surface)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.3), radius: 8)
            .padding(.horizontal, 24)
    }
    
    private func onboardingMessage(for step: Int) -> String {
        switch step {
        case 1:
            return "学習に役立つヒントが毎日届きます。\nモチベーションを高めましょう！"
        case 2:
            return "学習の進捗がひと目でわかります。\n毎日のリコール回数を増やしましょう！"
        case 3:
            return "ここから教材の登録・アクティブリコールができます。\nマイク入力やカメラからAIで自動生成！"
        default:
            return ""
        }
    }
}
