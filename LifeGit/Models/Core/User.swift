import Foundation
import SwiftData

@Model
class User {
    @Attribute(.unique) var id: UUID
    var currentVersion: String = "v1.0"
    var createdAt: Date = Date()
    var lastActiveAt: Date = Date()
    
    @Relationship(deleteRule: .cascade) var branches: [Branch] = []
    @Relationship(deleteRule: .cascade) var commits: [Commit] = []
    @Relationship(deleteRule: .cascade) var versionHistory: [VersionRecord] = []
    @Relationship(deleteRule: .cascade) var tags: [Tag] = []
    
    init(id: UUID = UUID(), currentVersion: String = "v1.0", createdAt: Date = Date()) {
        self.id = id
        self.currentVersion = currentVersion
        self.createdAt = createdAt
        self.lastActiveAt = createdAt
        
        // Create initial version record
        let initialVersion = VersionRecord(
            version: currentVersion,
            upgradedAt: createdAt,
            triggerBranchName: "Initial Setup",
            versionDescription: "Life Git journey begins"
        )
        self.versionHistory = [initialVersion]
    }
}