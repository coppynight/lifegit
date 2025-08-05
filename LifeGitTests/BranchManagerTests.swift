import XCTest
@testable import LifeGit

/// Unit tests for BranchManager
@MainActor
final class BranchManagerTests: XCTestCase {
    
    // MARK: - Test Properties
    private var branchManager: BranchManager!
    private var mockBranchRepository: MockBranchRepository!
    private var mockTaskPlanRepository: MockTaskPlanRepository!
    private var mockCommitRepository: MockCommitRepository!
    private var mockTaskPlanService: MockTaskPlanService!
    private var mockAIErrorHandler: MockAIServiceErrorHandler!
    
    // MARK: - Setup & Teardown
    override func setUp() async throws {
        try await super.setUp()
        
        mockBranchRepository = MockBranchRepository()
        mockTaskPlanRepository = MockTaskPlanRepository()
        mockCommitRepository = MockCommitRepository()
        mockTaskPlanService = MockTaskPlanService()
        mockAIErrorHandler = MockAIServiceErrorHandler()
        
        branchManager = BranchManager(
            branchRepository: mockBranchRepository,
            taskPlanRepository: mockTaskPlanRepository,
            commitRepository: mockCommitRepository,
            taskPlanService: mockTaskPlanService,
            aiErrorHandler: mockAIErrorHandler
        )
    }
    
    override func tearDown() async throws {
        branchManager = nil
        mockBranchRepository = nil
        mockTaskPlanRepository = nil
        mockCommitRepository = nil
        mockTaskPlanService = nil
        mockAIErrorHandler = nil
        try await super.tearDown()
    }
    
    // MARK: - Branch Creation Tests
    func testCreateBranchSuccess() async throws {
        // Arrange
        let userId = UUID()
        let branchName = "学习Swift编程"
        let branchDescription = "掌握Swift编程语言的基础和高级特性"
        
        mockTaskPlanService.configureForSuccess()
        mockBranchRepository.shouldSucceed = true
        mockTaskPlanRepository.shouldSucceed = true
        
        // Act
        let branch = try await branchManager.createBranch(
            name: branchName,
            description: branchDescription,
            userId: userId
        )
        
        // Assert
        XCTAssertEqual(branch.name, branchName)
        XCTAssertEqual(branch.description, branchDescription)
        XCTAssertEqual(branch.status, .active)
        XCTAssertFalse(branch.isMaster)
        XCTAssertNotNil(branch.taskPlan)
        XCTAssertFalse(branchManager.isCreatingBranch)
        
        // Verify repository calls
        XCTAssertEqual(mockBranchRepository.createCallCount, 1)
        XCTAssertEqual(mockBranchRepository.updateCallCount, 1)
        XCTAssertEqual(mockTaskPlanRepository.createCallCount, 1)
        XCTAssertEqual(mockTaskPlanService.generateCallCount, 1)
    }
    
    func testCreateBranchWithTimeframe() async throws {
        // Arrange
        let userId = UUID()
        let timeframe = "8周"
        
        mockTaskPlanService.configureForSuccess()
        mockBranchRepository.shouldSucceed = true
        mockTaskPlanRepository.shouldSucceed = true
        
        // Act
        let branch = try await branchManager.createBranch(
            name: "健身计划",
            description: "建立健康的运动习惯",
            userId: userId,
            timeframe: timeframe
        )
        
        // Assert
        XCTAssertNotNil(branch.taskPlan)
        XCTAssertTrue(mockTaskPlanService.lastTimeframe?.contains(timeframe) ?? false)
    }
    
    func testCreateBranchAIServiceFailure() async throws {
        // Arrange
        let userId = UUID()
        
        mockTaskPlanService.configureForFailure()
        mockBranchRepository.shouldSucceed = true
        mockTaskPlanRepository.shouldSucceed = true
        mockAIErrorHandler.shouldRetry = false
        
        // Act
        let branch = try await branchManager.createBranch(
            name: "测试目标",
            description: "测试描述",
            userId: userId
        )
        
        // Assert - Should fallback to manual task plan
        XCTAssertNotNil(branch.taskPlan)
        XCTAssertEqual(mockAIErrorHandler.handleErrorCallCount, 1)
        XCTAssertEqual(mockAIErrorHandler.createManualTaskPlanCallCount, 1)
    }
    
    func testCreateBranchRepositoryFailure() async {
        // Arrange
        let userId = UUID()
        
        mockBranchRepository.shouldSucceed = false
        mockBranchRepository.mockError = BranchRepositoryError.saveFailed("Mock save error")
        
        // Act & Assert
        do {
            _ = try await branchManager.createBranch(
                name: "测试目标",
                description: "测试描述",
                userId: userId
            )
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(branchManager.error)
            XCTAssertFalse(branchManager.isCreatingBranch)
        }
    }
    
    func testCreateBranchWithManualTaskPlan() async throws {
        // Arrange
        let userId = UUID()
        
        mockBranchRepository.shouldSucceed = true
        mockTaskPlanRepository.shouldSucceed = true
        
        // Act
        let branch = try await branchManager.createBranchWithManualTaskPlan(
            name: "手动目标",
            description: "手动创建的目标",
            userId: userId
        )
        
        // Assert
        XCTAssertEqual(branch.name, "手动目标")
        XCTAssertNotNil(branch.taskPlan)
        XCTAssertEqual(mockAIErrorHandler.createManualTaskPlanCallCount, 1)
        XCTAssertEqual(mockTaskPlanService.generateCallCount, 0) // Should not call AI service
    }
    
    // MARK: - Task Plan Regeneration Tests
    func testRegenerateTaskPlanSuccess() async throws {
        // Arrange
        let branch = createTestBranch()
        let existingTaskPlan = TaskPlan(branchId: branch.id, totalDuration: "旧计划")
        branch.taskPlan = existingTaskPlan
        
        mockTaskPlanService.configureForSuccess()
        mockTaskPlanRepository.shouldSucceed = true
        mockBranchRepository.shouldSucceed = true
        
        // Act
        try await branchManager.regenerateTaskPlan(for: branch)
        
        // Assert
        XCTAssertEqual(mockTaskPlanRepository.deleteCallCount, 1)
        XCTAssertEqual(mockTaskPlanService.generateCallCount, 1)
        XCTAssertEqual(mockBranchRepository.updateCallCount, 1)
        XCTAssertFalse(branchManager.isGeneratingTaskPlan)
    }
    
    func testRegenerateTaskPlanNoExistingPlan() async {
        // Arrange
        let branch = createTestBranch()
        // No task plan assigned
        
        // Act & Assert
        do {
            try await branchManager.regenerateTaskPlan(for: branch)
            XCTFail("Expected error to be thrown")
        } catch let error as BranchManagerError {
            switch error {
            case .noTaskPlan:
                // Expected
                break
            default:
                XCTFail("Expected noTaskPlan error, got \(error)")
            }
        } catch {
            XCTFail("Expected BranchManagerError, got \(error)")
        }
    }
    
    // MARK: - Branch Merging Tests
    func testMergeBranchSuccess() async throws {
        // Arrange
        let branch = createTestBranch()
        branch.status = .completed
        
        let masterBranch = createTestBranch()
        masterBranch.isMaster = true
        masterBranch.name = "Master"
        
        mockBranchRepository.masterBranch = masterBranch
        mockCommitRepository.shouldSucceed = true
        mockBranchRepository.shouldSucceed = true
        
        // Act
        try await branchManager.mergeBranch(branch)
        
        // Assert
        XCTAssertEqual(mockCommitRepository.createCallCount, 1)
        XCTAssertEqual(mockBranchRepository.updateCallCount, 1)
        XCTAssertNotNil(branch.mergedAt)
        XCTAssertFalse(branchManager.isMergingBranch)
    }
    
    func testMergeBranchNotCompleted() async {
        // Arrange
        let branch = createTestBranch()
        branch.status = .active // Not completed
        
        // Act & Assert
        do {
            try await branchManager.mergeBranch(branch)
            XCTFail("Expected error to be thrown")
        } catch let error as BranchManagerError {
            switch error {
            case .invalidBranchState:
                // Expected
                break
            default:
                XCTFail("Expected invalidBranchState error, got \(error)")
            }
        } catch {
            XCTFail("Expected BranchManagerError, got \(error)")
        }
    }
    
    func testMergeMasterBranch() async {
        // Arrange
        let masterBranch = createTestBranch()
        masterBranch.isMaster = true
        masterBranch.status = .completed
        
        // Act & Assert
        do {
            try await branchManager.mergeBranch(masterBranch)
            XCTFail("Expected error to be thrown")
        } catch let error as BranchManagerError {
            switch error {
            case .invalidOperation:
                // Expected
                break
            default:
                XCTFail("Expected invalidOperation error, got \(error)")
            }
        } catch {
            XCTFail("Expected BranchManagerError, got \(error)")
        }
    }
    
    func testMergeBranchNoMasterFound() async {
        // Arrange
        let branch = createTestBranch()
        branch.status = .completed
        
        mockBranchRepository.masterBranch = nil // No master branch
        
        // Act & Assert
        do {
            try await branchManager.mergeBranch(branch)
            XCTFail("Expected error to be thrown")
        } catch let error as BranchManagerError {
            switch error {
            case .masterBranchNotFound:
                // Expected
                break
            default:
                XCTFail("Expected masterBranchNotFound error, got \(error)")
            }
        } catch {
            XCTFail("Expected BranchManagerError, got \(error)")
        }
    }
    
    // MARK: - Branch Abandonment Tests
    func testAbandonBranchSuccess() async throws {
        // Arrange
        let branch = createTestBranch()
        branch.status = .active
        
        mockBranchRepository.shouldSucceed = true
        
        // Act
        try await branchManager.abandonBranch(branch)
        
        // Assert
        XCTAssertEqual(branch.status, .abandoned)
        XCTAssertNotNil(branch.abandonedAt)
        XCTAssertEqual(mockBranchRepository.updateCallCount, 1)
    }
    
    func testAbandonMasterBranch() async {
        // Arrange
        let masterBranch = createTestBranch()
        masterBranch.isMaster = true
        
        // Act & Assert
        do {
            try await branchManager.abandonBranch(masterBranch)
            XCTFail("Expected error to be thrown")
        } catch let error as BranchManagerError {
            switch error {
            case .invalidOperation:
                // Expected
                break
            default:
                XCTFail("Expected invalidOperation error, got \(error)")
            }
        } catch {
            XCTFail("Expected BranchManagerError, got \(error)")
        }
    }
    
    // MARK: - Branch Completion Tests
    func testCompleteBranchSuccess() async throws {
        // Arrange
        let branch = createTestBranch()
        branch.status = .active
        
        mockBranchRepository.shouldSucceed = true
        mockCommitRepository.shouldSucceed = true
        
        // Act
        try await branchManager.completeBranch(branch)
        
        // Assert
        XCTAssertEqual(branch.status, .completed)
        XCTAssertNotNil(branch.completedAt)
        XCTAssertEqual(mockBranchRepository.updateCallCount, 1)
        XCTAssertEqual(mockCommitRepository.createCallCount, 1)
    }
    
    func testCompleteBranchInvalidState() async {
        // Arrange
        let branch = createTestBranch()
        branch.status = .completed // Already completed
        
        // Act & Assert
        do {
            try await branchManager.completeBranch(branch)
            XCTFail("Expected error to be thrown")
        } catch let error as BranchManagerError {
            switch error {
            case .invalidBranchState:
                // Expected
                break
            default:
                XCTFail("Expected invalidBranchState error, got \(error)")
            }
        } catch {
            XCTFail("Expected BranchManagerError, got \(error)")
        }
    }
    
    // MARK: - Branch Statistics Tests
    func testGetBranchStatistics() async throws {
        // Arrange
        let branch = createTestBranch()
        let taskPlan = TaskPlan(branchId: branch.id, totalDuration: "4周")
        
        // Add tasks to task plan
        let task1 = TaskItem(title: "任务1", description: "描述1", estimatedDuration: 60, timeScope: .daily, orderIndex: 1)
        let task2 = TaskItem(title: "任务2", description: "描述2", estimatedDuration: 90, timeScope: .weekly, orderIndex: 2)
        task1.markAsCompleted()
        
        taskPlan.tasks = [task1, task2]
        
        mockCommitRepository.commitCount = 5
        mockTaskPlanRepository.taskPlan = taskPlan
        
        // Act
        let statistics = try await branchManager.getBranchStatistics(branch)
        
        // Assert
        XCTAssertEqual(statistics.commitCount, 5)
        XCTAssertEqual(statistics.totalTasks, 2)
        XCTAssertEqual(statistics.completedTasks, 1)
        XCTAssertEqual(statistics.progress, 0.5, accuracy: 0.01)
        XCTAssertEqual(statistics.estimatedDuration, 150) // 60 + 90
    }
    
    func testGetBranchStatisticsNoTaskPlan() async throws {
        // Arrange
        let branch = createTestBranch()
        
        mockCommitRepository.commitCount = 3
        mockTaskPlanRepository.taskPlan = nil
        
        // Act
        let statistics = try await branchManager.getBranchStatistics(branch)
        
        // Assert
        XCTAssertEqual(statistics.commitCount, 3)
        XCTAssertEqual(statistics.totalTasks, 0)
        XCTAssertEqual(statistics.completedTasks, 0)
        XCTAssertEqual(statistics.progress, 0.0)
        XCTAssertEqual(statistics.estimatedDuration, 0)
    }
    
    // MARK: - Error Handling Tests
    func testClearError() {
        // Arrange
        branchManager.error = BranchManagerError.creationFailed("Test error")
        
        // Act
        branchManager.clearError()
        
        // Assert
        XCTAssertNil(branchManager.error)
    }
    
    // MARK: - State Management Tests
    func testCreatingBranchState() async throws {
        // Arrange
        let userId = UUID()
        
        mockTaskPlanService.configureForSlowResponse()
        mockBranchRepository.shouldSucceed = true
        mockTaskPlanRepository.shouldSucceed = true
        
        // Act
        let task = Task {
            try await branchManager.createBranch(
                name: "测试目标",
                description: "测试描述",
                userId: userId
            )
        }
        
        // Check state during creation
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        XCTAssertTrue(branchManager.isCreatingBranch)
        
        // Wait for completion
        _ = try await task.value
        XCTAssertFalse(branchManager.isCreatingBranch)
    }
    
    // MARK: - Helper Methods
    private func createTestBranch() -> Branch {
        return Branch(
            name: "测试分支",
            description: "测试用的分支",
            status: .active
        )
    }
}

// MARK: - Mock Implementations

class MockBranchRepository: BranchRepository {
    var shouldSucceed = true
    var mockError: Error?
    var masterBranch: Branch?
    
    var createCallCount = 0
    var updateCallCount = 0
    var deleteCallCount = 0
    var findCallCount = 0
    
    func create(_ branch: Branch) async throws {
        createCallCount += 1
        if !shouldSucceed, let error = mockError {
            throw error
        }
    }
    
    func update(_ branch: Branch) async throws {
        updateCallCount += 1
        if !shouldSucceed, let error = mockError {
            throw error
        }
    }
    
    func delete(id: UUID) async throws {
        deleteCallCount += 1
        if !shouldSucceed, let error = mockError {
            throw error
        }
    }
    
    func findById(_ id: UUID) async throws -> Branch? {
        findCallCount += 1
        return nil
    }
    
    func findMasterBranch() async throws -> Branch? {
        return masterBranch
    }
    
    func findAll() async throws -> [Branch] {
        return []
    }
}

class MockTaskPlanRepository: TaskPlanRepository {
    var shouldSucceed = true
    var mockError: Error?
    var taskPlan: TaskPlan?
    
    var createCallCount = 0
    var updateCallCount = 0
    var deleteCallCount = 0
    var findCallCount = 0
    
    func create(_ taskPlan: TaskPlan) async throws {
        createCallCount += 1
        if !shouldSucceed, let error = mockError {
            throw error
        }
    }
    
    func update(_ taskPlan: TaskPlan) async throws {
        updateCallCount += 1
        if !shouldSucceed, let error = mockError {
            throw error
        }
    }
    
    func delete(id: UUID) async throws {
        deleteCallCount += 1
        if !shouldSucceed, let error = mockError {
            throw error
        }
    }
    
    func findByBranchId(_ branchId: UUID) async throws -> TaskPlan? {
        findCallCount += 1
        return taskPlan
    }
}

class MockCommitRepository: CommitRepository {
    var shouldSucceed = true
    var mockError: Error?
    var commitCount = 0
    
    var createCallCount = 0
    
    func create(_ commit: Commit) async throws {
        createCallCount += 1
        if !shouldSucceed, let error = mockError {
            throw error
        }
    }
    
    func getCommitCount(for branchId: UUID) async throws -> Int {
        return commitCount
    }
    
    func findByBranchId(_ branchId: UUID) async throws -> [Commit] {
        return []
    }
}

class MockTaskPlanService {
    var shouldSucceed = true
    var responseDelay: TimeInterval = 0.1
    var generateCallCount = 0
    var lastGoalTitle: String?
    var lastGoalDescription: String?
    var lastTimeframe: String?
    
    func generateTaskPlan(goalTitle: String, goalDescription: String, timeframe: String?) async throws -> AIGeneratedTaskPlan {
        generateCallCount += 1
        lastGoalTitle = goalTitle
        lastGoalDescription = goalDescription
        lastTimeframe = timeframe
        
        if responseDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(responseDelay * 1_000_000_000))
        }
        
        if !shouldSucceed {
            throw TaskPlanError.aiServiceError("Mock AI service error")
        }
        
        return AIGeneratedTaskPlan(
            totalDuration: "4周",
            tasks: [
                AIGeneratedTask(
                    title: "测试任务",
                    description: "测试任务描述",
                    timeScope: "daily",
                    estimatedDuration: 60,
                    orderIndex: 1,
                    executionTips: "测试提示"
                )
            ]
        )
    }
    
    func convertToTaskPlan(_ aiTaskPlan: AIGeneratedTaskPlan, branchId: UUID) -> TaskPlan {
        let taskPlan = TaskPlan(branchId: branchId, totalDuration: aiTaskPlan.totalDuration, isAIGenerated: true)
        
        let taskItems = aiTaskPlan.tasks.map { aiTask in
            TaskItem(
                title: aiTask.title,
                description: aiTask.description,
                estimatedDuration: aiTask.estimatedDuration,
                timeScope: TaskTimeScope(rawValue: aiTask.timeScope) ?? .daily,
                orderIndex: aiTask.orderIndex,
                executionTips: aiTask.executionTips
            )
        }
        
        taskPlan.tasks = taskItems
        return taskPlan
    }
    
    func configureForSuccess() {
        shouldSucceed = true
        responseDelay = 0.1
    }
    
    func configureForFailure() {
        shouldSucceed = false
    }
    
    func configureForSlowResponse() {
        shouldSucceed = true
        responseDelay = 1.0
    }
}

class MockAIServiceErrorHandler {
    var shouldRetry = false
    var handleErrorCallCount = 0
    var createManualTaskPlanCallCount = 0
    
    func handleError(_ error: Error) -> (canRetry: Bool, userMessage: String) {
        handleErrorCallCount += 1
        return (canRetry: shouldRetry, userMessage: "Mock error message")
    }
    
    func createManualTaskPlan(goalTitle: String, goalDescription: String) -> TaskPlan {
        createManualTaskPlanCallCount += 1
        
        let taskPlan = TaskPlan(
            branchId: UUID(),
            totalDuration: "手动创建",
            isAIGenerated: false
        )
        
        let manualTask = TaskItem(
            title: "手动任务",
            description: "用户手动创建的任务",
            estimatedDuration: 60,
            timeScope: .daily,
            isAIGenerated: false,
            orderIndex: 1
        )
        
        taskPlan.tasks = [manualTask]
        return taskPlan
    }
    
    func shouldRetry() -> Bool {
        return shouldRetry
    }
    
    func getRetryDelay() -> Double {
        return 1.0
    }
    
    func resetRetryCount() {
        // Mock implementation
    }
}

// MARK: - Mock Repository Errors

enum BranchRepositoryError: Error {
    case saveFailed(String)
    case notFound(String)
    case deleteFailed(String)
}

enum TaskPlanRepositoryError: Error {
    case saveFailed(String)
    case notFound(String)
    case deleteFailed(String)
}

enum CommitRepositoryError: Error {
    case saveFailed(String)
    case notFound(String)
}