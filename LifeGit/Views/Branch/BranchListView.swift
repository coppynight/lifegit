import SwiftUI
import SwiftData

struct BranchListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var branches: [Branch]
    @EnvironmentObject var appState: AppStateManager
    @StateObject private var performanceOptimizer = UIPerformanceOptimizer.shared
    @State private var selectedFilter: BranchFilter = .all
    @State private var searchText = ""
    @State private var isShowingCreateBranch = false
    @State private var visibleRange: Range<Int> = 0..<20
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter chips
                filterChipsView
                
                // Branch list
                if filteredBranches.isEmpty {
                    emptyStateView
                } else {
                    branchListView
                }
            }
            .navigationTitle("分支管理")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "搜索分支...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isShowingCreateBranch = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .medium))
                    }
                }
            }
            .sheet(isPresented: $isShowingCreateBranch) {
                // TODO: BranchCreationView()
                Text("分支创建功能开发中...")
                    .presentationDetents([.medium])
            }
            .refreshable {
                // Debounced refresh to prevent multiple simultaneous refreshes
                performanceOptimizer.debounce(key: "branchRefresh", delay: 0.5) {
                    Task {
                        await appState.refreshBranches()
                    }
                }
            }
        }
    }
    
    // MARK: - Filter Chips View
    
    private var filterChipsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(BranchFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.displayName,
                        count: getBranchCount(for: filter),
                        isSelected: selectedFilter == filter
                    ) {
                        selectedFilter = filter
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Branch List View
    
    private var branchListView: some View {
        List {
            ForEach(groupedBranches.keys.sorted(by: { $0.sortOrder < $1.sortOrder }), id: \.self) { section in
                if let sectionBranches = groupedBranches[section], !sectionBranches.isEmpty {
                    Section(section.displayName) {
                        ForEach(Array(sectionBranches.enumerated()), id: \.element.id) { index, branch in
                            OptimizedBranchRowView(
                                branch: branch,
                                isVisible: visibleRange.contains(index)
                            )
                            .onTapGesture {
                                // Debounced tap to prevent multiple rapid taps
                                performanceOptimizer.debounce(key: "branchTap", delay: 0.1) {
                                    // 确保所有分支都可以点击，包括master分支
                                    appState.switchToBranch(branch)
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                if !branch.isMaster {
                                    branchSwipeActions(for: branch)
                                }
                            }
                            .onAppear {
                                updateVisibleRange(around: index, total: sectionBranches.count)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
        .optimizedForPerformance()
        .debouncedOnChange(of: searchText, debounceTime: 0.3) { _ in
            // Debounced search to improve performance
        }
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "git.branch")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text(emptyStateTitle)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(emptyStateMessage)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if selectedFilter == .all && searchText.isEmpty {
                Button(action: {
                    isShowingCreateBranch = true
                }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("创建第一个分支")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(8)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }
    
    // MARK: - Swipe Actions
    
    @ViewBuilder
    private func branchSwipeActions(for branch: Branch) -> some View {
        if branch.status == .active {
            Button("完成") {
                // TODO: Complete branch
            }
            .tint(.green)
            
            Button("废弃") {
                // TODO: Abandon branch
            }
            .tint(.red)
        } else if branch.status == .abandoned {
            Button("重新激活") {
                // TODO: Reactivate branch
            }
            .tint(.blue)
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredBranches: [Branch] {
        var result = branches
        
        // Apply status filter
        switch selectedFilter {
        case .all:
            break
        case .active:
            result = result.filter { $0.status == .active }
        case .completed:
            result = result.filter { $0.status == .completed }
        case .abandoned:
            result = result.filter { $0.status == .abandoned }
        case .master:
            result = result.filter { $0.status == .master }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter { branch in
                branch.name.localizedCaseInsensitiveContains(searchText) ||
                branch.branchDescription.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return result
    }
    
    private var groupedBranches: [BranchSection: [Branch]] {
        Dictionary(grouping: filteredBranches) { branch in
            switch branch.status {
            case .master:
                return .master
            case .active:
                return .active
            case .completed:
                return .completed
            case .abandoned:
                return .abandoned
            }
        }
    }
    
    private func getBranchCount(for filter: BranchFilter) -> Int {
        switch filter {
        case .all:
            return branches.count
        case .active:
            return branches.filter { $0.status == .active }.count
        case .completed:
            return branches.filter { $0.status == .completed }.count
        case .abandoned:
            return branches.filter { $0.status == .abandoned }.count
        case .master:
            return branches.filter { $0.status == .master }.count
        }
    }
    
    private var emptyStateTitle: String {
        if !searchText.isEmpty {
            return "未找到匹配的分支"
        } else {
            switch selectedFilter {
            case .all:
                return "暂无分支"
            case .active:
                return "暂无活跃分支"
            case .completed:
                return "暂无已完成分支"
            case .abandoned:
                return "暂无已废弃分支"
            case .master:
                return "暂无主干分支"
            }
        }
    }
    
    private var emptyStateMessage: String {
        if !searchText.isEmpty {
            return "尝试使用不同的关键词搜索"
        } else {
            switch selectedFilter {
            case .all:
                return "开始创建你的第一个目标分支吧"
            case .active:
                return "创建新分支开始追求目标"
            case .completed:
                return "完成一些分支来查看成就"
            case .abandoned:
                return "暂时没有废弃的分支"
            case .master:
                return "主干分支应该会自动创建"
            }
        }
    }
    
    // MARK: - Performance Optimization Methods
    
    private func updateVisibleRange(around index: Int, total: Int) {
        let bufferSize = 10
        let newStart = max(0, index - bufferSize)
        let newEnd = min(total, index + bufferSize * 2)
        
        if newStart != visibleRange.lowerBound || newEnd != visibleRange.upperBound {
            visibleRange = newStart..<newEnd
        }
    }
}

// MARK: - Optimized Branch Row View

struct OptimizedBranchRowView: View {
    let branch: Branch
    let isVisible: Bool
    @EnvironmentObject private var appState: AppStateManager
    @StateObject private var performanceOptimizer = UIPerformanceOptimizer.shared
    
    var body: some View {
        if isVisible {
            BranchRowView(branch: branch)
        } else {
            // Placeholder for non-visible items to maintain scroll position
            Rectangle()
                .fill(Color.clear)
                .frame(height: 80) // Estimated row height
        }
    }
}

struct BranchRowView: View {
    let branch: Branch
    @EnvironmentObject private var appState: AppStateManager
    @StateObject private var performanceOptimizer = UIPerformanceOptimizer.shared
    
    var body: some View {
        HStack(spacing: 12) {
            // Branch status icon
            Image(systemName: branchIcon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(branchColor)
                .frame(width: 32, height: 32)
                .background(branchColor.opacity(0.1))
                .cornerRadius(8)
            
            // Branch info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(branch.name)
                        .font(.system(size: 16, weight: .semibold))
                        .lineLimit(1)
                    
                    if appState.currentBranch?.id == branch.id {
                        Text("当前")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.blue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                    }
                    
                    Spacer()
                }
                
                if !branch.branchDescription.isEmpty {
                    Text(branch.branchDescription)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                // Branch metadata
                HStack(spacing: 12) {
                    // Progress indicator
                    if !branch.isMaster {
                        HStack(spacing: 4) {
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 10))
                            Text("\(Int(branch.progress * 100))%")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.blue)
                    }
                    
                    // Creation date
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 10))
                        Text(branch.createdAt.formatted(.dateTime.month().day()))
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
            
            // Chevron for navigation
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .optimizedForPerformance()
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

// MARK: - Supporting Types

enum BranchFilter: CaseIterable {
    case all, active, completed, abandoned, master
    
    var displayName: String {
        switch self {
        case .all: return "全部"
        case .active: return "活跃"
        case .completed: return "已完成"
        case .abandoned: return "已废弃"
        case .master: return "主干"
        }
    }
}

enum BranchSection {
    case master, active, completed, abandoned
    
    var displayName: String {
        switch self {
        case .master: return "主干分支"
        case .active: return "活跃分支"
        case .completed: return "已完成分支"
        case .abandoned: return "已废弃分支"
        }
    }
    
    var sortOrder: Int {
        switch self {
        case .master: return 0
        case .active: return 1
        case .completed: return 2
        case .abandoned: return 3
        }
    }
}

#Preview {
    BranchListView()
        .environmentObject(AppStateManager())
        .modelContainer(for: [User.self, Branch.self, Commit.self, TaskPlan.self, TaskItem.self])
}