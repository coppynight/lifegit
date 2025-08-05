import XCTest
import SwiftData
@testable import LifeGit

/// End-to-End tests covering complete user workflows
/// Tests the full user journey: 创建目标→AI生成任务→执行任务→完成目标
@MainActor
final class EndToEndTests: XCTestCase {
    
    // MARK: - Test Properties
    private var modelContainer: ModelContainer!
    private var modelContext: ModelContext!
    private var appStateManager: AppStateManager!
    private var branchManager: BranchManager!
    private var taskPlanManager: TaskPlanManager!
    private var commitManager: CommitManager!
    private var mockTaskPlanService: MockTaskPlanService!
    private var mockAIErrorHandler: MockAIServiceErrorHandler!
    private var testUser: User!
    
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
        let branchRepository = SwiftDataBranchRepository(modelContext: modelContext)
        let taskPlanRepository = SwiftDataTaskPlanRepository(modelContext: modelContext)
        let commitRepository = SwiftDataCommitRepository(modelContext: modelContext)
        
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
        
        appStateManager = AppStateManager(
            branchManager: branchManager,
            commitManager: commitManager,
            taskPlanManager: taskPlanManager
        )
        
        // Create test user
        testUser = User()
        modelContext.insert(testUser)
        try modelContext.save()
        
        // Create master branch
        let masterBranch = Branch(
            name: "Master",
            description: "人生主干",
            isMaster: true
        )
        masterBranch.user = testUser
        modelContext.insert(masterBranch)
        try modelContext.save()
    }
    
    override func tearDown() async throws {
        appStateManager = nil
        branchManager = nil
        taskPlanManager = nil
        commitManager = nil
        mockTaskPlanService = nil
        mockAIErrorHandler = nil
        testUser = nil
        modelContext = nil
        modelContainer = nil
        try await super.tearDown()
    }
    
    // MARK: - Complete User Journey Tests
    
    /// Test the complete happy path: 创建目标→AI生成任务→执行任务→完成目标
    func testCompleteUserJourneyHappyPath() async throws {
        // Configure AI service for success
        mockTaskPlanService.configureForSuccess()
        
        // STEP 1: 用户创建新目标
        print("🎯 Step 1: Creating new goal...")
        let goalName = "学习SwiftUI开发"
        let goalDescription = "掌握SwiftUI框架，能够独立开发iOS应用"
        
        let branch = try await branchManager.createBranch(
            name: goalName,
            description: goalDescription,
            userId: testUser.id
        )
        
        // Verify goal creation
        XCTAssertEqual(branch.name, goalName)
        XCTAssertEqual(branch.description, goalDescription)
        XCTAssertEqual(branch.status, .active)
        XCTAssertFalse(branch.isMaster)
        XCTAssertNotNil(branch.taskPlan)
        
        print("✅ Goal created successfully: \(branch.name)")
        
        // STEP 2: AI生成任务计划
        print("🤖 Step 2: AI generating task plan...")
        guard let taskPlan = branch.taskPlan else {
            XCTFail("Task plan should be generated")
            return
        }
        
        // Verify AI task plan generation
        XCTAssertTrue(taskPlan.isAIGenerated)
        XCTAssertFalse(taskPlan.tasks.isEmpty)
        XCTAssertEqual(taskPlan.branchId, branch.id)
        XCTAssertEqual(taskPlan.totalDuration, "4周")
        
        // Verify task structure
        let tasks = taskPlan.tasks.sorted { $0.orderIndex < $1.orderIndex }
        XCTAssertGreaterThan(tasks.count, 0)
        
        for task in tasks {
            XCTAssertFalse(task.title.isEmpty)
            XCTAssertFalse(task.description.isEmpty)
            XCTAssertGreaterThan(task.estimatedDuration, 0)
            XCTAssertTrue(task.isAIGenerated)
        }
        
        print("✅ AI generated \(tasks.count) tasks successfully")
        
        // STEP 3: 用户确认并可能修改任务计划
        print("📝 Step 3: User reviewing and modifying task plan...")
        
        // Simulate user adding a custom task
        let customTask = TaskItem(
            title: "创建个人项目",
            description: "应用所学知识创建一个个人iOS项目",
            estimatedDuration: 240, // 4 hours
            timeScope: .weekly,
            isAIGenerated: false,
            orderIndex: tasks.count
        )
        
        taskPlan.tasks.append(customTask)
        taskPlan.lastModifiedAt = Date()
        
        try await taskPlanManager.updateTaskPlan(taskPlan)
        
        // Verify task plan modification
        XCTAssertNotNil(taskPlan.lastModifiedAt)
        let userTasks = taskPlan.tasks.filter { !$0.isAIGenerated }
        XCTAssertEqual(userTasks.count, 1)
        XCTAssertEqual(userTasks.first?.title, "创建个人项目")
        
        print("✅ User added custom task: \(customTask.title)")
        
        // STEP 4: 用户开始执行任务，记录进展
        print("🚀 Step 4: User executing tasks and recording progress...")
        
        // Switch to the new branch in app state
        appStateManager.switchToBranch(branch)
        XCTAssertEqual(appStateManager.currentBranch?.id, branch.id)
        
        // Simulate user working on tasks over several days
        let progressCommits = [
            ("开始学习SwiftUI基础语法", CommitType.learning),
            ("完成第一个SwiftUI视图", CommitType.taskComplete),
            ("学习了状态管理和数据绑定", CommitType.learning),
            ("今天的学习让我对声明式UI有了更深理解", CommitType.reflection),
            ("完成了导航和列表视图练习", CommitType.taskComplete),
            ("学习了动画和手势处理", CommitType.learning),
            ("完成了一个完整的小应用", CommitType.milestone)
        ]
        
        var createdCommits: [Commit] = []
        for (message, type) in progressCommits {
            let commit = try await commitManager.createCommit(
                message: message,
                type: type,
                branchId: branch.id,
                relatedTaskId: type == .taskComplete ? tasks.first?.id : nil
            )
            createdCommits.append(commit)
            
            // Simulate time passing between commits
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
        
        // Verify progress recording
        XCTAssertEqual(createdCommits.count, 7)
        
        let commitsByType = Dictionary(grouping: createdCommits) { $0.type }
        XCTAssertEqual(commitsByType[.learning]?.count, 3)
        XCTAssertEqual(commitsByType[.taskComplete]?.count, 2)
        XCTAssertEqual(commitsByType[.reflection]?.count, 1)
        XCTAssertEqual(commitsByType[.milestone]?.count, 1)
        
        print("✅ Recorded \(createdCommits.count) progress commits")
        
        // STEP 5: 用户完成任务，标记任务为已完成
        print("✅ Step 5: User completing tasks...")
        
        // Mark some tasks as completed
        let tasksToComplete = Array(tasks.prefix(3)) // Complete first 3 tasks
        for task in tasksToComplete {
            task.markAsCompleted()
        }
        
        // Also complete the custom task
        customTask.markAsCompleted()
        
        try await taskPlanManager.updateTaskPlan(taskPlan)
        
        // Verify task completion
        let completedTasks = taskPlan.tasks.filter { $0.isCompleted }
        XCTAssertEqual(completedTasks.count, 4) // 3 AI tasks + 1 custom task
        
        // Calculate and verify progress
        let progress = Double(completedTasks.count) / Double(taskPlan.tasks.count)
        XCTAssertGreaterThan(progress, 0.5) // More than 50% complete
        
        print("✅ Completed \(completedTasks.count)/\(taskPlan.tasks.count) tasks")
        
        // STEP 6: 用户完成所有任务，准备完成目标
        print("🎉 Step 6: User completing all tasks and finishing goal...")
        
        // Complete remaining tasks
        let remainingTasks = taskPlan.tasks.filter { !$0.isCompleted }
        for task in remainingTasks {
            task.markAsCompleted()
            
            // Create completion commit for each task
            _ = try await commitManager.createCommit(
                message: "完成任务: \(task.title)",
                type: .taskComplete,
                branchId: branch.id,
                relatedTaskId: task.id
            )
        }
        
        try await taskPlanManager.updateTaskPlan(taskPlan)
        
        // Verify all tasks completed
        let allCompletedTasks = taskPlan.tasks.filter { $0.isCompleted }
        XCTAssertEqual(allCompletedTasks.count, taskPlan.tasks.count)
        
        print("✅ All tasks completed!")
        
        // STEP 7: 完成目标分支
        print("🏆 Step 7: Completing goal branch...")
        
        try await branchManager.completeBranch(branch)
        
        // Verify branch completion
        XCTAssertEqual(branch.status, .completed)
        XCTAssertNotNil(branch.completedAt)
        
        // Verify completion commit was created
        let allCommits = try await commitManager.getCommitHistory(for: branch.id)
        let completionCommits = allCommits.filter { $0.type == .milestone && $0.message.contains("完成目标") }
        XCTAssertEqual(completionCommits.count, 1)
        
        print("✅ Goal branch completed successfully")
        
        // STEP 8: 合并目标到主干
        print("🔀 Step 8: Merging goal to master branch...")
        
        try await branchManager.mergeBranch(branch)
        
        // Verify merge
        XCTAssertNotNil(branch.mergedAt)
        
        // Verify merge commit in master branch
        let masterBranch = try await branchManager.getMasterBranch(for: testUser.id)
        let masterCommits = try await commitManager.getCommitHistory(for: masterBranch.id)
        let mergeCommits = masterCommits.filter { $0.message.contains("合并目标") }
        XCTAssertEqual(mergeCommits.count, 1)
        
        print("✅ Goal successfully merged to master branch")
        
        // STEP 9: 验证最终状态
        print("📊 Step 9: Verifying final state...")
        
        // Verify branch statistics
        let statistics = try await branchManager.getBranchStatistics(branch)
        XCTAssertGreaterThan(statistics.commitCount, 7) // Original 7 + task completion commits
        XCTAssertEqual(statistics.completedTasks, statistics.totalTasks)
        XCTAssertEqual(statistics.progress, 1.0, accuracy: 0.01)
        
        // Verify app state
        XCTAssertEqual(appStateManager.currentBranch?.id, branch.id)
        
        // Verify user's overall progress
        let userBranches = try await branchManager.getAllBranches(for: testUser.id)
        let completedBranches = userBranches.filter { $0.status == .completed }
        XCTAssertEqual(completedBranches.count, 1)
        
        print("✅ End-to-end test completed successfully!")
        print("📈 Final Statistics:")
        print("   - Total commits: \(statistics.commitCount)")
        print("   - Tasks completed: \(statistics.completedTasks)/\(statistics.totalTasks)")
        print("   - Progress: \(Int(statistics.progress * 100))%")
        print("   - Branch status: \(branch.status)")
    }
    
    // MARK: - Error Scenario Tests
    
    /// Test user journey when AI service fails
    func testUserJourneyWithAIFailure() async throws {
        // Configure AI service for failure
        mockTaskPlanService.configureForFailure()
        mockAIErrorHandler.shouldRetry = false // Don't retry, fallback immediately
        
        print("🚨 Testing user journey with AI failure...")
        
        // STEP 1: User creates goal but AI fails
        let branch = try await branchManager.createBranch(
            name: "AI失败测试目标",
            description: "测试AI服务失败时的用户体验",
            userId: testUser.id
        )
        
        // Verify fallback behavior
        XCTAssertNotNil(branch.taskPlan)
        XCTAssertFalse(branch.taskPlan?.isAIGenerated ?? true) // Should be manual
        XCTAssertEqual(branch.taskPlan?.totalDuration, "手动创建")
        
        // User should still be able to add tasks manually
        guard let taskPlan = branch.taskPlan else {
            XCTFail("Task plan should exist even with AI failure")
            return
        }
        
        let manualTask = TaskItem(
            title: "手动添加的任务",
            description: "用户在AI失败后手动添加的任务",
            estimatedDuration: 120,
            timeScope: .daily,
            isAIGenerated: false,
            orderIndex: 0
        )
        
        taskPlan.tasks.append(manualTask)
        try await taskPlanManager.updateTaskPlan(taskPlan)
        
        // User can still complete the workflow
        manualTask.markAsCompleted()
        try await taskPlanManager.updateTaskPlan(taskPlan)
        
        _ = try await commitManager.createCommit(
            message: "即使AI失败，我也能完成任务",
            type: .taskComplete,
            branchId: branch.id,
            relatedTaskId: manualTask.id
        )
        
        try await branchManager.completeBranch(branch)
        
        // Verify successful completion despite AI failure
        XCTAssertEqual(branch.status, .completed)
        XCTAssertEqual(taskPlan.tasks.filter { $0.isCompleted }.count, 1)
        
        print("✅ User journey completed successfully despite AI failure")
    }
    
    /// Test user journey with network interruptions
    func testUserJourneyWithNetworkInterruptions() async throws {
        print("📶 Testing user journey with network interruptions...")
        
        // Start with working AI
        mockTaskPlanService.configureForSuccess()
        
        let branch = try await branchManager.createBranch(
            name: "网络中断测试",
            description: "测试网络中断时的用户体验",
            userId: testUser.id
        )
        
        // Verify initial creation works
        XCTAssertNotNil(branch.taskPlan)
        XCTAssertTrue(branch.taskPlan?.isAIGenerated ?? false)
        
        // Simulate network interruption during task plan regeneration
        mockTaskPlanService.configureForFailure()
        
        // User tries to regenerate task plan but fails due to network
        do {
            try await branchManager.regenerateTaskPlan(for: branch)
            XCTFail("Should have failed due to network interruption")
        } catch {
            // Expected failure
            XCTAssertNotNil(error)
        }
        
        // Verify original task plan is preserved
        XCTAssertNotNil(branch.taskPlan)
        XCTAssertTrue(branch.taskPlan?.isAIGenerated ?? false)
        
        // User can still work offline
        _ = try await commitManager.createCommit(
            message: "离线工作中",
            type: .learning,
            branchId: branch.id
        )
        
        // Network comes back
        mockTaskPlanService.configureForSuccess()
        
        // User can now regenerate task plan
        try await branchManager.regenerateTaskPlan(for: branch)
        
        // Verify regeneration worked
        XCTAssertNotNil(branch.taskPlan)
        XCTAssertTrue(branch.taskPlan?.isAIGenerated ?? false)
        
        print("✅ User journey handled network interruptions gracefully")
    }
    
    // MARK: - Edge Case Tests
    
    /// Test user journey with large number of tasks
    func testUserJourneyWithManyTasks() async throws {
        print("📚 Testing user journey with many tasks...")
        
        // Configure AI to generate many tasks
        mockTaskPlanService.configureForManyTasks()
        
        let branch = try await branchManager.createBranch(
            name: "复杂目标",
            description: "包含大量任务的复杂目标",
            userId: testUser.id
        )
        
        guard let taskPlan = branch.taskPlan else {
            XCTFail("Task plan should exist")
            return
        }
        
        // Verify many tasks were created
        XCTAssertGreaterThan(taskPlan.tasks.count, 10)
        
        // User completes tasks in batches
        let batchSize = 3
        let totalBatches = (taskPlan.tasks.count + batchSize - 1) / batchSize
        
        for batchIndex in 0..<totalBatches {
            let startIndex = batchIndex * batchSize
            let endIndex = min(startIndex + batchSize, taskPlan.tasks.count)
            let batch = Array(taskPlan.tasks[startIndex..<endIndex])
            
            // Complete batch of tasks
            for task in batch {
                task.markAsCompleted()
                
                _ = try await commitManager.createCommit(
                    message: "完成任务批次 \(batchIndex + 1): \(task.title)",
                    type: .taskComplete,
                    branchId: branch.id,
                    relatedTaskId: task.id
                )
            }
            
            try await taskPlanManager.updateTaskPlan(taskPlan)
            
            // Verify progress
            let completedCount = taskPlan.tasks.filter { $0.isCompleted }.count
            let expectedCompleted = min((batchIndex + 1) * batchSize, taskPlan.tasks.count)
            XCTAssertEqual(completedCount, expectedCompleted)
        }
        
        // Complete the goal
        try await branchManager.completeBranch(branch)
        
        // Verify all tasks completed
        let statistics = try await branchManager.getBranchStatistics(branch)
        XCTAssertEqual(statistics.completedTasks, statistics.totalTasks)
        XCTAssertEqual(statistics.progress, 1.0, accuracy: 0.01)
        
        print("✅ Successfully completed goal with \(taskPlan.tasks.count) tasks")
    }
    
    /// Test concurrent user operations
    func testConcurrentUserOperations() async throws {
        print("⚡ Testing concurrent user operations...")
        
        mockTaskPlanService.configureForSuccess()
        
        // Create multiple branches concurrently
        let branchNames = ["并发目标1", "并发目标2", "并发目标3"]
        
        let branches = try await withThrowingTaskGroup(of: Branch.self) { group in
            for name in branchNames {
                group.addTask {
                    return try await self.branchManager.createBranch(
                        name: name,
                        description: "并发创建的目标",
                        userId: self.testUser.id
                    )
                }
            }
            
            var results: [Branch] = []
            for try await branch in group {
                results.append(branch)
            }
            return results
        }
        
        XCTAssertEqual(branches.count, 3)
        
        // Create commits concurrently for all branches
        try await withThrowingTaskGroup(of: Void.self) { group in
            for branch in branches {
                group.addTask {
                    for i in 0..<5 {
                        _ = try await self.commitManager.createCommit(
                            message: "并发提交 \(i)",
                            type: .learning,
                            branchId: branch.id
                        )
                    }
                }
            }
            
            for try await _ in group {
                // Wait for all commits to complete
            }
        }
        
        // Verify all operations completed successfully
        for branch in branches {
            let commits = try await commitManager.getCommitHistory(for: branch.id)
            XCTAssertEqual(commits.count, 5)
        }
        
        print("✅ Concurrent operations completed successfully")
    }
    
    // MARK: - Performance Tests
    
    /// Test user journey performance
    func testUserJourneyPerformance() async throws {
        print("⏱️ Testing user journey performance...")
        
        mockTaskPlanService.configureForSuccess()
        
        // Measure complete user journey performance
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Create goal
        let branch = try await branchManager.createBranch(
            name: "性能测试目标",
            description: "测试完整用户流程的性能",
            userId: testUser.id
        )
        
        let creationTime = CFAbsoluteTimeGetCurrent()
        
        // Add commits
        for i in 0..<10 {
            _ = try await commitManager.createCommit(
                message: "性能测试提交 \(i)",
                type: .taskComplete,
                branchId: branch.id
            )
        }
        
        let commitsTime = CFAbsoluteTimeGetCurrent()
        
        // Complete tasks
        if let taskPlan = branch.taskPlan {
            for task in taskPlan.tasks {
                task.markAsCompleted()
            }
            try await taskPlanManager.updateTaskPlan(taskPlan)
        }
        
        let tasksTime = CFAbsoluteTimeGetCurrent()
        
        // Complete branch
        try await branchManager.completeBranch(branch)
        
        let completionTime = CFAbsoluteTimeGetCurrent()
        
        // Verify performance requirements
        let totalTime = completionTime - startTime
        let branchCreationTime = creationTime - startTime
        let commitCreationTime = commitsTime - creationTime
        let taskCompletionTime = tasksTime - commitsTime
        let branchCompletionTime = completionTime - tasksTime
        
        print("📊 Performance Results:")
        print("   - Total time: \(String(format: "%.3f", totalTime))s")
        print("   - Branch creation: \(String(format: "%.3f", branchCreationTime))s")
        print("   - 10 commits: \(String(format: "%.3f", commitCreationTime))s")
        print("   - Task completion: \(String(format: "%.3f", taskCompletionTime))s")
        print("   - Branch completion: \(String(format: "%.3f", branchCompletionTime))s")
        
        // Performance assertions based on requirements
        XCTAssertLessThan(branchCreationTime, 10.0, "Branch creation should be < 10s (AI response time)")
        XCTAssertLessThan(commitCreationTime / 10, 1.0, "Each commit should be < 1s")
        XCTAssertLessThan(taskCompletionTime, 2.0, "Task completion should be < 2s")
        XCTAssertLessThan(branchCompletionTime, 2.0, "Branch completion should be < 2s")
        
        print("✅ Performance requirements met")
    }
    
    // MARK: - Data Integrity Tests
    
    /// Test data consistency throughout user journey
    func testDataIntegrityThroughoutJourney() async throws {
        print("🔒 Testing data integrity throughout user journey...")
        
        mockTaskPlanService.configureForSuccess()
        
        // Create branch and capture initial state
        let branch = try await branchManager.createBranch(
            name: "数据完整性测试",
            description: "测试整个流程中的数据一致性",
            userId: testUser.id
        )
        
        let initialTaskCount = branch.taskPlan?.tasks.count ?? 0
        let initialBranchId = branch.id
        
        // Perform various operations and verify data integrity
        
        // 1. Add commits and verify relationships
        var commitIds: [UUID] = []
        for i in 0..<5 {
            let commit = try await commitManager.createCommit(
                message: "数据完整性测试提交 \(i)",
                type: .learning,
                branchId: branch.id
            )
            commitIds.append(commit.id)
            
            // Verify commit-branch relationship
            XCTAssertEqual(commit.branchId, branch.id)
        }
        
        // 2. Modify task plan and verify consistency
        guard let taskPlan = branch.taskPlan else {
            XCTFail("Task plan should exist")
            return
        }
        
        let originalTaskPlanId = taskPlan.id
        
        // Add custom task
        let customTask = TaskItem(
            title: "数据完整性测试任务",
            description: "验证任务数据完整性",
            estimatedDuration: 60,
            timeScope: .daily,
            isAIGenerated: false,
            orderIndex: initialTaskCount
        )
        
        taskPlan.tasks.append(customTask)
        try await taskPlanManager.updateTaskPlan(taskPlan)
        
        // Verify task plan integrity
        XCTAssertEqual(taskPlan.id, originalTaskPlanId) // ID should not change
        XCTAssertEqual(taskPlan.branchId, branch.id) // Relationship preserved
        XCTAssertEqual(taskPlan.tasks.count, initialTaskCount + 1) // Task added
        
        // 3. Complete tasks and verify state consistency
        let tasksToComplete = Array(taskPlan.tasks.prefix(2))
        for task in tasksToComplete {
            task.markAsCompleted()
        }
        
        try await taskPlanManager.updateTaskPlan(taskPlan)
        
        // Verify task completion state
        let completedTasks = taskPlan.tasks.filter { $0.isCompleted }
        XCTAssertEqual(completedTasks.count, 2)
        
        // 4. Complete branch and verify final state
        try await branchManager.completeBranch(branch)
        
        // Verify branch state integrity
        XCTAssertEqual(branch.id, initialBranchId) // ID preserved
        XCTAssertEqual(branch.status, .completed) // Status updated
        XCTAssertNotNil(branch.completedAt) // Completion time set
        
        // 5. Verify all relationships are intact
        let allCommits = try await commitManager.getCommitHistory(for: branch.id)
        XCTAssertGreaterThan(allCommits.count, 5) // Original 5 + completion commit
        
        // All commits should belong to this branch
        for commit in allCommits {
            XCTAssertEqual(commit.branchId, branch.id)
        }
        
        // Task plan should still be associated
        XCTAssertEqual(taskPlan.branchId, branch.id)
        
        // 6. Merge and verify master branch integrity
        try await branchManager.mergeBranch(branch)
        
        let masterBranch = try await branchManager.getMasterBranch(for: testUser.id)
        let masterCommits = try await commitManager.getCommitHistory(for: masterBranch.id)
        
        // Verify merge commit exists
        let mergeCommits = masterCommits.filter { $0.message.contains("合并目标") }
        XCTAssertEqual(mergeCommits.count, 1)
        XCTAssertEqual(mergeCommits.first?.branchId, masterBranch.id)
        
        print("✅ Data integrity maintained throughout entire user journey")
    }
}

// MARK: - Mock Service Extensions for E2E Testing

extension MockTaskPlanService {
    func configureForManyTasks() {
        shouldSucceed = true
        mockTaskPlan = TaskPlan(
            branchId: UUID(),
            tasks: (0..<15).map { index in
                TaskItem(
                    title: "大量任务测试 \(index + 1)",
                    description: "这是第 \(index + 1) 个任务的详细描述",
                    estimatedDuration: 30 + (index * 10),
                    timeScope: TaskTimeScope.allCases[index % 3],
                    isAIGenerated: true,
                    orderIndex: index
                )
            },
            totalDuration: "8周",
            isAIGenerated: true
        )
    }
}