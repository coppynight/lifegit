import Foundation
import SwiftData

@Model
class VersionRecord {
    @Attribute(.unique) var id: UUID
    var version: String
    var upgradedAt: Date
    var triggerBranchName: String
    var versionDescription: String
    var isImportantMilestone: Bool
    var achievementCount: Int // Number of goals completed at this version
    var totalCommitsAtUpgrade: Int // Total commits when this version was reached
    
    @Relationship(inverse: \User.versionHistory) var user: User?
    
    init(id: UUID = UUID(), 
         version: String, 
         upgradedAt: Date = Date(), 
         triggerBranchName: String, 
         versionDescription: String,
         isImportantMilestone: Bool = false,
         achievementCount: Int = 0,
         totalCommitsAtUpgrade: Int = 0) {
        self.id = id
        self.version = version
        self.upgradedAt = upgradedAt
        self.triggerBranchName = triggerBranchName
        self.versionDescription = versionDescription
        self.isImportantMilestone = isImportantMilestone
        self.achievementCount = achievementCount
        self.totalCommitsAtUpgrade = totalCommitsAtUpgrade
    }
    
    // Helper computed properties
    var majorVersion: Int {
        let components = version.replacingOccurrences(of: "v", with: "").split(separator: ".")
        return Int(components.first ?? "1") ?? 1
    }
    
    var minorVersion: Int {
        let components = version.replacingOccurrences(of: "v", with: "").split(separator: ".")
        return components.count > 1 ? (Int(components[1]) ?? 0) : 0
    }
}