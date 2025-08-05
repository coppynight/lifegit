import Foundation
import SwiftData

/// Manager for commit-related operations
@MainActor
class CommitManager: ObservableObject {
    // MARK: - Published Properties
    @Published var isCreating = false
    @Published var isLoading = false
    @Published var error: CommitManagerError?
    
    // MARK: - Private Properties
    private let commitRepository: CommitRepository
    
    // MARK: - Initialization
    init(commitRepository: CommitRepository) {
        self.commitRepository = commitRepository
    }
    
    // MARK: - Commit Creation
    /// Create a new commit
    /// - Parameters:
    ///   - message: Commit message
    ///   - type: Type of commit
    ///   - branchId: ID of the branch to commit to
    /// - Returns: Created commit
    func createCommit(
        message: String,
        type: CommitType,
        branchId: UUID
    ) async throws -> Commit {
        guard !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CommitManagerError.invalidInput("提交信息不能为空")
        }
        
        isCreating = true
        defer { isCreating = false }
        
        do {
            let commit = Commit(
                message: message,
                type: type,
                branchId: branchId
            )
            
            try await commitRepository.create(commit)
            return commit
            
        } catch {
            self.error = CommitManagerError.creationFailed(error.localizedDescription)
            throw error
        }
    }
    
    /// Create a quick commit with predefined message
    /// - Parameters:
    ///   - type: Type of commit
    ///   - branchId: ID of the branch to commit to
    ///   - customMessage: Optional custom message, uses default if nil
    /// - Returns: Created commit
    func createQuickCommit(
        type: CommitType,
        branchId: UUID,
        customMessage: String? = nil
    ) async throws -> Commit {
        let message = customMessage ?? getDefaultMessage(for: type)
        return try await createCommit(message: message, type: type, branchId: branchId)
    }
    
    /// Create a task completion commit
    /// - Parameters:
    ///   - taskTitle: Title of the completed task
    ///   - branchId: ID of the branch
    /// - Returns: Created commit
    func createTaskCompletionCommit(
        taskTitle: String,
        branchId: UUID
    ) async throws -> Commit {
        let message = "✅ 完成任务: \(taskTitle)"
        return try await createCommit(message: message, type: .taskComplete, branchId: branchId)
    }
    
    /// Create a milestone commit
    /// - Parameters:
    ///   - milestone: Milestone description
    ///   - branchId: ID of the branch
    /// - Returns: Created commit
    func createMilestoneCommit(
        milestone: String,
        branchId: UUID
    ) async throws -> Commit {
        let message = "🏆 达成里程碑: \(milestone)"
        return try await createCommit(message: message, type: .milestone, branchId: branchId)
    }
    
    // MARK: - Commit Queries
    /// Get commits for a specific branch
    /// - Parameter branchId: Branch ID to get commits for
    /// - Returns: Array of commits
    func getCommits(for branchId: UUID) async throws -> [Commit] {
        isLoading = true
        defer { isLoading = false }
        
        do {
            return try await commitRepository.findByBranchId(branchId)
        } catch {
            self.error = CommitManagerError.queryFailed(error.localizedDescription)
            throw error
        }
    }
    
    /// Get commits by type for a branch
    /// - Parameters:
    ///   - branchId: Branch ID
    ///   - type: Commit type to filter by
    /// - Returns: Array of filtered commits
    func getCommits(for branchId: UUID, type: CommitType) async throws -> [Commit] {
        isLoading = true
        defer { isLoading = false }
        
        do {
            return try await commitRepository.findByBranchIdAndType(branchId, type: type)
        } catch {
            self.error = CommitManagerError.queryFailed(error.localizedDescription)
            throw error
        }
    }
    
    /// Get recent commits across all branches
    /// - Parameter count: Maximum number of commits to return
    /// - Returns: Array of recent commits
    func getRecentCommits(count: Int = 20) async throws -> [Commit] {
        isLoading = true
        defer { isLoading = false }
        
        do {
            return try await commitRepository.getRecentCommits(count: count)
        } catch {
            self.error = CommitManagerError.queryFailed(error.localizedDescription)
            throw error
        }
    }
    
    /// Get commits within a date range
    /// - Parameters:
    ///   - startDate: Start date of the range
    ///   - endDate: End date of the range
    ///   - branchId: Optional branch ID to filter by
    /// - Returns: Array of commits within the date range
    func getCommits(
        from startDate: Date,
        to endDate: Date,
        branchId: UUID? = nil
    ) async throws -> [Commit] {
        isLoading = true
        defer { isLoading = false }
        
        do {
            if let branchId = branchId {
                return try await commitRepository.findByBranchIdAndDateRange(
                    branchId,
                    from: startDate,
                    to: endDate
                )
            } else {
                return try await commitRepository.findByDateRange(
                    from: startDate,
                    to: endDate
                )
            }
        } catch {
            self.error = CommitManagerError.queryFailed(error.localizedDescription)
            throw error
        }
    }
    
    /// Search commits by content
    /// - Parameter searchText: Text to search for
    /// - Returns: Array of matching commits
    func searchCommits(_ searchText: String) async throws -> [Commit] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            return try await commitRepository.searchByContent(searchText)
        } catch {
            self.error = CommitManagerError.queryFailed(error.localizedDescription)
            throw error
        }
    }
    
    // MARK: - Commit Management
    /// Update an existing commit
    /// - Parameters:
    ///   - commit: Commit to update
    ///   - message: New message
    ///   - type: New type
    func updateCommit(
        _ commit: Commit,
        message: String,
        type: CommitType
    ) async throws {
        guard !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CommitManagerError.invalidInput("提交信息不能为空")
        }
        
        do {
            commit.message = message
            commit.type = type
            
            try await commitRepository.update(commit)
            
        } catch {
            self.error = CommitManagerError.updateFailed(error.localizedDescription)
            throw error
        }
    }
    
    /// Delete a commit
    /// - Parameter commit: Commit to delete
    func deleteCommit(_ commit: Commit) async throws {
        do {
            try await commitRepository.delete(id: commit.id)
        } catch {
            self.error = CommitManagerError.deletionFailed(error.localizedDescription)
            throw error
        }
    }
    
    // MARK: - Statistics
    /// Get commit statistics for a branch
    /// - Parameter branchId: Branch ID to get statistics for
    /// - Returns: Commit statistics
    func getCommitStatistics(for branchId: UUID) async throws -> CommitStatistics {
        do {
            let allCommits = try await commitRepository.findByBranchId(branchId)
            
            let taskCompleteCount = allCommits.filter { $0.type == .taskComplete }.count
            let learningCount = allCommits.filter { $0.type == .learning }.count
            let reflectionCount = allCommits.filter { $0.type == .reflection }.count
            let milestoneCount = allCommits.filter { $0.type == .milestone }.count
            
            // Calculate commit frequency (commits per day over last 30 days)
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            let recentCommits = allCommits.filter { $0.timestamp >= thirtyDaysAgo }
            let commitFrequency = Double(recentCommits.count) / 30.0
            
            // Find most active day of week
            let dayOfWeekCounts = Dictionary(grouping: allCommits) { commit in
                Calendar.current.component(.weekday, from: commit.timestamp)
            }.mapValues { $0.count }
            
            let mostActiveDay = dayOfWeekCounts.max(by: { $0.value < $1.value })?.key ?? 1
            
            return CommitStatistics(
                totalCommits: allCommits.count,
                taskCompleteCount: taskCompleteCount,
                learningCount: learningCount,
                reflectionCount: reflectionCount,
                milestoneCount: milestoneCount,
                commitFrequency: commitFrequency,
                mostActiveDay: mostActiveDay,
                firstCommitDate: allCommits.last?.timestamp,
                lastCommitDate: allCommits.first?.timestamp
            )
            
        } catch {
            throw CommitManagerError.statisticsCalculationFailed(error.localizedDescription)
        }
    }
    
    /// Get commit streak (consecutive days with commits)
    /// - Parameter branchId: Branch ID to calculate streak for
    /// - Returns: Current commit streak in days
    func getCommitStreak(for branchId: UUID) async throws -> Int {
        do {
            let commits = try await commitRepository.findByBranchId(branchId)
            
            guard !commits.isEmpty else { return 0 }
            
            let calendar = Calendar.current
            var streak = 0
            var currentDate = calendar.startOfDay(for: Date())
            
            // Group commits by date
            let commitsByDate = Dictionary(grouping: commits) { commit in
                calendar.startOfDay(for: commit.timestamp)
            }
            
            // Count consecutive days with commits
            while commitsByDate[currentDate] != nil {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            }
            
            return streak
            
        } catch {
            throw CommitManagerError.statisticsCalculationFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Helper Methods
    /// Get default message for commit type
    private func getDefaultMessage(for type: CommitType) -> String {
        switch type {
        case .taskComplete:
            return "✅ 完成了一项任务"
        case .learning:
            return "📚 学习了新知识"
        case .reflection:
            return "🌟 记录了一些思考"
        case .milestone:
            return "🏆 达成了一个里程碑"
        }
    }
    
    // MARK: - Error Handling
    func clearError() {
        error = nil
    }
}

// MARK: - Supporting Types

/// Commit statistics data
struct CommitStatistics {
    let totalCommits: Int
    let taskCompleteCount: Int
    let learningCount: Int
    let reflectionCount: Int
    let milestoneCount: Int
    let commitFrequency: Double // commits per day
    let mostActiveDay: Int // 1 = Sunday, 2 = Monday, etc.
    let firstCommitDate: Date?
    let lastCommitDate: Date?
    
    var mostActiveWeekdayName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.weekdaySymbols[mostActiveDay - 1]
    }
    
    var averageCommitsPerWeek: Double {
        commitFrequency * 7.0
    }
}

/// Commit manager specific errors
enum CommitManagerError: Error, LocalizedError {
    case creationFailed(String)
    case updateFailed(String)
    case deletionFailed(String)
    case queryFailed(String)
    case statisticsCalculationFailed(String)
    case invalidInput(String)
    
    var errorDescription: String? {
        switch self {
        case .creationFailed(let message):
            return "提交创建失败: \(message)"
        case .updateFailed(let message):
            return "提交更新失败: \(message)"
        case .deletionFailed(let message):
            return "提交删除失败: \(message)"
        case .queryFailed(let message):
            return "提交查询失败: \(message)"
        case .statisticsCalculationFailed(let message):
            return "统计计算失败: \(message)"
        case .invalidInput(let message):
            return "输入无效: \(message)"
        }
    }
}