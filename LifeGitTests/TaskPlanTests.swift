import XCTest
import SwiftData
@testable import LifeGit

/// Unit tests for TaskPlan model
final class TaskPlanTests: XCTestCase {
    
    // MARK: - Test Properties
    private var taskPlan: TaskPlan!
    private var branchId: UUID!
    
    // MARK: - Setup & Teardown
    override func setUp() {
        super.setUp()
        branchId = UUID()
        taskPlan = TaskPlan(
            branchId: branchId,
            totalDuration: "3周",
            isAIGenerated: true
        )
        
        // Add test tasks
        let task1 = TaskItem(
            title: "任务1",
            description: "第一个任务",
            estimatedDuration: 60,
            timeScope: .daily,
            orderIndex: 2
        )
        
        let task2 = TaskItem(
            title: "任务2",
            description: "第二个任务",
            estimatedDuration: 90,
            timeScope: .weekly,
            orderIndex: 1
        )
        
        let task3 = TaskItem(
            title: "任务3",
            description: "第三个任务",
            estimatedDuration: 120,
            timeScope: .monthly,
            orderIndex: 3
        )
        
        taskPlan.tasks = [task1, task2, task3]
    }
    
    override func tearDown() {
        taskPlan = nil
        branchId = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    func testTaskPlanInitialization() {
        XCTAssertNotNil(taskPlan.id)
        XCTAssertEqual(taskPlan.branchId, branchId)
        XCTAssertEqual(taskPlan.totalDuration, "3周")
        XCTAssertTrue(taskPlan.isAIGenerated)
        XCTAssertNotNil(taskPlan.createdAt)
        XCTAssertNil(taskPlan.lastModifiedAt)
        XCTAssertEqual(taskPlan.tasks.count, 3)
    }
    
    func testManualTaskPlanInitialization() {
        let manualPlan = TaskPlan(
            branchId: UUID(),
            totalDuration: "1个月",
            isAIGenerated: false
        )
        
        XCTAssertFalse(manualPlan.isAIGenerated)
        XCTAssertEqual(manualPlan.totalDuration, "1个月")
        XCTAssertTrue(manualPlan.tasks.isEmpty)
    }
    
    // MARK: - Ordered Tasks Tests
    func testOrderedTasks() {
        let orderedTasks = taskPlan.orderedTasks
        
        XCTAssertEqual(orderedTasks.count, 3)
        XCTAssertEqual(orderedTasks[0].title, "任务2") // orderIndex: 1
        XCTAssertEqual(orderedTasks[1].title, "任务1") // orderIndex: 2
        XCTAssertEqual(orderedTasks[2].title, "任务3") // orderIndex: 3
    }
    
    func testOrderedTasksWithSameIndex() {
        // Add tasks with same order index
        let task4 = TaskItem(
            title: "任务4",
            description: "第四个任务",
            estimatedDuration: 30,
            timeScope: .daily,
            orderIndex: 1 // Same as task2
        )
        
        taskPlan.tasks.append(task4)
        
        let orderedTasks = taskPlan.orderedTasks
        XCTAssertEqual(orderedTasks.count, 4)
        
        // Both tasks with orderIndex 1 should come first
        XCTAssertEqual(orderedTasks[0].orderIndex, 1)
        XCTAssertEqual(orderedTasks[1].orderIndex, 1)
    }
    
    func testOrderedTasksEmpty() {
        let emptyPlan = TaskPlan(
            branchId: UUID(),
            totalDuration: "未知"
        )
        
        XCTAssertTrue(emptyPlan.orderedTasks.isEmpty)
    }
    
    // MARK: - Completed Tasks Count Tests
    func testCompletedTasksCount() {
        XCTAssertEqual(taskPlan.completedTasksCount, 0)
        
        // Complete first task
        taskPlan.tasks[0].markAsCompleted()
        XCTAssertEqual(taskPlan.completedTasksCount, 1)
        
        // Complete second task
        taskPlan.tasks[1].markAsCompleted()
        XCTAssertEqual(taskPlan.completedTasksCount, 2)
        
        // Complete all tasks
        taskPlan.tasks[2].markAsCompleted()
        XCTAssertEqual(taskPlan.completedTasksCount, 3)
    }
    
    func testCompletedTasksCountWithToggle() {
        // Complete all tasks
        taskPlan.tasks.forEach { $0.markAsCompleted() }
        XCTAssertEqual(taskPlan.completedTasksCount, 3)
        
        // Mark one as incomplete
        taskPlan.tasks[0].markAsIncomplete()
        XCTAssertEqual(taskPlan.completedTasksCount, 2)
        
        // Mark another as incomplete
        taskPlan.tasks[1].markAsIncomplete()
        XCTAssertEqual(taskPlan.completedTasksCount, 1)
    }
    
    // MARK: - Total Estimated Duration Tests
    func testTotalEstimatedDuration() {
        // 60 + 90 + 120 = 270 minutes
        XCTAssertEqual(taskPlan.totalEstimatedDuration, 270)
    }
    
    func testTotalEstimatedDurationEmpty() {
        let emptyPlan = TaskPlan(
            branchId: UUID(),
            totalDuration: "未知"
        )
        
        XCTAssertEqual(emptyPlan.totalEstimatedDuration, 0)
    }
    
    func testTotalEstimatedDurationWithZeroDuration() {
        let task = TaskItem(
            title: "零时长任务",
            description: "不需要时间的任务",
            estimatedDuration: 0,
            timeScope: .daily,
            orderIndex: 1
        )
        
        taskPlan.tasks.append(task)
        
        // 60 + 90 + 120 + 0 = 270 minutes
        XCTAssertEqual(taskPlan.totalEstimatedDuration, 270)
    }
    
    // MARK: - Task Management Tests
    func testAddTask() {
        let initialCount = taskPlan.tasks.count
        
        let newTask = TaskItem(
            title: "新任务",
            description: "新添加的任务",
            estimatedDuration: 45,
            timeScope: .daily,
            orderIndex: 4
        )
        
        taskPlan.tasks.append(newTask)
        
        XCTAssertEqual(taskPlan.tasks.count, initialCount + 1)
        XCTAssertEqual(taskPlan.totalEstimatedDuration, 315) // 270 + 45
    }
    
    func testRemoveTask() {
        let initialCount = taskPlan.tasks.count
        let initialDuration = taskPlan.totalEstimatedDuration
        
        let removedTask = taskPlan.tasks.removeFirst()
        
        XCTAssertEqual(taskPlan.tasks.count, initialCount - 1)
        XCTAssertEqual(taskPlan.totalEstimatedDuration, initialDuration - removedTask.estimatedDuration)
    }
    
    func testClearAllTasks() {
        taskPlan.tasks.removeAll()
        
        XCTAssertTrue(taskPlan.tasks.isEmpty)
        XCTAssertEqual(taskPlan.completedTasksCount, 0)
        XCTAssertEqual(taskPlan.totalEstimatedDuration, 0)
        XCTAssertTrue(taskPlan.orderedTasks.isEmpty)
    }
    
    // MARK: - Modification Tracking Tests
    func testLastModifiedAtUpdate() {
        XCTAssertNil(taskPlan.lastModifiedAt)
        
        // Simulate modification
        taskPlan.lastModifiedAt = Date()
        
        XCTAssertNotNil(taskPlan.lastModifiedAt)
        
        let now = Date()
        let timeDifference = now.timeIntervalSince(taskPlan.lastModifiedAt!)
        XCTAssertLessThan(timeDifference, 1.0)
    }
    
    // MARK: - AI Generation Tests
    func testAIGeneratedFlag() {
        XCTAssertTrue(taskPlan.isAIGenerated)
        
        let manualPlan = TaskPlan(
            branchId: UUID(),
            totalDuration: "手动创建",
            isAIGenerated: false
        )
        
        XCTAssertFalse(manualPlan.isAIGenerated)
    }
    
    // MARK: - Edge Cases Tests
    func testEmptyTotalDuration() {
        let emptyDurationPlan = TaskPlan(
            branchId: UUID(),
            totalDuration: ""
        )
        
        XCTAssertEqual(emptyDurationPlan.totalDuration, "")
        XCTAssertNotNil(emptyDurationPlan.id)
    }
    
    func testVeryLongTotalDuration() {
        let longDuration = String(repeating: "很长的时间描述", count: 100)
        let longDurationPlan = TaskPlan(
            branchId: UUID(),
            totalDuration: longDuration
        )
        
        XCTAssertEqual(longDurationPlan.totalDuration.count, longDuration.count)
    }
    
    func testTaskPlanWithManyTasks() {
        let manyTasksPlan = TaskPlan(
            branchId: UUID(),
            totalDuration: "很长时间"
        )
        
        // Add 100 tasks
        for i in 0..<100 {
            let task = TaskItem(
                title: "任务\(i)",
                description: "描述\(i)",
                estimatedDuration: 30,
                timeScope: .daily,
                orderIndex: i
            )
            manyTasksPlan.tasks.append(task)
        }
        
        XCTAssertEqual(manyTasksPlan.tasks.count, 100)
        XCTAssertEqual(manyTasksPlan.totalEstimatedDuration, 3000) // 100 * 30
        XCTAssertEqual(manyTasksPlan.orderedTasks.count, 100)
    }
    
    // MARK: - Performance Tests
    func testOrderedTasksPerformance() {
        // Create plan with many tasks
        let largePlan = TaskPlan(
            branchId: UUID(),
            totalDuration: "很长时间"
        )
        
        // Add 1000 tasks with random order indices
        for i in 0..<1000 {
            let task = TaskItem(
                title: "任务\(i)",
                description: "描述\(i)",
                estimatedDuration: 30,
                timeScope: .daily,
                orderIndex: Int.random(in: 0...999)
            )
            largePlan.tasks.append(task)
        }
        
        measure {
            _ = largePlan.orderedTasks
        }
    }
    
    func testCompletedTasksCountPerformance() {
        // Create plan with many tasks
        let largePlan = TaskPlan(
            branchId: UUID(),
            totalDuration: "很长时间"
        )
        
        // Add 1000 tasks, half completed
        for i in 0..<1000 {
            let task = TaskItem(
                title: "任务\(i)",
                description: "描述\(i)",
                estimatedDuration: 30,
                timeScope: .daily,
                orderIndex: i
            )
            
            if i % 2 == 0 {
                task.markAsCompleted()
            }
            
            largePlan.tasks.append(task)
        }
        
        measure {
            _ = largePlan.completedTasksCount
        }
    }
    
    func testTotalEstimatedDurationPerformance() {
        // Create plan with many tasks
        let largePlan = TaskPlan(
            branchId: UUID(),
            totalDuration: "很长时间"
        )
        
        // Add 1000 tasks
        for i in 0..<1000 {
            let task = TaskItem(
                title: "任务\(i)",
                description: "描述\(i)",
                estimatedDuration: Int.random(in: 15...180),
                timeScope: .daily,
                orderIndex: i
            )
            largePlan.tasks.append(task)
        }
        
        measure {
            _ = largePlan.totalEstimatedDuration
        }
    }
}