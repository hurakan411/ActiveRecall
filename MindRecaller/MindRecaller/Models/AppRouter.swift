import Foundation

class AppRouter: ObservableObject {
    @Published var homeResetID = UUID()
    @Published var libraryResetID = UUID()
    
    func resetToHome() {
        homeResetID = UUID()
    }
}
