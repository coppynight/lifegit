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
    
    init(id: UUID = UUID(), branchId: UUID, tasks: [TaskItem] = [], 
         totalDuration: String, createdAt: Date = Date(), 
         isAIGenerated: Bool = false) {
        self.id = id
        self.branchId = branchId
        self.tasks = tasks
        self.totalDuration = totalDuration
        self.createdAt = createdAt
        self.isAIGenerated = isAIGenerated
    }
}