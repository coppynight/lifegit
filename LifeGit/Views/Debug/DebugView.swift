import SwiftUI
import SwiftData

#if DEBUG
/// Debug view for development and testing
struct DebugView: View {
    @StateObject private var devManager = DevelopmentDataManager.shared
    @StateObject private var sampleGenerator = SampleDataGenerator.shared
    @EnvironmentObject private var appState: AppStateManager
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            List {
                Section("快速操作") {
                    Button("生成示例数据") {
                        generateSampleData()
                    }
                    .disabled(isLoading)
                    
                    Button("清除所有数据") {
                        clearAllData()
                    }
                    .disabled(isLoading)
                    .foregroundColor(.red)
                }
                
                Section("测试场景") {
                    ForEach(TestScenario.allCases, id: \.self) { scenario in
                        Button(scenario.displayName) {
                            createTestScenario(scenario)
                        }
                        .disabled(isLoading)
                    }
                }
                
                Section("数据统计") {
                    DataStatisticsView()
                }
                
                Section("开发工具") {
                    NavigationLink("错误历史") {
                        ErrorHistoryView()
                    }
                    
                    NavigationLink("性能监控") {
                        PerformanceMonitorView()
                    }
                    
                    Button("触发示例错误") {
                        triggerSampleError()
                    }
                    
                    Button("生成随机提交") {
                        generateRandomCommits()
                    }
                    .disabled(isLoading)
                }
            }
            .navigationTitle("调试工具")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
            .alert("操作完成", isPresented: $showingAlert) {
                Button("确定") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func generateSampleData() {
        isLoading = true
        Task {
            await sampleGenerator.generateSampleData()
            await appState.refreshBranches()
            await MainActor.run {
                isLoading = false
                alertMessage = "示例数据生成完成"
                showingAlert = true
            }
        }
    }
    
    private func clearAllData() {
        isLoading = true
        Task {
            do {
                try await devManager.clearAllData()
                await appState.refreshBranches()
                await MainActor.run {
                    isLoading = false
                    alertMessage = "所有数据已清除"
                    showingAlert = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    alertMessage = "清除数据失败: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
    
    private func createTestScenario(_ scenario: TestScenario) {
        isLoading = true
        Task {
            await devManager.createTestScenario(scenario)
            await appState.refreshBranches()
            await MainActor.run {
                isLoading = false
                alertMessage = "测试场景 \(scenario.displayName) 创建完成"
                showingAlert = true
            }
        }
    }
    
    private func generateRandomCommits() {
        isLoading = true
        Task {
            await devManager.generateRandomCommits(count: 10)
            await appState.refreshBranches()
            await MainActor.run {
                isLoading = false
                alertMessage = "随机提交生成完成"
                showingAlert = true
            }
        }
    }
    
    private func triggerSampleError() {
        let errorHandler = ErrorHandler.shared
        let sampleError = AppError.aiServiceError(.networkUnavailable)
        errorHandler.handle(sampleError, context: "Debug view test error")
    }
}

/// Data statistics view for debugging
struct DataStatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var stats: DataStats?
    
    var body: some View {
        Group {
            if let stats = stats {
                VStack(alignment: .leading, spacing: 8) {
                    StatRow(label: "用户数", value: "\(stats.userCount)")
                    StatRow(label: "分支数", value: "\(stats.branchCount)")
                    StatRow(label: "提交数", value: "\(stats.commitCount)")
                    StatRow(label: "任务计划数", value: "\(stats.taskPlanCount)")
                    StatRow(label: "任务项数", value: "\(stats.taskItemCount)")
                }
            } else {
                Text("加载统计数据...")
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            loadStats()
        }
    }
    
    private func loadStats() {
        Task {
            let stats = await calculateStats()
            await MainActor.run {
                self.stats = stats
            }
        }
    }
    
    private func calculateStats() async -> DataStats {
        do {
            let userCount = try modelContext.fetch(FetchDescriptor<User>()).count
            let branchCount = try modelContext.fetch(FetchDescriptor<Branch>()).count
            let commitCount = try modelContext.fetch(FetchDescriptor<Commit>()).count
            let taskPlanCount = try modelContext.fetch(FetchDescriptor<TaskPlan>()).count
            let taskItemCount = try modelContext.fetch(FetchDescriptor<TaskItem>()).count
            
            return DataStats(
                userCount: userCount,
                branchCount: branchCount,
                commitCount: commitCount,
                taskPlanCount: taskPlanCount,
                taskItemCount: taskItemCount
            )
        } catch {
            print("Failed to calculate stats: \(error)")
            return DataStats(userCount: 0, branchCount: 0, commitCount: 0, taskPlanCount: 0, taskItemCount: 0)
        }
    }
}

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct DataStats {
    let userCount: Int
    let branchCount: Int
    let commitCount: Int
    let taskPlanCount: Int
    let taskItemCount: Int
}

#Preview {
    DebugView()
        .environmentObject(AppStateManager())
        .modelContainer(for: [User.self, Branch.self, Commit.self, TaskPlan.self, TaskItem.self])
}

#else
/// Release build placeholder
struct DebugView: View {
    var body: some View {
        Text("Debug view is only available in debug builds")
    }
}
#endif