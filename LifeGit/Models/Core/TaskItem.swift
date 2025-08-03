import Foundation
import SwiftData

@Model
class TaskItem {
    @Attribute(.unique) var id: UUID
    var title: String
    var taskDescription: String
    var estimatedDuration: Int // 预估时长（分钟）
    var timeScope: TaskTimeScope // 时间维度：日、周、月
    var isAIGenerated: Bool // 是否由AI生成
    var orderIndex: Int // 任务顺序
    var isCompleted: Bool // 是否已完成
    var completedAt: Date? // 完成时间
    
    @Relationship(inverse: \TaskPlan.tasks) var taskPlan: TaskPlan?
    
    init(id: UUID = UUID(), title: String, taskDescription: String, 
         estimatedDuration: Int, timeScope: TaskTimeScope, 
         isAIGenerated: Bool, orderIndex: Int, isCompleted: Bool = false,
         completedAt: Date? = nil) {
        self.id = id
        self.title = title
        self.taskDescription = taskDescription
        self.estimatedDuration = estimatedDuration
        self.timeScope = timeScope
        self.isAIGenerated = isAIGenerated
        self.orderIndex = orderIndex
        self.isCompleted = isCompleted
        self.completedAt = completedAt
    }
}