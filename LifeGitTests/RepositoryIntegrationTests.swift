import XCTest
import SwiftData
@testable import LifeGit

/// Integration tests for Repository layer with SwiftData
final class RepositoryIntegrationTests: XCTestCase {
    
    // MARK: - Test Properties
    private var modelContainer: ModelContainer!
    private var modelContext: ModelContext!
    private var branchRepository: SwiftDataBranchRepository!
    private var taskPlanRepository: SwiftDataTaskPlanRepository!
    private var commitRepository: SwiftDataCommitRepository!
    
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
    }
    
    override func tearDown() async throws {
        // Clean up
        branchRepository = nil
        taskPlanRepository = nil
        commitRepository = nil
        modelContext = nil
        modelContainer = nil
        try await super.tearDown()
    }
    
    // MARK: - Branch Repository Integration Tests
    func testBranchRepositoryCreateAndFind() async throws {
        // Arrange
        let branch = Branch(
            name: "学习Swift编程",
            description: "掌握Swift编程语言的基础和高级特性",
            status: .active
        )
        
        // Act - Create
        try await branchRepository.create(branch)
        
        // Act - Find
        let foundBranch = try await branchRepository.findById(branch.id)
        
        // Assert
        XCTAssertNotNil(foundBranch)
        XCTAssertEqual(foundBranch?.id, branch.id)
        XCTAssertEqual(foundBranch?.name, "学习Swift编程")
        XCTAssertEqual(foundBranch?.status, .active)
    }
    
    func testBranchRepositoryUpdate() async throws {
        // Arrange
        let branch = Branch(
            name: "原始名称",
            description: "原始描述",
            status: .active
        )
        
        try await branchRepository.create(branch)
        
        // Act - Update
        branch.name = "更新后的名称"
        branch.status = .completed
        branch.completedAt = Date()
        
        try await branchRepository.update(branch)
        
        // Act - Find updated branch
        let updatedBranch = try await branchRepository.findById(branch.id)
        
        // Assert
        XCTAssertNotNil(updatedBranch)
        XCTAssertEqual(updatedBranch?.name, "更新后的名称")
        XCTAssertEqual(updatedBranch?.status, .completed)
        XCTAssertNotNil(updatedBranch?.completedAt)
    }
    
    func testBranchRepositoryDelete() async throws {
        // Arrange
        let branch = Branch(
            name: "待删除分支",
            description: "这个分支将被删除",
            status: .active
        )
        
        try await branchRepository.create(branch)
        
        // Verify it exists
        let existingBranch = try await branchRepository.findById(branch.id)
        XCTAssertNotNil(existingBranch)
        
        // Act - Delete
        try await branchRepository.delete(id: branch.id)
        
        // Assert - Should not be found
        let deletedBranch = try await branchRepository.findById(branch.id)
        XCTAssertNil(deletedBranch)
    }
    
    func testBranchRepositoryFindAll() async throws {
        // Arrange - Create multiple branches
        let branch1 = Branch(name: "分支1", description: "描述1", status: .active)
        let branch2 = Branch(name: "分支2", description: "描述2", status: .completed)
        let branch3 = Branch(name: "分支3", description: "描述3", status: .abandoned)
        
        try await branchRepository.create(branch1)
        try await branchRepository.create(branch2)
        try await branchRepository.create(branch3)
        
        // Act
        let allBranches = try await branchRepository.findAll()
        
        // Assert
        XCTAssertEqual(allBranches.count, 3)
        
        let branchNames = allBranches.map { $0.name }.sorted()
        XCTAssertEqual(branchNames, ["分支1", "分支2", "分支3"])
    }
    
    func testBranchRepositoryFindMasterBranch() async throws {
        // Arrange - Create regular branch and master branch
        let regularBranch = Branch(name: "普通分支", description: "普通分支", status: .active)
        let masterBranch = Branch(name: "Master", description: "主干分支", isMaster: true)
        
        try await branchRepository.create(regularBranch)
        try await branchRepository.create(masterBranch)
        
        // Act
        let foundMaster = try await branchRepository.findMasterBranch()
        
        // Assert
        XCTAssertNotNil(foundMaster)
        XCTAssertTrue(foundMaster?.isMaster ?? false)
        XCTAssertEqual(foundMaster?.name, "Master")
    }
    
    // MARK: - TaskPlan Repository Integration Tests
    func testTaskPlanRepositoryCreateAndFind() async throws {
        // Arrange
        let branchId = UUID()
        let taskPlan = TaskPlan(
            branchId: branchId,
            totalDuration: "4周",
            isAIGenerated: true
        )
        
        // Add tasks
        let task1 = TaskItem(
            title: "任务1",
            description: "第一个任务",
            estimatedDuration: 60,
            timeScope: .daily,
            orderIndex: 1
        )
        
        let task2 = TaskItem(
            title: "任务2",
            description: "第二个任务",
            estimatedDuration: 90,
            timeScope: .weekly,
            orderIndex: 2
        )
        
        taskPlan.tasks = [task1, task2]
        
        // Act - Create
        try await taskPlanRepository.create(taskPlan)
        
        // Act - Find by branch ID
        let foundTaskPlan = try await taskPlanRepository.findByBranchId(branchId)
        
        // Assert
        XCTAssertNotNil(foundTaskPlan)
        XCTAssertEqual(foundTaskPlan?.branchId, branchId)
        XCTAssertEqual(foundTaskPlan?.totalDuration, "4周")
        XCTAssertTrue(foundTaskPlan?.isAIGenerated ?? false)
        XCTAssertEqual(foundTaskPlan?.tasks.count, 2)
        
        // Verify tasks
        let orderedTasks = foundTaskPlan?.orderedTasks ?? []
        XCTAssertEqual(orderedTasks[0].title, "任务1")
        XCTAssertEqual(orderedTasks[1].title, "任务2")
    }
    
    func testTaskPlanRepositoryUpdate() async throws {
        // Arrange
        let branchId = UUID()
        let taskPlan = TaskPlan(
            branchId: branchId,
            totalDuration: "原始时长",
            isAIGenerated: true
        )
        
        try await taskPlanRepository.create(taskPlan)
        
        // Act - Update
        taskPlan.totalDuration = "更新后的时长"
        taskPlan.lastModifiedAt = Date()
        
        // Add a new task
        let newTask = TaskItem(
            title: "新任务",
            description: "新添加的任务",
            estimatedDuration: 120,
            timeScope: .monthly,
            orderIndex: 1
        )
        taskPlan.tasks.append(newTask)
        
        try await taskPlanRepository.update(taskPlan)
        
        // Act - Find updated task plan
        let updatedTaskPlan = try await taskPlanRepository.findByBranchId(branchId)
        
        // Assert
        XCTAssertNotNil(updatedTaskPlan)
        XCTAssertEqual(updatedTaskPlan?.totalDuration, "更新后的时长")
        XCTAssertNotNil(updatedTaskPlan?.lastModifiedAt)
        XCTAssertEqual(updatedTaskPlan?.tasks.count, 1)
        XCTAssertEqual(updatedTaskPlan?.tasks.first?.title, "新任务")
    }
    
    func testTaskPlanRepositoryDelete() async throws {
        // Arrange
        let branchId = UUID()
        let taskPlan = TaskPlan(branchId: branchId, totalDuration: "待删除")
        
        try await taskPlanRepository.create(taskPlan)
        
        // Verify it exists
        let existingTaskPlan = try await taskPlanRepository.findByBranchId(branchId)
        XCTAssertNotNil(existingTaskPlan)
        
        // Act - Delete
        try await taskPlanRepository.delete(id: taskPlan.id)
        
        // Assert - Should not be found
        let deletedTaskPlan = try await taskPlanRepository.findByBranchId(branchId)
        XCTAssertNil(deletedTaskPlan)
    }
    
    // MARK: - Commit Repository Integration Tests
    func testCommitRepositoryCreateAndFind() async throws {
        // Arrange
        let branchId = UUID()
        let commit = Commit(
            message: "完成第一个任务",
            type: .taskComplete,
            branchId: branchId
        )
        
        // Act - Create
        try await commitRepository.create(commit)
        
        // Act - Find by branch ID
        let commits = try await commitRepository.findByBranchId(branchId)
        
        // Assert
        XCTAssertEqual(commits.count, 1)
        XCTAssertEqual(commits.first?.message, "完成第一个任务")
        XCTAssertEqual(commits.first?.type, .taskComplete)
        XCTAssertEqual(commits.first?.branchId, branchId)
    }
    
    func testCommitRepositoryGetCommitCount() async throws {
        // Arrange
        let branchId = UUID()
        
        let commit1 = Commit(message: "提交1", type: .taskComplete, branchId: branchId)
        let commit2 = Commit(message: "提交2", type: .learning, branchId: branchId)
        let commit3 = Commit(message: "提交3", type: .reflection, branchId: branchId)
        
        try await commitRepository.create(commit1)
        try await commitRepository.create(commit2)
        try await commitRepository.create(commit3)
        
        // Act
        let commitCount = try await commitRepository.getCommitCount(for: branchId)
        
        // Assert
        XCTAssertEqual(commitCount, 3)
    }
    
    func testCommitRepositoryMultipleBranches() async throws {
        // Arrange
        let branchId1 = UUID()
        let branchId2 = UUID()
        
        let commit1 = Commit(message: "分支1提交1", type: .taskComplete, branchId: branchId1)
        let commit2 = Commit(message: "分支1提交2", type: .learning, branchId: branchId1)
        let commit3 = Commit(message: "分支2提交1", type: .reflection, branchId: branchId2)
        
        try await commitRepository.create(commit1)
        try await commitRepository.create(commit2)
        try await commitRepository.create(commit3)
        
        // Act
        let branch1Commits = try await commitRepository.findByBranchId(branchId1)
        let branch2Commits = try await commitRepository.findByBranchId(branchId2)
        let branch1Count = try await commitRepository.getCommitCount(for: branchId1)
        let branch2Count = try await commitRepository.getCommitCount(for: branchId2)
        
        // Assert
        XCTAssertEqual(branch1Commits.count, 2)
        XCTAssertEqual(branch2Commits.count, 1)
        XCTAssertEqual(branch1Count, 2)
        XCTAssertEqual(branch2Count, 1)
        
        XCTAssertTrue(branch1Commits.contains { $0.message == "分支1提交1" })
        XCTAssertTrue(branch1Commits.contains { $0.message == "分支1提交2" })
        XCTAssertEqual(branch2Commits.first?.message, "分支2提交1")
    }
    
    // MARK: - Cross-Repository Integration Tests
    func testBranchWithTaskPlanIntegration() async throws {
        // Arrange
        let branch = Branch(
            name: "集成测试分支",
            description: "测试分支和任务计划的集成",
            status: .active
        )
        
        let taskPlan = TaskPlan(
            branchId: branch.id,
            totalDuration: "6周",
            isAIGenerated: true
        )
        
        let task = TaskItem(
            title: "集成测试任务",
            description: "测试任务",
            estimatedDuration: 120,
            timeScope: .daily,
            orderIndex: 1
        )
        taskPlan.tasks = [task]
        
        // Act - Create branch and task plan
        try await branchRepository.create(branch)
        try await taskPlanRepository.create(taskPlan)
        
        // Update branch to reference task plan
        branch.taskPlan = taskPlan
        try await branchRepository.update(branch)
        
        // Act - Retrieve and verify
        let retrievedBranch = try await branchRepository.findById(branch.id)
        let retrievedTaskPlan = try await taskPlanRepository.findByBranchId(branch.id)
        
        // Assert
        XCTAssertNotNil(retrievedBranch)
        XCTAssertNotNil(retrievedTaskPlan)
        XCTAssertEqual(retrievedTaskPlan?.branchId, branch.id)
        XCTAssertEqual(retrievedTaskPlan?.tasks.count, 1)
        XCTAssertEqual(retrievedTaskPlan?.tasks.first?.title, "集成测试任务")
    }
    
    func testBranchWithCommitsIntegration() async throws {
        // Arrange
        let branch = Branch(
            name: "有提交的分支",
            description: "包含多个提交的分支",
            status: .active
        )
        
        try await branchRepository.create(branch)
        
        // Create commits for the branch
        let commits = [
            Commit(message: "初始提交", type: .taskComplete, branchId: branch.id),
            Commit(message: "学习记录", type: .learning, branchId: branch.id),
            Commit(message: "反思总结", type: .reflection, branchId: branch.id),
            Commit(message: "里程碑达成", type: .milestone, branchId: branch.id)
        ]
        
        for commit in commits {
            try await commitRepository.create(commit)
        }
        
        // Act - Retrieve branch and commits
        let retrievedBranch = try await branchRepository.findById(branch.id)
        let branchCommits = try await commitRepository.findByBranchId(branch.id)
        let commitCount = try await commitRepository.getCommitCount(for: branch.id)
        
        // Assert
        XCTAssertNotNil(retrievedBranch)
        XCTAssertEqual(branchCommits.count, 4)
        XCTAssertEqual(commitCount, 4)
        
        // Verify commit types
        let commitTypes = branchCommits.map { $0.type }.sorted { $0.rawValue < $1.rawValue }
        XCTAssertTrue(commitTypes.contains(.taskComplete))
        XCTAssertTrue(commitTypes.contains(.learning))
        XCTAssertTrue(commitTypes.contains(.reflection))
        XCTAssertTrue(commitTypes.contains(.milestone))
    }
    
    func testCompleteWorkflowIntegration() async throws {
        // Arrange - Create a complete workflow: Branch -> TaskPlan -> Commits
        let branch = Branch(
            name: "完整工作流测试",
            description: "测试完整的工作流程",
            status: .active
        )
        
        // Step 1: Create branch
        try await branchRepository.create(branch)
        
        // Step 2: Create task plan
        let taskPlan = TaskPlan(
            branchId: branch.id,
            totalDuration: "8周",
            isAIGenerated: true
        )
        
        let tasks = [
            TaskItem(title: "任务1", description: "第一个任务", estimatedDuration: 60, timeScope: .daily, orderIndex: 1),
            TaskItem(title: "任务2", description: "第二个任务", estimatedDuration: 90, timeScope: .weekly, orderIndex: 2),
            TaskItem(title: "任务3", description: "第三个任务", estimatedDuration: 120, timeScope: .monthly, orderIndex: 3)
        ]
        taskPlan.tasks = tasks
        
        try await taskPlanRepository.create(taskPlan)
        
        // Step 3: Complete some tasks and create commits
        tasks[0].markAsCompleted()
        tasks[1].markAsCompleted()
        
        let commits = [
            Commit(message: "完成任务1", type: .taskComplete, branchId: branch.id, relatedTaskId: tasks[0].id),
            Commit(message: "完成任务2", type: .taskComplete, branchId: branch.id, relatedTaskId: tasks[1].id),
            Commit(message: "学习心得", type: .learning, branchId: branch.id)
        ]
        
        for commit in commits {
            try await commitRepository.create(commit)
        }
        
        // Step 4: Update branch progress and status
        branch.updateProgress()
        branch.taskPlan = taskPlan
        try await branchRepository.update(branch)
        
        // Act - Retrieve all data
        let finalBranch = try await branchRepository.findById(branch.id)
        let finalTaskPlan = try await taskPlanRepository.findByBranchId(branch.id)
        let finalCommits = try await commitRepository.findByBranchId(branch.id)
        let finalCommitCount = try await commitRepository.getCommitCount(for: branch.id)
        
        // Assert - Verify complete workflow
        XCTAssertNotNil(finalBranch)
        XCTAssertNotNil(finalTaskPlan)
        
        // Branch assertions
        XCTAssertEqual(finalBranch?.name, "完整工作流测试")
        XCTAssertEqual(finalBranch?.status, .active)
        XCTAssertEqual(finalBranch?.progress, 2.0/3.0, accuracy: 0.01) // 2 out of 3 tasks completed
        
        // Task plan assertions
        XCTAssertEqual(finalTaskPlan?.totalDuration, "8周")
        XCTAssertTrue(finalTaskPlan?.isAIGenerated ?? false)
        XCTAssertEqual(finalTaskPlan?.tasks.count, 3)
        XCTAssertEqual(finalTaskPlan?.completedTasksCount, 2)
        XCTAssertEqual(finalTaskPlan?.totalEstimatedDuration, 270) // 60 + 90 + 120
        
        // Commit assertions
        XCTAssertEqual(finalCommits.count, 3)
        XCTAssertEqual(finalCommitCount, 3)
        
        let taskCompleteCommits = finalCommits.filter { $0.type == .taskComplete }
        XCTAssertEqual(taskCompleteCommits.count, 2)
        
        let learningCommits = finalCommits.filter { $0.type == .learning }
        XCTAssertEqual(learningCommits.count, 1)
    }
    
    // MARK: - Error Handling Integration Tests
    func testRepositoryErrorHandling() async throws {
        // Test finding non-existent branch
        let nonExistentId = UUID()
        let notFoundBranch = try await branchRepository.findById(nonExistentId)
        XCTAssertNil(notFoundBranch)
        
        // Test finding task plan for non-existent branch
        let notFoundTaskPlan = try await taskPlanRepository.findByBranchId(nonExistentId)
        XCTAssertNil(notFoundTaskPlan)
        
        // Test finding commits for non-existent branch
        let notFoundCommits = try await commitRepository.findByBranchId(nonExistentId)
        XCTAssertTrue(notFoundCommits.isEmpty)
        
        // Test commit count for non-existent branch
        let zeroCommitCount = try await commitRepository.getCommitCount(for: nonExistentId)
        XCTAssertEqual(zeroCommitCount, 0)
    }
    
    // MARK: - Performance Integration Tests
    func testRepositoryPerformanceWithLargeDataset() async throws {
        // Create many branches, task plans, and commits
        let branchCount = 100
        let commitsPerBranch = 10
        
        var branches: [Branch] = []
        
        // Create branches and task plans
        for i in 0..<branchCount {
            let branch = Branch(
                name: "分支\(i)",
                description: "描述\(i)",
                status: .active
            )
            branches.append(branch)
            
            try await branchRepository.create(branch)
            
            let taskPlan = TaskPlan(
                branchId: branch.id,
                totalDuration: "4周",
                isAIGenerated: true
            )
            
            let task = TaskItem(
                title: "任务\(i)",
                description: "描述\(i)",
                estimatedDuration: 60,
                timeScope: .daily,
                orderIndex: 1
            )
            taskPlan.tasks = [task]
            
            try await taskPlanRepository.create(taskPlan)
        }
        
        // Create commits for each branch
        for (index, branch) in branches.enumerated() {
            for j in 0..<commitsPerBranch {
                let commit = Commit(
                    message: "分支\(index)提交\(j)",
                    type: .taskComplete,
                    branchId: branch.id
                )
                try await commitRepository.create(commit)
            }
        }
        
        // Measure performance of bulk operations
        measure {
            Task {
                do {
                    // Test finding all branches
                    let allBranches = try await branchRepository.findAll()
                    XCTAssertEqual(allBranches.count, branchCount)
                    
                    // Test finding commits for first branch
                    let firstBranchCommits = try await commitRepository.findByBranchId(branches[0].id)
                    XCTAssertEqual(firstBranchCommits.count, commitsPerBranch)
                    
                } catch {
                    XCTFail("Performance test failed: \(error)")
                }
            }
        }
    }
}