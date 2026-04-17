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
    @Published var selectedRecallMaterial: Material?
    
    func resetToHome() {
        showLibrarySheet = false
        selectedRecallMaterial = nil
        selectedTab = .home
        
        // SwiftUIのUI更新サイクルと競合してIDリセットが無視されるのを防ぐため遅延更新していたが、
        // 画面が3秒間真っ白になる原因だったため、UUIDリセットによるツリー再構築を無効化
        // DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
        //     self.homeResetID = UUID()
        //     self.libraryResetID = UUID()
        // }
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
