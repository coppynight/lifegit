import Foundation
import SwiftData

@Model
class Branch {
    @Attribute(.unique) var id: UUID
    var name: String
    var branchDescription: String
    var status: BranchStatus
    var createdAt: Date
    var expectedCompletionDate: Date?
    var progress: Double // 0.0 - 1.0
    var parentBranchId: UUID? // 通常是master
    
    @Relationship(deleteRule: .cascade) var commits: [Commit] = []
    @Relationship(deleteRule: .cascade) var taskPlan: TaskPlan?
    @Relationship(inverse: \User.branches) var user: User?
    
    init(id: UUID = UUID(), name: String, branchDescription: String, 
         status: BranchStatus = .active, createdAt: Date = Date(),
         expectedCompletionDate: Date? = nil, progress: Double = 0.0,
         parentBranchId: UUID? = nil) {
        self.id = id
        self.name = name
        self.branchDescription = branchDescription
        self.status = status
        self.createdAt = createdAt
        self.expectedCompletionDate = expectedCompletionDate
        self.progress = progress
        self.parentBranchId = parentBranchId
    }
}