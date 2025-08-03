import SwiftUI
import SwiftData

@main
struct LifeGitApp: App {
    @StateObject private var dataManager = DataManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
        }
        .modelContainer(dataManager.modelContainer)
    }
}
