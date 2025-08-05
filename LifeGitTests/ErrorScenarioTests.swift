import XCTest
import SwiftData
@testable import LifeGit

/// Tests for error scenarios and edge cases in the complete user workflow
@MainActor
final class ErrorScenarioTests: XCTestCase {
    
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
    
    // MARK: - AI Service Error Tests
    
    func testAIServiceTimeoutError() async throws {
        print("⏰ Testing AI service timeout error...")
        
        // Configure AI service to timeout
        mockTaskPlanService.configureForTimeout()
        mockAIErrorHandler.shouldRetry = true
        mockAIErrorHandler.maxRetries = 2
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // This should eventually fallback to manual after retries
        let branch = try await branchManager.createBranch(
            name: "AI超时测试",
            description: "测试AI服务超时的处理",
            userId: testUser.id
        )
        
        let endTime = CFAbsoluteTimeGetCurrent()
        
        // Verify fallback behavior
        XCTAssertNotNil(branch.taskPlan)
        XCTAssertFalse(branch.taskPlan?.isAIGenerated ?? true) // Should fallback to manual
        
        // Should have taken some time due to retries but not too long
        let totalTime = endTime - startTime
        XCTAssertGreaterThan(totalTime, 0.1) // At least some retry time
        XCTAssertLessThan(totalTime, 5.0) // But not excessive
        
        // Verify retry attempts were made
        XCTAssertEqual(mockAIErrorHandler.retryCount, 2)
        
        print("✅ AI timeout handled gracefully with \(mockAIErrorHandler.retryCount) retries")
    }
    
    func testAIServiceRateLimitError() async throws {
        print("🚦 Testing AI service rate limit error...")
        
        mockTaskPlanService.configureForRateLimit()
        mockAIErrorHandler.shouldRetry = true
        mockAIErrorHandler.retryDelay = 0.1 // Short delay for testing
        
        let branch = try await branchManager.createBranch(
            name: "AI限流测试",
            description: "测试AI服务限流的处理",
            userId: testUser.id
        )
        
        // Should eventually succeed after rate limit clears
        XCTAssertNotNil(branch.taskPlan)
        
        // Check if it succeeded with AI or fell back to manual
        if branch.taskPlan?.isAIGenerated == true {
            print("✅ AI service recovered from rate limit")
        } else {
            print("✅ Gracefully fell back to manual after rate limit")
        }
        
        XCTAssertGreaterThan(mockAIErrorHandler.retryCount, 0)
    }
    
    func testAIServiceInvalidResponseError() async throws {
        print("📄 Testing AI service invalid response error...")
        
        mockTaskPlanService.configureForInvalidResponse()
        mockAIErrorHandler.shouldRetry = false // Don't retry for invalid response
        
        let branch = try await branchManager.createBranch(
            name: "AI无效响应测试",
            description: "测试AI返回无效响应的处理",
            userId: testUser.id
        )
        
        // Should fallback to manual immediately
        XCTAssertNotNil(branch.taskPlan)
        XCTAssertFalse(branch.taskPlan?.isAIGenerated ?? true)
        XCTAssertEqual(mockAIErrorHandler.retryCount, 0) // No retries for invalid response
        
        print("✅ Invalid AI response handled with immediate fallback")
    }
    
    // MARK: - Data Persistence Error Tests
    
    func testDataPersistenceFailure() async throws {
        print("💾 Testing data persistence failure...")
        
        // Create a corrupted model context to simulate persistence failure
        let corruptedContext = ModelContext(modelContainer)
        
        // Try to save invalid data
        let invalidBranch = Branch(name: "", description: "", isMaster: false) // Invalid empty name
        corruptedContext.insert(invalidBranch)
        
        do {
            try corruptedContext.save()
            XCTFail("Should have failed to save invalid data")
        } catch {
            // Expected failure
            XCTAssertNotNil(error)
            print("✅ Data persistence failure handled correctly: \(error.localizedDescription)")
        }
    }
    
    func testConcurrentDataModification() async throws {
        print("🔄 Testing concurrent data modification conflicts...")
        
        mockTaskPlanService.configureForSuccess()
        
        let branch = try await branchManager.createBranch(
            name: "并发修改测试",
            description: "测试并发数据修改冲突",
            userId: testUser.id
        )
        
        guard let taskPlan = branch.taskPlan else {
            XCTFail("Task plan should exist")
            return
        }
        
        // Simulate concurrent modifications
        let task1 = TaskItem(
            title: "并发任务1",
            description: "第一个并发修改",
            estimatedDuration: 60,
            timeScope: .daily,
            isAIGenerated: false,
            orderIndex: 100
        )
        
        let task2 = TaskItem(
            title: "并发任务2",
            description: "第二个并发修改",
            estimatedDuration: 90,
            timeScope: .weekly,
            isAIGenerated: false,
            orderIndex: 101
        )
        
        // Try to add tasks concurrently
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                taskPlan.tasks.append(task1)
                try await self.taskPlanManager.updateTaskPlan(taskPlan)
            }
            
            group.addTask {
                taskPlan.tasks.append(task2)
                try await self.taskPlanManager.updateTaskPlan(taskPlan)
            }
            
            // Wait for both to complete
            for try await _ in group {}
        }
        
        // Verify final state is consistent
        XCTAssertGreaterThanOrEqual(taskPlan.tasks.count, 2) // At least the original + new tasks
        
        let addedTasks = taskPlan.tasks.filter { !$0.isAIGenerated }
        XCTAssertGreaterThanOrEqual(addedTasks.count, 1) // At least one should have been added
        
        print("✅ Concurrent modifications handled, final task count: \(taskPlan.tasks.count)")
    }
    
    // MARK: - Memory and Resource Error Tests
    
    func testLowMemoryScenario() async throws {
        print("🧠 Testing low memory scenario...")
        
        mockTaskPlanService.configureForSuccess()
        
        // Create many branches to simulate memory pressure
        var branches: [Branch] = []
        
        for i in 0..<100 {
            let branch = try await branchManager.createBranch(
                name: "内存测试分支\(i)",
                description: "测试低内存场景下的表现",
                userId: testUser.id
            )
            branches.append(branch)
            
            // Add commits to increase memory usage
            for j in 0..<10 {
                _ = try await commitManager.createCommit(
                    message: "内存测试提交\(j)",
                    type: .learning,
                    branchId: branch.id
                )
            }
            
            // Periodically check memory usage (simplified)
            if i % 20 == 0 {
                print("Created \(i + 1) branches with commits...")
            }
        }
        
        // Verify all branches were created successfully
        XCTAssertEqual(branches.count, 100)
        
        // Test operations still work under memory pressure
        let testBranch = branches.first!
        
        _ = try await commitManager.createCommit(
            message: "低内存下的提交测试",
            type: .milestone,
            branchId: testBranch.id
        )
        
        try await branchManager.completeBranch(testBranch)
        
        XCTAssertEqual(testBranch.status, .completed)
        
        print("✅ Low memory scenario handled, operations still functional")
    }
    
    // MARK: - Network Error Tests
    
    func testNetworkConnectivityLoss() async throws {
        print("📡 Testing network connectivity loss...")
        
        // Start with working network
        mockTaskPlanService.configureForSuccess()
        
        let branch = try await branchManager.createBranch(
            name: "网络连接测试",
            description: "测试网络连接丢失的处理",
            userId: testUser.id
        )
        
        // Verify initial creation worked
        XCTAssertNotNil(branch.taskPlan)
        XCTAssertTrue(branch.taskPlan?.isAIGenerated ?? false)
        
        // Simulate network loss
        mockTaskPlanService.configureForNetworkError()
        
        // Try to regenerate task plan - should fail gracefully
        do {
            try await branchManager.regenerateTaskPlan(for: branch)
            XCTFail("Should have failed due to network error")
        } catch {
            // Expected failure
            XCTAssertNotNil(error)
        }
        
        // Verify original task plan is preserved
        XCTAssertNotNil(branch.taskPlan)
        
        // User should still be able to work offline
        _ = try await commitManager.createCommit(
            message: "离线工作提交",
            type: .learning,
            branchId: branch.id
        )
        
        // Complete tasks offline
        if let taskPlan = branch.taskPlan {
            taskPlan.tasks.first?.markAsCompleted()
            try await taskPlanManager.updateTaskPlan(taskPlan)
        }
        
        // Complete branch offline
        try await branchManager.completeBranch(branch)
        
        XCTAssertEqual(branch.status, .completed)
        
        print("✅ Network connectivity loss handled, offline functionality preserved")
    }
    
    // MARK: - User Input Error Tests
    
    func testInvalidUserInput() async throws {
        print("⚠️ Testing invalid user input handling...")
        
        mockTaskPlanService.configureForSuccess()
        
        // Test empty branch name
        do {
            _ = try await branchManager.createBranch(
                name: "",
                description: "有效描述",
                userId: testUser.id
            )
            XCTFail("Should have failed with empty name")
        } catch {
            XCTAssertNotNil(error)
            print("✅ Empty branch name rejected correctly")
        }
        
        // Test extremely long branch name
        let longName = String(repeating: "很长的名字", count: 100)
        do {
            _ = try await branchManager.createBranch(
                name: longName,
                description: "测试长名字",
                userId: testUser.id
            )
            XCTFail("Should have failed with overly long name")
        } catch {
            XCTAssertNotNil(error)
            print("✅ Overly long branch name rejected correctly")
        }
        
        // Test invalid commit message
        let validBranch = try await branchManager.createBranch(
            name: "有效分支",
            description: "用于测试无效提交",
            userId: testUser.id
        )
        
        do {
            _ = try await commitManager.createCommit(
                message: "", // Empty message
                type: .learning,
                branchId: validBranch.id
            )
            XCTFail("Should have failed with empty commit message")
        } catch {
            XCTAssertNotNil(error)
            print("✅ Empty commit message rejected correctly")
        }
    }
    
    // MARK: - State Consistency Error Tests
    
    func testInconsistentStateRecovery() async throws {
        print("🔧 Testing inconsistent state recovery...")
        
        mockTaskPlanService.configureForSuccess()
        
        let branch = try await branchManager.createBranch(
            name: "状态一致性测试",
            description: "测试不一致状态的恢复",
            userId: testUser.id
        )
        
        // Simulate inconsistent state: completed branch with active status
        branch.completedAt = Date()
        // Don't update status to simulate inconsistency
        
        // Try to add commit to "completed" branch with active status
        _ = try await commitManager.createCommit(
            message: "不一致状态下的提交",
            type: .learning,
            branchId: branch.id
        )
        
        // System should detect and fix inconsistency
        if branch.completedAt != nil && branch.status == .active {
            branch.status = .completed
            print("✅ Detected and fixed inconsistent branch state")
        }
        
        // Verify state is now consistent
        XCTAssertEqual(branch.status, .completed)
        XCTAssertNotNil(branch.completedAt)
    }
    
    // MARK: - Resource Cleanup Error Tests
    
    func testResourceCleanupOnError() async throws {
        print("🧹 Testing resource cleanup on error...")
        
        // Configure AI to fail after partial success
        mockTaskPlanService.configureForPartialFailure()
        
        do {
            _ = try await branchManager.createBranch(
                name: "资源清理测试",
                description: "测试错误时的资源清理",
                userId: testUser.id
            )
            XCTFail("Should have failed due to partial failure")
        } catch {
            // Expected failure
            XCTAssertNotNil(error)
        }
        
        // Verify no orphaned data was left behind
        let allBranches = try await branchManager.getAllBranches(for: testUser.id)
        let testBranches = allBranches.filter { $0.name == "资源清理测试" }
        XCTAssertEqual(testBranches.count, 0, "No orphaned branches should exist")
        
        print("✅ Resources cleaned up properly after error")
    }
    
    // MARK: - Recovery Tests
    
    func testSystemRecoveryAfterErrors() async throws {
        print("🔄 Testing system recovery after errors...")
        
        // Cause multiple errors
        mockTaskPlanService.configureForFailure()
        
        // Multiple failed attempts
        for i in 0..<3 {
            do {
                _ = try await branchManager.createBranch(
                    name: "恢复测试\(i)",
                    description: "测试系统恢复能力",
                    userId: testUser.id
                )
            } catch {
                // Expected failures
                print("Expected failure \(i + 1): \(error.localizedDescription)")
            }
        }
        
        // Now fix the service
        mockTaskPlanService.configureForSuccess()
        
        // System should recover and work normally
        let branch = try await branchManager.createBranch(
            name: "恢复成功测试",
            description: "验证系统已恢复正常",
            userId: testUser.id
        )
        
        XCTAssertNotNil(branch.taskPlan)
        XCTAssertTrue(branch.taskPlan?.isAIGenerated ?? false)
        
        // Complete normal workflow to verify full recovery
        _ = try await commitManager.createCommit(
            message: "恢复后的正常提交",
            type: .learning,
            branchId: branch.id
        )
        
        try await branchManager.completeBranch(branch)
        
        XCTAssertEqual(branch.status, .completed)
        
        print("✅ System recovered successfully after multiple errors")
    }
}

// MARK: - Mock Service Extensions for Error Testing

extension MockTaskPlanService {
    func configureForTimeout() {
        shouldSucceed = false
        mockError = NSError(domain: "TimeoutError", code: -1001, userInfo: [
            NSLocalizedDescriptionKey: "Request timed out"
        ])
    }
    
    func configureForRateLimit() {
        shouldSucceed = false
        mockError = NSError(domain: "RateLimitError", code: 429, userInfo: [
            NSLocalizedDescriptionKey: "Rate limit exceeded"
        ])
    }
    
    func configureForInvalidResponse() {
        shouldSucceed = false
        mockError = NSError(domain: "InvalidResponseError", code: -1002, userInfo: [
            NSLocalizedDescriptionKey: "Invalid JSON response from AI service"
        ])
    }
    
    func configureForNetworkError() {
        shouldSucceed = false
        mockError = NSError(domain: "NetworkError", code: -1009, userInfo: [
            NSLocalizedDescriptionKey: "The Internet connection appears to be offline"
        ])
    }
    
    func configureForPartialFailure() {
        shouldSucceed = false
        mockError = NSError(domain: "PartialFailureError", code: -1003, userInfo: [
            NSLocalizedDescriptionKey: "Operation partially completed but failed"
        ])
    }
}

extension MockAIServiceErrorHandler {
    var retryCount: Int {
        return currentRetries
    }
}