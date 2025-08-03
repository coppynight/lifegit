import Foundation
import SwiftData

@Model
class User {
    @Attribute(.unique) var id: UUID
    var currentVersion: String
    var createdAt: Date
    var lastActiveAt: Date
    
    @Relationship(deleteRule: .cascade) var branches: [Branch] = []
    @Relationship(deleteRule: .cascade) var commits: [Commit] = []
    
    init(id: UUID = UUID(), currentVersion: String = "v1.0", createdAt: Date = Date()) {
        self.id = id
        self.currentVersion = currentVersion
        self.createdAt = createdAt
        self.lastActiveAt = createdAt
    }
}