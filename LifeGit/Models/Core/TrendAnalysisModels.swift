import Foundation

// MARK: - Main Growth Trend Analysis

/// Comprehensive growth trend analysis data structure
struct GrowthTrendAnalysis {
    let timeframe: Int // days
    let commitTrends: CommitTrendAnalysis
    let branchActivityTrends: BranchActivityTrendAnalysis
    let goalCompletionTrends: GoalCompletionTrendAnalysis
    let productivityTrends: ProductivityTrendAnalysis
    let skillDevelopmentTrends: SkillDevelopmentTrendAnalysis
    let overallGrowthScore: Double // 0-100
    let analysisDate: Date
    
    /// Growth level based on overall score
    var growthLevel: GrowthLevel {
        switch overallGrowthScore {
        case 0..<20:
            return .declining
        case 20..<40:
            return .stagnant
        case 40..<60:
            return .steady
        case 60..<80:
            return .growing
        case 80...100:
            return .thriving
        default:
            return .steady
        }
    }
    
    /// Key insights from the analysis
    var keyInsights: [String] {
        var insights: [String] = []
        
        // Commit trends insights
        if commitTrends.trendDirection == .increasing {
            insights.append("提交活动呈上升趋势，保持良好的学习节奏")
        } else if commitTrends.trendDirection == .decreasing {
            insights.append("提交活动有所下降，建议重新激发学习动力")
        }
        
        // Goal completion insights
        if goalCompletionTrends.overallTrend == .increasing {
            insights.append("目标完成能力持续提升")
        } else if goalCompletionTrends.averageCompletionRate > 0.7 {
            insights.append("目标完成率保持在较高水平")
        }
        
        // Productivity insights
        if productivityTrends.overallTrend == .increasing {
            insights.append("整体生产力呈上升趋势")
        }
        
        // Skill development insights
        if skillDevelopmentTrends.learningConsistencyScore > 60 {
            insights.append("学习活动保持良好的连续性")
        }
        
        return insights
    }
}

// MARK: - Commit Trend Analysis

/// Commit trends analysis data
struct CommitTrendAnalysis {
    let totalCommits: Int
    let averageCommitsPerDay: Double
    let trendDirection: TrendDirection
    let changePercentage: Double
    let consistencyScore: Double // 0-100
    let activeDays: Int
    let peakActivityDays: [CommitFrequencyData]
    let typeEvolution: CommitTypeEvolution
    
    /// Formatted change percentage
    var formattedChangePercentage: String {
        let sign = changePercentage >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", changePercentage))%"
    }
    
    /// Consistency level
    var consistencyLevel: ConsistencyLevel {
        switch consistencyScore {
        case 0..<20:
            return .poor
        case 20..<40:
            return .fair
        case 40..<60:
            return .good
        case 60..<80:
            return .excellent
        case 80...100:
            return .outstanding
        default:
            return .fair
        }
    }
}

/// Commit type evolution over time
struct CommitTypeEvolution {
    let earlierDistribution: [CommitType: Double]
    let laterDistribution: [CommitType: Double]
    let mostImprovedType: CommitType?
    let mostDeclinedType: CommitType?
    let typeChanges: [CommitType: Double]
    
    /// Get improvement for a specific type
    func getImprovement(for type: CommitType) -> Double {
        return typeChanges[type] ?? 0.0
    }
    
    /// Get formatted improvement string
    func getFormattedImprovement(for type: CommitType) -> String {
        let change = getImprovement(for: type)
        let sign = change >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", change))%"
    }
}

// MARK: - Branch Activity Trend Analysis

/// Branch activity trends analysis data
struct BranchActivityTrendAnalysis {
    let totalBranchesCreated: Int
    let branchesPerWeek: [WeeklyBranchData]
    let completionRates: [CompletionRateData]
    let complexityTrends: BranchComplexityTrends
    let averageBranchLifespan: TimeInterval
    let mostProductivePeriod: WeeklyBranchData?
    
    /// Average branches per week
    var averageBranchesPerWeek: Double {
        let totalBranches = branchesPerWeek.map { $0.branchesCreated }.reduce(0, +)
        return Double(totalBranches) / Double(max(1, branchesPerWeek.count))
    }
    
    /// Average completion rate
    var averageCompletionRate: Double {
        let totalRate = completionRates.map { $0.completionRate }.reduce(0, +)
        return totalRate / Double(max(1, completionRates.count))
    }
    
    /// Average lifespan in days
    var averageLifespanDays: Double {
        return averageBranchLifespan / (24 * 60 * 60)
    }
}

/// Weekly branch creation data
struct WeeklyBranchData {
    let weekStart: Date
    let branchesCreated: Int
    let branchesCompleted: Int
    let branchesAbandoned: Int
    
    /// Week completion rate
    var completionRate: Double {
        let total = branchesCompleted + branchesAbandoned
        return total > 0 ? Double(branchesCompleted) / Double(total) : 0.0
    }
    
    /// Formatted week string
    var weekString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: weekStart)
    }
}

/// Completion rate data over time
struct CompletionRateData {
    let period: Date
    let totalBranches: Int
    let completedBranches: Int
    let completionRate: Double
    
    /// Completion rate as percentage
    var completionRatePercentage: Double {
        return completionRate * 100.0
    }
}

/// Branch complexity trends
struct BranchComplexityTrends {
    let averageTaskCount: Double
    let averageEstimatedDuration: Double // minutes
    let aiUsageRate: Double // 0-1
    let complexityTrend: TrendDirection
    
    /// Average duration in hours
    var averageDurationHours: Double {
        return averageEstimatedDuration / 60.0
    }
    
    /// AI usage percentage
    var aiUsagePercentage: Double {
        return aiUsageRate * 100.0
    }
}

// MARK: - Goal Completion Trend Analysis

/// Goal completion trends analysis data
struct GoalCompletionTrendAnalysis {
    let monthlyData: [GoalCompletionTrendData]
    let overallTrend: TrendDirection
    let improvementPercentage: Double
    let bestPerformingMonth: GoalCompletionTrendData?
    let worstPerformingMonth: GoalCompletionTrendData?
    let averageCompletionRate: Double
    
    /// Formatted improvement percentage
    var formattedImprovementPercentage: String {
        let sign = improvementPercentage >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", improvementPercentage))%"
    }
    
    /// Average completion rate as percentage
    var averageCompletionRatePercentage: Double {
        return averageCompletionRate * 100.0
    }
}

// MARK: - Productivity Trend Analysis

/// Productivity trends analysis data
struct ProductivityTrendAnalysis {
    let weeklyData: [WeeklyProductivityData]
    let overallTrend: TrendDirection
    let changePercentage: Double
    let averageProductivityScore: Double
    let peakProductivityWeek: WeeklyProductivityData?
    
    /// Formatted change percentage
    var formattedChangePercentage: String {
        let sign = changePercentage >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", changePercentage))%"
    }
    
    /// Productivity level
    var productivityLevel: ProductivityLevel {
        switch averageProductivityScore {
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
            return .average
        }
    }
}

/// Weekly productivity data
struct WeeklyProductivityData {
    let weekStart: Date
    let productivityScore: Double
    let commitCount: Int
    let branchCount: Int
    
    /// Formatted week string
    var weekString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: weekStart)
    }
}

// MARK: - Skill Development Trend Analysis

/// Skill development trends analysis data
struct SkillDevelopmentTrendAnalysis {
    let totalLearningActivities: Int
    let learningFrequency: Double // percentage of days with learning
    let skillDiversityScore: Double // 0-100
    let learningConsistencyScore: Double // 0-100
    let dominantLearningType: CommitType?
    let learningTrend: TrendDirection
    
    /// Learning frequency as percentage
    var learningFrequencyPercentage: String {
        return String(format: "%.1f%%", learningFrequency)
    }
    
    /// Skill diversity level
    var skillDiversityLevel: SkillDiversityLevel {
        switch skillDiversityScore {
        case 0..<20:
            return .narrow
        case 20..<40:
            return .limited
        case 40..<60:
            return .moderate
        case 60..<80:
            return .broad
        case 80...100:
            return .diverse
        default:
            return .moderate
        }
    }
    
    /// Learning consistency level
    var learningConsistencyLevel: ConsistencyLevel {
        switch learningConsistencyScore {
        case 0..<20:
            return .poor
        case 20..<40:
            return .fair
        case 40..<60:
            return .good
        case 60..<80:
            return .excellent
        case 80...100:
            return .outstanding
        default:
            return .fair
        }
    }
}

// MARK: - Personal Efficiency Analysis

/// Personal efficiency analysis data
struct PersonalEfficiencyAnalysis {
    let overallEfficiencyScore: Double // 0-100
    let timePatterns: TimePatterns
    let goalPatterns: GoalSettingPatterns
    let suggestions: [EfficiencySuggestion]
    let strengths: [String]
    let improvementAreas: [String]
    
    /// Efficiency level
    var efficiencyLevel: EfficiencyLevel {
        switch overallEfficiencyScore {
        case 0..<20:
            return .veryLow
        case 20..<40:
            return .low
        case 40..<60:
            return .moderate
        case 60..<80:
            return .high
        case 80...100:
            return .veryHigh
        default:
            return .moderate
        }
    }
    
    /// High priority suggestions
    var highPrioritySuggestions: [EfficiencySuggestion] {
        return suggestions.filter { $0.priority == .high }
    }
}

/// Time usage patterns
struct TimePatterns {
    let mostProductiveHour: Int
    let mostProductiveDay: Int
    let activityDistribution: [Int] // 24 hours
    let consistencyScore: Double
    
    /// Most productive hour formatted
    var mostProductiveHourFormatted: String {
        return String(format: "%02d:00", mostProductiveHour)
    }
    
    /// Most productive day name
    var mostProductiveDayName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.weekdaySymbols[mostProductiveDay - 1]
    }
}

/// Goal setting patterns
struct GoalSettingPatterns {
    let averageGoalsPerMonth: Double
    let successRate: Double
    let averageCompletionTime: Double // days
    let goalComplexityTrend: TrendDirection
    
    /// Success rate as percentage
    var successRatePercentage: String {
        return String(format: "%.1f%%", successRate)
    }
    
    /// Average completion time formatted
    var averageCompletionTimeFormatted: String {
        if averageCompletionTime < 1 {
            return "不到1天"
        } else if averageCompletionTime < 7 {
            return String(format: "%.1f天", averageCompletionTime)
        } else {
            return String(format: "%.1f周", averageCompletionTime / 7)
        }
    }
}

/// Efficiency improvement suggestion
struct EfficiencySuggestion {
    let type: SuggestionType
    let title: String
    let description: String
    let priority: SuggestionPriority
    let estimatedImpact: SuggestionImpact
    
    /// Priority color
    var priorityColor: String {
        switch priority {
        case .low:
            return "gray"
        case .medium:
            return "blue"
        case .high:
            return "red"
        }
    }
    
    /// Impact color
    var impactColor: String {
        switch estimatedImpact {
        case .low:
            return "gray"
        case .medium:
            return "orange"
        case .high:
            return "green"
        }
    }
}

// MARK: - Growth Visualization Data

/// Data for growth visualization charts
struct GrowthVisualizationData {
    let commitFrequencyChart: [ChartDataPoint]
    let goalCompletionChart: [ChartDataPoint]
    let activityHeatmap: [[Double]]
    let progressTimeline: [ProgressTimelineEvent]
}

/// Chart data point
struct ChartDataPoint {
    let date: Date
    let value: Double
    
    /// Formatted date string
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
}

/// Progress timeline event
struct ProgressTimelineEvent {
    let date: Date
    let type: TimelineEventType
    let title: String
    let description: String
    
    /// Formatted date string
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Enums

/// Trend direction
enum TrendDirection: String, CaseIterable {
    case increasing = "increasing"
    case stable = "stable"
    case decreasing = "decreasing"
    
    var displayName: String {
        switch self {
        case .increasing:
            return "上升"
        case .stable:
            return "稳定"
        case .decreasing:
            return "下降"
        }
    }
    
    var emoji: String {
        switch self {
        case .increasing:
            return "📈"
        case .stable:
            return "➡️"
        case .decreasing:
            return "📉"
        }
    }
    
    var color: String {
        switch self {
        case .increasing:
            return "green"
        case .stable:
            return "blue"
        case .decreasing:
            return "red"
        }
    }
}

/// Growth level classification
enum GrowthLevel: String, CaseIterable {
    case declining = "declining"
    case stagnant = "stagnant"
    case steady = "steady"
    case growing = "growing"
    case thriving = "thriving"
    
    var displayName: String {
        switch self {
        case .declining:
            return "下滑"
        case .stagnant:
            return "停滞"
        case .steady:
            return "稳定"
        case .growing:
            return "成长"
        case .thriving:
            return "蓬勃"
        }
    }
    
    var emoji: String {
        switch self {
        case .declining:
            return "📉"
        case .stagnant:
            return "😐"
        case .steady:
            return "🙂"
        case .growing:
            return "📈"
        case .thriving:
            return "🚀"
        }
    }
    
    var color: String {
        switch self {
        case .declining:
            return "red"
        case .stagnant:
            return "gray"
        case .steady:
            return "blue"
        case .growing:
            return "green"
        case .thriving:
            return "purple"
        }
    }
}

/// Consistency level
enum ConsistencyLevel: String, CaseIterable {
    case poor = "poor"
    case fair = "fair"
    case good = "good"
    case excellent = "excellent"
    case outstanding = "outstanding"
    
    var displayName: String {
        switch self {
        case .poor:
            return "较差"
        case .fair:
            return "一般"
        case .good:
            return "良好"
        case .excellent:
            return "优秀"
        case .outstanding:
            return "卓越"
        }
    }
    
    var emoji: String {
        switch self {
        case .poor:
            return "😞"
        case .fair:
            return "😐"
        case .good:
            return "🙂"
        case .excellent:
            return "😊"
        case .outstanding:
            return "🌟"
        }
    }
    
    var color: String {
        switch self {
        case .poor:
            return "red"
        case .fair:
            return "orange"
        case .good:
            return "yellow"
        case .excellent:
            return "blue"
        case .outstanding:
            return "purple"
        }
    }
}

/// Skill diversity level
enum SkillDiversityLevel: String, CaseIterable {
    case narrow = "narrow"
    case limited = "limited"
    case moderate = "moderate"
    case broad = "broad"
    case diverse = "diverse"
    
    var displayName: String {
        switch self {
        case .narrow:
            return "单一"
        case .limited:
            return "有限"
        case .moderate:
            return "中等"
        case .broad:
            return "广泛"
        case .diverse:
            return "多样"
        }
    }
    
    var emoji: String {
        switch self {
        case .narrow:
            return "🎯"
        case .limited:
            return "📚"
        case .moderate:
            return "🌱"
        case .broad:
            return "🌳"
        case .diverse:
            return "🌈"
        }
    }
}

/// Efficiency level
enum EfficiencyLevel: String, CaseIterable {
    case veryLow = "veryLow"
    case low = "low"
    case moderate = "moderate"
    case high = "high"
    case veryHigh = "veryHigh"
    
    var displayName: String {
        switch self {
        case .veryLow:
            return "很低"
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
        case .veryLow:
            return "🐌"
        case .low:
            return "🚶"
        case .moderate:
            return "🚴"
        case .high:
            return "🏃"
        case .veryHigh:
            return "🚀"
        }
    }
    
    var color: String {
        switch self {
        case .veryLow:
            return "red"
        case .low:
            return "orange"
        case .moderate:
            return "yellow"
        case .high:
            return "blue"
        case .veryHigh:
            return "green"
        }
    }
}

/// Suggestion type
enum SuggestionType: String, CaseIterable {
    case consistency = "consistency"
    case timeOptimization = "timeOptimization"
    case goalSetting = "goalSetting"
    case learning = "learning"
    case productivity = "productivity"
    
    var displayName: String {
        switch self {
        case .consistency:
            return "一致性"
        case .timeOptimization:
            return "时间优化"
        case .goalSetting:
            return "目标设定"
        case .learning:
            return "学习提升"
        case .productivity:
            return "生产力"
        }
    }
    
    var emoji: String {
        switch self {
        case .consistency:
            return "🔄"
        case .timeOptimization:
            return "⏰"
        case .goalSetting:
            return "🎯"
        case .learning:
            return "📚"
        case .productivity:
            return "⚡"
        }
    }
}

/// Suggestion priority
enum SuggestionPriority: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    var displayName: String {
        switch self {
        case .low:
            return "低"
        case .medium:
            return "中"
        case .high:
            return "高"
        }
    }
}

/// Suggestion impact
enum SuggestionImpact: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    var displayName: String {
        switch self {
        case .low:
            return "低"
        case .medium:
            return "中"
        case .high:
            return "高"
        }
    }
}

/// Timeline event type
enum TimelineEventType: String, CaseIterable {
    case goalCompleted = "goalCompleted"
    case milestoneReached = "milestoneReached"
    case skillLearned = "skillLearned"
    case habitFormed = "habitFormed"
    
    var displayName: String {
        switch self {
        case .goalCompleted:
            return "目标完成"
        case .milestoneReached:
            return "里程碑"
        case .skillLearned:
            return "技能学习"
        case .habitFormed:
            return "习惯养成"
        }
    }
    
    var emoji: String {
        switch self {
        case .goalCompleted:
            return "🎯"
        case .milestoneReached:
            return "🏆"
        case .skillLearned:
            return "📚"
        case .habitFormed:
            return "🔄"
        }
    }
    
    var color: String {
        switch self {
        case .goalCompleted:
            return "green"
        case .milestoneReached:
            return "gold"
        case .skillLearned:
            return "blue"
        case .habitFormed:
            return "purple"
        }
    }
}

// MARK: - Trend Analysis Errors

/// Trend analysis specific errors
enum TrendAnalysisError: Error, LocalizedError {
    case analysisFailed(String)
    case dataInsufficient(String)
    case efficiencyAnalysisFailed(String)
    case visualizationDataFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .analysisFailed(let message):
            return "趋势分析失败: \(message)"
        case .dataInsufficient(let message):
            return "数据不足: \(message)"
        case .efficiencyAnalysisFailed(let message):
            return "效率分析失败: \(message)"
        case .visualizationDataFailed(let message):
            return "可视化数据生成失败: \(message)"
        }
    }
}