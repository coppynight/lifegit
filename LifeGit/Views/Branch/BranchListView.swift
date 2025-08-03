import SwiftUI
import SwiftData

struct BranchListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var branches: [Branch]
    @EnvironmentObject var appState: AppStateManager
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(branches) { branch in
                    BranchRowView(branch: branch)
                        .onTapGesture {
                            appState.switchToBranch(branch)
                        }
                }
            }
            .navigationTitle("分支列表")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // TODO: 创建新分支
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}

struct BranchRowView: View {
    let branch: Branch
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(branch.status.emoji)
                    Text(branch.name)
                        .font(.headline)
                }
                
                Text(branch.branchDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("\(Int(branch.progress * 100))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                
                Text(branch.createdAt.formatted(.dateTime.month().day()))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    BranchListView()
        .environmentObject(AppStateManager())
        .modelContainer(for: [User.self, Branch.self, Commit.self, TaskPlan.self, TaskItem.self])
}