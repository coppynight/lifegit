import SwiftUI

/// Branch switcher component for quick navigation between branches
struct BranchSwitcher: View {
    @EnvironmentObject private var appState: AppStateManager
    @State private var isShowingBranchList = false
    
    var body: some View {
        HStack {
            // Enhanced current branch indicator with progress
            Button(action: {
                // Haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                
                isShowingBranchList.toggle()
            }) {
                HStack(spacing: 10) {
                    // Animated branch status indicator
                    ZStack {
                        Circle()
                            .fill(currentBranchColor.opacity(0.2))
                            .frame(width: 24, height: 24)
                        
                        Image(systemName: currentBranchIcon)
                            .foregroundColor(currentBranchColor)
                            .font(.system(size: 12, weight: .semibold))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        // Branch name
                        Text(currentBranchName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        // Progress or status info
                        if let branch = appState.currentBranch, !branch.isMaster {
                            HStack(spacing: 4) {
                                Text(branch.status.displayName)
                                    .font(.caption2)
                                    .foregroundColor(currentBranchColor)
                                
                                if branch.status == .active && branch.progress > 0 {
                                    Text("•")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    
                                    Text("\(Int(branch.progress * 100))%")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        } else if appState.currentBranch?.isMaster == true {
                            Text("人生主干")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Dropdown arrow with animation
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isShowingBranchList ? 180 : 0))
                        .animation(.easeInOut(duration: 0.2), value: isShowingBranchList)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Quick action buttons
            HStack(spacing: 12) {
                // Create new branch button
                Button(action: {
                    // Haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    
                    // TODO: Show branch creation
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.accentColor)
                        .clipShape(Circle())
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .sheet(isPresented: $isShowingBranchList) {
            BranchSwitcherSheet()
                .environmentObject(appState)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Computed Properties
    
    private var currentBranchName: String {
        appState.currentBranch?.name ?? "选择分支"
    }
    
    private var currentBranchIcon: String {
        guard let branch = appState.currentBranch else {
            return "questionmark.circle"
        }
        
        switch branch.status {
        case .master:
            return "house.circle"
        case .active:
            return "git.branch"
        case .completed:
            return "checkmark.circle"
        case .abandoned:
            return "xmark.circle"
        }
    }
    
    private var currentBranchColor: Color {
        guard let branch = appState.currentBranch else {
            return .gray
        }
        
        switch branch.status {
        case .master:
            return .blue
        case .active:
            return .green
        case .completed:
            return .blue
        case .abandoned:
            return .red
        }
    }
}

/// Sheet view for branch selection
struct BranchSwitcherSheet: View {
    @EnvironmentObject private var appState: AppStateManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                // Master branch section
                if let masterBranch = appState.masterBranch {
                    Section("主干") {
                        BranchSwitcherRow(
                            branch: masterBranch,
                            isSelected: appState.currentBranch?.id == masterBranch.id
                        ) {
                            appState.switchToBranch(masterBranch)
                            dismiss()
                        }
                    }
                }
                
                // Active branches section
                if !appState.activeBranches.isEmpty {
                    Section("活跃分支") {
                        ForEach(appState.activeBranches) { branch in
                            BranchSwitcherRow(
                                branch: branch,
                                isSelected: appState.currentBranch?.id == branch.id
                            ) {
                                appState.switchToBranch(branch)
                                dismiss()
                            }
                        }
                    }
                }
                
                // Completed branches section
                if !appState.completedBranches.isEmpty {
                    Section("已完成分支") {
                        ForEach(appState.completedBranches) { branch in
                            BranchSwitcherRow(
                                branch: branch,
                                isSelected: appState.currentBranch?.id == branch.id
                            ) {
                                appState.switchToBranch(branch)
                                dismiss()
                            }
                        }
                    }
                }
                
                // Empty state
                if appState.branches.isEmpty {
                    Section {
                        Text("暂无分支")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    }
                }
            }
            .navigationTitle("切换分支")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

/// Individual branch row in the switcher
struct BranchSwitcherRow: View {
    let branch: Branch
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Branch icon
                Image(systemName: branchIcon)
                    .foregroundColor(branchColor)
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    // Branch name
                    Text(branch.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    // Branch description
                    if !branch.branchDescription.isEmpty {
                        Text(branch.branchDescription)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                        .font(.system(size: 16, weight: .medium))
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Computed Properties
    
    private var branchIcon: String {
        switch branch.status {
        case .master:
            return "house.circle.fill"
        case .active:
            return "git.branch"
        case .completed:
            return "checkmark.circle.fill"
        case .abandoned:
            return "xmark.circle.fill"
        }
    }
    
    private var branchColor: Color {
        switch branch.status {
        case .master:
            return .blue
        case .active:
            return .green
        case .completed:
            return .blue
        case .abandoned:
            return .red
        }
    }
}

/// Custom button style with scale animation for better UX
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    BranchSwitcher()
        .environmentObject(AppStateManager())
        .padding()
}