import XCTest
import SwiftData
@testable import LifeGit

/// Unit tests for TaskItem model
final class TaskItemTests: XCTestCase {
    
    // MARK: - Test Properties
    private var taskItem: TaskItem!
    
    // MARK: - Setup & Teardown
    override func setUp() {
        super.setUp()
        taskItem = TaskItem(
            title: "学习SwiftUI基础",
            description: "掌握SwiftUI的基本组件和布局",
            estimatedDuration: 120,
            timeScope: .daily,
            isAIGenerated: true,
            orderIndex: 1
        )
    }
    
    override func tearDown() {
        taskItem = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    func testTaskItemInitialization() {
        XCTAssertNotNil(taskItem.id)
        XCTAssertEqual(taskItem.title, "学习SwiftUI基础")
        XCTAssertEqual(taskItem.description, "掌握SwiftUI的基本组件和布局")
        XCTAssertEqual(taskItem.estimatedDuration, 120)
        XCTAssertEqual(taskItem.timeScope, .daily)
        XCTAssertTrue(taskItem.isAIGenerated)
        XCTAssertEqual(taskItem.orderIndex, 1)
        XCTAssertFalse(taskItem.isCompleted)
        XCTAssertNil(taskItem.completedAt)
        XCTAssertNotNil(taskItem.createdAt)
    }
    
    func testManualTaskItemInitialization() {
        let manualTask = TaskItem(
            title: "手动创建的任务",
            description: "用户手动添加的任务",
            estimatedDuration: 60,
            timeScope: .weekly,
            isAIGenerated: false,
            orderIndex: 2
        )
        
        XCTAssertFalse(manualTask.isAIGenerated)
        XCTAssertEqual(manualTask.timeScope, .weekly)
    }
    
    // MARK: - Completion Tests
    func testMarkAsCompleted() {
        XCTAssertFalse(taskItem.isCompleted)
        XCTAssertNil(taskItem.completedAt)
        
        taskItem.markAsCompleted()
        
        XCTAssertTrue(taskItem.isCompleted)
        XCTAssertNotNil(taskItem.completedAt)
        XCTAssertNotNil(taskItem.lastModifiedAt)
        
        // Check that completion time is recent
        let now = Date()
        let timeDifference = now.timeIntervalSince(taskItem.completedAt!)
        XCTAssertLessThan(timeDifference, 1.0) // Within 1 second
    }
    
    func testMarkAsIncomplete() {
        // First complete the task
        taskItem.markAsCompleted()
        XCTAssertTrue(taskItem.isCompleted)
        XCTAssertNotNil(taskItem.completedAt)
        
        // Then mark as incomplete
        taskItem.markAsIncomplete()
        
        XCTAssertFalse(taskItem.isCompleted)
        XCTAssertNil(taskItem.completedAt)
        XCTAssertNotNil(taskItem.lastModifiedAt)
    }
    
    func testMultipleCompletionToggle() {
        // Toggle completion multiple times
        for _ in 0..<5 {
            taskItem.markAsCompleted()
            XCTAssertTrue(taskItem.isCompleted)
            
            taskItem.markAsIncomplete()
            XCTAssertFalse(taskItem.isCompleted)
        }
    }
    
    // MARK: - Duration Formatting Tests
    func testFormattedDurationMinutes() {
        taskItem.estimatedDuration = 30
        XCTAssertEqual(taskItem.formattedDuration, "30分钟")
        
        taskItem.estimatedDuration = 59
        XCTAssertEqual(taskItem.formattedDuration, "59分钟")
    }
    
    func testFormattedDurationHours() {
        taskItem.estimatedDuration = 60
        XCTAssertEqual(taskItem.formattedDuration, "1小时")
        
        taskItem.estimatedDuration = 120
        XCTAssertEqual(taskItem.formattedDuration, "2小时")
        
        taskItem.estimatedDuration = 180
        XCTAssertEqual(taskItem.formattedDuration, "3小时")
    }
    
    func testFormattedDurationHoursAndMinutes() {
        taskItem.estimatedDuration = 90
        XCTAssertEqual(taskItem.formattedDuration, "1小时30分钟")
        
        taskItem.estimatedDuration = 135
        XCTAssertEqual(taskItem.formattedDuration, "2小时15分钟")
        
        taskItem.estimatedDuration = 245
        XCTAssertEqual(taskItem.formattedDuration, "4小时5分钟")
    }
    
    func testFormattedDurationZero() {
        taskItem.estimatedDuration = 0
        XCTAssertEqual(taskItem.formattedDuration, "0分钟")
    }
    
    // MARK: - Time Scope Tests
    func testTimeScopeValues() {
        taskItem.timeScope = .daily
        XCTAssertEqual(taskItem.timeScope, .daily)
        XCTAssertEqual(taskItem.timeScope.displayName, "每日任务")
        
        taskItem.timeScope = .weekly
        XCTAssertEqual(taskItem.timeScope, .weekly)
        XCTAssertEqual(taskItem.timeScope.displayName, "每周任务")
        
        taskItem.timeScope = .monthly
        XCTAssertEqual(taskItem.timeScope, .monthly)
        XCTAssertEqual(taskItem.timeScope.displayName, "每月任务")
    }
    
    // MARK: - Execution Tips Tests
    func testExecutionTips() {
        XCTAssertNil(taskItem.executionTips)
        
        let tips = "建议在早上精力充沛时完成这个任务"
        taskItem.executionTips = tips
        
        XCTAssertEqual(taskItem.executionTips, tips)
    }
    
    // MARK: - Order Index Tests
    func testOrderIndex() {
        XCTAssertEqual(taskItem.orderIndex, 1)
        
        taskItem.orderIndex = 5
        XCTAssertEqual(taskItem.orderIndex, 5)
        
        // Test negative order index
        taskItem.orderIndex = -1
        XCTAssertEqual(taskItem.orderIndex, -1)
    }
    
    // MARK: - Edge Cases Tests
    func testEmptyTitle() {
        let emptyTitleTask = TaskItem(
            title: "",
            description: "Valid description",
            estimatedDuration: 30,
            timeScope: .daily,
            orderIndex: 1
        )
        
        XCTAssertEqual(emptyTitleTask.title, "")
        XCTAssertNotNil(emptyTitleTask.id)
    }
    
    func testEmptyDescription() {
        let emptyDescTask = TaskItem(
            title: "Valid title",
            description: "",
            estimatedDuration: 30,
            timeScope: .daily,
            orderIndex: 1
        )
        
        XCTAssertEqual(emptyDescTask.description, "")
        XCTAssertNotNil(emptyDescTask.id)
    }
    
    func testNegativeDuration() {
        let negDurationTask = TaskItem(
            title: "Test task",
            description: "Test description",
            estimatedDuration: -30,
            timeScope: .daily,
            orderIndex: 1
        )
        
        XCTAssertEqual(negDurationTask.estimatedDuration, -30)
        // Note: In a real app, you might want to validate this in the initializer
    }
    
    func testVeryLargeDuration() {
        let largeDurationTask = TaskItem(
            title: "Long task",
            description: "Very long task",
            estimatedDuration: 10080, // 1 week in minutes
            timeScope: .monthly,
            orderIndex: 1
        )
        
        XCTAssertEqual(largeDurationTask.estimatedDuration, 10080)
        XCTAssertEqual(largeDurationTask.formattedDuration, "168小时")
    }
    
    // MARK: - Date Tests
    func testCreatedAtIsRecent() {
        let now = Date()
        let timeDifference = now.timeIntervalSince(taskItem.createdAt)
        XCTAssertLessThan(timeDifference, 1.0) // Within 1 second
    }
    
    func testLastModifiedAtUpdates() {
        XCTAssertNil(taskItem.lastModifiedAt)
        
        taskItem.markAsCompleted()
        XCTAssertNotNil(taskItem.lastModifiedAt)
        
        let firstModification = taskItem.lastModifiedAt!
        
        // Wait a tiny bit and modify again
        Thread.sleep(forTimeInterval: 0.01)
        taskItem.markAsIncomplete()
        
        XCTAssertNotNil(taskItem.lastModifiedAt)
        XCTAssertGreaterThan(taskItem.lastModifiedAt!, firstModification)
    }
    
    // MARK: - Performance Tests
    func testCompletionTogglePerformance() {
        measure {
            for _ in 0..<1000 {
                taskItem.markAsCompleted()
                taskItem.markAsIncomplete()
            }
        }
    }
    
    func testFormattedDurationPerformance() {
        measure {
            for duration in 1...1000 {
                taskItem.estimatedDuration = duration
                _ = taskItem.formattedDuration
            }
        }
    }
}