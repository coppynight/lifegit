import Foundation
import SwiftData
import SwiftUI

/// Service for analyzing version upgrade data and providing insights
class VersionAnalytics {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Version Analysis
    
    /// Analyzes version upgrade patterns and provides insights
    func analyzeVersionHistory(for user: User) async -> VersionAnalysisResult {
        let versionHistory = user.versionHistory.sorted { $0.upgradedAt < $1.upgradedAt }
        
        guard versionHistory.count > 1 else {
            return VersionAnalysisResult.initial()
        }
        
        let totalVersions = versionHistory.count
        let importantMilestones = versionHistory.filter { $0.isImportantMilestone }.count
        let regularUpgrades = totalVersions - importantMilestones
        
        // Calculate upgrade frequency
        let firstVersion = versionHistory.first!
        let latestVersion = versionHistory.last!
        let totalDays = Calendar.current.dateComponents([.day], from: firstVersion.upgradedAt, to: latestVersion.upgradedAt).day ?? 1
        let averageDaysBetweenUpgrades = totalDays > 0 ? Double(totalDays) / Double(max(totalVersions - 1, 1)) : 0
        
        // Calculate growth metrics
        let growthMetrics = calculateGrowthMetrics(versionHistory: versionHistory)
        
        // Analyze upgrade trends
        let trendAnalysis = analyzeTrends(versionHistory: versionHistory)
        
        // Generate insights
        let insights = generateInsights(
            versionHistory: versionHistory,
            growthMetrics: growthMetrics,
            trendAnalysis: trendAnalysis
        )
        
        return VersionAnalysisResult(
            totalVersions: totalVersions,
            importantMilestones: importantMilestones,
            regularUpgrades: regularUpgrades,
            averageDaysBetweenUpgrades: averageDaysBetweenUpgrades,
            currentVersion: user.currentVersion,
            growthMetrics: growthMetrics,
            trendAnalysis: trendAnalysis,
            insights: insights,
            versionHistory: versionHistory
        )
    }
    
    /// Calculates growth metrics between versions
    private func calculateGrowthMetrics(versionHistory: [VersionRecord]) -> GrowthMetrics {
        guard versionHistory.count > 1 else {
            return GrowthMetrics.empty()
        }
        
        let firstVersion = versionHistory.first!
        let latestVersion = versionHistory.last!
        
        // Achievement growth
        let achievementGrowth = latestVersion.achievementCount - firstVersion.achievementCount
        let achievementGrowthRate = firstVersion.achievementCount > 0 
            ? Double(achievementGrowth) / Double(firstVersion.achievementCount) * 100
            : 0
        
        // Commit growth
        let commitGrowth = latestVersion.totalCommitsAtUpgrade - firstVersion.totalCommitsAtUpgrade
        let commitGrowthRate = firstVersion.totalCommitsAtUpgrade > 0
            ? Double(commitGrowth) / Double(firstVersion.totalCommitsAtUpgrade) * 100
            : 0
        
        // Calculate productivity metrics
        let productivityMetrics = calculateProductivityMetrics(versionHistory: versionHistory)
        
        return GrowthMetrics(
            achievementGrowth: achievementGrowth,
            achievementGrowthRate: achievementGrowthRate,
            commitGrowth: commitGrowth,
            commitGrowthRate: commitGrowthRate,
            productivityScore: productivityMetrics.score,
            consistencyScore: productivityMetrics.consistency
        )
    }
    
    /// Calculates productivity and consistency metrics
    private func calculateProductivityMetrics(versionHistory: [VersionRecord]) -> (score: Double, consistency: Double) {
        guard versionHistory.count > 2 else {
            return (score: 0, consistency: 0)
        }
        
        var intervalProductivity: [Double] = []
        
        for i in 1..<versionHistory.count {
            let previousVersion = versionHistory[i-1]
            let currentVersion = versionHistory[i]
            
            let daysBetween = Calendar.current.dateComponents([.day], 
                from: previousVersion.upgradedAt, 
                to: currentVersion.upgradedAt).day ?? 1
            
            let achievementIncrease = currentVersion.achievementCount - previousVersion.achievementCount
            let commitIncrease = currentVersion.totalCommitsAtUpgrade - previousVersion.totalCommitsAtUpgrade
            
            // Productivity score based on achievements and commits per day
            let productivity = Double(achievementIncrease * 10 + commitIncrease) / Double(max(daysBetween, 1))
            intervalProductivity.append(productivity)
        }
        
        let averageProductivity = intervalProductivity.reduce(0, +) / Double(intervalProductivity.count)
        
        // Consistency score based on variance in productivity
        let variance = intervalProductivity.map { pow($0 - averageProductivity, 2) }.reduce(0, +) / Double(intervalProductivity.count)
        let standardDeviation = sqrt(variance)
        let consistencyScore = max(0, 100 - (standardDeviation / max(averageProductivity, 1)) * 100)
        
        return (score: averageProductivity * 10, consistency: consistencyScore)
    }
    
    /// Analyzes upgrade trends over time
    private func analyzeTrends(versionHistory: [VersionRecord]) -> TrendAnalysis {
        guard versionHistory.count > 2 else {
            return TrendAnalysis.insufficient()
        }
        
        // Analyze upgrade frequency trend
        let frequencyTrend = analyzeFrequencyTrend(versionHistory: versionHistory)
        
        // Analyze achievement trend
        let achievementTrend = analyzeAchievementTrend(versionHistory: versionHistory)
        
        // Analyze milestone frequency
        let milestoneTrend = analyzeMilestoneTrend(versionHistory: versionHistory)
        
        // Predict next upgrade
        let nextUpgradePrediction = predictNextUpgrade(versionHistory: versionHistory)
        
        return TrendAnalysis(
            frequencyTrend: frequencyTrend,
            achievementTrend: achievementTrend,
            milestoneTrend: milestoneTrend,
            nextUpgradePrediction: nextUpgradePrediction
        )
    }
    
    /// Analyzes upgrade frequency trend
    private func analyzeFrequencyTrend(versionHistory: [VersionRecord]) -> VersionTrendDirection {
        let intervals = calculateUpgradeIntervals(versionHistory: versionHistory)
        guard intervals.count >= 2 else { return .stable }
        
        let recentIntervals = Array(intervals.suffix(3))
        let earlierIntervals = Array(intervals.prefix(max(intervals.count - 3, 1)))
        
        let recentAverage = recentIntervals.reduce(0, +) / Double(recentIntervals.count)
        let earlierAverage = earlierIntervals.reduce(0, +) / Double(earlierIntervals.count)
        
        let changePercentage = (recentAverage - earlierAverage) / earlierAverage * 100
        
        if changePercentage > 20 {
            return .decreasing // Longer intervals = decreasing frequency
        } else if changePercentage < -20 {
            return .increasing // Shorter intervals = increasing frequency
        } else {
            return .stable
        }
    }
    
    /// Analyzes achievement trend
    private func analyzeAchievementTrend(versionHistory: [VersionRecord]) -> VersionTrendDirection {
        guard versionHistory.count >= 3 else { return .stable }
        
        let recentVersions = Array(versionHistory.suffix(3))
        let achievementCounts = recentVersions.map { $0.achievementCount }
        
        let isIncreasing = achievementCounts.enumerated().allSatisfy { index, count in
            index == 0 || count >= achievementCounts[index - 1]
        }
        
        let isDecreasing = achievementCounts.enumerated().allSatisfy { index, count in
            index == 0 || count <= achievementCounts[index - 1]
        }
        
        if isIncreasing && achievementCounts.last! > achievementCounts.first! {
            return .increasing
        } else if isDecreasing && achievementCounts.last! < achievementCounts.first! {
            return .decreasing
        } else {
            return .stable
        }
    }
    
    /// Analyzes milestone frequency trend
    private func analyzeMilestoneTrend(versionHistory: [VersionRecord]) -> VersionTrendDirection {
        guard versionHistory.count >= 4 else { return .stable }
        
        let halfPoint = versionHistory.count / 2
        let earlierHalf = Array(versionHistory.prefix(halfPoint))
        let laterHalf = Array(versionHistory.suffix(versionHistory.count - halfPoint))
        
        let earlierMilestones = earlierHalf.filter { $0.isImportantMilestone }.count
        let laterMilestones = laterHalf.filter { $0.isImportantMilestone }.count
        
        let earlierRate = Double(earlierMilestones) / Double(earlierHalf.count)
        let laterRate = Double(laterMilestones) / Double(laterHalf.count)
        
        if laterRate > earlierRate * 1.2 {
            return .increasing
        } else if laterRate < earlierRate * 0.8 {
            return .decreasing
        } else {
            return .stable
        }
    }
    
    /// Predicts when the next upgrade might occur
    private func predictNextUpgrade(versionHistory: [VersionRecord]) -> NextUpgradePrediction {
        let intervals = calculateUpgradeIntervals(versionHistory: versionHistory)
        guard !intervals.isEmpty else {
            return NextUpgradePrediction(estimatedDays: 30, confidence: .low)
        }
        
        let averageInterval = intervals.reduce(0, +) / Double(intervals.count)
        let recentInterval = intervals.suffix(3).reduce(0, +) / Double(min(intervals.count, 3))
        
        // Weight recent intervals more heavily
        let predictedInterval = (averageInterval * 0.3) + (recentInterval * 0.7)
        
        // Calculate confidence based on consistency
        let variance = intervals.map { pow($0 - averageInterval, 2) }.reduce(0, +) / Double(intervals.count)
        let standardDeviation = sqrt(variance)
        let coefficientOfVariation = standardDeviation / averageInterval
        
        let confidence: PredictionConfidence
        if coefficientOfVariation < 0.3 {
            confidence = .high
        } else if coefficientOfVariation < 0.6 {
            confidence = .medium
        } else {
            confidence = .low
        }
        
        return NextUpgradePrediction(
            estimatedDays: Int(predictedInterval),
            confidence: confidence
        )
    }
    
    /// Calculates intervals between version upgrades in days
    private func calculateUpgradeIntervals(versionHistory: [VersionRecord]) -> [Double] {
        guard versionHistory.count > 1 else { return [] }
        
        var intervals: [Double] = []
        
        for i in 1..<versionHistory.count {
            let previousVersion = versionHistory[i-1]
            let currentVersion = versionHistory[i]
            
            let days = Calendar.current.dateComponents([.day], 
                from: previousVersion.upgradedAt, 
                to: currentVersion.upgradedAt).day ?? 0
            
            intervals.append(Double(days))
        }
        
        return intervals
    }
    
    /// Generates insights based on analysis results
    private func generateInsights(
        versionHistory: [VersionRecord],
        growthMetrics: GrowthMetrics,
        trendAnalysis: TrendAnalysis
    ) -> [VersionInsight] {
        var insights: [VersionInsight] = []
        
        // Growth insights
        if growthMetrics.achievementGrowthRate > 100 {
            insights.append(VersionInsight(
                type: .achievement,
                title: "目标完成加速",
                description: "您的目标完成率提升了\(Int(growthMetrics.achievementGrowthRate))%，保持这个势头！",
                importance: .high
            ))
        }
        
        // Productivity insights
        if growthMetrics.productivityScore > 50 {
            insights.append(VersionInsight(
                type: .productivity,
                title: "高效执行",
                description: "您的执行效率很高，生产力得分达到\(Int(growthMetrics.productivityScore))分",
                importance: .medium
            ))
        }
        
        // Consistency insights
        if growthMetrics.consistencyScore > 80 {
            insights.append(VersionInsight(
                type: .consistency,
                title: "稳定成长",
                description: "您的成长节奏很稳定，一致性得分\(Int(growthMetrics.consistencyScore))分",
                importance: .medium
            ))
        }
        
        // Trend insights
        if trendAnalysis.frequencyTrend == .increasing {
            insights.append(VersionInsight(
                type: .trend,
                title: "升级频率提升",
                description: "最近的版本升级频率在提高，说明您的成长在加速",
                importance: .high
            ))
        }
        
        // Milestone insights
        if trendAnalysis.milestoneTrend == .increasing {
            insights.append(VersionInsight(
                type: .milestone,
                title: "重要突破增多",
                description: "重要里程碑的频率在增加，您正在实现更多重要目标",
                importance: .high
            ))
        }
        
        return insights
    }
    
    // MARK: - Version Comparison
    
    /// Compares two versions and provides detailed analysis
    func compareVersions(_ version1: VersionRecord, _ version2: VersionRecord) -> VersionComparison {
        let timeDifference = Calendar.current.dateComponents([.day], 
            from: version1.upgradedAt, 
            to: version2.upgradedAt).day ?? 0
        
        let achievementDifference = version2.achievementCount - version1.achievementCount
        let commitDifference = version2.totalCommitsAtUpgrade - version1.totalCommitsAtUpgrade
        
        let achievementRate = timeDifference > 0 ? Double(achievementDifference) / Double(timeDifference) : 0
        let commitRate = timeDifference > 0 ? Double(commitDifference) / Double(timeDifference) : 0
        
        return VersionComparison(
            version1: version1,
            version2: version2,
            timeDifference: timeDifference,
            achievementDifference: achievementDifference,
            commitDifference: commitDifference,
            achievementRate: achievementRate,
            commitRate: commitRate
        )
    }
}

// MARK: - Supporting Types

struct VersionAnalysisResult {
    let totalVersions: Int
    let importantMilestones: Int
    let regularUpgrades: Int
    let averageDaysBetweenUpgrades: Double
    let currentVersion: String
    let growthMetrics: GrowthMetrics
    let trendAnalysis: TrendAnalysis
    let insights: [VersionInsight]
    let versionHistory: [VersionRecord]
    
    static func initial() -> VersionAnalysisResult {
        return VersionAnalysisResult(
            totalVersions: 1,
            importantMilestones: 0,
            regularUpgrades: 1,
            averageDaysBetweenUpgrades: 0,
            currentVersion: "v1.0",
            growthMetrics: GrowthMetrics.empty(),
            trendAnalysis: TrendAnalysis.insufficient(),
            insights: [],
            versionHistory: []
        )
    }
}

struct GrowthMetrics {
    let achievementGrowth: Int
    let achievementGrowthRate: Double
    let commitGrowth: Int
    let commitGrowthRate: Double
    let productivityScore: Double
    let consistencyScore: Double
    
    static func empty() -> GrowthMetrics {
        return GrowthMetrics(
            achievementGrowth: 0,
            achievementGrowthRate: 0,
            commitGrowth: 0,
            commitGrowthRate: 0,
            productivityScore: 0,
            consistencyScore: 0
        )
    }
}

struct TrendAnalysis {
    let frequencyTrend: VersionTrendDirection
    let achievementTrend: VersionTrendDirection
    let milestoneTrend: VersionTrendDirection
    let nextUpgradePrediction: NextUpgradePrediction
    
    static func insufficient() -> TrendAnalysis {
        return TrendAnalysis(
            frequencyTrend: .stable,
            achievementTrend: .stable,
            milestoneTrend: .stable,
            nextUpgradePrediction: NextUpgradePrediction(estimatedDays: 30, confidence: .low)
        )
    }
}

enum VersionTrendDirection {
    case increasing
    case decreasing
    case stable
    
    var displayName: String {
        switch self {
        case .increasing: return "上升"
        case .decreasing: return "下降"
        case .stable: return "稳定"
        }
    }
    
    var color: Color {
        switch self {
        case .increasing: return .green
        case .decreasing: return .red
        case .stable: return .blue
        }
    }
    
    var icon: String {
        switch self {
        case .increasing: return "arrow.up.right"
        case .decreasing: return "arrow.down.right"
        case .stable: return "arrow.right"
        }
    }
}

struct NextUpgradePrediction {
    let estimatedDays: Int
    let confidence: PredictionConfidence
}

enum PredictionConfidence {
    case high
    case medium
    case low
    
    var displayName: String {
        switch self {
        case .high: return "高"
        case .medium: return "中"
        case .low: return "低"
        }
    }
    
    var color: Color {
        switch self {
        case .high: return .green
        case .medium: return .orange
        case .low: return .red
        }
    }
}

struct VersionInsight {
    let type: InsightType
    let title: String
    let description: String
    let importance: InsightImportance
}

enum InsightType {
    case achievement
    case productivity
    case consistency
    case trend
    case milestone
    
    var icon: String {
        switch self {
        case .achievement: return "target"
        case .productivity: return "speedometer"
        case .consistency: return "chart.line.uptrend.xyaxis"
        case .trend: return "arrow.up.right"
        case .milestone: return "star.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .achievement: return .green
        case .productivity: return .blue
        case .consistency: return .purple
        case .trend: return .orange
        case .milestone: return .yellow
        }
    }
}

enum InsightImportance {
    case high
    case medium
    case low
    
    var color: Color {
        switch self {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }
}

struct VersionComparison {
    let version1: VersionRecord
    let version2: VersionRecord
    let timeDifference: Int
    let achievementDifference: Int
    let commitDifference: Int
    let achievementRate: Double
    let commitRate: Double
}