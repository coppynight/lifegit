import Foundation
import SwiftData

@Model
class Commit {
    @Attribute(.unique) var id: UUID
    var message: String
    var type: CommitType
    var timestamp: Date = Date()
    var branchId: UUID
    var relatedTaskId: UUID? // 关联的任务项ID（如果有）
    
    @Relationship(inverse: \Branch.commits) var branch: Branch?
    @Relationship(inverse: \User.commits) var user: User?
    
    init(id: UUID = UUID(),
         message: String,
         type: CommitType,
         timestamp: Date = Date(),
         branchId: UUID,
         relatedTaskId: UUID? = nil) {
        self.id = id
        self.message = message
        self.type = type
        self.timestamp = timestamp
        self.branchId = branchId
        self.relatedTaskId = relatedTaskId
    }
}