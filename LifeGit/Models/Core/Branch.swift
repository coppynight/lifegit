import Foundation
import SwiftData

@Model
class Branch {
    @Attribute(.unique) var id: UUID
    var name: String
    var description: String
    var status: BranchStatus
    var createdAt: Date
    var completedAt: Date?
    var expectedCompletionDate: Date?
    var progress: Double // 0.0 - 1.0
    var parentBranchId: UUID? // 通常是master分支的ID
    var isMaster: Bool // 标识是否为主干分支
    
    @Relationship(deleteRule: .cascade) var commits: [Commit] = []
    @Relationship(deleteRule: .cascade) var taskPlan: TaskPlan?
    @Relationship(inverse: \User.branches) var user: User?
    
    init(id: UUID = UUID(), 
         name: String, 
         description: String, 
         status: BranchStatus = .active,
         createdAt: Date = Date(),
         expectedCompletionDate: Date? = nil,
         progress: Double = 0.0,
         parentBranchId: UUID? = nil,
         isMaster: Bool = false) {
        self.id = id
        self.name = name
        self.description = description
        self.status = status
        self.createdAt = createdAt
        self.expectedCompletionDate = expectedCompletionDate
        self.progress = progress
        self.parentBranchId = parentBranchId
        self.isMaster = isMaster
    }
    
    // 计算完成的任务数量
    var completedTasksCount: Int {
        taskPlan?.tasks.filter { $0.isCompleted }.count ?? 0
    }
    
    // 计算总任务数量
    var totalTasksCount: Int {
        taskPlan?.tasks.count ?? 0
    }
    
    // 更新进度
    func updateProgress() {
        guard totalTasksCount > 0 else {
            progress = 0.0
            return
        }
        progress = Double(completedTasksCount) / Double(totalTasksCount)
    }
}