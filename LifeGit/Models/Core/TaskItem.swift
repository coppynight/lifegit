import Foundation
import SwiftData

@Model
class TaskItem {
    @Attribute(.unique) var id: UUID
    var title: String
    var taskDescription: String
    var estimatedDuration: Int // 预估时长（分钟）
    var timeScope: TaskTimeScope // 时间维度：日、周、月
    var isAIGenerated: Bool = false // 是否由AI生成
    var orderIndex: Int // 任务顺序
    var isCompleted: Bool = false // 是否已完成
    var completedAt: Date? // 完成时间
    var createdAt: Date = Date()
    var lastModifiedAt: Date?
    var executionTips: String? // 执行建议
    
    @Relationship(inverse: \TaskPlan.tasks) var taskPlan: TaskPlan?
    
    init(id: UUID = UUID(),
         title: String,
         taskDescription: String,
         estimatedDuration: Int,
         timeScope: TaskTimeScope,
         isAIGenerated: Bool = false,
         orderIndex: Int,
         isCompleted: Bool = false,
         createdAt: Date = Date(),
         executionTips: String? = nil) {
        self.id = id
        self.title = title
        self.taskDescription = taskDescription
        self.estimatedDuration = estimatedDuration
        self.timeScope = timeScope
        self.isAIGenerated = isAIGenerated
        self.orderIndex = orderIndex
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.executionTips = executionTips
    }
    
    // 标记任务为完成
    func markAsCompleted() {
        isCompleted = true
        completedAt = Date()
        lastModifiedAt = Date()
    }
    
    // 取消完成状态
    func markAsIncomplete() {
        isCompleted = false
        completedAt = nil
        lastModifiedAt = Date()
    }
    
    // 格式化预估时长显示
    var formattedDuration: String {
        if estimatedDuration < 60 {
            return "\(estimatedDuration)分钟"
        } else {
            let hours = estimatedDuration / 60
            let minutes = estimatedDuration % 60
            if minutes == 0 {
                return "\(hours)小时"
            } else {
                return "\(hours)小时\(minutes)分钟"
            }
        }
    }
}