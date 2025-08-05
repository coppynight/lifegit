import Foundation
import SwiftData
@testable import LifeGit

/// Test configuration and utilities for LifeGit tests
class TestConfiguration {
    
    // MARK: - Test Database Setup
    static func createTestModelContainer() throws -> ModelContainer {
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
        
        return try ModelContainer(
            for: schema,
            configurations: [modelConfiguration]
        )
    }
    
    // MARK: - Test Data Factories
    static func createTestUser() -> User {
        return User(
            currentVersion: "v1.0",
            createdAt: Date()
        )
    }
    
    static func createTestBranch(
        name: String = "测试分支",
        description: String = "测试用的分支",
        status: BranchStatus = .active,
        isMaster: Bool = false
    ) -> Branch {
        return Branch(
            name: name,
            description: description,
            status: status,
            isMaster: isMaster
        )
    }
    
    static func createTestTaskPlan(
        branchId: UUID,
        totalDuration: String = "4周",
        isAIGenerated: Bool = true,
        taskCount: Int = 3
    ) -> TaskPlan {
        let taskPlan = TaskPlan(
            branchId: branchId,
            totalDuration: totalDuration,
            isAIGenerated: isAIGenerated
        )
        
        // Add test tasks
        for i in 0..<taskCount {
            let task = TaskItem(
                title: "测试任务\(i + 1)",
                description: "测试任务描述\(i + 1)",
                estimatedDuration: 60 + (i * 30),
                timeScope: TaskTimeScope.allCases[i % TaskTimeScope.allCases.count],
                isAIGenerated: isAIGenerated,
                orderIndex: i + 1
            )
            taskPlan.tasks.append(task)
        }
        
        return taskPlan
    }
    
    static func createTestCommit(
        message: String = "测试提交",
        type: CommitType = .taskComplete,
        branchId: UUID,
        relatedTaskId: UUID? = nil
    ) -> Commit {
        return Commit(
            message: message,
            type: type,
            branchId: branchId,
            relatedTaskId: relatedTaskId
        )
    }
    
    // MARK: - Test Scenarios
    static func createCompleteTestScenario() -> (User, Branch, TaskPlan, [Commit]) {
        let user = createTestUser()
        let branch = createTestBranch()
        let taskPlan = createTestTaskPlan(branchId: branch.id)
        
        let commits = [
            createTestCommit(message: "开始学习", type: .learning, branchId: branch.id),
            createTestCommit(message: "完成第一个任务", type: .taskComplete, branchId: branch.id, relatedTaskId: taskPlan.tasks.first?.id),
            createTestCommit(message: "今日反思", type: .reflection, branchId: branch.id),
            createTestCommit(message: "达成里程碑", type: .milestone, branchId: branch.id)
        ]
        
        // Set up relationships
        branch.taskPlan = taskPlan
        user.branches.append(branch)
        user.commits.append(contentsOf: commits)
        
        return (user, branch, taskPlan, commits)
    }
    
    // MARK: - Test Assertions
    static func assertBranchValid(_ branch: Branch, file: StaticString = #file, line: UInt = #line) {
        XCTAssertNotNil(branch.id, "Branch should have a valid ID", file: file, line: line)
        XCTAssertFalse(branch.name.isEmpty, "Branch name should not be empty", file: file, line: line)
        XCTAssertFalse(branch.description.isEmpty, "Branch description should not be empty", file: file, line: line)
        XCTAssertGreaterThanOrEqual(branch.progress, 0.0, "Branch progress should be >= 0", file: file, line: line)
        XCTAssertLessThanOrEqual(branch.progress, 1.0, "Branch progress should be <= 1", file: file, line: line)
    }
    
    static func assertTaskPlanValid(_ taskPlan: TaskPlan, file: StaticString = #file, line: UInt = #line) {
        XCTAssertNotNil(taskPlan.id, "TaskPlan should have a valid ID", file: file, line: line)
        XCTAssertNotNil(taskPlan.branchId, "TaskPlan should have a valid branch ID", file: file, line: line)
        XCTAssertFalse(taskPlan.totalDuration.isEmpty, "TaskPlan total duration should not be empty", file: file, line: line)
        XCTAssertGreaterThanOrEqual(taskPlan.tasks.count, 0, "TaskPlan should have >= 0 tasks", file: file, line: line)
    }
    
    static func assertTaskItemValid(_ taskItem: TaskItem, file: StaticString = #file, line: UInt = #line) {
        XCTAssertNotNil(taskItem.id, "TaskItem should have a valid ID", file: file, line: line)
        XCTAssertFalse(taskItem.title.isEmpty, "TaskItem title should not be empty", file: file, line: line)
        XCTAssertFalse(taskItem.description.isEmpty, "TaskItem description should not be empty", file: file, line: line)
        XCTAssertGreaterThan(taskItem.estimatedDuration, 0, "TaskItem estimated duration should be > 0", file: file, line: line)
        XCTAssertGreaterThanOrEqual(taskItem.orderIndex, 0, "TaskItem order index should be >= 0", file: file, line: line)
    }
    
    static func assertCommitValid(_ commit: Commit, file: StaticString = #file, line: UInt = #line) {
        XCTAssertNotNil(commit.id, "Commit should have a valid ID", file: file, line: line)
        XCTAssertFalse(commit.message.isEmpty, "Commit message should not be empty", file: file, line: line)
        XCTAssertNotNil(commit.branchId, "Commit should have a valid branch ID", file: file, line: line)
        XCTAssertNotNil(commit.timestamp, "Commit should have a valid timestamp", file: file, line: line)
    }
    
    // MARK: - Test Utilities
    static func waitForAsyncOperation(timeout: TimeInterval = 5.0, operation: @escaping () async throws -> Void) async throws {
        let expectation = XCTestExpectation(description: "Async operation")
        
        Task {
            do {
                try await operation()
                expectation.fulfill()
            } catch {
                XCTFail("Async operation failed: \(error)")
                expectation.fulfill()
            }
        }
        
        await fulfillment(of: [expectation], timeout: timeout)
    }
    
    static func measureAsyncPerformance<T>(
        _ operation: @escaping () async throws -> T,
        iterations: Int = 10
    ) async -> (averageTime: TimeInterval, results: [T]) {
        var times: [TimeInterval] = []
        var results: [T] = []
        
        for _ in 0..<iterations {
            let startTime = Date()
            do {
                let result = try await operation()
                results.append(result)
            } catch {
                XCTFail("Performance test operation failed: \(error)")
            }
            let endTime = Date()
            times.append(endTime.timeIntervalSince(startTime))
        }
        
        let averageTime = times.reduce(0, +) / Double(times.count)
        return (averageTime, results)
    }
    
    // MARK: - Mock Data Generation
    static func generateMockAITaskPlan(
        goalTitle: String = "测试目标",
        taskCount: Int = 3
    ) -> AIGeneratedTaskPlan {
        var tasks: [AIGeneratedTask] = []
        
        for i in 0..<taskCount {
            let task = AIGeneratedTask(
                title: "AI生成任务\(i + 1)",
                description: "AI生成的任务描述\(i + 1)",
                timeScope: TaskTimeScope.allCases[i % TaskTimeScope.allCases.count].rawValue,
                estimatedDuration: 60 + (i * 30),
                orderIndex: i + 1,
                executionTips: "执行建议\(i + 1)"
            )
            tasks.append(task)
        }
        
        return AIGeneratedTaskPlan(
            totalDuration: "4周",
            tasks: tasks
        )
    }
    
    // MARK: - Test Environment Setup
    static func setupTestEnvironment() {
        // Set up any global test configuration
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
    }
    
    static func tearDownTestEnvironment() {
        // Clean up test environment
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
    }
    
    // MARK: - Test Constants
    struct TestConstants {
        static let defaultTimeout: TimeInterval = 5.0
        static let longTimeout: TimeInterval = 30.0
        static let performanceIterations = 10
        static let largeDatasetSize = 1000
        
        struct TestData {
            static let sampleGoalTitle = "学习Swift编程"
            static let sampleGoalDescription = "掌握Swift编程语言的基础和高级特性"
            static let sampleCommitMessage = "完成了重要的学习任务"
            static let sampleTaskTitle = "学习Swift基础语法"
            static let sampleTaskDescription = "掌握变量、常量、数据类型和控制流"
        }
    }
}

// MARK: - XCTest Extensions

extension XCTestCase {
    
    /// Helper method to create a test model container
    func createTestModelContainer() throws -> ModelContainer {
        return try TestConfiguration.createTestModelContainer()
    }
    
    /// Helper method to wait for async operations
    func waitForAsync<T>(
        timeout: TimeInterval = TestConfiguration.TestConstants.defaultTimeout,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        return try await withTimeout(timeout) {
            try await operation()
        }
    }
    
    /// Helper method to assert async operations
    func assertAsync<T>(
        timeout: TimeInterval = TestConfiguration.TestConstants.defaultTimeout,
        operation: @escaping () async throws -> T,
        assertion: @escaping (T) throws -> Void
    ) async throws {
        let result = try await waitForAsync(timeout: timeout, operation: operation)
        try assertion(result)
    }
    
    /// Helper method to measure async performance
    func measureAsync(
        iterations: Int = TestConfiguration.TestConstants.performanceIterations,
        operation: @escaping () async throws -> Void
    ) async {
        let (averageTime, _) = await TestConfiguration.measureAsyncPerformance({
            try await operation()
            return ()
        }, iterations: iterations)
        
        print("Average execution time: \(averageTime) seconds")
    }
}

// MARK: - Timeout Utility

func withTimeout<T>(_ timeout: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
    return try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }
        
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            throw TimeoutError()
        }
        
        guard let result = try await group.next() else {
            throw TimeoutError()
        }
        
        group.cancelAll()
        return result
    }
}

struct TimeoutError: Error {
    let localizedDescription = "Operation timed out"
}

// MARK: - Test Result Utilities

struct TestResult<T> {
    let value: T?
    let error: Error?
    let executionTime: TimeInterval
    
    var isSuccess: Bool {
        return error == nil && value != nil
    }
    
    var isFailure: Bool {
        return !isSuccess
    }
}

extension TestResult {
    static func success(_ value: T, executionTime: TimeInterval) -> TestResult<T> {
        return TestResult(value: value, error: nil, executionTime: executionTime)
    }
    
    static func failure(_ error: Error, executionTime: TimeInterval) -> TestResult<T> {
        return TestResult(value: nil, error: error, executionTime: executionTime)
    }
}