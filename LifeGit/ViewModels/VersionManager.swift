import Foundation
import SwiftData
import SwiftUI

@MainActor
class VersionManager: ObservableObject {
    @Published var pendingVersionUpgrade: PendingVersionUpgrade?
    @Published var isShowingUpgradeConfirmation = false
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Version Upgrade Logic
    
    /// Evaluates if a branch merge should trigger a version upgrade
    func evaluateBranchForVersionUpgrade(_ branch: Branch, user: User) async {
        let upgradeDecision = await analyzeVersionUpgradeEligibility(branch: branch, user: user)
        
        if upgradeDecision.shouldUpgrade {
            let pendingUpgrade = PendingVersionUpgrade(
                branch: branch,
                currentVersion: user.currentVersion,
                suggestedVersion: upgradeDecision.suggestedVersion,
                reason: upgradeDecision.reason,
                isImportantMilestone: upgradeDecision.isImportantMilestone
            )
            
            self.pendingVersionUpgrade = pendingUpgrade
            self.isShowingUpgradeConfirmation = true
        }
    }
    
    /// Analyzes whether a branch qualifies for version upgrade
    private func analyzeVersionUpgradeEligibility(branch: Branch, user: User) async -> VersionUpgradeDecision {
        // Criteria for version upgrade:
        // 1. Branch has significant number of commits (>= 10)
        // 2. Branch duration is substantial (>= 7 days)
        // 3. Branch has completed task plan with high completion rate
        // 4. Branch represents important life area (career, education, health, relationships)
        
        let commitCount = branch.commits.count
        let branchDuration = branch.createdAt.distance(to: Date()) / (24 * 3600) // days
        let taskCompletionRate = calculateTaskCompletionRate(branch)
        let isImportantLifeArea = identifyImportantLifeArea(branch)
        
        var score = 0
        var reasons: [String] = []
        
        // Scoring system
        if commitCount >= 10 {
            score += 3
            reasons.append("高频率记录 (\(commitCount) 次提交)")
        } else if commitCount >= 5 {
            score += 1
            reasons.append("持续记录 (\(commitCount) 次提交)")
        }
        
        if branchDuration >= 7 {
            score += 2
            reasons.append("长期坚持 (\(Int(branchDuration)) 天)")
        }
        
        if taskCompletionRate >= 0.8 {
            score += 3
            reasons.append("高完成度 (\(Int(taskCompletionRate * 100))%)")
        } else if taskCompletionRate >= 0.5 {
            score += 1
            reasons.append("良好进展 (\(Int(taskCompletionRate * 100))%)")
        }
        
        if isImportantLifeArea {
            score += 2
            reasons.append("重要人生领域")
        }
        
        let shouldUpgrade = score >= 5
        let isImportantMilestone = score >= 7
        
        let currentVersion = user.currentVersion
        let suggestedVersion = generateNextVersion(currentVersion: currentVersion, isImportantMilestone: isImportantMilestone)
        
        return VersionUpgradeDecision(
            shouldUpgrade: shouldUpgrade,
            suggestedVersion: suggestedVersion,
            reason: reasons.joined(separator: "、"),
            isImportantMilestone: isImportantMilestone,
            score: score
        )
    }
    
    /// Calculates task completion rate for a branch
    private func calculateTaskCompletionRate(_ branch: Branch) -> Double {
        guard let taskPlan = branch.taskPlan,
              !taskPlan.tasks.isEmpty else { return 0.0 }
        
        let completedTasks = taskPlan.tasks.filter { task in
            // Check if task has related completed commits
            return branch.commits.contains { commit in
                commit.relatedTaskId == task.id && commit.type == .taskComplete
            }
        }
        
        return Double(completedTasks.count) / Double(taskPlan.tasks.count)
    }
    
    /// Identifies if branch represents important life area
    private func identifyImportantLifeArea(_ branch: Branch) -> Bool {
        let importantKeywords = [
            // Career
            "工作", "职业", "事业", "升职", "跳槽", "创业", "技能",
            // Education
            "学习", "考试", "证书", "课程", "培训", "读书", "研究",
            // Health
            "健康", "运动", "健身", "减肥", "锻炼", "医疗", "养生",
            // Relationships
            "关系", "家庭", "朋友", "恋爱", "结婚", "社交", "沟通",
            // Finance
            "理财", "投资", "存钱", "买房", "财务", "收入",
            // Personal Growth
            "成长", "习惯", "目标", "梦想", "人生", "价值观"
        ]
        
        let branchText = (branch.name + " " + branch.branchDescription).lowercased()
        return importantKeywords.contains { keyword in
            branchText.contains(keyword)
        }
    }
    
    /// Generates next version number
    private func generateNextVersion(currentVersion: String, isImportantMilestone: Bool) -> String {
        let versionNumber = currentVersion.replacingOccurrences(of: "v", with: "")
        let components = versionNumber.split(separator: ".").compactMap { Int($0) }
        
        guard components.count >= 2 else {
            return isImportantMilestone ? "v2.0" : "v1.1"
        }
        
        let major = components[0]
        let minor = components[1]
        
        if isImportantMilestone {
            // Major version upgrade for important milestones
            return "v\(major + 1).0"
        } else {
            // Minor version upgrade for regular achievements
            return "v\(major).\(minor + 1)"
        }
    }
    
    // MARK: - Version Upgrade Execution
    
    /// Confirms and executes version upgrade
    func confirmVersionUpgrade() async {
        guard let pendingUpgrade = pendingVersionUpgrade else { return }
        
        do {
            try await executeVersionUpgrade(pendingUpgrade)
            
            // Clear pending upgrade
            self.pendingVersionUpgrade = nil
            self.isShowingUpgradeConfirmation = false
            
        } catch {
            print("Version upgrade failed: \(error)")
        }
    }
    
    /// Executes the version upgrade process
    private func executeVersionUpgrade(_ upgrade: PendingVersionUpgrade) async throws {
        // Find user
        let userDescriptor = FetchDescriptor<User>()
        let users = try modelContext.fetch(userDescriptor)
        guard let user = users.first else {
            throw VersionManagerError.userNotFound
        }
        
        // Update user version
        user.currentVersion = upgrade.suggestedVersion
        
        // Create version record
        let versionRecord = VersionRecord(
            version: upgrade.suggestedVersion,
            upgradedAt: Date(),
            triggerBranchName: upgrade.branch.name,
            versionDescription: upgrade.reason,
            isImportantMilestone: upgrade.isImportantMilestone,
            achievementCount: user.branches.filter { $0.status == .completed }.count,
            totalCommitsAtUpgrade: user.commits.count
        )
        
        user.versionHistory.append(versionRecord)
        
        // Save changes
        try modelContext.save()
        
        // Trigger celebration animation (will be implemented in UI layer)
        NotificationCenter.default.post(
            name: .versionUpgraded,
            object: versionRecord
        )
    }
    
    /// Declines version upgrade
    func declineVersionUpgrade() {
        pendingVersionUpgrade = nil
        isShowingUpgradeConfirmation = false
    }
    
    // MARK: - Version History Management
    
    /// Gets version history for a user
    func getVersionHistory(for user: User) -> [VersionRecord] {
        return user.versionHistory.sorted { $0.upgradedAt > $1.upgradedAt }
    }
    
    /// Gets current version info
    func getCurrentVersionInfo(for user: User) -> VersionRecord? {
        return user.versionHistory.first { $0.version == user.currentVersion }
    }
}

// MARK: - Supporting Types

struct PendingVersionUpgrade {
    let branch: Branch
    let currentVersion: String
    let suggestedVersion: String
    let reason: String
    let isImportantMilestone: Bool
}

struct VersionUpgradeDecision {
    let shouldUpgrade: Bool
    let suggestedVersion: String
    let reason: String
    let isImportantMilestone: Bool
    let score: Int
}

enum VersionManagerError: Error {
    case userNotFound
    case invalidVersionFormat
    case upgradeAlreadyInProgress
}

// MARK: - Notification Names

extension Notification.Name {
    static let versionUpgraded = Notification.Name("versionUpgraded")
}