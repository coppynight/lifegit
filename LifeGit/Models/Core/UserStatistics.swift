import Foundation

/// Comprehensive user statistics data structure
struct UserStatistics {
    let branchStatistics: BranchStatistics
    let commitStatistics: CommitStatistics
    let goalCompletionStatistics: GoalCompletionStatistics
    let activityStatistics: ActivityStatistics
    let streakStatistics: StreakStatistics
    let lastUpdated: Date
    
    /// Overall user engagement score (0-100)
    var engagementScore: Double {
        let activityWeight = 0.4
        let completionWeight = 0.3
        let consistencyWeight = 0.3
        
        let activityScore = activityStatistics.activityScore
        let completionScore = goalCompletionStatistics.completionRate * 100
        let consistencyScore = min(100.0, Double(streakStatistics.currentCommitStreak) * 10.0)
        
        return (activityScore * activityWeight) + 
               (completionScore * completionWeight) + 
               (consistencyScore * consistencyWeight)
    }
    
    /// User level based on engagement score
    var userLevel: UserLevel {
        switch engagementScore {
        case 0..<20:
            return .beginner
        case 20..<40:
            return .novice
        case 40..<60:
            return .intermediate
        case 60..<80:
            return .advanced
        case 80...100:
            return .expert
        default:
            return .beginner
        }
    }
}

/// Branch-related statistics
struct BranchStatistics {
    let totalBranches: Int
    let activeBranches: Int
    let completedBranches: Int
    let abandonedBranches: Int
    let averageCompletionTime: TimeInterval // in seconds
    let successRate: Double // 0.0 - 1.0
    let mostProductiveMonth: Int // 1-12
    let mostProductiveWeekday: Int // 1-7 (Sunday = 1)
    
    /// Average completion time in days
    var averageCompletionDays: Double {
        averageCompletionTime / (24 * 60 * 60)
    }
    
    /// Success rate as percentage
    var successRatePercentage: Double {
        successRate * 100
    }
    
    /// Most productive month name
    var mostProductiveMonthName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.monthSymbols[mostProductiveMonth - 1]
    }
    
    /// Most productive weekday name
    var mostProductiveWeekdayName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.weekdaySymbols[mostProductiveWeekday - 1]
    }
}

/// Commit-related statistics
struct CommitStatistics {
    let totalCommits: Int
    let weeklyFrequency: Double // commits per day in last 7 days
    let monthlyFrequency: Double // commits per day in last 30 days
    let averageCommitsPerDay: Double
    let typeDistribution: [CommitTypeDistribution]
    let mostActiveHour: Int // 0-23
    let mostActiveWeekday: Int // 1-7 (Sunday = 1)
    let firstCommitDate: Date?
    let lastCommitDate: Date?
    
    /// Most used commit type
    var mostUsedType: CommitType? {
        typeDistribution.first?.type
    }
    
    /// Most active hour formatted
    var mostActiveHourFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:00"
        let date = Calendar.current.date(bySettingHour: mostActiveHour, minute: 0, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date)
    }
    
    /// Most active weekday name
    var mostActiveWeekdayName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.weekdaySymbols[mostActiveWeekday - 1]
    }
    
    /// Days since first commit
    var daysSinceFirstCommit: Int? {
        guard let firstDate = firstCommitDate else { return nil }
        return Calendar.current.dateComponents([.day], from: firstDate, to: Date()).day
    }
}

/// Commit type distribution data
struct CommitTypeDistribution {
    let type: CommitType
    let count: Int
    let percentage: Double
    
    /// Percentage formatted as string
    var percentageFormatted: String {
        String(format: "%.1f%%", percentage * 100)
    }
}

/// Goal completion statistics
struct GoalCompletionStatistics {
    let totalGoals: Int
    let completedGoals: Int
    let activeGoals: Int
    let abandonedGoals: Int
    let completionRate: Double // 0.0 - 1.0
    let averageActiveProgress: Double // 0.0 - 1.0
    let mostProductiveMonth: Int // 1-12
    let totalTasks: Int
    let completedTasks: Int
    let taskCompletionRate: Double // 0.0 - 1.0
    
    /// Completion rate as percentage
    var completionRatePercentage: Double {
        completionRate * 100
    }
    
    /// Average active progress as percentage
    var averageActiveProgressPercentage: Double {
        averageActiveProgress * 100
    }
    
    /// Task completion rate as percentage
    var taskCompletionRatePercentage: Double {
        taskCompletionRate * 100
    }
    
    /// Most productive month name
    var mostProductiveMonthName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.monthSymbols[mostProductiveMonth - 1]
    }
}

/// User activity statistics
struct ActivityStatistics {
    let commitsLast7Days: Int
    let commitsLast30Days: Int
    let commitsLast90Days: Int
    let branchesLast7Days: Int
    let branchesLast30Days: Int
    let branchesLast90Days: Int
    let activityScore: Double // 0-100
    let dailyActivityPattern: [Int] // 24 hours
    let weeklyActivityPattern: [Int] // 7 days
    
    /// Activity level based on score
    var activityLevel: ActivityLevel {
        switch activityScore {
        case 0..<20:
            return .low
        case 20..<50:
            return .moderate
        case 50..<80:
            return .high
        case 80...100:
            return .veryHigh
        default:
            return .low
        }
    }
    
    /// Most active hour of day
    var mostActiveHour: Int {
        guard let maxIndex = dailyActivityPattern.enumerated().max(by: { $0.element < $1.element })?.offset else {
            return 12
        }
        return maxIndex
    }
    
    /// Most active day of week
    var mostActiveWeekday: Int {
        guard let maxIndex = weeklyActivityPattern.enumerated().max(by: { $0.element < $1.element })?.offset else {
            return 0
        }
        return maxIndex + 1 // Convert to 1-7 format
    }
}

/// Streak statistics
struct StreakStatistics {
    let currentCommitStreak: Int
    let longestCommitStreak: Int
    let currentGoalStreak: Int
    let longestGoalStreak: Int
    
    /// Overall streak score
    var streakScore: Double {
        let commitWeight = 0.6
        let goalWeight = 0.4
        
        let commitScore = min(100.0, Double(currentCommitStreak) * 10.0)
        let goalScore = min(100.0, Double(currentGoalStreak) * 20.0)
        
        return (commitScore * commitWeight) + (goalScore * goalWeight)
    }
}

// MARK: - Supporting Enums

/// User level based on engagement
enum UserLevel: String, CaseIterable {
    case beginner = "beginner"
    case novice = "novice"
    case intermediate = "intermediate"
    case advanced = "advanced"
    case expert = "expert"
    
    var displayName: String {
        switch self {
        case .beginner:
            return "初学者"
        case .novice:
            return "新手"
        case .intermediate:
            return "进阶者"
        case .advanced:
            return "高级用户"
        case .expert:
            return "专家"
        }
    }
    
    var emoji: String {
        switch self {
        case .beginner:
            return "🌱"
        case .novice:
            return "🌿"
        case .intermediate:
            return "🌳"
        case .advanced:
            return "🏆"
        case .expert:
            return "👑"
        }
    }
    
    var color: String {
        switch self {
        case .beginner:
            return "green"
        case .novice:
            return "blue"
        case .intermediate:
            return "orange"
        case .advanced:
            return "purple"
        case .expert:
            return "gold"
        }
    }
}

/// Activity level classification
enum ActivityLevel: String, CaseIterable {
    case low = "low"
    case moderate = "moderate"
    case high = "high"
    case veryHigh = "veryHigh"
    
    var displayName: String {
        switch self {
        case .low:
            return "较低"
        case .moderate:
            return "中等"
        case .high:
            return "较高"
        case .veryHigh:
            return "很高"
        }
    }
    
    var emoji: String {
        switch self {
        case .low:
            return "😴"
        case .moderate:
            return "🚶"
        case .high:
            return "🏃"
        case .veryHigh:
            return "🚀"
        }
    }
    
    var color: String {
        switch self {
        case .low:
            return "gray"
        case .moderate:
            return "blue"
        case .high:
            return "orange"
        case .veryHigh:
            return "red"
        }
    }
}

// MARK: - Statistics Error

/// Statistics calculation errors
enum StatisticsError: Error, LocalizedError {
    case calculationFailed(String)
    case dataNotAvailable(String)
    case cacheError(String)
    
    var errorDescription: String? {
        switch self {
        case .calculationFailed(let message):
            return "统计计算失败: \(message)"
        case .dataNotAvailable(let message):
            return "数据不可用: \(message)"
        case .cacheError(let message):
            return "缓存错误: \(message)"
        }
    }
}