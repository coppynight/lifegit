import Foundation
import SwiftData

@Model
class TaskPlan {
    @Attribute(.unique) var id: UUID
    var branchId: UUID
    var totalDuration: String // 预计总时长描述
    var createdAt: Date
    var lastModifiedAt: Date?
    var isAIGenerated: Bool
    
    @Relationship(deleteRule: .cascade) var tasks: [TaskItem] = []
    @Relationship(inverse: \Branch.taskPlan) var branch: Branch?
    
    init(id: UUID = UUID(),
         branchId: UUID,
         totalDuration: String,
         createdAt: Date = Date(),
         isAIGenerated: Bool = false) {
        self.id = id
        self.branchId = branchId
        self.totalDuration = totalDuration
        self.createdAt = createdAt
        self.isAIGenerated = isAIGenerated
    }
    
    // 获取按顺序排列的任务
    var orderedTasks: [TaskItem] {
        tasks.sorted { $0.orderIndex < $1.orderIndex }
    }
    
    // 计算完成的任务数量
    var completedTasksCount: Int {
        tasks.filter { $0.isCompleted }.count
    }
    
    // 计算总预估时长（分钟）
    var totalEstimatedDuration: Int {
        tasks.reduce(0) { $0 + $1.estimatedDuration }
    }
}