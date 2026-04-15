import SwiftUI

enum TabSelection: String, CaseIterable {
    case home = "ホーム"
    case library = "ライブラリ"

    var icon: String {
        switch self {
        case .home: return "brain.head.profile"
        case .library: return "books.vertical"
        }
    }
}

class AppRouter: ObservableObject {
    @Published var homeResetID = UUID()
    @Published var libraryResetID = UUID()
    @Published var selectedTab: TabSelection = .home
    @Published var showLibrarySheet = false
    
    func resetToHome() {
        showLibrarySheet = false
        selectedTab = .home
        
        // SwiftUIのUI更新サイクルと競合してIDリセットが無視されるのを防ぐため、
        // 少しだけ遅延させてからIDを更新し、確実にNavigationStackを再構築させる
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.homeResetID = UUID()
            self.libraryResetID = UUID()
        }
    }
}

struct ContentView: View {
    @StateObject private var appRouter = AppRouter()

    var body: some View {
        TabView(selection: $appRouter.selectedTab) {
            HomeView()
                .tabItem {
                    Label(TabSelection.home.rawValue, systemImage: TabSelection.home.icon)
                }
                .tag(TabSelection.home)

            MaterialLibraryView()
                .tabItem {
                    Label(TabSelection.library.rawValue, systemImage: TabSelection.library.icon)
                }
                .tag(TabSelection.library)
        }
        .environmentObject(appRouter)
        .id(appRouter.homeResetID)
        .tint(AppColors.primary)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Material.self, StudyLog.self], inMemory: true)
}
