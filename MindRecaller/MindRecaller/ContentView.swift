import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .home

    enum Tab: String, CaseIterable {
        case home = "ホーム"
        case library = "ライブラリ"

        var icon: String {
            switch self {
            case .home: return "brain.head.profile"
            case .library: return "books.vertical"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label(Tab.home.rawValue, systemImage: Tab.home.icon)
                }
                .tag(Tab.home)

            MaterialLibraryView()
                .tabItem {
                    Label(Tab.library.rawValue, systemImage: Tab.library.icon)
                }
                .tag(Tab.library)
        }
        .tint(AppColors.primary)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Material.self, StudyLog.self], inMemory: true)
}
