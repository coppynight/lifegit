import Foundation
import SwiftData

/// Manager for collecting and analyzing user behavior statistics
@MainActor
class StatisticsManager: ObservableObject {
    // MARK: - Published Properties
    @Published var isCalculating = false
    @Published var error: StatisticsError?
    @Published var cachedStatistics: UserStatistics?
    @Published var lastUpdateTime: Date?
    
    // MARK: - Private Properties
    private let modelContext: ModelContext
    private let branchRepository: BranchRepository
    private let commitRepository: CommitRepository
    private let taskPlanRepository: TaskPlanRepository
    private let cache: StatisticsCache
    
    // Cache configuration
    private let cacheExpirationInterval: TimeInterval = 300 // 5 minutes
    
    // MARK: - Initialization
    init(
        modelContext: ModelContext,
        branchRepository: BranchRepository,
        commitRepository: CommitRepository,
        taskPlanRepository: TaskPlanRepository,
        cache: StatisticsCache? = nil
    ) {
        self.modelContext = modelContext
        self.branchRepository = branchRepository
        self.commitRepository = commitRepository
        self.taskPlanRepository = taskPlanRepository
        self.cache = cache ?? StatisticsCache()
    }
    
    // MARK: - Main Statistics Collection
    
    /// Collect comprehensive user statistics
    /// - Parameter forceRefresh: Whether to force refresh cached data
    /// - Returns: Complete user statistics
    func collectUserStatistics(forceRefresh: Bool = false) async throws -> UserStatistics {
        // Check cache validity
        if !forceRefresh, let cached = cache.retrieveUserStatistics() {
            cachedStatistics = cached
            return cached
        }
        
        isCalculating = true
        defer { isCalculating = false }
        
        do {
            // Collect all data in parallel for better performance
            async let branchStats = collectBranchStatistics()
            async let commitStats = collectCommitStatistics()
            async let goalStats = collectGoalCompletionStatistics()
            async let activityStats = collectActivityStatistics()
            async let streakStats = collectStreakStatistics()
            
            let statistics = UserStatistics(
                branchStatistics: try await branchStats,
                commitStatistics: try await commitStats,
                goalCompletionStatistics: try await goalStats,
                activityStatistics: try await activityStats,
                streakStatistics: try await streakStats,
                lastUpdated: Date()
            )
            
            // Cache the results
            cachedStatistics = statistics
            lastUpdateTime = Date()
            cache.storeUserStatistics(statistics)
            
            return statistics
            
        } catch {
            self.error = StatisticsError.calculationFailed(error.localizedDescription)
            throw error
        }
    }
    
    // MARK: - Branch Statistics
    
    /// Collect branch-related statistics
    private func collectBranchStatistics() async throws -> BranchStatistics {
        let allBranches = try await branchRepository.findAll()
        
        let activeBranches = allBranches.filter { $0.status == .active && !$0.isMaster }
        let completedBranches = allBranches.filter { $0.status == .completed }
        let abandonedBranches = allBranches.filter { $0.status == .abandoned }
        
        // Calculate average completion time for completed branches
        let completedBranchesWithDuration = completedBranches.compactMap { branch -> TimeInterval? in
            guard let completedAt = branch.completedAt else { return nil }
            return completedAt.timeIntervalSince(branch.createdAt)
        }
        
        let averageCompletionTime = completedBranchesWithDuration.isEmpty ? 0 :
            completedBranchesWithDuration.reduce(0, +) / Double(completedBranchesWithDuration.count)
        
        // Calculate success rate
        let totalGoalBranches = completedBranches.count + abandonedBranches.count
        let successRate = totalGoalBranches > 0 ? Double(completedBranches.count) / Double(totalGoalBranches) : 0.0
        
        // Find most productive time periods
        let branchCreationTimes = allBranches.map { $0.createdAt }
        let mostProductiveMonth = findMostProductiveMonth(from: branchCreationTimes)
        let mostProductiveWeekday = findMostProductiveWeekday(from: branchCreationTimes)
        
        return BranchStatistics(
            totalBranches: allBranches.count,
            activeBranches: activeBranches.count,
            completedBranches: completedBranches.count,
            abandonedBranches: abandonedBranches.count,
            averageCompletionTime: averageCompletionTime,
            successRate: successRate,
            mostProductiveMonth: mostProductiveMonth,
            mostProductiveWeekday: mostProductiveWeekday
        )
    }
    
    // MARK: - Commit Statistics
    
    /// Collect commit-related statistics
    private func collectCommitStatistics() async throws -> CommitStatistics {
        let allCommits = try await commitRepository.findAll()
        
        // Group commits by type
        let commitsByType = Dictionary(grouping: allCommits) { $0.type }
        
        // Calculate commit frequency (commits per day over different periods)
        let now = Date()
        let calendar = Calendar.current
        
        // Last 7 days
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        let weeklyCommits = allCommits.filter { $0.timestamp >= weekAgo }
        let weeklyFrequency = Double(weeklyCommits.count) / 7.0
        
        // Last 30 days
        let monthAgo = calendar.date(byAdding: .day, value: -30, to: now) ?? now
        let monthlyCommits = allCommits.filter { $0.timestamp >= monthAgo }
        let monthlyFrequency = Double(monthlyCommits.count) / 30.0
        
        // Find most active time patterns
        let mostActiveHour = findMostActiveHour(from: allCommits)
        let mostActiveWeekday = findMostActiveWeekday(from: allCommits.map { $0.timestamp })
        
        // Calculate type distribution
        let typeDistribution = CommitType.allCases.map { type in
            CommitTypeDistribution(
                type: type,
                count: commitsByType[type]?.count ?? 0,
                percentage: allCommits.isEmpty ? 0.0 : Double(commitsByType[type]?.count ?? 0) / Double(allCommits.count)
            )
        }.sorted { $0.count > $1.count }
        
        return CommitStatistics(
            totalCommits: allCommits.count,
            weeklyFrequency: weeklyFrequency,
            monthlyFrequency: monthlyFrequency,
            averageCommitsPerDay: monthlyFrequency,
            typeDistribution: typeDistribution,
            mostActiveHour: mostActiveHour,
            mostActiveWeekday: mostActiveWeekday,
            firstCommitDate: allCommits.last?.timestamp,
            lastCommitDate: allCommits.first?.timestamp
        )
    }
    
    // MARK: - Goal Completion Statistics
    
    /// Collect goal completion statistics
    private func collectGoalCompletionStatistics() async throws -> GoalCompletionStatistics {
        let allBranches = try await branchRepository.findAll()
        let goalBranches = allBranches.filter { !$0.isMaster }
        
        let completedGoals = goalBranches.filter { $0.status == .completed }
        let activeGoals = goalBranches.filter { $0.status == .active }
        let abandonedGoals = goalBranches.filter { $0.status == .abandoned }
        
        // Calculate completion rate
        let totalGoals = goalBranches.count
        let completionRate = totalGoals > 0 ? Double(completedGoals.count) / Double(totalGoals) : 0.0
        
        // Calculate average progress of active goals
        let activeGoalProgresses = activeGoals.compactMap { branch -> Double? in
            guard let taskPlan = branch.taskPlan else { return nil }
            let totalTasks = taskPlan.tasks.count
            let completedTasks = taskPlan.tasks.filter { $0.isCompleted }.count
            return totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) : 0.0
        }
        
        let averageActiveProgress = activeGoalProgresses.isEmpty ? 0.0 :
            activeGoalProgresses.reduce(0, +) / Double(activeGoalProgresses.count)
        
        // Find completion patterns
        let completionsByMonth = Dictionary(grouping: completedGoals) { goal in
            Calendar.current.component(.month, from: goal.completedAt ?? goal.createdAt)
        }
        
        let mostProductiveMonth = completionsByMonth.max { $0.value.count < $1.value.count }?.key ?? 1
        
        // Calculate task completion statistics
        let allTaskPlans = try await taskPlanRepository.findAll()
        let allTasks = allTaskPlans.flatMap { $0.tasks }
        let completedTasks = allTasks.filter { $0.isCompleted }
        
        let taskCompletionRate = allTasks.isEmpty ? 0.0 : Double(completedTasks.count) / Double(allTasks.count)
        
        return GoalCompletionStatistics(
            totalGoals: totalGoals,
            completedGoals: completedGoals.count,
            activeGoals: activeGoals.count,
            abandonedGoals: abandonedGoals.count,
            completionRate: completionRate,
            averageActiveProgress: averageActiveProgress,
            mostProductiveMonth: mostProductiveMonth,
            totalTasks: allTasks.count,
            completedTasks: completedTasks.count,
            taskCompletionRate: taskCompletionRate
        )
    }
    
    // MARK: - Activity Statistics
    
    /// Collect user activity statistics
    private func collectActivityStatistics() async throws -> ActivityStatistics {
        let allCommits = try await commitRepository.findAll()
        let allBranches = try await branchRepository.findAll()
        
        let calendar = Calendar.current
        let now = Date()
        
        // Calculate activity over different time periods
        let last7Days = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        let last30Days = calendar.date(byAdding: .day, value: -30, to: now) ?? now
        let last90Days = calendar.date(byAdding: .day, value: -90, to: now) ?? now
        
        let commitsLast7Days = allCommits.filter { $0.timestamp >= last7Days }.count
        let commitsLast30Days = allCommits.filter { $0.timestamp >= last30Days }.count
        let commitsLast90Days = allCommits.filter { $0.timestamp >= last90Days }.count
        
        let branchesLast7Days = allBranches.filter { $0.createdAt >= last7Days }.count
        let branchesLast30Days = allBranches.filter { $0.createdAt >= last30Days }.count
        let branchesLast90Days = allBranches.filter { $0.createdAt >= last90Days }.count
        
        // Calculate activity score (weighted combination of commits and branches)
        let activityScore = calculateActivityScore(
            commitsLast30Days: commitsLast30Days,
            branchesLast30Days: branchesLast30Days
        )
        
        // Find activity patterns
        let dailyActivity = calculateDailyActivityPattern(from: allCommits)
        let weeklyActivity = calculateWeeklyActivityPattern(from: allCommits)
        
        return ActivityStatistics(
            commitsLast7Days: commitsLast7Days,
            commitsLast30Days: commitsLast30Days,
            commitsLast90Days: commitsLast90Days,
            branchesLast7Days: branchesLast7Days,
            branchesLast30Days: branchesLast30Days,
            branchesLast90Days: branchesLast90Days,
            activityScore: activityScore,
            dailyActivityPattern: dailyActivity,
            weeklyActivityPattern: weeklyActivity
        )
    }
    
    // MARK: - Streak Statistics
    
    /// Collect streak statistics
    private func collectStreakStatistics() async throws -> StreakStatistics {
        let allCommits = try await commitRepository.findAll()
        
        // Calculate current commit streak
        let currentStreak = calculateCurrentCommitStreak(from: allCommits)
        let longestStreak = calculateLongestCommitStreak(from: allCommits)
        
        // Calculate goal completion streaks
        let completedBranches = try await branchRepository.findByStatus(.completed)
        let currentGoalStreak = calculateCurrentGoalStreak(from: completedBranches)
        let longestGoalStreak = calculateLongestGoalStreak(from: completedBranches)
        
        return StreakStatistics(
            currentCommitStreak: currentStreak,
            longestCommitStreak: longestStreak,
            currentGoalStreak: currentGoalStreak,
            longestGoalStreak: longestGoalStreak
        )
    }
    
    // MARK: - Helper Methods
    
    /// Check if cached statistics are still valid
    private func isCacheValid() -> Bool {
        guard let lastUpdate = lastUpdateTime else { return false }
        return Date().timeIntervalSince(lastUpdate) < cacheExpirationInterval
    }
    
    /// Find the most productive month based on dates
    private func findMostProductiveMonth(from dates: [Date]) -> Int {
        let monthCounts = Dictionary(grouping: dates) { date in
            Calendar.current.component(.month, from: date)
        }
        return monthCounts.max { $0.value.count < $1.value.count }?.key ?? 1
    }
    
    /// Find the most productive weekday based on dates
    private func findMostProductiveWeekday(from dates: [Date]) -> Int {
        let weekdayCounts = Dictionary(grouping: dates) { date in
            Calendar.current.component(.weekday, from: date)
        }
        return weekdayCounts.max { $0.value.count < $1.value.count }?.key ?? 1
    }
    
    /// Find the most active hour based on commits
    private func findMostActiveHour(from commits: [Commit]) -> Int {
        let hourCounts = Dictionary(grouping: commits) { commit in
            Calendar.current.component(.hour, from: commit.timestamp)
        }
        return hourCounts.max { $0.value.count < $1.value.count }?.key ?? 12
    }
    
    /// Calculate activity score based on recent activity
    private func calculateActivityScore(commitsLast30Days: Int, branchesLast30Days: Int) -> Double {
        // Weighted score: commits have weight 1, branches have weight 5
        let commitScore = Double(commitsLast30Days)
        let branchScore = Double(branchesLast30Days) * 5.0
        
        // Normalize to 0-100 scale
        let totalScore = commitScore + branchScore
        return min(100.0, totalScore * 2.0) // Scale factor to make 50 activities = 100 score
    }
    
    /// Calculate daily activity pattern (24 hours)
    private func calculateDailyActivityPattern(from commits: [Commit]) -> [Int] {
        var hourlyActivity = Array(repeating: 0, count: 24)
        
        for commit in commits {
            let hour = Calendar.current.component(.hour, from: commit.timestamp)
            hourlyActivity[hour] += 1
        }
        
        return hourlyActivity
    }
    
    /// Calculate weekly activity pattern (7 days)
    private func calculateWeeklyActivityPattern(from commits: [Commit]) -> [Int] {
        var weeklyActivity = Array(repeating: 0, count: 7)
        
        for commit in commits {
            let weekday = Calendar.current.component(.weekday, from: commit.timestamp) - 1 // 0-6
            weeklyActivity[weekday] += 1
        }
        
        return weeklyActivity
    }
    
    /// Calculate current commit streak
    private func calculateCurrentCommitStreak(from commits: [Commit]) -> Int {
        guard !commits.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let sortedCommits = commits.sorted { $0.timestamp > $1.timestamp }
        
        // Group commits by date
        let commitsByDate = Dictionary(grouping: sortedCommits) { commit in
            calendar.startOfDay(for: commit.timestamp)
        }
        
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        // Count consecutive days with commits
        while commitsByDate[currentDate] != nil {
            streak += 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        }
        
        return streak
    }
    
    /// Calculate longest commit streak
    private func calculateLongestCommitStreak(from commits: [Commit]) -> Int {
        guard !commits.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let sortedCommits = commits.sorted { $0.timestamp < $1.timestamp }
        
        // Get unique dates with commits
        let commitDates = Set(sortedCommits.map { calendar.startOfDay(for: $0.timestamp) })
            .sorted()
        
        var longestStreak = 0
        var currentStreak = 1
        
        for i in 1..<commitDates.count {
            let previousDate = commitDates[i - 1]
            let currentDate = commitDates[i]
            
            if calendar.dateInterval(of: .day, for: currentDate)?.start ==
               calendar.date(byAdding: .day, value: 1, to: previousDate) {
                currentStreak += 1
            } else {
                longestStreak = max(longestStreak, currentStreak)
                currentStreak = 1
            }
        }
        
        return max(longestStreak, currentStreak)
    }
    
    /// Calculate current goal completion streak
    private func calculateCurrentGoalStreak(from branches: [Branch]) -> Int {
        let completedBranches = branches
            .filter { $0.completedAt != nil }
            .sorted { ($0.completedAt ?? Date.distantPast) > ($1.completedAt ?? Date.distantPast) }
        
        // For simplicity, count consecutive completed goals
        return completedBranches.count
    }
    
    /// Calculate longest goal completion streak
    private func calculateLongestGoalStreak(from branches: [Branch]) -> Int {
        // This is a simplified implementation
        // In a more sophisticated version, we would track streaks over time periods
        return calculateCurrentGoalStreak(from: branches)
    }
    
    // MARK: - Cache Management
    
    /// Clear cached statistics
    func clearCache() {
        cachedStatistics = nil
        lastUpdateTime = nil
        cache.clearAll()
    }
    
    /// Force refresh statistics
    func refreshStatistics() async throws -> UserStatistics {
        return try await collectUserStatistics(forceRefresh: true)
    }
    
    // MARK: - Error Handling
    
    func clearError() {
        error = nil
    }
   
    // MARK: - Specific Statistics Collection
    
    /// Get statistics for a specific branch
    /// - Parameter branchId: Branch ID to get statistics for
    /// - Returns: Branch-specific statistics
    func getBranchStatistics(for branchId: UUID) async throws -> BranchSpecificStatistics {
        // Check cache first
        if let cached = cache.retrieveBranchStatistics(forBranch: branchId) {
            return BranchSpecificStatistics(
                branchId: branchId,
                commitCount: 0, // Will be filled from cache
                taskProgress: 0.0,
                timeSpent: 0,
                lastActivity: Date()
            )
        }
        
        do {
            let commits = try await commitRepository.findByBranchId(branchId)
            let branch = try await branchRepository.findById(branchId)
            
            let commitCount = commits.count
            let taskProgress = branch?.progress ?? 0.0
            
            // Calculate time spent (rough estimate based on commits)
            let timeSpent = calculateTimeSpent(from: commits)
            let lastActivity = commits.first?.timestamp ?? Date.distantPast
            
            let statistics = BranchSpecificStatistics(
                branchId: branchId,
                commitCount: commitCount,
                taskProgress: taskProgress,
                timeSpent: timeSpent,
                lastActivity: lastActivity
            )
            
            return statistics
            
        } catch {
            throw StatisticsError.calculationFailed("Failed to calculate branch statistics: \(error.localizedDescription)")
        }
    }
    
    /// Get daily statistics for a specific date
    /// - Parameter date: Date to get statistics for
    /// - Returns: Daily statistics
    func getDailyStatistics(for date: Date) async throws -> DailyStatistics {
        // Check cache first
        if let cached = cache.retrieveDailyStatistics(for: date) {
            return cached
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
        
        do {
            let dayCommits = try await commitRepository.findByDateRange(from: startOfDay, to: endOfDay)
            let dayBranches = try await branchRepository.findAll().filter { 
                calendar.isDate($0.createdAt, inSameDayAs: date)
            }
            
            // Calculate tasks completed on this day
            let allTaskPlans = try await taskPlanRepository.findAll()
            let tasksCompletedToday = allTaskPlans.flatMap { $0.tasks }.filter { task in
                guard let completedAt = task.completedAt else { return false }
                return calendar.isDate(completedAt, inSameDayAs: date)
            }.count
            
            // Find most active hour
            let hourCounts = Dictionary(grouping: dayCommits) { commit in
                calendar.component(.hour, from: commit.timestamp)
            }
            let mostActiveHour = hourCounts.max { $0.value.count < $1.value.count }?.key ?? 12
            
            // Group commits by type
            let commitTypesCounts = Dictionary(grouping: dayCommits) { $0.type }
                .mapValues { $0.count }
            
            let statistics = DailyStatistics(
                date: date,
                commitsCount: dayCommits.count,
                branchesCreated: dayBranches.count,
                tasksCompleted: tasksCompletedToday,
                timeSpent: calculateTimeSpent(from: dayCommits),
                mostActiveHour: mostActiveHour,
                commitTypes: commitTypesCounts
            )
            
            // Cache the result
            cache.storeDailyStatistics(statistics, for: date)
            
            return statistics
            
        } catch {
            throw StatisticsError.calculationFailed("Failed to calculate daily statistics: \(error.localizedDescription)")
        }
    }
    
    /// Get commit frequency data for trend analysis
    /// - Parameter days: Number of days to analyze (default: 30)
    /// - Returns: Array of daily commit counts
    func getCommitFrequencyData(days: Int = 30) async throws -> [CommitFrequencyData] {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) ?? endDate
        
        do {
            let commits = try await commitRepository.findByDateRange(from: startDate, to: endDate)
            
            var frequencyData: [CommitFrequencyData] = []
            
            for i in 0..<days {
                let date = calendar.date(byAdding: .day, value: -i, to: endDate) ?? endDate
                let dayCommits = commits.filter { calendar.isDate($0.timestamp, inSameDayAs: date) }
                
                frequencyData.append(CommitFrequencyData(
                    date: date,
                    commitCount: dayCommits.count,
                    typeDistribution: Dictionary(grouping: dayCommits) { $0.type }.mapValues { $0.count }
                ))
            }
            
            return frequencyData.reversed() // Return in chronological order
            
        } catch {
            throw StatisticsError.calculationFailed("Failed to get commit frequency data: \(error.localizedDescription)")
        }
    }
    
    /// Get goal completion rate over time
    /// - Parameter months: Number of months to analyze (default: 6)
    /// - Returns: Array of monthly completion rates
    func getGoalCompletionTrend(months: Int = 6) async throws -> [GoalCompletionTrendData] {
        let calendar = Calendar.current
        let endDate = Date()
        
        do {
            let allBranches = try await branchRepository.findAll()
            let goalBranches = allBranches.filter { !$0.isMaster }
            
            var trendData: [GoalCompletionTrendData] = []
            
            for i in 0..<months {
                let monthDate = calendar.date(byAdding: .month, value: -i, to: endDate) ?? endDate
                let monthStart = calendar.dateInterval(of: .month, for: monthDate)?.start ?? monthDate
                let monthEnd = calendar.dateInterval(of: .month, for: monthDate)?.end ?? monthDate
                
                let monthBranches = goalBranches.filter { branch in
                    branch.createdAt >= monthStart && branch.createdAt < monthEnd
                }
                
                let completedBranches = monthBranches.filter { $0.status == .completed }
                let completionRate = monthBranches.isEmpty ? 0.0 : Double(completedBranches.count) / Double(monthBranches.count)
                
                trendData.append(GoalCompletionTrendData(
                    month: monthDate,
                    totalGoals: monthBranches.count,
                    completedGoals: completedBranches.count,
                    completionRate: completionRate
                ))
            }
            
            return trendData.reversed() // Return in chronological order
            
        } catch {
            throw StatisticsError.calculationFailed("Failed to get goal completion trend: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Helper Methods for Calculations
    
    /// Calculate estimated time spent based on commits
    private func calculateTimeSpent(from commits: [Commit]) -> TimeInterval {
        // Simple heuristic: assume each commit represents 15-30 minutes of work
        let averageTimePerCommit: TimeInterval = 22.5 * 60 // 22.5 minutes in seconds
        return Double(commits.count) * averageTimePerCommit
    }
    
    /// Get productivity score based on recent activity
    func getProductivityScore(days: Int = 7) async throws -> ProductivityScore {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) ?? endDate
        
        do {
            let recentCommits = try await commitRepository.findByDateRange(from: startDate, to: endDate)
            let recentBranches = try await branchRepository.findAll().filter { $0.createdAt >= startDate }
            
            // Calculate various productivity metrics
            let commitScore = Double(recentCommits.count) * 2.0
            let branchScore = Double(recentBranches.count) * 10.0
            let consistencyScore = calculateConsistencyScore(commits: recentCommits, days: days)
            
            let totalScore = commitScore + branchScore + consistencyScore
            let normalizedScore = min(100.0, totalScore / Double(days) * 2.0) // Normalize to 0-100
            
            return ProductivityScore(
                score: normalizedScore,
                period: days,
                commitCount: recentCommits.count,
                branchCount: recentBranches.count,
                consistencyScore: consistencyScore
            )
            
        } catch {
            throw StatisticsError.calculationFailed("Failed to calculate productivity score: \(error.localizedDescription)")
        }
    }
    
    /// Calculate consistency score based on daily activity
    private func calculateConsistencyScore(commits: [Commit], days: Int) -> Double {
        let calendar = Calendar.current
        let endDate = Date()
        
        var activeDays = 0
        
        for i in 0..<days {
            let date = calendar.date(byAdding: .day, value: -i, to: endDate) ?? endDate
            let hasActivity = commits.contains { calendar.isDate($0.timestamp, inSameDayAs: date) }
            if hasActivity {
                activeDays += 1
            }
        }
        
        return (Double(activeDays) / Double(days)) * 20.0 // Max 20 points for consistency
    }
    
    // MARK: - Time Pattern Analysis Helper Methods
    
    /// Find the most active weekday from timestamps
    private func findMostActiveWeekday(from timestamps: [Date]) -> Int {
        let calendar = Calendar.current
        let weekdayCounts = Dictionary(grouping: timestamps) { timestamp in
            calendar.component(.weekday, from: timestamp)
        }.mapValues { $0.count }
        
        return weekdayCounts.max(by: { $0.value < $1.value })?.key ?? 1 // Default to Sunday
    }
}

// MARK: - Additional Supporting Types

/// Branch-specific statistics
struct BranchSpecificStatistics {
    let branchId: UUID
    let commitCount: Int
    let taskProgress: Double
    let timeSpent: TimeInterval
    let lastActivity: Date
    
    var timeSpentHours: Double {
        timeSpent / 3600.0
    }
    
    var progressPercentage: Double {
        taskProgress * 100.0
    }
}

/// Commit frequency data for trend analysis
struct CommitFrequencyData {
    let date: Date
    let commitCount: Int
    let typeDistribution: [CommitType: Int]
    
    var hasActivity: Bool {
        commitCount > 0
    }
}

/// Goal completion trend data
struct GoalCompletionTrendData {
    let month: Date
    let totalGoals: Int
    let completedGoals: Int
    let completionRate: Double
    
    var completionRatePercentage: Double {
        completionRate * 100.0
    }
    
    var monthName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: month)
    }
}

/// Productivity score data
struct ProductivityScore {
    let score: Double // 0-100
    let period: Int // days
    let commitCount: Int
    let branchCount: Int
    let consistencyScore: Double
    
    var level: ProductivityLevel {
        switch score {
        case 0..<20:
            return .low
        case 20..<40:
            return .belowAverage
        case 40..<60:
            return .average
        case 60..<80:
            return .aboveAverage
        case 80...100:
            return .high
        default:
            return .low
        }
    }
}

/// Productivity level classification
enum ProductivityLevel: String, CaseIterable {
    case low = "low"
    case belowAverage = "belowAverage"
    case average = "average"
    case aboveAverage = "aboveAverage"
    case high = "high"
    
    var displayName: String {
        switch self {
        case .low:
            return "较低"
        case .belowAverage:
            return "偏低"
        case .average:
            return "一般"
        case .aboveAverage:
            return "良好"
        case .high:
            return "优秀"
        }
    }
    
    var emoji: String {
        switch self {
        case .low:
            return "😴"
        case .belowAverage:
            return "😐"
        case .average:
            return "🙂"
        case .aboveAverage:
            return "😊"
        case .high:
            return "🚀"
        }
    }
    
    var color: String {
        switch self {
        case .low:
            return "red"
        case .belowAverage:
            return "orange"
        case .average:
            return "yellow"
        case .aboveAverage:
            return "blue"
        case .high:
            return "green"
        }
    }
}