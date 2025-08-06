import SwiftUI

/// Main task plan view that displays AI-generated task plans with management capabilities
struct TaskPlanView: View {
    let branch: Branch
    @StateObject private var taskPlanManager: TaskPlanManager
    
    init(branch: Branch) {
        self.branch = branch
        self._taskPlanManager = StateObject(wrappedValue: TaskPlanManager(
            taskPlanRepository: SwiftDataTaskPlanRepository(),
            taskPlanService: TaskPlanService(apiKey: ""), // TODO: Get from config
            aiErrorHandler: AIServiceErrorHandler()
        ))
    }
    
    @State private var taskPlan: TaskPlan?
    @State private var isShowingEditView = false
    @State private var isRegenerating = false
    @State private var showingError = false
    @State private var expandedSections: Set<TaskTimeScope> = []
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let taskPlan = taskPlan {
                    // Task Plan Header
                    taskPlanHeaderView(taskPlan)
                    
                    // Task Sections
                    taskSectionsView(taskPlan)
                    
                } else if taskPlanManager.isLoading {
                    // Loading State
                    loadingView
                    
                } else {
                    // Empty State
                    emptyStateView
                }
            }
            .padding()
        }
        .navigationTitle("任务计划")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                toolbarMenu
            }
        }
        .sheet(isPresented: $isShowingEditView) {
            if let taskPlan = taskPlan {
                TaskPlanEditView(taskPlan: taskPlan) { updatedPlan in
                    self.taskPlan = updatedPlan
                }
            }
        }
        .alert("错误", isPresented: $showingError) {
            Button("确定") {
                taskPlanManager.clearError()
            }
        } message: {
            Text(taskPlanManager.error?.localizedDescription ?? "未知错误")
        }
        .task {
            await loadTaskPlan()
        }
        .onChange(of: taskPlanManager.error) { _, error in
            showingError = error != nil
        }
    }
    
    // MARK: - Task Plan Header
    
    @ViewBuilder
    private func taskPlanHeaderView(_ taskPlan: TaskPlan) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title and AI Badge
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI任务计划")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("为目标 \"\(branch.name)\" 生成的详细任务分解")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if taskPlan.isAIGenerated {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.caption)
                        Text("AI生成")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.purple)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            // Statistics Cards
            HStack(spacing: 12) {
                TaskPlanStatCard(
                    title: "总任务",
                    value: "\(taskPlan.tasks.count)",
                    icon: "list.bullet",
                    color: .blue
                )
                
                TaskPlanStatCard(
                    title: "已完成",
                    value: "\(taskPlan.completedTasksCount)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                TaskPlanStatCard(
                    title: "预计时长",
                    value: taskPlan.totalDuration,
                    icon: "clock.fill",
                    color: .orange
                )
            }
            
            // Progress Section
            progressView(taskPlan)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    @ViewBuilder
    private func progressView(_ taskPlan: TaskPlan) -> some View {
        let progress = taskPlanManager.calculateProgress(for: taskPlan)
        
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("完成进度")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(Int(progress.progress * 100))%")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            ProgressView(value: progress.progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .scaleEffect(y: 2)
            
            HStack {
                Text("剩余 \(progress.remainingTasks) 个任务")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if progress.remainingDuration > 0 {
                    Text("约 \(formatDuration(progress.remainingDuration))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Task Sections
    
    @ViewBuilder
    private func taskSectionsView(_ taskPlan: TaskPlan) -> some View {
        let groupedTasks = Dictionary(grouping: taskPlan.orderedTasks) { $0.timeScope }
        let sortedScopes = TaskTimeScope.allCases.filter { groupedTasks[$0] != nil }
        
        LazyVStack(spacing: 16) {
            ForEach(sortedScopes, id: \.self) { scope in
                if let tasks = groupedTasks[scope] {
                    TaskSectionView(
                        scope: scope,
                        tasks: tasks,
                        isExpanded: expandedSections.contains(scope),
                        onToggleExpansion: {
                            toggleSection(scope)
                        },
                        onTaskToggle: { task in
                            await toggleTaskCompletion(task)
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Loading and Empty States
    
    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("正在加载任务计划...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("暂无任务计划")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("为此目标生成AI任务计划，开始系统化地实现目标")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                Task {
                    await generateTaskPlan()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                    Text("生成任务计划")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.blue)
                .cornerRadius(10)
            }
            .disabled(taskPlanManager.isGenerating)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
    
    // MARK: - Toolbar Menu
    
    @ViewBuilder
    private var toolbarMenu: some View {
        Menu {
            if taskPlan != nil {
                Button(action: {
                    isShowingEditView = true
                }) {
                    Label("编辑计划", systemImage: "pencil")
                }
                
                Button(action: {
                    Task {
                        await regenerateTaskPlan()
                    }
                }) {
                    Label("重新生成", systemImage: "arrow.clockwise")
                }
                .disabled(isRegenerating)
                
                Divider()
            }
            
            Button(action: {
                Task {
                    await generateTaskPlan()
                }
            }) {
                Label("生成新计划", systemImage: "sparkles")
            }
            .disabled(taskPlanManager.isGenerating)
            
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 18))
        }
    }
    
    // MARK: - Helper Methods
    
    private func toggleSection(_ scope: TaskTimeScope) {
        withAnimation(.easeInOut(duration: 0.3)) {
            if expandedSections.contains(scope) {
                expandedSections.remove(scope)
            } else {
                expandedSections.insert(scope)
            }
        }
    }
    
    private func loadTaskPlan() async {
        do {
            taskPlan = try await taskPlanManager.getTaskPlan(for: branch.id)
            
            // Expand all sections by default if task plan exists
            if taskPlan != nil {
                expandedSections = Set(TaskTimeScope.allCases)
            }
        } catch {
            print("Failed to load task plan: \(error)")
        }
    }
    
    private func generateTaskPlan() async {
        do {
            let newTaskPlan = try await taskPlanManager.generateTaskPlan(
                goalTitle: branch.name,
                goalDescription: branch.branchDescription,
                branchId: branch.id
            )
            
            taskPlan = newTaskPlan
            expandedSections = Set(TaskTimeScope.allCases)
            
        } catch {
            print("Failed to generate task plan: \(error)")
        }
    }
    
    private func regenerateTaskPlan() async {
        guard let currentTaskPlan = taskPlan else { return }
        
        isRegenerating = true
        defer { isRegenerating = false }
        
        do {
            let newTaskPlan = try await taskPlanManager.regenerateTaskPlan(currentTaskPlan)
            taskPlan = newTaskPlan
            expandedSections = Set(TaskTimeScope.allCases)
            
        } catch {
            print("Failed to regenerate task plan: \(error)")
        }
    }
    
    private func toggleTaskCompletion(_ task: TaskItem) async {
        do {
            try await taskPlanManager.toggleTaskCompletion(task)
        } catch {
            print("Failed to toggle task completion: \(error)")
        }
    }
    
    private func formatDuration(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)分钟"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours)小时"
            } else {
                return "\(hours)小时\(remainingMinutes)分钟"
            }
        }
    }
}

// MARK: - Supporting Views

/// Statistics card component
struct TaskPlanStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(color)
                
                Text(value)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

/// Task section view with collapsible functionality
struct TaskSectionView: View {
    let scope: TaskTimeScope
    let tasks: [TaskItem]
    let isExpanded: Bool
    let onToggleExpansion: () -> Void
    let onTaskToggle: (TaskItem) async -> Void
    
    private var completedCount: Int {
        tasks.filter { $0.isCompleted }.count
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Section Header
            Button(action: onToggleExpansion) {
                HStack {
                    HStack(spacing: 10) {
                        Image(systemName: scope.icon)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(scope.color)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(scope.displayName)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Text("\(tasks.count) 个任务")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        // Progress indicator
                        Text("\(completedCount)/\(tasks.count)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray5))
                            .cornerRadius(6)
                        
                        // Expand/collapse chevron
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                            .animation(.easeInOut(duration: 0.2), value: isExpanded)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Section Content
            if isExpanded {
                VStack(spacing: 12) {
                    ForEach(tasks.sorted(by: { $0.orderIndex < $1.orderIndex })) { task in
                        TaskItemRowView(
                            task: task,
                            onToggle: {
                                Task {
                                    await onTaskToggle(task)
                                }
                            }
                        )
                    }
                }
                .padding(.top, 12)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isExpanded)
    }
}



#Preview {
    NavigationView {
        TaskPlanView(branch: Branch(
            id: UUID(),
            name: "学习Swift编程",
            branchDescription: "系统学习Swift编程语言，掌握iOS开发技能",
            status: .active,
            createdAt: Date(),
            progress: 0.3
        ))
    }
}