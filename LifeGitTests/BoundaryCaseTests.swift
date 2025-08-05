import XCTest
import SwiftData
@testable import LifeGit

/// Tests for boundary cases and edge conditions in the user workflow
@MainActor
final class BoundaryCaseTests: XCTestCase {
    
    // MARK: - Test Properties
    private var modelContainer: ModelContainer!
    private var modelContext: ModelContext!
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
        
        // Create test user
        testUser = User()
        modelContext.insert(testUser)
        try modelContext.save()
    }
    
    override func tearDown() async throws {
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
    
    // MARK: - Data Size Boundary Tests
    
    func testMaximumBranchNameLength() async throws {
        print("📏 Testing maximum branch name length...")
        
        mockTaskPlanService.configureForSuccess()
        
        // Test with maximum allowed length (assuming 100 characters)
        let maxLengthName = String(repeating: "测", count: 100)
        
        let branch = try await branchManager.createBranch(
            name: maxLengthName,
            description: "测试最大长度分支名",
            userId: testUser.id
        )
        
        XCTAssertEqual(branch.name.count, 100)
        XCTAssertNotNil(branch.taskPlan)
        
        print("✅ Maximum branch name length handled: \(branch.name.count) characters")
    }
    
    func testMaximumDescriptionLength() async throws {
        print("📝 Testing maximum description length...")
        
        mockTaskPlanService.configureForSuccess()
        
        // Test with very long description (1000 characters)
        let longDescription = String(repeating: "这是一个非常详细的描述，包含了大量的信息和细节。", count: 40) // ~40 chars * 25 = 1000 chars
        
        let branch = try await branchManager.createBranch(
            name: "长描述测试",
            description: longDescription,
            userId: testUser.id
        )
        
        XCTAssertEqual(branch.description.count, longDescription.count)
        XCTAssertNotNil(branch.taskPlan)
        
        print("✅ Maximum description length handled: \(branch.description.count) characters")
    }
    
    func testMaximumTaskCount() async throws {
        print("📋 Testing maximum task count...")
        
        // Configure AI to generate maximum tasks
        mockTaskPlanService.configureForMaximumTasks()
        
        let branch = try await branchManager.createBranch(
            name: "最大任务数测试",
            description: "测试系统能处理的最大任务数量",
            userId: testUser.id
        )
        
        guard let taskPlan = branch.taskPlan else {
            XCTFail("Task plan should exist")
            return
        }
        
        // Verify large number of tasks
        XCTAssertGreaterThan(taskPlan.tasks.count, 50)
        XCTAssertLessThan(taskPlan.tasks.count, 200) // Reasonable upper limit
        
        // Verify all tasks are valid
        for task in taskPlan.tasks {
            XCTAssertFalse(task.title.isEmpty)
            XCTAssertFalse(task.description.isEmpty)
            XCTAssertGreaterThan(task.estimatedDuration, 0)
        }
        
        print("✅ Maximum task count handled: \(taskPlan.tasks.count) tasks")
    }
    
    func testMaximumCommitCount() async throws {
        print("💬 Testing maximum commit count...")
        
        mockTaskPlanService.configureForSuccess()
        
        let branch = try await branchManager.createBranch(
            name: "最大提交数测试",
            description: "测试分支能处理的最大提交数",
            userId: testUser.id
        )
        
        // Create large number of commits
        let maxCommits = 1000
        var commitIds: [UUID] = []
        
        for i in 0..<maxCommits {
            let commit = try await commitManager.createCommit(
                message: "大量提交测试 \(i + 1)",
                type: CommitType.allCases[i % CommitType.allCases.count],
                branchId: branch.id
            )
            commitIds.append(commit.id)
            
            // Progress indicator
            if (i + 1) % 100 == 0 {
                print("Created \(i + 1) commits...")
            }
        }
        
        // Verify all commits were created
        let allCommits = try await commitManager.getCommitHistory(for: branch.id)
        XCTAssertEqual(allCommits.count, maxCommits)
        
        // Verify commit retrieval performance
        let startTime = CFAbsoluteTimeGetCurrent()
        let retrievedCommits = try await commitManager.getCommitHistory(for: branch.id)
        let endTime = CFAbsoluteTimeGetCurrent()
        
        XCTAssertEqual(retrievedCommits.count, maxCommits)
        XCTAssertLessThan(endTime - startTime, 1.0, "Commit retrieval should be fast even with many commits")
        
        print("✅ Maximum commit count handled: \(allCommits.count) commits")
    }
    
    // MARK: - Time Boundary Tests
    
    func testVeryShortTaskDuration() async throws {
        print("⏱️ Testing very short task duration...")
        
        mockTaskPlanService.configureForSuccess()
        
        let branch = try await branchManager.createBranch(
            name: "短时任务测试",
            description: "测试极短时间任务的处理",
            userId: testUser.id
        )
        
        guard let taskPlan = branch.taskPlan else {
            XCTFail("Task plan should exist")
            return
        }
        
        // Add task with minimum duration (1 minute)
        let shortTask = TaskItem(
            title: "1分钟任务",
            description: "测试最短时间任务",
            estimatedDuration: 1,
            timeScope: .daily,
            isAIGenerated: false,
            orderIndex: taskPlan.tasks.count
        )
        
        taskPlan.tasks.append(shortTask)
        try await taskPlanManager.updateTaskPlan(taskPlan)
        
        // Complete the short task
        shortTask.markAsCompleted()
        try await taskPlanManager.updateTaskPlan(taskPlan)
        
        XCTAssertTrue(shortTask.isCompleted)
        XCTAssertEqual(shortTask.estimatedDuration, 1)
        
        print("✅ Very short task duration handled: \(shortTask.estimatedDuration) minute")
    }
    
    func testVeryLongTaskDuration() async throws {
        print("⏰ Testing very long task duration...")
        
        mockTaskPlanService.configureForSuccess()
        
        let branch = try await branchManager.createBranch(
            name: "长时任务测试",
            description: "测试极长时间任务的处理",
            userId: testUser.id
        )
        
        guard let taskPlan = branch.taskPlan else {
            XCTFail("Task plan should exist")
            return
        }
        
        // Add task with very long duration (24 hours = 1440 minutes)
        let longTask = TaskItem(
            title: "24小时任务",
            description: "测试最长时间任务",
            estimatedDuration: 1440,
            timeScope: .monthly,
            isAIGenerated: false,
            orderIndex: taskPlan.tasks.count
        )
        
        taskPlan.tasks.append(longTask)
        try await taskPlanManager.updateTaskPlan(taskPlan)
        
        // Verify task was added correctly
        XCTAssertEqual(longTask.estimatedDuration, 1440)
        XCTAssertEqual(longTask.timeScope, .monthly)
        
        print("✅ Very long task duration handled: \(longTask.estimatedDuration) minutes (24 hours)")
    }
    
    func testRapidCommitCreation() async throws {
        print("⚡ Testing rapid commit creation...")
        
        mockTaskPlanService.configureForSuccess()
        
        let branch = try await branchManager.createBranch(
            name: "快速提交测试",
            description: "测试快速连续创建提交",
            userId: testUser.id
        )
        
        let commitCount = 100
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Create commits as fast as possible
        var commitIds: [UUID] = []
        for i in 0..<commitCount {
            let commit = try await commitManager.createCommit(
                message: "快速提交 \(i + 1)",
                type: .learning,
                branchId: branch.id
            )
            commitIds.append(commit.id)
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let totalTime = endTime - startTime
        let averageTime = totalTime / Double(commitCount)
        
        // Verify all commits were created
        XCTAssertEqual(commitIds.count, commitCount)
        
        // Verify performance requirement (< 1 second per commit)
        XCTAssertLessThan(averageTime, 1.0, "Average commit creation time should be < 1 second")
        
        print("✅ Rapid commit creation handled: \(commitCount) commits in \(String(format: "%.3f", totalTime))s")
        print("   Average time per commit: \(String(format: "%.3f", averageTime))s")
    }
    
    // MARK: - Unicode and Special Character Tests
    
    func testUnicodeCharacterHandling() async throws {
        print("🌍 Testing Unicode character handling...")
        
        mockTaskPlanService.configureForSuccess()
        
        // Test with various Unicode characters
        let unicodeName = "🎯学习Swift开发📱💻🚀"
        let unicodeDescription = "包含各种Unicode字符的描述：中文、English、日本語、한국어、العربية、🎉🎊✨"
        
        let branch = try await branchManager.createBranch(
            name: unicodeName,
            description: unicodeDescription,
            userId: testUser.id
        )
        
        XCTAssertEqual(branch.name, unicodeName)
        XCTAssertEqual(branch.description, unicodeDescription)
        
        // Test Unicode in commits
        let unicodeCommit = try await commitManager.createCommit(
            message: "完成了🎯目标的第一步✅，感觉很棒👍！",
            type: .milestone,
            branchId: branch.id
        )
        
        XCTAssertTrue(unicodeCommit.message.contains("🎯"))
        XCTAssertTrue(unicodeCommit.message.contains("✅"))
        XCTAssertTrue(unicodeCommit.message.contains("👍"))
        
        print("✅ Unicode characters handled correctly in names, descriptions, and commits")
    }
    
    func testSpecialCharacterHandling() async throws {
        print("🔤 Testing special character handling...")
        
        mockTaskPlanService.configureForSuccess()
        
        // Test with special characters that might cause issues
        let specialName = "Test@#$%^&*()_+-=[]{}|;':\",./<>?"
        let specialDescription = "Description with special chars: \n\t\r\\\"'`~!@#$%^&*()"
        
        let branch = try await branchManager.createBranch(
            name: specialName,
            description: specialDescription,
            userId: testUser.id
        )
        
        XCTAssertEqual(branch.name, specialName)
        XCTAssertEqual(branch.description, specialDescription)
        
        print("✅ Special characters handled correctly")
    }
    
    // MARK: - Concurrent Operation Boundary Tests
    
    func testMaximumConcurrentBranchCreation() async throws {
        print("🔀 Testing maximum concurrent branch creation...")
        
        mockTaskPlanService.configureForSuccess()
        
        let concurrentCount = 50
        let branchNames = (0..<concurrentCount).map { "并发分支\($0)" }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Create branches concurrently
        let branches = try await withThrowingTaskGroup(of: Branch.self) { group in
            for name in branchNames {
                group.addTask {
                    return try await self.branchManager.createBranch(
                        name: name,
                        description: "并发创建测试",
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
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let totalTime = endTime - startTime
        
        // Verify all branches were created
        XCTAssertEqual(branches.count, concurrentCount)
        
        // Verify each branch has a task plan
        for branch in branches {
            XCTAssertNotNil(branch.taskPlan)
        }
        
        // Verify reasonable performance
        XCTAssertLessThan(totalTime, 30.0, "Concurrent branch creation should complete within 30 seconds")
        
        print("✅ Maximum concurrent branch creation handled: \(branches.count) branches in \(String(format: "%.3f", totalTime))s")
    }
    
    func testMaximumConcurrentCommitCreation() async throws {
        print("💬 Testing maximum concurrent commit creation...")
        
        mockTaskPlanService.configureForSuccess()
        
        let branch = try await branchManager.createBranch(
            name: "并发提交测试",
            description: "测试最大并发提交创建",
            userId: testUser.id
        )
        
        let concurrentCommits = 100
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Create commits concurrently
        let commits = try await withThrowingTaskGroup(of: Commit.self) { group in
            for i in 0..<concurrentCommits {
                group.addTask {
                    return try await self.commitManager.createCommit(
                        message: "并发提交\(i)",
                        type: CommitType.allCases[i % CommitType.allCases.count],
                        branchId: branch.id
                    )
                }
            }
            
            var results: [Commit] = []
            for try await commit in group {
                results.append(commit)
            }
            return results
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let totalTime = endTime - startTime
        
        // Verify all commits were created
        XCTAssertEqual(commits.count, concurrentCommits)
        
        // Verify all commits belong to the branch
        for commit in commits {
            XCTAssertEqual(commit.branchId, branch.id)
        }
        
        print("✅ Maximum concurrent commit creation handled: \(commits.count) commits in \(String(format: "%.3f", totalTime))s")
    }
    
    // MARK: - Memory Usage Boundary Tests
    
    func testLargeDataSetHandling() async throws {
        print("💾 Testing large data set handling...")
        
        mockTaskPlanService.configureForSuccess()
        
        // Create a branch with large amounts of data
        let branch = try await branchManager.createBranch(
            name: "大数据集测试",
            description: "测试系统处理大量数据的能力",
            userId: testUser.id
        )
        
        guard let taskPlan = branch.taskPlan else {
            XCTFail("Task plan should exist")
            return
        }
        
        // Add many tasks with long descriptions
        let taskCount = 200
        for i in 0..<taskCount {
            let longDescription = String(repeating: "这是一个包含大量文本的任务描述，用于测试系统处理大量数据的能力。", count: 10)
            
            let task = TaskItem(
                title: "大数据任务\(i + 1)",
                description: longDescription,
                estimatedDuration: 60 + i,
                timeScope: TaskTimeScope.allCases[i % TaskTimeScope.allCases.count],
                isAIGenerated: false,
                orderIndex: taskPlan.tasks.count + i
            )
            
            taskPlan.tasks.append(task)
        }
        
        // Update task plan with large data set
        let updateStartTime = CFAbsoluteTimeGetCurrent()
        try await taskPlanManager.updateTaskPlan(taskPlan)
        let updateEndTime = CFAbsoluteTimeGetCurrent()
        
        // Verify update performance
        let updateTime = updateEndTime - updateStartTime
        XCTAssertLessThan(updateTime, 5.0, "Large data set update should complete within 5 seconds")
        
        // Verify data integrity
        XCTAssertEqual(taskPlan.tasks.count, taskCount + 1) // +1 for original AI task
        
        // Test retrieval performance
        let retrievalStartTime = CFAbsoluteTimeGetCurrent()
        let retrievedTaskPlan = try await taskPlanManager.getTaskPlan(for: branch.id)
        let retrievalEndTime = CFAbsoluteTimeGetCurrent()
        
        let retrievalTime = retrievalEndTime - retrievalStartTime
        XCTAssertLessThan(retrievalTime, 2.0, "Large data set retrieval should complete within 2 seconds")
        
        XCTAssertNotNil(retrievedTaskPlan)
        XCTAssertEqual(retrievedTaskPlan?.tasks.count, taskCount + 1)
        
        print("✅ Large data set handled: \(taskPlan.tasks.count) tasks")
        print("   Update time: \(String(format: "%.3f", updateTime))s")
        print("   Retrieval time: \(String(format: "%.3f", retrievalTime))s")
    }
    
    // MARK: - Edge Case Workflow Tests
    
    func testEmptyTaskPlanWorkflow() async throws {
        print("📋 Testing empty task plan workflow...")
        
        // Configure AI to return empty task plan
        mockTaskPlanService.configureForEmptyTaskPlan()
        
        let branch = try await branchManager.createBranch(
            name: "空任务计划测试",
            description: "测试空任务计划的处理",
            userId: testUser.id
        )
        
        guard let taskPlan = branch.taskPlan else {
            XCTFail("Task plan should exist even if empty")
            return
        }
        
        // Verify empty task plan
        XCTAssertTrue(taskPlan.tasks.isEmpty)
        
        // User should still be able to add manual tasks
        let manualTask = TaskItem(
            title: "手动添加的任务",
            description: "在空任务计划中手动添加",
            estimatedDuration: 120,
            timeScope: .daily,
            isAIGenerated: false,
            orderIndex: 0
        )
        
        taskPlan.tasks.append(manualTask)
        try await taskPlanManager.updateTaskPlan(taskPlan)
        
        // Complete the manual task
        manualTask.markAsCompleted()
        try await taskPlanManager.updateTaskPlan(taskPlan)
        
        // Complete the branch
        try await branchManager.completeBranch(branch)
        
        XCTAssertEqual(branch.status, .completed)
        XCTAssertEqual(taskPlan.tasks.count, 1)
        XCTAssertTrue(taskPlan.tasks.first?.isCompleted ?? false)
        
        print("✅ Empty task plan workflow completed successfully")
    }
    
    func testSingleTaskWorkflow() async throws {
        print("1️⃣ Testing single task workflow...")
        
        // Configure AI to return single task
        mockTaskPlanService.configureForSingleTask()
        
        let branch = try await branchManager.createBranch(
            name: "单任务测试",
            description: "测试只有一个任务的工作流",
            userId: testUser.id
        )
        
        guard let taskPlan = branch.taskPlan else {
            XCTFail("Task plan should exist")
            return
        }
        
        // Verify single task
        XCTAssertEqual(taskPlan.tasks.count, 1)
        
        let singleTask = taskPlan.tasks.first!
        XCTAssertFalse(singleTask.title.isEmpty)
        
        // Complete the single task
        singleTask.markAsCompleted()
        try await taskPlanManager.updateTaskPlan(taskPlan)
        
        // Create completion commit
        _ = try await commitManager.createCommit(
            message: "完成唯一任务",
            type: .taskComplete,
            branchId: branch.id,
            relatedTaskId: singleTask.id
        )
        
        // Complete the branch
        try await branchManager.completeBranch(branch)
        
        // Verify completion
        XCTAssertEqual(branch.status, .completed)
        
        let statistics = try await branchManager.getBranchStatistics(branch)
        XCTAssertEqual(statistics.totalTasks, 1)
        XCTAssertEqual(statistics.completedTasks, 1)
        XCTAssertEqual(statistics.progress, 1.0, accuracy: 0.01)
        
        print("✅ Single task workflow completed successfully")
    }
}

// MARK: - Mock Service Extensions for Boundary Testing

extension MockTaskPlanService {
    func configureForMaximumTasks() {
        shouldSucceed = true
        mockTaskPlan = TaskPlan(
            branchId: UUID(),
            tasks: (0..<100).map { index in
                TaskItem(
                    title: "边界测试任务 \(index + 1)",
                    description: "这是第 \(index + 1) 个任务，用于测试系统处理大量任务的能力。包含详细的描述信息以增加数据量。",
                    estimatedDuration: 30 + (index % 120), // 30-150 minutes
                    timeScope: TaskTimeScope.allCases[index % 3],
                    isAIGenerated: true,
                    orderIndex: index
                )
            },
            totalDuration: "20周",
            isAIGenerated: true
        )
    }
    
    func configureForEmptyTaskPlan() {
        shouldSucceed = true
        mockTaskPlan = TaskPlan(
            branchId: UUID(),
            tasks: [],
            totalDuration: "未知",
            isAIGenerated: true
        )
    }
    
    func configureForSingleTask() {
        shouldSucceed = true
        mockTaskPlan = TaskPlan(
            branchId: UUID(),
            tasks: [
                TaskItem(
                    title: "唯一任务",
                    description: "这是唯一的一个任务",
                    estimatedDuration: 60,
                    timeScope: .daily,
                    isAIGenerated: true,
                    orderIndex: 0
                )
            ],
            totalDuration: "1天",
            isAIGenerated: true
        )
    }
}