import SwiftUI

struct HomepagePreferencesView: View {
    @EnvironmentObject private var appState: AppStateManager
    @State private var selectedMode: HomepageMode
    @State private var showingPreview = false
    @State private var previewBranch: Branch?
    
    init() {
        // Initialize with current mode from app state or default
        self._selectedMode = State(initialValue: .intelligent)
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Text("选择应用启动时显示的首页内容")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } header: {
                    Text("首页显示模式")
                }
                
                Section {
                    ForEach(HomepageMode.allCases, id: \.self) { mode in
                        HomepageModeRow(
                            mode: mode,
                            isSelected: selectedMode == mode,
                            onSelect: {
                                selectedMode = mode
                                updateHomepageMode(mode)
                            }
                        )
                    }
                } header: {
                    Text("显示模式")
                }
                
                Section {
                    Button(action: {
                        showPreview()
                    }) {
                        HStack {
                            Image(systemName: "eye")
                                .foregroundColor(.blue)
                            Text("预览当前模式")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: {
                        testHomepageLogic()
                    }) {
                        HStack {
                            Image(systemName: "play.circle")
                                .foregroundColor(.green)
                            Text("测试智能推荐")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("测试功能")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("智能推荐说明")
                            .font(.headline)
                        
                        Text("智能推荐会根据以下因素选择显示内容：")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            BulletPoint(text: "最近的使用习惯和活跃时间")
                            BulletPoint(text: "分支的活跃度和进度情况")
                            BulletPoint(text: "一天中的不同时间段偏好")
                            BulletPoint(text: "刚完成目标时优先显示主干")
                        }
                        .padding(.leading, 8)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("功能说明")
                }
            }
            .navigationTitle("首页偏好设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        // Dismiss view
                    }
                }
            }
        }
        .onAppear {
            loadCurrentMode()
        }
        .sheet(isPresented: $showingPreview) {
            HomepagePreviewView(
                mode: selectedMode,
                previewBranch: previewBranch
            )
        }
    }
    
    private func loadCurrentMode() {
        if let smartManager = appState.smartHomepageManager {
            selectedMode = smartManager.homepageMode
        }
    }
    
    private func updateHomepageMode(_ mode: HomepageMode) {
        appState.smartHomepageManager?.updateHomepageMode(mode)
        
        // Also update the legacy preference for compatibility
        let legacyMode: StartupView = switch mode {
        case .lastViewed: .lastViewed
        case .masterBranch: .masterBranch
        case .mostActiveBranch: .mostActiveBranch
        case .intelligent: .intelligent
        }
        appState.updateStartupPreference(legacyMode)
    }
    
    private func showPreview() {
        Task {
            previewBranch = await appState.smartHomepageManager?.getRecommendedBranch()
            showingPreview = true
        }
    }
    
    private func testHomepageLogic() {
        Task {
            guard let smartManager = appState.smartHomepageManager else { return }
            
            // Temporarily switch to intelligent mode for testing
            let originalMode = smartManager.homepageMode
            smartManager.updateHomepageMode(.intelligent)
            
            // Get recommendation
            previewBranch = await smartManager.getRecommendedBranch()
            
            // Restore original mode
            smartManager.updateHomepageMode(originalMode)
            
            // Show preview
            showingPreview = true
        }
    }
}

struct HomepageModeRow: View {
    let mode: HomepageMode
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.displayName)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Text(mode.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct BulletPoint: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundColor(.secondary)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
    }
}

struct HomepagePreviewView: View {
    let mode: HomepageMode
    let previewBranch: Branch?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Mode info
                VStack(spacing: 8) {
                    Text("预览模式")
                        .font(.headline)
                    
                    Text(mode.displayName)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(mode.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Divider()
                
                // Preview content
                VStack(spacing: 16) {
                    Text("推荐显示内容")
                        .font(.headline)
                    
                    if let branch = previewBranch {
                        BranchPreviewCard(branch: branch)
                    } else {
                        Text("暂无推荐内容")
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Test note
                VStack(spacing: 8) {
                    Text("💡 提示")
                        .font(.headline)
                    
                    Text("这是基于当前数据的预览结果。实际显示内容会根据您的使用习惯动态调整。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .padding()
            .navigationTitle("首页预览")
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

struct BranchPreviewCard: View {
    let branch: Branch
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(branch.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                BranchStatusBadge(status: branch.status)
            }
            
            if !branch.branchDescription.isEmpty {
                Text(branch.branchDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            HStack {
                if branch.isMaster {
                    Label("主干分支", systemImage: "tree")
                        .font(.caption)
                        .foregroundColor(.blue)
                } else {
                    ProgressView(value: branch.progress)
                        .progressViewStyle(LinearProgressViewStyle())
                    
                    Text("\(Int(branch.progress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct BranchStatusBadge: View {
    let status: BranchStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(statusText)
                .font(.caption)
                .foregroundColor(statusColor)
        }
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
    
    private var statusText: String {
        switch status {
        case .active:
            return "进行中"
        case .completed:
            return "已完成"
        case .abandoned:
            return "已废弃"
        case .master:
            return "主干"
        }
    }
}

#Preview {
    HomepagePreferencesView()
        .environmentObject(AppStateManager())
}