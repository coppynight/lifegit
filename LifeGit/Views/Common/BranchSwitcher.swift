import SwiftUI

struct BranchSwitcher: View {
    @EnvironmentObject private var appState: AppStateManager
    @State private var showingBranchList = false
    
    var body: some View {
        HStack {
            Button(action: {
                showingBranchList = true
            }) {
                HStack(spacing: 8) {
                    if let currentBranch = appState.currentBranch {
                        BranchStatusIndicator(status: currentBranch.status)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(currentBranch.name)
                                .font(.headline)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            
                            if currentBranch.isMaster {
                                Text("主干分支")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("进度 \(Int(currentBranch.progress * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    } else {
                        Text("选择分支")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 8)
        .sheet(isPresented: $showingBranchList) {
            BranchListSheet()
        }
    }
}

struct BranchStatusIndicator: View {
    let status: BranchStatus
    
    var body: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 12, height: 12)
    }
    
    private var statusColor: Color {
        switch status {
        case .active:
            return .blue
        case .completed:
            return .green
        case .abandoned:
            return .red
        case .master:
            return .purple
        }
    }
}

struct BranchListSheet: View {
    @EnvironmentObject private var appState: AppStateManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(appState.branches, id: \.id) { branch in
                    BranchRowView(branch: branch) {
                        appState.switchToBranch(branch)
                        dismiss()
                    }
                }
            }
            .navigationTitle("选择分支")
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

struct BranchRowView: View {
    let branch: Branch
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                BranchStatusIndicator(status: branch.status)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(branch.name)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    if branch.isMaster {
                        Text("主干分支")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("进度 \(Int(branch.progress * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    BranchSwitcher()
        .environmentObject(AppStateManager())
}