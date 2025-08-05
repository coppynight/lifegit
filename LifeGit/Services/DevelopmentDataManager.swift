import Foundation
import SwiftData
import SwiftUI

/// Development utilities for managing test data
@MainActor
class DevelopmentDataManager: ObservableObject {
    static let shared = DevelopmentDataManager()
    
    private init() {}
    
    /// Reset all data and create fresh sample data
    func resetWithSampleData() async {
        do {
            let dataManager = DataManager.shared
            let modelContext = dataManager.modelContext
            
            // Clear all existing data
            try await clearAllData()
            
            // Generate fresh sample data
            await SampleDataGenerator.shared.generateSampleData()
            
            print("✅ 重置并生成示例数据完成")
            
        } catch {
            print("❌ 重置示例数据失败: \(error)")
        }
    }
    
    /// Clear all data from the database
    func clearAllData() async throws {
        let dataManager = DataManager.shared
        let modelContext = dataManager.modelContext
        
        // Delete all entities in reverse dependency order
        try await deleteAll(TaskItem.self, from: modelContext)
        try await deleteAll(TaskPlan.self, from: modelContext)
        try await deleteAll(Commit.self, from: modelContext)
        try await deleteAll(Branch.self, from: modelContext)
        try await deleteAll(User.self, from: modelContext)
        
        try dataManager.save()
        
        print("✅ 清除所有数据完成")
    }
    
    /// Delete all instances of a specific model type
    private func deleteAll<T: PersistentModel>(_ modelType: T.Type, from context: ModelContext) async throws {
        let descriptor = FetchDescriptor<T>()
        let items = try context.fetch(descriptor)
        
        for item in items {
            context.delete(item)
        }
    }
    
    /// Create specific test scenarios
    func createTestScenario(_ scenario: TestScenario) async {
        do {
            let dataManager = DataManager.shared
            let user = try dataManager.getDefaultUser()
            
            switch scenario {
            case .emptyState:
                try await clearAllData()
                // Only create master branch
                _ = try dataManager.getMasterBranch()
                
            case .singleActiveBranch:
                try await clearAllData()
                _ = try dataManager.getMasterBranch()
                await SampleDataGenerator.shared.generateMinimalSampleData()
                
            case .multipleBranches:
                try await clearAllData()
                _ = try dataManager.getMasterBranch()
                await SampleDataGenerator.shared.generateSampleData()
                
            case .completedGoals:
                try await clearAllData()
                _ = try dataManager.getMasterBranch()
                await createCompletedGoalsScenario(for: user)
                
            case .abandonedGoals:
                try await clearAllData()
                _ = try dataManager.getMasterBranch()
                await createAbandonedGoalsScenario(for: user)
            }
            
            print("✅ 测试场景 \(scenario.displayName) 创建完成")
            
        } catch {
            print("❌ 创建测试场景失败: \(error)")
        }
    }
    
    /// Create scenario with completed goals
    private func createCompletedGoalsScenario(for user: User) async {
        let dataManager = DataManager.shared
        let modelContext = dataManager.modelContext
        
        let completedBranches = [
            ("学会做饭", "掌握基本的烹饪技能，能够独立制作简单菜肴"),
            ("读完《原则》", "认真阅读并理解达利欧的《原则》一书"),
            ("建立晨练习惯", "每天早上进行30分钟的体育锻炼")
        ]
        
        for (index, (name, description)) in completedBranches.enumerated() {
            let completedAt = Calendar.current.date(byAdding: .day, value: -(30 - index * 10), to: Date()) ?? Date()
            let createdAt = Calendar.current.date(byAdding: .day, value: -60, to: completedAt) ?? Date()
            
            let branch = Branch(
                name: name,
                branchDescription: description,
                status: .completed,
                createdAt: createdAt,
                progress: 1.0
            )
            branch.completedAt = completedAt
            branch.user = user
            modelContext.insert(branch)
            
            // Add some commits
            let commits = createCompletionCommits(for: branch, user: user)
            for commit in commits {
                modelContext.insert(commit)
            }
        }
        
        try? dataManager.save()
    }
    
    /// Create scenario with abandoned goals
    private func createAbandonedGoalsScenario(for user: User) async {
        let dataManager = DataManager.shared
        let modelContext = dataManager.modelContext
        
        let abandonedBranches = [
            ("学习钢琴", "学会弹奏基本的钢琴曲目"),
            ("每日冥想", "建立每天冥想20分钟的习惯"),
            ("学习法语", "掌握法语基础对话能力")
        ]
        
        for (index, (name, description)) in abandonedBranches.enumerated() {
            let createdAt = Calendar.current.date(byAdding: .day, value: -(90 + index * 20), to: Date()) ?? Date()
            
            let branch = Branch(
                name: name,
                branchDescription: description,
                status: .abandoned,
                createdAt: createdAt,
                progress: Double.random(in: 0.1...0.4) // Low progress before abandoning
            )
            branch.user = user
            modelContext.insert(branch)
            
            // Add some commits showing initial effort
            let commits = createAbandonmentCommits(for: branch, user: user)
            for commit in commits {
                modelContext.insert(commit)
            }
        }
        
        try? dataManager.save()
    }
    
    /// Create commits for completed branches
    private func createCompletionCommits(for branch: Branch, user: User) -> [Commit] {
        let commitMessages = [
            "开始学习\(branch.name)",
            "取得初步进展",
            "遇到困难但坚持下来",
            "找到了有效的方法",
            "看到明显的改善",
            "达成阶段性目标",
            "完成最终目标！"
        ]
        
        return commitMessages.enumerated().map { index, message in
            let daysAgo = commitMessages.count - index
            let timestamp = Calendar.current.date(byAdding: .day, value: -daysAgo, to: branch.completedAt ?? Date()) ?? Date()
            
            let commitType: CommitType = index == commitMessages.count - 1 ? .milestone : 
                                       (index % 3 == 0 ? .taskComplete : 
                                        (index % 3 == 1 ? .learning : .reflection))
            
            let commit = Commit(
                message: message,
                type: commitType,
                timestamp: timestamp,
                branchId: branch.id
            )
            commit.branch = branch
            commit.user = user
            return commit
        }
    }
    
    /// Create commits for abandoned branches
    private func createAbandonmentCommits(for branch: Branch, user: User) -> [Commit] {
        let commitMessages = [
            "开始学习\(branch.name)",
            "初步尝试，感觉有点困难",
            "继续努力中",
            "进展缓慢，有些沮丧",
            "暂时搁置，以后再试"
        ]
        
        return commitMessages.enumerated().map { index, message in
            let daysAgo = commitMessages.count - index
            let timestamp = Calendar.current.date(byAdding: .day, value: -daysAgo, to: branch.createdAt) ?? Date()
            
            let commitType: CommitType = index < 2 ? .taskComplete : .reflection
            
            let commit = Commit(
                message: message,
                type: commitType,
                timestamp: timestamp,
                branchId: branch.id
            )
            commit.branch = branch
            commit.user = user
            return commit
        }
    }
    
    /// Generate random commits for testing
    func generateRandomCommits(count: Int = 10) async {
        do {
            let dataManager = DataManager.shared
            let modelContext = dataManager.modelContext
            let user = try dataManager.getDefaultUser()
            
            // Get all active branches
            let branchDescriptor = FetchDescriptor<Branch>()
            let allBranches = try modelContext.fetch(branchDescriptor)
            let activeBranches = allBranches.filter { $0.status == .active }
            
            guard !activeBranches.isEmpty else {
                print("❌ 没有活跃分支可以添加提交")
                return
            }
            
            for _ in 0..<count {
                let randomBranch = activeBranches.randomElement()!
                let randomType = CommitType.allCases.randomElement()!
                let randomMessage = generateRandomCommitMessage(for: randomBranch, type: randomType)
                let randomDaysAgo = Int.random(in: 1...30)
                let timestamp = Calendar.current.date(byAdding: .day, value: -randomDaysAgo, to: Date()) ?? Date()
                
                let commit = Commit(
                    message: randomMessage,
                    type: randomType,
                    timestamp: timestamp,
                    branchId: randomBranch.id
                )
                commit.branch = randomBranch
                commit.user = user
                
                modelContext.insert(commit)
            }
            
            try dataManager.save()
            print("✅ 生成 \(count) 个随机提交完成")
            
        } catch {
            print("❌ 生成随机提交失败: \(error)")
        }
    }
    
    /// Generate random commit message
    private func generateRandomCommitMessage(for branch: Branch, type: CommitType) -> String {
        let templates: [CommitType: [String]] = [
            .taskComplete: [
                "完成了\(branch.name)的一个重要任务",
                "在\(branch.name)上取得进展",
                "达成了今日的\(branch.name)目标"
            ],
            .learning: [
                "学到了关于\(branch.name)的新知识",
                "理解了\(branch.name)的关键概念",
                "掌握了\(branch.name)的新技巧"
            ],
            .reflection: [
                "对\(branch.name)有了新的思考",
                "反思了\(branch.name)的进展",
                "总结了\(branch.name)的经验"
            ],
            .milestone: [
                "在\(branch.name)上达成重要里程碑",
                "\(branch.name)取得突破性进展",
                "完成了\(branch.name)的阶段性目标"
            ]
        ]
        
        let typeTemplates = templates[type] ?? ["完成了相关任务"]
        return typeTemplates.randomElement() ?? "完成了相关任务"
    }
}

/// Test scenarios for development
enum TestScenario: CaseIterable {
    case emptyState
    case singleActiveBranch
    case multipleBranches
    case completedGoals
    case abandonedGoals
    
    var displayName: String {
        switch self {
        case .emptyState:
            return "空状态"
        case .singleActiveBranch:
            return "单个活跃分支"
        case .multipleBranches:
            return "多个分支"
        case .completedGoals:
            return "已完成目标"
        case .abandonedGoals:
            return "已废弃目标"
        }
    }
    
    var description: String {
        switch self {
        case .emptyState:
            return "只有主干分支，没有其他数据"
        case .singleActiveBranch:
            return "一个简单的活跃分支用于测试"
        case .multipleBranches:
            return "多个不同状态的分支和丰富的数据"
        case .completedGoals:
            return "多个已完成的目标和相关提交"
        case .abandonedGoals:
            return "多个已废弃的目标和相关提交"
        }
    }
}

#if DEBUG
/// Development menu for testing
struct DevelopmentMenu: View {
    @StateObject private var devManager = DevelopmentDataManager.shared
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            List {
                Section("数据重置") {
                    Button("重置并生成示例数据") {
                        Task {
                            isLoading = true
                            await devManager.resetWithSampleData()
                            isLoading = false
                        }
                    }
                    .disabled(isLoading)
                    
                    Button("清除所有数据") {
                        Task {
                            isLoading = true
                            try await devManager.clearAllData()
                            isLoading = false
                        }
                    }
                    .disabled(isLoading)
                }
                
                Section("测试场景") {
                    ForEach(TestScenario.allCases, id: \.self) { scenario in
                        VStack(alignment: .leading) {
                            Button(scenario.displayName) {
                                Task {
                                    isLoading = true
                                    await devManager.createTestScenario(scenario)
                                    isLoading = false
                                }
                            }
                            .disabled(isLoading)
                            
                            Text(scenario.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("随机数据") {
                    Button("生成10个随机提交") {
                        Task {
                            isLoading = true
                            await devManager.generateRandomCommits(count: 10)
                            isLoading = false
                        }
                    }
                    .disabled(isLoading)
                    
                    Button("生成50个随机提交") {
                        Task {
                            isLoading = true
                            await devManager.generateRandomCommits(count: 50)
                            isLoading = false
                        }
                    }
                    .disabled(isLoading)
                }
            }
            .navigationTitle("开发工具")
            .navigationBarTitleDisplayMode(.inline)
            .overlay {
                if isLoading {
                    LoadingView()
                        .background(Color.black.opacity(0.3))
                }
            }
        }
    }
}
#endif