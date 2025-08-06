import SwiftUI

struct BranchListView: View {
    @EnvironmentObject private var appState: AppStateManager
    @State private var showingCreateBranch = false
    
    var body: some View {
        NavigationView {
            List {
                // Active branches
                if !appState.activeBranches.isEmpty {
                    Section("活跃分支") {
                        ForEach(appState.activeBranches, id: \.id) { branch in
                            BranchListRow(branch: branch)
                        }
                    }
                }
                
                // Completed branches
                if !appState.completedBranches.isEmpty {
                    Section("已完成分支") {
                        ForEach(appState.completedBranches, id: \.id) { branch in
                            BranchListRow(branch: branch)
                        }
                    }
                }
                
                // Master branch
                if let masterBranch = appState.masterBranch {
                    Section("主干分支") {
                        BranchListRow(branch: masterBranch)
                    }
                }
            }
            .navigationTitle("分支列表")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingCreateBranch = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreateBranch) {
            CreateBranchPlaceholderView()
        }
    }
}

struct BranchListRow: View {
    let branch: Branch
    @EnvironmentObject private var appState: AppStateManager
    
    var body: some View {
        Button(action: {
            appState.switchToBranch(branch)
        }) {
            HStack {
                BranchStatusIndicator(status: branch.status)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(branch.name)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Text(branch.branchDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    if !branch.isMaster {
                        ProgressView(value: branch.progress)
                            .progressViewStyle(LinearProgressViewStyle())
                            .frame(height: 4)
                    }
                }
                
                Spacer()
                
                if branch.id == appState.currentBranch?.id {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CreateBranchPlaceholderView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("创建新分支")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("分支创建功能正在开发中")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationTitle("创建分支")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    BranchListView()
        .environmentObject(AppStateManager())
}