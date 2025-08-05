import XCTest
import SwiftData
@testable import LifeGit

/// Unit tests for Branch model
final class BranchTests: XCTestCase {
    
    // MARK: - Test Properties
    private var branch: Branch!
    private var taskPlan: TaskPlan!
    
    // MARK: - Setup & Teardown
    override func setUp() {
        super.setUp()
        branch = Branch(
            name: "学习Swift编程",
            description: "掌握Swift编程语言的基础和高级特性",
            status: .active
        )
        
        taskPlan = TaskPlan(
            branchId: branch.id,
            totalDuration: "4周",
            isAIGenerated: true
        )
        
        // Add some test tasks
        let task1 = TaskItem(
            title: "学习Swift基础语法",
            description: "变量、常量、数据类型",
            estimatedDuration: 120,
            timeScope: .daily,
            orderIndex: 1
        )
        
        let task2 = TaskItem(
            title: "练习面向对象编程",
            description: "类、结构体、协议",
            estimatedDuration: 180,
            timeScope: .weekly,
            orderIndex: 2
        )
        
        taskPlan.tasks = [task1, task2]
        branch.taskPlan = taskPlan
    }
    
    override func tearDown() {
        branch = nil
        taskPlan = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    func testBranchInitialization() {
        XCTAssertNotNil(branch.id)
        XCTAssertEqual(branch.name, "学习Swift编程")
        XCTAssertEqual(branch.description, "掌握Swift编程语言的基础和高级特性")
        XCTAssertEqual(branch.status, .active)
        XCTAssertEqual(branch.progress, 0.0)
        XCTAssertFalse(branch.isMaster)
        XCTAssertNil(branch.completedAt)
        XCTAssertTrue(branch.commits.isEmpty)
    }
    
    func testMasterBranchInitialization() {
        let masterBranch = Branch(
            name: "Master",
            description: "人生主干",
            isMaster: true
        )
        
        XCTAssertTrue(masterBranch.isMaster)
        XCTAssertEqual(masterBranch.name, "Master")
    }
    
    // MARK: - Progress Calculation Tests
    func testCompletedTasksCount() {
        XCTAssertEqual(branch.completedTasksCount, 0)
        
        // Mark first task as completed
        taskPlan.tasks[0].markAsCompleted()
        XCTAssertEqual(branch.completedTasksCount, 1)
        
        // Mark second task as completed
        taskPlan.tasks[1].markAsCompleted()
        XCTAssertEqual(branch.completedTasksCount, 2)
    }
    
    func testTotalTasksCount() {
        XCTAssertEqual(branch.totalTasksCount, 2)
        
        // Add another task
        let task3 = TaskItem(
            title: "构建实际项目",
            description: "应用所学知识",
            estimatedDuration: 300,
            timeScope: .monthly,
            orderIndex: 3
        )
        taskPlan.tasks.append(task3)
        
        XCTAssertEqual(branch.totalTasksCount, 3)
    }
    
    func testUpdateProgress() {
        // Initially no progress
        branch.updateProgress()
        XCTAssertEqual(branch.progress, 0.0)
        
        // Complete one task (50% progress)
        taskPlan.tasks[0].markAsCompleted()
        branch.updateProgress()
        XCTAssertEqual(branch.progress, 0.5, accuracy: 0.01)
        
        // Complete all tasks (100% progress)
        taskPlan.tasks[1].markAsCompleted()
        branch.updateProgress()
        XCTAssertEqual(branch.progress, 1.0, accuracy: 0.01)
    }
    
    func testUpdateProgressWithNoTasks() {
        // Branch with no task plan
        let emptyBranch = Branch(
            name: "Empty Branch",
            description: "No tasks"
        )
        
        emptyBranch.updateProgress()
        XCTAssertEqual(emptyBranch.progress, 0.0)
    }
    
    // MARK: - Status Tests
    func testBranchStatusTransitions() {
        // Start as active
        XCTAssertEqual(branch.status, .active)
        
        // Can transition to completed
        branch.status = .completed
        branch.completedAt = Date()
        XCTAssertEqual(branch.status, .completed)
        XCTAssertNotNil(branch.completedAt)
        
        // Can transition to abandoned
        branch.status = .abandoned
        XCTAssertEqual(branch.status, .abandoned)
    }
    
    // MARK: - Relationship Tests
    func testTaskPlanRelationship() {
        XCTAssertNotNil(branch.taskPlan)
        XCTAssertEqual(branch.taskPlan?.branchId, branch.id)
        XCTAssertEqual(branch.taskPlan?.tasks.count, 2)
    }
    
    func testCommitsRelationship() {
        let commit1 = Commit(
            message: "完成第一个任务",
            type: .taskComplete,
            branchId: branch.id
        )
        
        let commit2 = Commit(
            message: "学习心得记录",
            type: .learning,
            branchId: branch.id
        )
        
        branch.commits = [commit1, commit2]
        
        XCTAssertEqual(branch.commits.count, 2)
        XCTAssertEqual(branch.commits[0].message, "完成第一个任务")
        XCTAssertEqual(branch.commits[1].type, .learning)
    }
    
    // MARK: - Edge Cases Tests
    func testBranchWithEmptyName() {
        let emptyNameBranch = Branch(
            name: "",
            description: "Test branch"
        )
        
        XCTAssertEqual(emptyNameBranch.name, "")
        XCTAssertNotNil(emptyNameBranch.id)
    }
    
    func testBranchWithLongDescription() {
        let longDescription = String(repeating: "A", count: 1000)
        let longDescBranch = Branch(
            name: "Test",
            description: longDescription
        )
        
        XCTAssertEqual(longDescBranch.description.count, 1000)
    }
    
    // MARK: - Performance Tests
    func testProgressCalculationPerformance() {
        // Create branch with many tasks
        let largeBranch = Branch(
            name: "Large Branch",
            description: "Many tasks"
        )
        
        let largeTaskPlan = TaskPlan(
            branchId: largeBranch.id,
            totalDuration: "1年"
        )
        
        // Add 1000 tasks
        for i in 0..<1000 {
            let task = TaskItem(
                title: "Task \(i)",
                description: "Description \(i)",
                estimatedDuration: 30,
                timeScope: .daily,
                orderIndex: i
            )
            largeTaskPlan.tasks.append(task)
        }
        
        largeBranch.taskPlan = largeTaskPlan
        
        // Measure performance
        measure {
            largeBranch.updateProgress()
        }
    }
}