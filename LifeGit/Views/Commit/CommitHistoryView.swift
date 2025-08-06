import SwiftUI
import SwiftData

/// View for displaying commit history with filtering and search capabilities
struct CommitHistoryView: View {
    // MARK: - Environment
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Properties
    let branch: Branch?
    @StateObject private var commitManager: CommitManager
    @StateObject private var performanceOptimizer = UIPerformanceOptimizer.shared
    
    // MARK: - State
    @State private var commits: [Commit] = []
    @State private var filteredCommits: [Commit] = []
    @State private var selectedFilter: CommitType?
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var selectedCommit: Commit?
    @State private var showingCommitDetail = false
    @State private var dateRange: CommitDateRange = .all
    
    // MARK: - Computed Properties
    private var title: String {
        if let branch = branch {
            return "\(branch.name) - 提交历史"
        } else {
            return "所有提交"
        }
    }
    
    // MARK: - Initialization
    init(branch: Branch? = nil, commitRepository: CommitRepository, modelContext: ModelContext) {
        self.branch = branch
        self._commitManager = StateObject(wrappedValue: CommitManager(commitRepository: commitRepository, modelContext: modelContext))
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search and Filter Bar
                searchAndFilterBar
                
                // Content
                if isLoading {
                    LoadingView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredCommits.isEmpty {
                    emptyStateView
                } else {
                    commitListView
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        dateRangeMenuItems
                    } label: {
                        Image(systemName: "calendar")
                    }
                }
            }
            .onAppear {
                Task {
                    await loadCommits()
                }
            }
            .refreshable {
                // Debounced refresh to prevent multiple simultaneous refreshes
                performanceOptimizer.debounce(key: "commitRefresh", delay: 0.5) {
                    Task {
                        await loadCommits()
                    }
                }
            }
            .sheet(isPresented: $showingCommitDetail) {
                if let commit = selectedCommit {
                    CommitDetailView(commit: commit)
                }
            }
            .alert("加载失败", isPresented: $showingError) {
                Button("重试") {
                    Task {
                        await loadCommits()
                    }
                }
                Button("确定") { }
            } message: {
                Text(errorMessage)
            }
        }
        .debouncedOnChange(of: searchText, debounceTime: 0.3) { _ in
            filterCommits()
        }
        .onChange(of: selectedFilter) { _, _ in
            filterCommits()
        }
        .onChange(of: dateRange) { _, _ in
            Task {
                await loadCommits()
            }
        }
    }
    
    // MARK: - Search and Filter Bar
    private var searchAndFilterBar: some View {
        VStack(spacing: 12) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("搜索提交信息...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button("清除") {
                        searchText = ""
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            // Filter Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(
                        title: "全部",
                        count: filteredCommits.count,
                        isSelected: selectedFilter == nil
                    ) {
                        selectedFilter = nil
                    }
                    
                    ForEach(CommitType.allCases, id: \.self) { type in
                        FilterChip(
                            title: "\(type.emoji) \(type.displayName)",
                            count: filteredCommits.filter { $0.type == type }.count,
                            isSelected: selectedFilter == type
                        ) {
                            selectedFilter = selectedFilter == type ? nil : type
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(.separator)),
            alignment: .bottom
        )
    }
    
    // MARK: - Commit List View
    private var commitListView: some View {
        List {
            ForEach(groupedCommits, id: \.date) { group in
                Section {
                    ForEach(group.commits, id: \.id) { commit in
                        commitRowView(for: commit)
                    }
                } header: {
                    Text(formatSectionDate(group.date))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
            }
        }
        .listStyle(PlainListStyle())
        .optimizedForPerformance()
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: searchText.isEmpty ? "clock" : "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(emptyStateTitle)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(emptyStateMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if !searchText.isEmpty {
                Button("清除搜索") {
                    searchText = ""
                }
                .foregroundColor(.blue)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    private var emptyStateTitle: String {
        if !searchText.isEmpty {
            return "未找到匹配的提交"
        } else if selectedFilter != nil {
            return "暂无此类型的提交"
        } else {
            return "暂无提交记录"
        }
    }
    
    private var emptyStateMessage: String {
        if !searchText.isEmpty {
            return "尝试使用不同的关键词搜索"
        } else if selectedFilter != nil {
            return "选择其他类型或清除筛选条件"
        } else if branch != nil {
            return "开始记录你在这个分支上的进展吧"
        } else {
            return "创建你的第一个提交记录"
        }
    }
    
    // MARK: - Date Range Menu Items
    private var dateRangeMenuItems: some View {
        Group {
            Button("全部时间") {
                dateRange = .all
            }
            
            Button("今天") {
                dateRange = .today
            }
            
            Button("本周") {
                dateRange = .thisWeek
            }
            
            Button("本月") {
                dateRange = .thisMonth
            }
            
            Button("最近30天") {
                dateRange = .last30Days
            }
        }
    }
    
    // MARK: - Computed Properties
    private var groupedCommits: [CommitGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredCommits) { commit in
            calendar.startOfDay(for: commit.timestamp)
        }
        
        return grouped.map { date, commits in
            CommitGroup(date: date, commits: commits.sorted { $0.timestamp > $1.timestamp })
        }.sorted { $0.date > $1.date }
    }
    
    // MARK: - Helper Methods
    private func commitRowView(for commit: Commit) -> some View {
        CommitListRowView(
            commit: commit,
            onTap: {
                performanceOptimizer.debounce(key: "commitTap", delay: 0.1) {
                    selectedCommit = commit
                    showingCommitDetail = true
                }
            }
        )
        .optimizedForPerformance()
    }
    
    private func loadCommits() async {
        isLoading = true
        
        do {
            let loadedCommits: [Commit]
            
            if let branch = branch {
                // Load commits for specific branch
                switch dateRange {
                case .all:
                    loadedCommits = try await commitManager.getCommits(for: branch.id)
                case .today:
                    let today = Calendar.current.startOfDay(for: Date())
                    let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? Date()
                    loadedCommits = try await commitManager.getCommits(
                        from: today,
                        to: tomorrow,
                        branchId: branch.id
                    )
                case .thisWeek:
                    let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
                    loadedCommits = try await commitManager.getCommits(
                        from: weekStart,
                        to: Date(),
                        branchId: branch.id
                    )
                case .thisMonth:
                    let monthStart = Calendar.current.dateInterval(of: .month, for: Date())?.start ?? Date()
                    loadedCommits = try await commitManager.getCommits(
                        from: monthStart,
                        to: Date(),
                        branchId: branch.id
                    )
                case .last30Days:
                    let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
                    loadedCommits = try await commitManager.getCommits(
                        from: thirtyDaysAgo,
                        to: Date(),
                        branchId: branch.id
                    )
                }
            } else {
                // Load all commits
                switch dateRange {
                case .all:
                    loadedCommits = try await commitManager.getRecentCommits(count: 1000)
                case .today:
                    let today = Calendar.current.startOfDay(for: Date())
                    let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? Date()
                    loadedCommits = try await commitManager.getCommits(from: today, to: tomorrow)
                case .thisWeek:
                    let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
                    loadedCommits = try await commitManager.getCommits(from: weekStart, to: Date())
                case .thisMonth:
                    let monthStart = Calendar.current.dateInterval(of: .month, for: Date())?.start ?? Date()
                    loadedCommits = try await commitManager.getCommits(from: monthStart, to: Date())
                case .last30Days:
                    let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
                    loadedCommits = try await commitManager.getCommits(from: thirtyDaysAgo, to: Date())
                }
            }
            
            commits = loadedCommits
            filterCommits()
            
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
        
        isLoading = false
    }
    
    private func filterCommits() {
        var filtered = commits
        
        // Apply type filter
        if let selectedFilter = selectedFilter {
            filtered = filtered.filter { $0.type == selectedFilter }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { commit in
                commit.message.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        filteredCommits = filtered
    }
    
    private func formatSectionDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        
        if calendar.isDateInToday(date) {
            return "今天"
        } else if calendar.isDateInYesterday(date) {
            return "昨天"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .year) {
            formatter.dateFormat = "M月d日"
            return formatter.string(from: date)
        } else {
            formatter.dateFormat = "yyyy年M月d日"
            return formatter.string(from: date)
        }
    }
}



// MARK: - Commit Detail View
private struct CommitDetailView: View {
    let commit: Commit
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(commit.type.emoji)
                                .font(.largeTitle)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(commit.type.displayName)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text(formatFullDate(commit.timestamp))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                    
                    Divider()
                    
                    // Message
                    VStack(alignment: .leading, spacing: 8) {
                        Text("提交信息")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(commit.message)
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    
                    // Metadata
                    VStack(alignment: .leading, spacing: 12) {
                        Text("详细信息")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 8) {
                            metadataRow(title: "提交ID", value: commit.id.uuidString.prefix(8).uppercased())
                            metadataRow(title: "分支ID", value: commit.branchId.uuidString.prefix(8).uppercased())
                            metadataRow(title: "提交时间", value: formatFullDate(commit.timestamp))
                            
                            if let taskId = commit.relatedTaskId {
                                metadataRow(title: "关联任务", value: taskId.uuidString.prefix(8).uppercased())
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("提交详情")
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
    
    private func metadataRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary)
                .textSelection(.enabled)
        }
    }
    
    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日 HH:mm:ss"
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Types
private struct CommitGroup {
    let date: Date
    let commits: [Commit]
}

private enum CommitDateRange: CaseIterable {
    case all
    case today
    case thisWeek
    case thisMonth
    case last30Days
    
    var displayName: String {
        switch self {
        case .all: return "全部时间"
        case .today: return "今天"
        case .thisWeek: return "本周"
        case .thisMonth: return "本月"
        case .last30Days: return "最近30天"
        }
    }
}

// MARK: - Preview
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Branch.self, Commit.self, configurations: config)
    let context = container.mainContext
    
    // Create sample branch
    let branch = Branch(
        name: "学习SwiftUI",
        branchDescription: "掌握SwiftUI开发技能，构建现代iOS应用"
    )
    
    // Create repository
    let repository = SwiftDataCommitRepository(modelContext: context)
    
    CommitHistoryView(branch: branch, commitRepository: repository, modelContext: context)
        .modelContainer(container)
}