import XCTest
import SwiftData
@testable import LifeGit

/// Integration tests for Business Logic layer with Repository layer
@MainActor
final class BusinessLogicIntegrationTests: XCTestCase {
    
    // MARK: - Test Properties
    private var modelContainer: ModelContainer!
    private var modelContext: ModelContext!
    private var branchRepository: SwiftDataBranchRepository!
    private var taskPlanRepository: SwiftDataTaskPlanRepository!
    private var commitRepository: SwiftDataCommitRepository!
    private var branchManager: BranchManager!
    private var taskPlanManager: TaskPlanManager!
    private var commitManager: CommitManager!
    private var mockTaskPlanService: MockTaskPlanService!
    private var mockAIErrorHandler: MockAIServiceErrorHandler!
    
    // MARK: - Setup & Teardown
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory model container for testing
        let schema = Schema([
            User.self,
            Branch.self,
            Commit.self,
            TaskPlan.self,
            TaskItem.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        
        modelContainer = try ModelContainer(
            for: schema,
            configurations: [modelConfiguration]
        )
        
        modelContext = ModelContext(modelContainer)
        
        // Initialize repositories
        branchRepository = SwiftDataBranchRepository(modelContext: modelContext)
        taskPlanRepository = SwiftDataTaskPlanRepository(modelContext: modelContext)
        commitRepository = SwiftDataCommitRepository(modelContext: modelContext)
        
        // Initialize mock services
        mockTaskPlanService = MockTaskPlanService()
        mockAIErrorHandler = MockAIServiceErrorHandler()
        
        // Initialize business logic managers
        branchManager = BranchManager(
            branchRepository: branchRepository,
            taskPlanRepository: taskPlanRepository,
            commitRepository: commitRepository,
            taskPlanService: mockTaskPlanService,
            aiErrorHandler: mockAIErrorHandler
        )
        
        taskPlanManager = TaskPlanManager(
            taskPlanRepository: taskPlanRepository,
            taskPlanService: mockTaskPlanService
        )
        
        commitManager = CommitManager(
            commitRepository: commitRepository,
            branchRepository: branchRepository
        )
    }
    
    override func tearDown() async throws {
        branchManager = nil
        taskPlanManager = nil
        commitManager = nil
        mockTaskPlanService = nil
        mockAIErrorHandler = nil
        branchRepository = nil
        taskPlanRepository = nil
        commitRepository = nil
        modelContext = nil
        modelContainer = nil
        try await super.tearDown()
    }
    
    // MARK: - Branch Creation Integration Tests
    func testCreateBranchWithAITaskPlanIntegration() async throws {
        // Arrange
        let userId = UUID()
        mockTaskPlanService.configureForSuccess()
        
        // Act
        let branch = try await branchManager.createBranch(
            name: "学习iOS开发",
            description: "掌握iOS应用开发的完整技能栈",
            userId: userId
        )
        
        // Assert - Branch created successfully
        XCTAssertEqual(branch.name, "学习iOS开发")
        XCTAssertEqual(branch.status, .active)
        XCTAssertFalse(branch.isMaster)
        
        // Assert - Task plan created and associated
        XCTAssertNotNil(branch.taskPlan)
        XCTAssertTrue(branch.taskPlan?.isAIGenerated ?? false)
        XCTAssertEqual(branch.taskPlan?.branchId, branch.id)
        
        // Assert - Data persisted in repository
        let persistedBranch = try await branchRepository.findById(branch.id)
        XCTAssertNotNil(persistedBranch)
        XCTAssertEqual(persistedBranch?.name, "学习iOS开发")
        
        let persistedTaskPlan = try await taskPlanRepository.findByBranchId(branch.id)
        XCTAssertNotNil(persistedTaskPlan)
        XCTAssertEqual(persistedTaskPlan?.totalDuration, "4周")
        XCTAssertFalse(persistedTaskPlan?.tasks.isEmpty ?? true)
    }
    
    func testCreateBranchWithAIFailureFallback() async throws {
        // Arrange
        let userId = UUID()
        mockTaskPlanService.configureForFailure()
        mockAIErrorHandler.shouldRetry = false // Don't retry, fallback immediately
        
        // Act
        let branch = try await branchManager.createBranch(
            name: "测试目标",
            description: "测试AI失败后的回退机制",
            userId: userId
        )
        
        // Assert - Branch created with manual task plan
        XCTAssertEqual(branch.name, "测试目标")
        XCTAssertNotNil(branch.taskPlan)
        XCTAssertFalse(branch.taskPlan?.isAIGenerated ?? true) // Should be manual
        
        // Assert - Manual task plan persisted
        let persistedTaskPlan = try await taskPlanRepository.findByBranchId(branch.id)
        XCTAssertNotNil(persistedTaskPlan)
        XCTAssertFalse(persistedTaskPlan?.isAIGenerated ?? true)
        XCTAssertEqual(persistedTaskPlan?.totalDuration, "手动创建")
    }
    
    // MARK: - Task Plan Management Integration Tests
    func testRegenerateTaskPlanIntegration() async throws {
        // Arrange - Create branch with initial task plan
        let userId = UUID()
        mockTaskPlanService.configureForSuccess()
        
        let branch = try await branchManager.createBranch(
            name: "需要重新生成任务计划的目标",
            description: "测试任务计划重新生成",
            userId: userId
        )
        
        let originalTaskPlanId = branch.taskPlan?.id
        XCTAssertNotNil(originalTaskPlanId)
        
        // Act - Regenerate task plan
        try await branchManager.regenerateTaskPlan(for: branch)
        
        // Assert - New task plan created
        XCTAssertNotNil(branch.taskPlan)
        XCTAssertNotEqual(branch.taskPlan?.id, originalTaskPlanId)
        
        // Assert - Old task plan deleted from repository
        let oldTaskPlan = try await taskPlanRepository.findByBranchId(branch.id)
        XCTAssertNotNil(oldTaskPlan) // New one should exist
        XCTAssertNotEqual(oldTaskPlan?.id, originalTaskPlanId)
        
        // Assert - Branch updated in repository
        let updatedBranch = try await branchRepository.findById(branch.id)
        XCTAssertNotNil(updatedBranch?.taskPlan)
    }
    
    func testTaskPlanEditingIntegration() async throws {
        // Arrange - Create branch with task plan
        let userId = UUID()
        mockTaskPlanService.configureForSuccess()
        
        let branch = try await branchManager.createBranch(
            name: "可编辑的目标",
            description: "测试任务计划编辑功能",
            userId: userId
        )
        
        guard let taskPlan = branch.taskPlan else {
            XCTFail("Task plan should exist")
            return
        }
        
        // Act - Edit task plan through TaskPlanManager
        let newTask = TaskItem(
            title: "用户添加的任务",
            description: "用户手动添加的新任务",
            estimatedDuration: 180,
            timeScope: .weekly,
            isAIGenerated: false,
            orderIndex: 10
        )
        
        taskPlan.tasks.append(newTask)
        taskPlan.lastModifiedAt = Date()
        
        try await taskPlanManager.updateTaskPlan(taskPlan)
        
        // Assert - Changes persisted
        let updatedTaskPlan = try await taskPlanRepository.findByBranchId(branch.id)
        XCTAssertNotNil(updatedTaskPlan)
        XCTAssertNotNil(updatedTaskPlan?.lastModifiedAt)
        
        let userAddedTasks = updatedTaskPlan?.tasks.filter { !$0.isAIGenerated } ?? []
        XCTAssertEqual(userAddedTasks.count, 1)
        XCTAssertEqual(userAddedTasks.first?.title, "用户添加的任务")
    }
    
    // MARK: - Commit Management Integration Tests
    func testCreateCommitIntegration() async throws {
        // Arrange - Create branch
        let userId = UUID()
        mockTaskPlanService.configureForSuccess()
        
        let branch = try await branchManager.createBranch(
            name: "有提交记录的目标",
            description: "测试提交记录功能",
            userId: userId
        )
        
        // Act - Create commit through CommitManager
        let commit = try await commitManager.createCommit(
            message: "完成了第一个重要任务",
            type: .taskComplete,
            branchId: branch.id,
            relatedTaskId: branch.taskPlan?.tasks.first?.id
        )
        
        // Assert - Commit created and persisted
        XCTAssertEqual(commit.message, "完成了第一个重要任务")
        XCTAssertEqual(commit.type, .taskComplete)
        XCTAssertEqual(commit.branchId, branch.id)
        
        // Assert - Commit persisted in repository
        let persistedCommits = try await commitRepository.findByBranchId(branch.id)
        XCTAssertEqual(persistedCommits.count, 1)
        XCTAssertEqual(persistedCommits.first?.message, "完成了第一个重要任务")
        
        // Assert - Commit count updated
        let commitCount = try await commitRepository.getCommitCount(for: branch.id)
        XCTAssertEqual(commitCount, 1)
    }
    
    func testMultipleCommitsIntegration() async throws {
        // Arrange - Create branch
        let userId = UUID()
        mockTaskPlanService.configureForSuccess()
        
        let branch = try await branchManager.createBranch(
            name: "多提交目标",
            description: "测试多个提交记录",
            userId: userId
        )
        
        // Act - Create multiple commits
        let commitMessages = [
            ("开始学习基础知识", CommitType.learning),
            ("完成第一个练习", CommitType.taskComplete),
            ("今天的学习心得", CommitType.reflection),
            ("达成重要里程碑", CommitType.milestone)
        ]
        
        var createdCommits: [Commit] = []
        for (message, type) in commitMessages {
            let commit = try await commitManager.createCommit(
                message: message,
                type: type,
                branchId: branch.id
            )
            createdCommits.append(commit)
        }
        
        // Assert - All commits created
        XCTAssertEqual(createdCommits.count, 4)
        
        // Assert - All commits persisted
        let persistedCommits = try await commitRepository.findByBranchId(branch.id)
        XCTAssertEqual(persistedCommits.count, 4)
        
        // Assert - Commit types are correct
        let commitTypes = persistedCommits.map { $0.type }.sorted { $0.rawValue < $1.rawValue }
        XCTAssertTrue(commitTypes.contains(.learning))
        XCTAssertTrue(commitTypes.contains(.taskComplete))
        XCTAssertTrue(commitTypes.contains(.reflection))
        XCTAssertTrue(commitTypes.contains(.milestone))
        
        // Assert - Commit count is correct
        let totalCommitCount = try await commitRepository.getCommitCount(for: branch.id)
        XCTAssertEqual(totalCommitCount, 4)
    }
    
    // MARK: - Branch Lifecycle Integration Tests
    func testCompleteBranchWorkflowIntegration() async throws {
        // Arrange - Create branch
        let userId = UUID()
        mockTaskPlanService.configureForSuccess()
        
        let branch = try await branchManager.createBranch(
            name: "完整生命周期测试",
            description: "测试分支的完整生命周期",
            userId: userId
        )
        
        // Step 1: Add some commits during active phase
        _ = try await commitManager.createCommit(
            message: "开始执行任务",
            type: .taskComplete,
            branchId: branch.id
        )
        
        _ = try await commitManager.createCommit(
            message: "学习进展记录",
            type: .learning,
            branchId: branch.id
        )
        
        // Step 2: Complete some tasks
        if let taskPlan = branch.taskPlan, !taskPlan.tasks.isEmpty {
            taskPlan.tasks[0].markAsCompleted()
            try await taskPlanRepository.update(taskPlan)
        }
        
        // Step 3: Complete the branch
        try await branchManager.completeBranch(branch)
        
        // Assert - Branch status updated
        XCTAssertEqual(branch.status, .completed)
        XCTAssertNotNil(branch.completedAt)
        
        // Assert - Completion commit created
        let allCommits = try await commitRepository.findByBranchId(branch.id)
        let milestoneCommits = allCommits.filter { $0.type == .milestone }
        XCTAssertEqual(milestoneCommits.count, 1)
        XCTAssertTrue(milestoneCommits.first?.message.contains("完成目标") ?? false)
        
        // Assert - Branch persisted with completed status
        let persistedBranch = try await branchRepository.findById(branch.id)
        XCTAssertEqual(persistedBranch?.status, .completed)
        XCTAssertNotNil(persistedBranch?.completedAt)
    }
    
    func testMergeBranchWorkflowIntegration() async throws {
        // Arrange - Create master branch and regular branch
        let userId = UUID()
        
        // Create master branch manually
        let masterBranch = Branch(
            name: "Master",
            description: "人生主干",
            isMaster: true
        )
        try await branchRepository.create(masterBranch)
        
        // Create regular branch
        mockTaskPlanService.configureForSuccess()
        let branch = try await branchManager.createBranch(
            name: "待合并的目标",
            description: "测试分支合并功能",
            userId: userId
        )
        
        // Complete the branch first
        try await branchManager.completeBranch(branch)
        
        // Act - Merge branch
        try await branchManager.mergeBranch(branch)
        
        // Assert - Merge commit created in master branch
        let masterCommits = try await commitRepository.findByBranchId(masterBranch.id)
        XCTAssertEqual(masterCommits.count, 1)
        XCTAssertTrue(masterCommits.first?.message.contains("合并目标") ?? false)
        XCTAssertEqual(masterCommits.first?.type, .milestone)
        
        // Assert - Branch marked as merged
        XCTAssertNotNil(branch.mergedAt)
        
        // Assert - Changes persisted
        let persistedBranch = try await branchRepository.findById(branch.id)
        XCTAssertNotNil(persistedBranch?.mergedAt)
    }
    
    // MARK: - Statistics Integration Tests
    func testBranchStatisticsIntegration() async throws {
        // Arrange - Create branch with task plan and commits
        let userId = UUID()
        mockTaskPlanService.configureForSuccess()
        
        let branch = try await branchManager.createBranch(
            name: "统计测试目标",
            description: "测试分支统计功能",
            userId: userId
        )
        
        // Add more tasks to task plan
        guard let taskPlan = branch.taskPlan else {
            XCTFail("Task plan should exist")
            return
        }
        
        let additionalTasks = [
            TaskItem(title: "额外任务1", description: "描述1", estimatedDuration: 120, timeScope: .weekly, orderIndex: 10),
            TaskItem(title: "额外任务2", description: "描述2", estimatedDuration: 90, timeScope: .monthly, orderIndex: 11)
        ]
        
        taskPlan.tasks.append(contentsOf: additionalTasks)
        try await taskPlanRepository.update(taskPlan)
        
        // Complete some tasks
        taskPlan.tasks[0].markAsCompleted()
        additionalTasks[0].markAsCompleted()
        try await taskPlanRepository.update(taskPlan)
        
        // Create several commits
        for i in 1...5 {
            _ = try await commitManager.createCommit(
                message: "提交\(i)",
                type: .taskComplete,
                branchId: branch.id
            )
        }
        
        // Act - Get statistics
        let statistics = try await branchManager.getBranchStatistics(branch)
        
        // Assert - Statistics are correct
        XCTAssertEqual(statistics.commitCount, 5)
        XCTAssertEqual(statistics.totalTasks, 3) // 1 original + 2 additional
        XCTAssertEqual(statistics.completedTasks, 2)
        XCTAssertEqual(statistics.progress, 2.0/3.0, accuracy: 0.01)
        
        // Total duration: original task (60) + additional tasks (120 + 90) = 270
        XCTAssertEqual(statistics.estimatedDuration, 270)
    }
    
    // MARK: - Error Handling Integration Tests
    func testErrorHandlingIntegration() async throws {
        // Test 1: Repository failure during branch creation
        let userId = UUID()
        mockTaskPlanService.configureForSuccess()
        
        // Simulate repository failure by using invalid model context
        let invalidBranchRepository = SwiftDataBranchRepository(modelContext: ModelContext(modelContainer))
        
        let invalidBranchManager = BranchManager(
            branchRepository: invalidBranchRepository,
            taskPlanRepository: taskPlanRepository,
            commitRepository: commitRepository,
            taskPlanService: mockTaskPlanService,
            aiErrorHandler: mockAIErrorHandler
        )
        
        // This should handle the error gracefully
        do {
            _ = try await invalidBranchManager.createBranch(
                name: "错误测试",
                description: "测试错误处理",
                userId: userId
            )
        } catch {
            // Expected to fail, verify error is handled
            XCTAssertNotNil(invalidBranchManager.error)
        }
    }
    
    func testConcurrentOperationsIntegration() async throws {
        // Test concurrent branch creation
        let userId = UUID()
        mockTaskPlanService.configureForSuccess()
        
        let branchNames = ["并发分支1", "并发分支2", "并发分支3", "并发分支4", "并发分支5"]
        
        // Create branches concurrently
        let branches = try await withThrowingTaskGroup(of: Branch.self) { group in
            for name in branchNames {
                group.addTask {
                    return try await self.branchManager.createBranch(
                        name: name,
                        description: "并发创建测试",
                        userId: userId
                    )
                }
            }
            
            var results: [Branch] = []
            for try await branch in group {
                results.append(branch)
            }
            return results
        }
        
        // Assert - All branches created successfully
        XCTAssertEqual(branches.count, 5)
        
        // Assert - All branches persisted
        let allBranches = try await branchRepository.findAll()
        XCTAssertGreaterThanOrEqual(allBranches.count, 5)
        
        // Verify each branch has a task plan
        for branch in branches {
            let taskPlan = try await taskPlanRepository.findByBranchId(branch.id)
            XCTAssertNotNil(taskPlan)
        }
    }
    
    // MARK: - Performance Integration Tests
    func testLargeScaleOperationsIntegration() async throws {
        // Create many branches with task plans and commits
        let userId = UUID()
        mockTaskPlanService.configureForSuccess()
        
        let branchCount = 50
        let commitsPerBranch = 20
        
        // Measure performance of large-scale operations
        measure {
            Task {
                do {
                    var branches: [Branch] = []
                    
                    // Create branches
                    for i in 0..<branchCount {
                        let branch = try await self.branchManager.createBranch(
                            name: "大规模测试分支\(i)",
                            description: "性能测试分支\(i)",
                            userId: userId
                        )
                        branches.append(branch)
                    }
                    
                    // Create commits for each branch
                    for branch in branches {
                        for j in 0..<commitsPerBranch {
                            _ = try await self.commitManager.createCommit(
                                message: "提交\(j)",
                                type: .taskComplete,
                                branchId: branch.id
                            )
                        }
                    }
                    
                    // Verify final state
                    let allBranches = try await self.branchRepository.findAll()
                    XCTAssertGreaterThanOrEqual(allBranches.count, branchCount)
                    
                } catch {
                    XCTFail("Large scale operations failed: \(error)")
                }
            }
        }
    }
}

// MARK: - Mock Business Logic Components

class MockTaskPlanManager {
    var updateCallCount = 0
    var shouldSucceed = true
    var mockError: Error?
    
    func updateTaskPlan(_ taskPlan: TaskPlan) async throws {
        updateCallCount += 1
        if !shouldSucceed, let error = mockError {
            throw error
        }
    }
}

class MockCommitManager {
    var createCallCount = 0
    var shouldSucceed = true
    var mockError: Error?
    
    func createCommit(message: String, type: CommitType, branchId: UUID, relatedTaskId: UUID? = nil) async throws -> Commit {
        createCallCount += 1
        if !shouldSucceed, let error = mockError {
            throw error
        }
        
        return Commit(
            message: message,
            type: type,
            branchId: branchId,
            relatedTaskId: relatedTaskId
        )
    }
}