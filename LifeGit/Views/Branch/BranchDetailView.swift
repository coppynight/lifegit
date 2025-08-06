import SwiftUI
import SwiftData

struct BranchDetailView: View {
    let branch: Branch
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppStateManager
    @Query private var commits: [Commit]
    @State private var isShowingCommitCreation = false
    @State private var isShowingTaskPlanGeneration = false
    @State private var isShowingBranchActions = false
    @State private var selectedTab: BranchDetailTab = .overview
    @State private var reviewService: BranchReviewService?
    
    init(branch: Branch) {
        self.branch = branch
        let branchId = branch.id
        // Query commits for this specific branch
        _commits = Query(
            filter: #Predicate<Commit> { commit in
                commit.branchId == branchId
            },
            sort: \Commit.timestamp,
            order: .reverse
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            tabSelectorView
            
            // Content based on selected tab
            TabView(selection: $selectedTab) {
                overviewTabView
                    .tag(BranchDetailTab.overview)
                
                taskPlanTabView
                    .tag(BranchDetailTab.taskPlan)
                
                commitsTabView
                    .tag(BranchDetailTab.commits)
                
                reviewTabView
                    .tag(BranchDetailTab.review)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                branchStatusIndicator
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    branchActionButtons
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 16, weight: .medium))
                }
            }
        }
        .sheet(isPresented: $isShowingCommitCreation) {
            // TODO: CommitCreationView(branch: branch)
            Text("提交创建功能开发中...")
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $isShowingTaskPlanGeneration) {
            // TODO: TaskPlanGenerationView(branch: branch)
            Text("任务计划生成功能开发中...")
                .presentationDetents([.medium, .large])
        }
        .alert("分支操作", isPresented: $isShowingBranchActions) {
            branchActionAlert
        }
    }
    
    // MARK: - Tab Selector
    
    private var tabSelectorView: some View {
        HStack(spacing: 0) {
            ForEach(BranchDetailTab.allCases, id: \.self) { tab in
                Button(action: {
                    selectedTab = tab
                }) {
                    VStack(spacing: 4) {
                        Text(tab.displayName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(selectedTab == tab ? .blue : .secondary)
                        
                        Rectangle()
                            .fill(selectedTab == tab ? Color.blue : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 16)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .fill(Color(.systemGray4))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }
    
    // MARK: - Overview Tab
    
    private var overviewTabView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Branch header
                branchHeaderView
                
                // Quick stats
                quickStatsView
                
                // Recent activity
                recentActivityView
                
                // Quick actions
                quickActionsView
            }
            .padding(16)
        }
    }
    
    // MARK: - Task Plan Tab
    
    private var taskPlanTabView: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let taskPlan = branch.taskPlan {
                    TaskPlanDisplayView(taskPlan: taskPlan)
                } else {
                    emptyTaskPlanView
                }
            }
            .padding(16)
        }
    }
    
    // MARK: - Commits Tab
    
    private var commitsTabView: some View {
        ScrollView {
            VStack(spacing: 16) {
                if commits.isEmpty {
                    emptyCommitsView
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(commits) { commit in
                            CommitRowView(commit: commit)
                        }
                    }
                }
            }
            .padding(16)
        }
    }
    
    // MARK: - Review Tab
    
    private var reviewTabView: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let reviewService = reviewService {
                    BranchReviewManagementView(branch: branch, reviewService: reviewService)
                } else {
                    Text("正在初始化复盘服务...")
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
        }
        .onAppear {
            if reviewService == nil {
                initializeReviewService()
            }
        }
    }
    
    private func initializeReviewService() {
        // In a real app, this would be injected via dependency injection
        let deepseekClient = DeepseekR1Client(apiKey: "your-api-key-here")
        reviewService = BranchReviewService(deepseekClient: deepseekClient, modelContext: modelContext)
    }
    
    // MARK: - Supporting Views
    
    private var branchStatusIndicator: some View {
        HStack(spacing: 6) {
            Image(systemName: branchStatusIcon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(branchStatusColor)
            
            Text(branch.status.displayName)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(branchStatusColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(branchStatusColor.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var branchHeaderView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(branch.name)
                .font(.title2)
                .fontWeight(.bold)
            
            if !branch.branchDescription.isEmpty {
                Text(branch.branchDescription)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            // Progress bar
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("完成进度")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(Int(branch.progress * 100))%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                
                ProgressView(value: branch.progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .scaleEffect(y: 1.5)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var quickStatsView: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            BranchStatCard(
                title: "提交数",
                value: "\(commits.count)",
                icon: "doc.text.fill",
                color: .blue
            )
            
            BranchStatCard(
                title: "活跃天数",
                value: "\(activeDays)",
                icon: "calendar.badge.clock",
                color: .green
            )
            
            BranchStatCard(
                title: "创建时间",
                value: daysAgo,
                icon: "clock.fill",
                color: .orange
            )
        }
    }
    
    private var recentActivityView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("最近活动")
                .font(.headline)
                .fontWeight(.semibold)
            
            if commits.isEmpty {
                Text("暂无活动记录")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(commits.prefix(3)) { commit in
                        CommitRowView(commit: commit, isCompact: true)
                    }
                }
                
                if commits.count > 3 {
                    Button("查看全部 \(commits.count) 个提交") {
                        selectedTab = .commits
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 8)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var quickActionsView: some View {
        VStack(spacing: 12) {
            Text("快速操作")
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 8) {
                Button(action: {
                    isShowingCommitCreation = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                        Text("记录进展")
                            .font(.system(size: 16, weight: .medium))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                
                if branch.taskPlan == nil {
                    Button(action: {
                        isShowingTaskPlanGeneration = true
                    }) {
                        HStack {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 18))
                            Text("生成AI任务计划")
                                .font(.system(size: 16, weight: .medium))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .foregroundColor(.blue)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
            }
        }
    }
    
    private var emptyTaskPlanView: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("暂无任务计划")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("让AI帮你制定详细的任务计划")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                isShowingTaskPlanGeneration = true
            }) {
                HStack {
                    Image(systemName: "brain.head.profile")
                    Text("生成AI任务计划")
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.blue)
                .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }
    
    private var emptyCommitsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("暂无提交记录")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("开始记录你的进展和学习心得")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                isShowingCommitCreation = true
            }) {
                HStack {
                    Image(systemName: "plus")
                    Text("创建第一个提交")
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.blue)
                .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }
    
    @ViewBuilder
    private var branchActionButtons: some View {
        if branch.status == .active {
            Button(action: {
                // TODO: Complete branch
            }) {
                Label("完成分支", systemImage: "checkmark.circle")
            }
            
            Button(action: {
                // TODO: Abandon branch
            }) {
                Label("废弃分支", systemImage: "xmark.circle")
            }
        } else if branch.status == .abandoned {
            Button(action: {
                // TODO: Reactivate branch
            }) {
                Label("重新激活", systemImage: "arrow.clockwise")
            }
        }
        
        Button(action: {
            // TODO: Edit branch
        }) {
            Label("编辑分支", systemImage: "pencil")
        }
    }
    
    @ViewBuilder
    private var branchActionAlert: some View {
        Button("取消", role: .cancel) {}
    }
    
    // MARK: - Computed Properties
    
    private var branchStatusIcon: String {
        switch branch.status {
        case .active:
            return "circle.fill"
        case .completed:
            return "checkmark.circle.fill"
        case .abandoned:
            return "xmark.circle.fill"
        case .master:
            return "house.circle.fill"
        }
    }
    
    private var branchStatusColor: Color {
        switch branch.status {
        case .active:
            return .green
        case .completed:
            return .blue
        case .abandoned:
            return .red
        case .master:
            return .blue
        }
    }
    
    private var activeDays: Int {
        let calendar = Calendar.current
        let uniqueDays = Set(commits.map { calendar.startOfDay(for: $0.timestamp) })
        return uniqueDays.count
    }
    
    private var daysAgo: String {
        let days = Calendar.current.dateComponents([.day], from: branch.createdAt, to: Date()).day ?? 0
        return "\(days)天前"
    }
}

// MARK: - Supporting Views

struct BranchStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 16, weight: .bold))
            
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct CommitRowView: View {
    let commit: Commit
    let isCompact: Bool
    
    init(commit: Commit, isCompact: Bool = false) {
        self.commit = commit
        self.isCompact = isCompact
    }
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    var body: some View {
        HStack(spacing: 12) {
            // Commit type icon
            Image(systemName: commitTypeIcon)
                .font(.system(size: isCompact ? 14 : 16, weight: .medium))
                .foregroundColor(commitTypeColor)
                .frame(width: isCompact ? 20 : 24, height: isCompact ? 20 : 24)
                .background(commitTypeColor.opacity(0.1))
                .cornerRadius(isCompact ? 4 : 6)
            
            // Commit content
            VStack(alignment: .leading, spacing: 2) {
                Text(commit.message)
                    .font(.system(size: isCompact ? 14 : 15, weight: .medium))
                    .lineLimit(isCompact ? 1 : 2)
                
                Text(commit.timestamp.formatted(.relative(presentation: .named)))
                    .font(.system(size: isCompact ? 11 : 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if !isCompact {
                Text(timeFormatter.string(from: commit.timestamp))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding(isCompact ? 8 : 12)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(8)
    }
    
    private var commitTypeIcon: String {
        switch commit.type {
        case .taskComplete:
            return "checkmark.circle.fill"
        case .learning:
            return "book.fill"
        case .reflection:
            return "lightbulb.fill"
        case .milestone:
            return "flag.fill"
        case .habit:
            return "repeat.circle.fill"
        case .exercise:
            return "figure.run"
        case .reading:
            return "book.closed.fill"
        case .creativity:
            return "paintbrush.fill"
        case .social:
            return "person.2.fill"
        case .health:
            return "heart.fill"
        case .finance:
            return "dollarsign.circle.fill"
        case .career:
            return "briefcase.fill"
        case .relationship:
            return "heart.circle.fill"
        case .travel:
            return "airplane"
        case .skill:
            return "wrench.fill"
        case .project:
            return "folder.fill"
        case .idea:
            return "lightbulb.fill"
        case .challenge:
            return "bolt.fill"
        case .gratitude:
            return "hands.sparkles.fill"
        case .custom:
            return "star.fill"
        }
    }
    
    private var commitTypeColor: Color {
        switch commit.type {
        case .taskComplete:
            return .green
        case .learning:
            return .blue
        case .reflection:
            return .orange
        case .milestone:
            return .purple
        case .habit:
            return .cyan
        case .exercise:
            return .red
        case .reading:
            return .brown
        case .creativity:
            return .pink
        case .social:
            return .yellow
        case .health:
            return .mint
        case .finance:
            return .green
        case .career:
            return .indigo
        case .relationship:
            return .pink
        case .travel:
            return .teal
        case .skill:
            return .blue
        case .project:
            return .gray
        case .idea:
            return .yellow
        case .challenge:
            return .red
        case .gratitude:
            return .purple
        case .custom:
            return .secondary
        }
    }
}

// MARK: - Supporting Types

enum BranchDetailTab: CaseIterable {
    case overview, taskPlan, commits, review
    
    var displayName: String {
        switch self {
        case .overview: return "概览"
        case .taskPlan: return "任务计划"
        case .commits: return "提交记录"
        case .review: return "复盘报告"
        }
    }
}

#Preview {
    let branch = Branch(name: "学习Swift", branchDescription: "掌握Swift编程语言")
    
    NavigationStack {
        BranchDetailView(branch: branch)
    }
    .modelContainer(for: [User.self, Branch.self, Commit.self, TaskPlan.self, TaskItem.self])
}