import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var appState = AppStateManager()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                if let currentBranch = appState.currentBranch {
                    BranchDetailView(branch: currentBranch)
                } else {
                    MasterBranchView()
                }
            }
            .tabItem {
                Image(systemName: "git.branch")
                Text("分支")
            }
            .tag(0)
            
            BranchListView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("列表")
                }
                .tag(1)
            
            Text("统计功能开发中...")
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("统计")
                }
                .tag(2)
            
            Text("设置功能开发中...")
                .tabItem {
                    Image(systemName: "gear")
                    Text("设置")
                }
                .tag(3)
        }
        .environmentObject(appState)
        .onAppear {
            appState.initialize(modelContext: modelContext)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [User.self, Branch.self, Commit.self, TaskPlan.self, TaskItem.self])
}