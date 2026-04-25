import SwiftUI
import SwiftData

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english = "en"
    case japanese = "ja"

    var id: String { self.rawValue }

    var displayName: String {
        switch self {
        case .system: return "System Default"
        case .english: return "English"
        case .japanese: return "日本語"
        }
    }
    
    var localeIdentifier: String? {
        switch self {
        case .system: return nil
        case .english: return "en"
        case .japanese: return "ja"
        }
    }
}

struct LocaleModifier: ViewModifier {
    var appLanguage: AppLanguage
    func body(content: Content) -> some View {
        if let identifier = appLanguage.localeIdentifier {
            content.environment(\.locale, Locale(identifier: identifier))
        } else {
            content
        }
    }
}

@main
struct MindRecallerApp: App {
    @AppStorage("appLanguage") private var appLanguage: AppLanguage = .system
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Material.self,
            StudyLog.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        do {
            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modifier(LocaleModifier(appLanguage: appLanguage))
                .id(appLanguage)  // 言語変更時にビュー階層を再生成（テキスト重なり防止）
        }
        .modelContainer(sharedModelContainer)
    }
}
