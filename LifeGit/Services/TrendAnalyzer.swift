import Foundation
import SwiftData

/// Analyzer for user growth trends and patterns
@MainActor
class TrendAnalyzer: ObservableObject {
    // MARK: - Published Properties
    @Published var isAnalyzing = false
    @Published var error: TrendAnalysisError?
    @Published var lastAnalysisTime: Date?
    
    // MARK: - Private Properties
    private let statisticsManager: StatisticsManager
    private let branchRepository: BranchRepository
    private let commitRepository: CommitRepository
    private let taskPlanRepository: TaskPlanRepository
    private let cache: StatisticsCache
    
    // MARK: - Initialization
    init(
        statisticsManager: StatisticsManager,
        branchRepository: BranchRepository,
        commitRepository: CommitRepository,
        taskPlanRepository: TaskPlanRepository,
        cache: StatisticsCache? = nil
    ) {
        self.statisticsManager = statisticsManager
        self.branchRepository = branchRepository
        self.commitRepository = commitRepository
        self.taskPlanRepository = taskPlanRepository
        self.cache = cache ?? StatisticsCache()
    }
    
    // MARK: - Growth Trend Analysis
    
    /// Analyze user growth trends over time
    /// - Parameter timeframe: Analysis timeframe (default: 90 days)
    /// - Returns: Comprehensive growth trend analysis
    func analyzeGrowthTrends(timeframe: Int = 90) async throws -> GrowthTrendAnalysis {
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        do {
            // Collect data for analysis
            async let commitTrends = analyzeCommitTrends(days: timeframe)
            async let branchActivityTrends = analyzeBranchActivityTrends(days: timeframe)
            async let goalCompletionTrends = analyzeGoalCompletionTrends(months: timeframe / 30)
            async let productivityTrends = analyzeProductivityTrends(weeks: timeframe / 7)
            async let skillDevelopmentTrends = analyzeSkillDevelopmentTrends(days: timeframe)
            
            let analysis = GrowthTrendAnalysis(
                timeframe: timeframe,
                commitTrends: try await commitTrends,
                branchActivityTrends: try await branchActivityTrends,
                goalCompletionTrends: try await goalCompletionTrends,
                productivityTrends: try await productivityTrends,
                skillDevelopmentTrends: try await skillDevelopmentTrends,
                overallGrowthScore: 0.0, // Will be calculated
                analysisDate: Date()
            )
            
            // Calculate overall growth score
            let growthScore = calculateOverallGrowthScore(from: analysis)
            let finalAnalysis = GrowthTrendAnalysis(
                timeframe: analysis.timeframe,
                commitTrends: analysis.commitTrends,
                branchActivityTrends: analysis.branchActivityTrends,
                goalCompletionTrends: analysis.goalCompletionTrends,
                productivityTrends: analysis.productivityTrends,
                skillDevelopmentTrends: analysis.skillDevelopmentTrends,
                overallGrowthScore: growthScore,
                analysisDate: analysis.analysisDate
            )
            
            lastAnalysisTime = Date()
            return finalAnalysis
            
        } catch {
            self.error = TrendAnalysisError.analysisFailed(error.localizedDescription)
            throw error
        }
    }
    
    // MARK: - Commit Trends Analysis
    
    /// Analyze commit trends and patterns
    private func analyzeCommitTrends(days: Int) async throws -> CommitTrendAnalysis {
        let frequencyData = try await statisticsManager.getCommitFrequencyData(days: days)
        
        // Calculate trend direction
        let recentPeriod = frequencyData.suffix(days / 3) // Last third of the period
        let earlierPeriod = frequencyData.prefix(days / 3) // First third of the period
        
        let recentAverage = recentPeriod.map { $0.commitCount }.reduce(0, +) / max(1, recentPeriod.count)
        let earlierAverage = earlierPeriod.map { $0.commitCount }.reduce(0, +) / max(1, earlierPeriod.count)
        
        let trendDirection: TrendDirection
        let changePercentage: Double
        
        if earlierAverage == 0 {
            trendDirection = recentAverage > 0 ? .increasing : .stable
            changePercentage = 0.0
        } else {
            changePercentage = (Double(recentAverage - earlierAverage) / Double(earlierAverage)) * 100.0
            
            if changePercentage > 10 {
                trendDirection = .increasing
            } else if changePercentage < -10 {
                trendDirection = .decreasing
            } else {
                trendDirection = .stable
            }
        }
        
        // Analyze consistency
        let activeDays = frequencyData.filter { $0.hasActivity }.count
        let consistencyScore = Double(activeDays) / Double(days) * 100.0
        
        // Find peak activity periods
        let peakDays = frequencyData.sorted { $0.commitCount > $1.commitCount }.prefix(5)
        
        // Analyze commit type evolution
        let typeEvolution = analyzeCommitTypeEvolution(from: frequencyData)
        
        return CommitTrendAnalysis(
            totalCommits: frequencyData.map { $0.commitCount }.reduce(0, +),
            averageCommitsPerDay: Double(frequencyData.map { $0.commitCount }.reduce(0, +)) / Double(days),
            trendDirection: trendDirection,
            changePercentage: changePercentage,
            consistencyScore: consistencyScore,
            activeDays: activeDays,
            peakActivityDays: Array(peakDays),
            typeEvolution: typeEvolution
        )
    }
    
    /// Analyze commit type evolution over time
    private func analyzeCommitTypeEvolution(from frequencyData: [CommitFrequencyData]) -> CommitTypeEvolution {
        let midpoint = frequencyData.count / 2
        let earlierPeriod = Array(frequencyData.prefix(midpoint))
        let laterPeriod = Array(frequencyData.suffix(midpoint))
        
        // Calculate type distribution for each period
        let earlierDistribution = calculateTypeDistribution(from: earlierPeriod)
        let laterDistribution = calculateTypeDistribution(from: laterPeriod)
        
        // Find the most improved and declined types
        var typeChanges: [CommitType: Double] = [:]
        
        for type in CommitType.allCases {
            let earlierPercentage = earlierDistribution[type] ?? 0.0
            let laterPercentage = laterDistribution[type] ?? 0.0
            typeChanges[type] = laterPercentage - earlierPercentage
        }
        
        let mostImprovedType = typeChanges.max { $0.value < $1.value }?.key
        let mostDeclinedType = typeChanges.min { $0.value < $1.value }?.key
        
        return CommitTypeEvolution(
            earlierDistribution: earlierDistribution,
            laterDistribution: laterDistribution,
            mostImprovedType: mostImprovedType,
            mostDeclinedType: mostDeclinedType,
            typeChanges: typeChanges
        )
    }
    
    /// Calculate commit type distribution from frequency data
    private func calculateTypeDistribution(from data: [CommitFrequencyData]) -> [CommitType: Double] {
        let totalCommits = data.flatMap { $0.typeDistribution.values }.reduce(0, +)
        guard totalCommits > 0 else { return [:] }
        
        var distribution: [CommitType: Double] = [:]
        
        for type in CommitType.allCases {
            let typeCount = data.compactMap { $0.typeDistribution[type] }.reduce(0, +)
            distribution[type] = Double(typeCount) / Double(totalCommits) * 100.0
        }
        
        return distribution
    }
    
    // MARK: - Branch Activity Trends Analysis
    
    /// Analyze branch activity trends
    private func analyzeBranchActivityTrends(days: Int) async throws -> BranchActivityTrendAnalysis {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) ?? endDate
        
        let allBranches = try await branchRepository.findAll()
        let periodBranches = allBranches.filter { $0.createdAt >= startDate && !$0.isMaster }
        
        // Analyze branch creation patterns
        let branchesPerWeek = analyzeBranchCreationPattern(branches: periodBranches, days: days)
        
        // Calculate completion rates over time
        let completionRates = calculateCompletionRatesOverTime(branches: periodBranches, days: days)
        
        // Analyze branch complexity trends
        let complexityTrends = try await analyzeBranchComplexityTrends(branches: periodBranches)
        
        // Calculate average branch lifespan
        let completedBranches = periodBranches.filter { $0.status == .completed && $0.completedAt != nil }
        let averageLifespan = calculateAverageBranchLifespan(branches: completedBranches)
        
        return BranchActivityTrendAnalysis(
            totalBranchesCreated: periodBranches.count,
            branchesPerWeek: branchesPerWeek,
            completionRates: completionRates,
            complexityTrends: complexityTrends,
            averageBranchLifespan: averageLifespan,
            mostProductivePeriod: findMostProductivePeriod(from: branchesPerWeek)
        )
    }
    
    /// Analyze branch creation patterns over time
    private func analyzeBranchCreationPattern(branches: [Branch], days: Int) -> [WeeklyBranchData] {
        let calendar = Calendar.current
        let endDate = Date()
        let weeks = days / 7
        
        var weeklyData: [WeeklyBranchData] = []
        
        for i in 0..<weeks {
            let weekStart = calendar.date(byAdding: .weekOfYear, value: -i, to: endDate) ?? endDate
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
            
            let weekBranches = branches.filter { branch in
                branch.createdAt >= weekStart && branch.createdAt < weekEnd
            }
            
            weeklyData.append(WeeklyBranchData(
                weekStart: weekStart,
                branchesCreated: weekBranches.count,
                branchesCompleted: weekBranches.filter { $0.status == .completed }.count,
                branchesAbandoned: weekBranches.filter { $0.status == .abandoned }.count
            ))
        }
        
        return weeklyData.reversed()
    }
    
    /// Calculate completion rates over time
    private func calculateCompletionRatesOverTime(branches: [Branch], days: Int) -> [CompletionRateData] {
        let calendar = Calendar.current
        let endDate = Date()
        let weeks = days / 7
        
        var completionData: [CompletionRateData] = []
        
        for i in 0..<weeks {
            let weekStart = calendar.date(byAdding: .weekOfYear, value: -i, to: endDate) ?? endDate
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
            
            let weekBranches = branches.filter { branch in
                branch.createdAt >= weekStart && branch.createdAt < weekEnd
            }
            
            let completedCount = weekBranches.filter { $0.status == .completed }.count
            let completionRate = weekBranches.isEmpty ? 0.0 : Double(completedCount) / Double(weekBranches.count)
            
            completionData.append(CompletionRateData(
                period: weekStart,
                totalBranches: weekBranches.count,
                completedBranches: completedCount,
                completionRate: completionRate
            ))
        }
        
        return completionData.reversed()
    }
    
    /// Analyze branch complexity trends
    private func analyzeBranchComplexityTrends(branches: [Branch]) async throws -> BranchComplexityTrends {
        var taskCounts: [Int] = []
        var estimatedDurations: [Int] = []
        var aiGeneratedCount = 0
        
        for branch in branches {
            if let taskPlan = branch.taskPlan {
                taskCounts.append(taskPlan.tasks.count)
                estimatedDurations.append(taskPlan.totalEstimatedDuration)
                if taskPlan.isAIGenerated {
                    aiGeneratedCount += 1
                }
            }
        }
        
        let averageTaskCount = taskCounts.isEmpty ? 0.0 : Double(taskCounts.reduce(0, +)) / Double(taskCounts.count)
        let averageDuration = estimatedDurations.isEmpty ? 0.0 : Double(estimatedDurations.reduce(0, +)) / Double(estimatedDurations.count)
        let aiUsageRate = branches.isEmpty ? 0.0 : Double(aiGeneratedCount) / Double(branches.count)
        
        return BranchComplexityTrends(
            averageTaskCount: averageTaskCount,
            averageEstimatedDuration: averageDuration,
            aiUsageRate: aiUsageRate,
            complexityTrend: determineComplexityTrend(taskCounts: taskCounts)
        )
    }
    
    /// Determine complexity trend direction
    private func determineComplexityTrend(taskCounts: [Int]) -> TrendDirection {
        guard taskCounts.count >= 4 else { return .stable }
        
        let firstHalf = Array(taskCounts.prefix(taskCounts.count / 2))
        let secondHalf = Array(taskCounts.suffix(taskCounts.count / 2))
        
        let firstAverage = Double(firstHalf.reduce(0, +)) / Double(firstHalf.count)
        let secondAverage = Double(secondHalf.reduce(0, +)) / Double(secondHalf.count)
        
        let change = (secondAverage - firstAverage) / firstAverage * 100.0
        
        if change > 15 {
            return .increasing
        } else if change < -15 {
            return .decreasing
        } else {
            return .stable
        }
    }
    
    /// Calculate average branch lifespan
    private func calculateAverageBranchLifespan(branches: [Branch]) -> TimeInterval {
        let lifespans = branches.compactMap { branch -> TimeInterval? in
            guard let completedAt = branch.completedAt else { return nil }
            return completedAt.timeIntervalSince(branch.createdAt)
        }
        
        guard !lifespans.isEmpty else { return 0 }
        return lifespans.reduce(0, +) / Double(lifespans.count)
    }
    
    /// Find most productive period
    private func findMostProductivePeriod(from weeklyData: [WeeklyBranchData]) -> WeeklyBranchData? {
        return weeklyData.max { $0.branchesCreated < $1.branchesCreated }
    }
    
    // MARK: - Goal Completion Trends Analysis
    
    /// Analyze goal completion trends
    private func analyzeGoalCompletionTrends(months: Int) async throws -> GoalCompletionTrendAnalysis {
        let trendData = try await statisticsManager.getGoalCompletionTrend(months: months)
        
        // Calculate trend direction
        let recentMonths = Array(trendData.suffix(months / 3))
        let earlierMonths = Array(trendData.prefix(months / 3))
        
        let recentAverage = recentMonths.map { $0.completionRate }.reduce(0, +) / Double(max(1, recentMonths.count))
        let earlierAverage = earlierMonths.map { $0.completionRate }.reduce(0, +) / Double(max(1, earlierMonths.count))
        
        let trendDirection: TrendDirection
        let improvement: Double
        
        if earlierAverage == 0 {
            trendDirection = recentAverage > 0 ? .increasing : .stable
            improvement = 0.0
        } else {
            improvement = ((recentAverage - earlierAverage) / earlierAverage) * 100.0
            
            if improvement > 5 {
                trendDirection = .increasing
            } else if improvement < -5 {
                trendDirection = .decreasing
            } else {
                trendDirection = .stable
            }
        }
        
        // Find best and worst performing months
        let bestMonth = trendData.max { $0.completionRate < $1.completionRate }
        let worstMonth = trendData.min { $0.completionRate < $1.completionRate }
        
        return GoalCompletionTrendAnalysis(
            monthlyData: trendData,
            overallTrend: trendDirection,
            improvementPercentage: improvement,
            bestPerformingMonth: bestMonth,
            worstPerformingMonth: worstMonth,
            averageCompletionRate: trendData.map { $0.completionRate }.reduce(0, +) / Double(max(1, trendData.count))
        )
    }
    
    // MARK: - Productivity Trends Analysis
    
    /// Analyze productivity trends over time
    private func analyzeProductivityTrends(weeks: Int) async throws -> ProductivityTrendAnalysis {
        var weeklyScores: [WeeklyProductivityData] = []
        let calendar = Calendar.current
        let endDate = Date()
        
        for i in 0..<weeks {
            let weekStart = calendar.date(byAdding: .weekOfYear, value: -i, to: endDate) ?? endDate
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
            
            // Calculate productivity score for this week
            let weekCommits = try await commitRepository.findByDateRange(from: weekStart, to: weekEnd)
            let weekBranches = try await branchRepository.findAll().filter { branch in
                branch.createdAt >= weekStart && branch.createdAt < weekEnd
            }
            
            let commitScore = Double(weekCommits.count) * 2.0
            let branchScore = Double(weekBranches.count) * 10.0
            let consistencyScore = weekCommits.isEmpty ? 0.0 : 20.0 // Simple binary consistency
            
            let totalScore = min(100.0, (commitScore + branchScore + consistencyScore) / 7.0 * 2.0)
            
            weeklyScores.append(WeeklyProductivityData(
                weekStart: weekStart,
                productivityScore: totalScore,
                commitCount: weekCommits.count,
                branchCount: weekBranches.count
            ))
        }
        
        weeklyScores = weeklyScores.reversed()
        
        // Calculate trend
        let recentWeeks = Array(weeklyScores.suffix(weeks / 3))
        let earlierWeeks = Array(weeklyScores.prefix(weeks / 3))
        
        let recentAverage = recentWeeks.map { $0.productivityScore }.reduce(0, +) / Double(max(1, recentWeeks.count))
        let earlierAverage = earlierWeeks.map { $0.productivityScore }.reduce(0, +) / Double(max(1, earlierWeeks.count))
        
        let trendDirection: TrendDirection
        let changePercentage: Double
        
        if earlierAverage == 0 {
            trendDirection = recentAverage > 0 ? .increasing : .stable
            changePercentage = 0.0
        } else {
            changePercentage = ((recentAverage - earlierAverage) / earlierAverage) * 100.0
            
            if changePercentage > 10 {
                trendDirection = .increasing
            } else if changePercentage < -10 {
                trendDirection = .decreasing
            } else {
                trendDirection = .stable
            }
        }
        
        return ProductivityTrendAnalysis(
            weeklyData: weeklyScores,
            overallTrend: trendDirection,
            changePercentage: changePercentage,
            averageProductivityScore: weeklyScores.map { $0.productivityScore }.reduce(0, +) / Double(max(1, weeklyScores.count)),
            peakProductivityWeek: weeklyScores.max { $0.productivityScore < $1.productivityScore }
        )
    }
    
    // MARK: - Skill Development Trends Analysis
    
    /// Analyze skill development trends based on commit types and learning activities
    private func analyzeSkillDevelopmentTrends(days: Int) async throws -> SkillDevelopmentTrendAnalysis {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) ?? endDate
        
        let commits = try await commitRepository.findByDateRange(from: startDate, to: endDate)
        
        // Analyze learning-related commits
        let learningCommits = commits.filter { $0.type == .learning }
        let skillCommits = commits.filter { $0.type == .skill }
        let readingCommits = commits.filter { $0.type == .reading }
        
        // Calculate learning frequency over time
        let learningFrequency = calculateLearningFrequency(commits: learningCommits, days: days)
        
        // Analyze skill diversity (based on commit messages and types)
        let skillDiversity = analyzeSkillDiversity(commits: learningCommits + skillCommits)
        
        // Calculate learning consistency
        let learningConsistency = calculateLearningConsistency(commits: learningCommits, days: days)
        
        return SkillDevelopmentTrendAnalysis(
            totalLearningActivities: learningCommits.count + skillCommits.count + readingCommits.count,
            learningFrequency: learningFrequency,
            skillDiversityScore: skillDiversity,
            learningConsistencyScore: learningConsistency,
            dominantLearningType: determineDominantLearningType(commits: commits),
            learningTrend: determineLearningTrend(commits: learningCommits, days: days)
        )
    }
    
    /// Calculate learning frequency over time
    private func calculateLearningFrequency(commits: [Commit], days: Int) -> Double {
        let learningDays = Set(commits.map { Calendar.current.startOfDay(for: $0.timestamp) }).count
        return Double(learningDays) / Double(days) * 100.0
    }
    
    /// Analyze skill diversity based on commit content
    private func analyzeSkillDiversity(commits: [Commit]) -> Double {
        // Simple heuristic: count unique keywords in commit messages
        let allWords = commits.flatMap { $0.message.lowercased().components(separatedBy: .whitespacesAndNewlines) }
        let uniqueWords = Set(allWords.filter { $0.count > 2 }) // Filter out short words
        
        // Normalize to 0-100 scale
        return min(100.0, Double(uniqueWords.count) * 2.0)
    }
    
    /// Calculate learning consistency
    private func calculateLearningConsistency(commits: [Commit], days: Int) -> Double {
        let calendar = Calendar.current
        let endDate = Date()
        
        var learningDays = 0
        
        for i in 0..<days {
            let date = calendar.date(byAdding: .day, value: -i, to: endDate) ?? endDate
            let hasLearning = commits.contains { calendar.isDate($0.timestamp, inSameDayAs: date) }
            if hasLearning {
                learningDays += 1
            }
        }
        
        return Double(learningDays) / Double(days) * 100.0
    }
    
    /// Determine dominant learning type
    private func determineDominantLearningType(commits: [Commit]) -> CommitType? {
        let learningTypes: [CommitType] = [.learning, .skill, .reading, .creativity]
        let typeCounts = learningTypes.map { type in
            (type, commits.filter { $0.type == type }.count)
        }
        
        return typeCounts.max { $0.1 < $1.1 }?.0
    }
    
    /// Determine learning trend direction
    private func determineLearningTrend(commits: [Commit], days: Int) -> TrendDirection {
        let midpoint = days / 2
        let calendar = Calendar.current
        let endDate = Date()
        let midDate = calendar.date(byAdding: .day, value: -midpoint, to: endDate) ?? endDate
        
        let recentCommits = commits.filter { $0.timestamp >= midDate }
        let earlierCommits = commits.filter { $0.timestamp < midDate }
        
        let recentRate = Double(recentCommits.count) / Double(midpoint)
        let earlierRate = Double(earlierCommits.count) / Double(midpoint)
        
        if earlierRate == 0 {
            return recentRate > 0 ? .increasing : .stable
        }
        
        let change = (recentRate - earlierRate) / earlierRate * 100.0
        
        if change > 20 {
            return .increasing
        } else if change < -20 {
            return .decreasing
        } else {
            return .stable
        }
    }
    
    // MARK: - Overall Growth Score Calculation
    
    /// Calculate overall growth score from all trend analyses
    private func calculateOverallGrowthScore(from analysis: GrowthTrendAnalysis) -> Double {
        let commitWeight = 0.25
        let branchWeight = 0.25
        let goalWeight = 0.25
        let productivityWeight = 0.15
        let skillWeight = 0.10
        
        // Convert trend directions to scores
        let commitScore = trendDirectionToScore(analysis.commitTrends.trendDirection) * analysis.commitTrends.consistencyScore / 100.0
        let branchScore = trendDirectionToScore(.increasing) * 50.0 // Simplified for branch activity
        let goalScore = trendDirectionToScore(analysis.goalCompletionTrends.overallTrend) * analysis.goalCompletionTrends.averageCompletionRate * 100.0
        let productivityScore = trendDirectionToScore(analysis.productivityTrends.overallTrend) * analysis.productivityTrends.averageProductivityScore / 100.0
        let skillScore = analysis.skillDevelopmentTrends.learningConsistencyScore
        
        let totalScore = (commitScore * commitWeight) +
                        (branchScore * branchWeight) +
                        (goalScore * goalWeight) +
                        (productivityScore * productivityWeight) +
                        (skillScore * skillWeight)
        
        return min(100.0, max(0.0, totalScore))
    }
    
    /// Convert trend direction to numerical score
    private func trendDirectionToScore(_ direction: TrendDirection) -> Double {
        switch direction {
        case .increasing:
            return 100.0
        case .stable:
            return 70.0
        case .decreasing:
            return 30.0
        }
    }
    
    // MARK: - Personal Efficiency Analysis
    
    /// Analyze personal efficiency patterns and provide suggestions
    func analyzePersonalEfficiency() async throws -> PersonalEfficiencyAnalysis {
        do {
            let userStats = try await statisticsManager.collectUserStatistics()
            let productivityScore = try await statisticsManager.getProductivityScore(days: 30)
            
            // Analyze time patterns
            let timePatterns = analyzeTimePatterns(from: userStats.activityStatistics)
            
            // Analyze goal setting patterns
            let goalPatterns = analyzeGoalSettingPatterns(from: userStats.branchStatistics)
            
            // Generate efficiency suggestions
            let suggestions = generateEfficiencySuggestions(
                userStats: userStats,
                productivityScore: productivityScore,
                timePatterns: timePatterns
            )
            
            return PersonalEfficiencyAnalysis(
                overallEfficiencyScore: calculateEfficiencyScore(userStats: userStats, productivityScore: productivityScore),
                timePatterns: timePatterns,
                goalPatterns: goalPatterns,
                suggestions: suggestions,
                strengths: identifyStrengths(from: userStats),
                improvementAreas: identifyImprovementAreas(from: userStats)
            )
            
        } catch {
            throw TrendAnalysisError.efficiencyAnalysisFailed(error.localizedDescription)
        }
    }
    
    /// Analyze time usage patterns
    private func analyzeTimePatterns(from activityStats: ActivityStatistics) -> TimePatterns {
        return TimePatterns(
            mostProductiveHour: activityStats.mostActiveHour,
            mostProductiveDay: activityStats.mostActiveWeekday,
            activityDistribution: activityStats.dailyActivityPattern,
            consistencyScore: Double(activityStats.commitsLast30Days) / 30.0 * 100.0
        )
    }
    
    /// Analyze goal setting patterns
    private func analyzeGoalSettingPatterns(from branchStats: BranchStatistics) -> GoalSettingPatterns {
        return GoalSettingPatterns(
            averageGoalsPerMonth: Double(branchStats.totalBranches) / 3.0, // Rough estimate
            successRate: branchStats.successRatePercentage,
            averageCompletionTime: branchStats.averageCompletionDays,
            goalComplexityTrend: .stable // Simplified
        )
    }
    
    /// Generate efficiency improvement suggestions
    private func generateEfficiencySuggestions(
        userStats: UserStatistics,
        productivityScore: ProductivityScore,
        timePatterns: TimePatterns
    ) -> [EfficiencySuggestion] {
        var suggestions: [EfficiencySuggestion] = []
        
        // Consistency suggestions
        if timePatterns.consistencyScore < 50 {
            suggestions.append(EfficiencySuggestion(
                type: .consistency,
                title: "提高活动一致性",
                description: "建议每天至少进行一次提交，保持学习和进步的连续性",
                priority: .high,
                estimatedImpact: .medium
            ))
        }
        
        // Time optimization suggestions
        if timePatterns.mostProductiveHour < 12 {
            suggestions.append(EfficiencySuggestion(
                type: .timeOptimization,
                title: "利用上午时光",
                description: "您在上午时段最为活跃，建议将重要任务安排在这个时间",
                priority: .medium,
                estimatedImpact: .high
            ))
        }
        
        // Goal setting suggestions
        if userStats.goalCompletionStatistics.completionRatePercentage < 60 {
            suggestions.append(EfficiencySuggestion(
                type: .goalSetting,
                title: "优化目标设定",
                description: "建议设定更具体、可衡量的小目标，提高完成率",
                priority: .high,
                estimatedImpact: .high
            ))
        }
        
        // Learning suggestions
        if userStats.commitStatistics.typeDistribution.first(where: { $0.type == .learning })?.percentage ?? 0 < 20 {
            suggestions.append(EfficiencySuggestion(
                type: .learning,
                title: "增加学习活动",
                description: "建议增加学习类型的提交，促进技能发展",
                priority: .medium,
                estimatedImpact: .medium
            ))
        }
        
        return suggestions
    }
    
    /// Calculate overall efficiency score
    private func calculateEfficiencyScore(userStats: UserStatistics, productivityScore: ProductivityScore) -> Double {
        let completionWeight = 0.3
        let consistencyWeight = 0.3
        let productivityWeight = 0.4
        
        let completionScore = userStats.goalCompletionStatistics.completionRatePercentage
        let consistencyScore = Double(userStats.streakStatistics.currentCommitStreak) * 10.0
        let prodScore = productivityScore.score
        
        return min(100.0, (completionScore * completionWeight) + 
                          (min(100.0, consistencyScore) * consistencyWeight) + 
                          (prodScore * productivityWeight))
    }
    
    /// Identify user strengths
    private func identifyStrengths(from userStats: UserStatistics) -> [String] {
        var strengths: [String] = []
        
        if userStats.streakStatistics.currentCommitStreak >= 7 {
            strengths.append("保持良好的学习连续性")
        }
        
        if userStats.goalCompletionStatistics.completionRatePercentage >= 70 {
            strengths.append("目标完成率较高")
        }
        
        if userStats.activityStatistics.activityScore >= 60 {
            strengths.append("活跃度表现优秀")
        }
        
        if let mostUsedType = userStats.commitStatistics.mostUsedType {
            strengths.append("在\(mostUsedType.displayName)方面表现突出")
        }
        
        return strengths
    }
    
    /// Identify improvement areas
    private func identifyImprovementAreas(from userStats: UserStatistics) -> [String] {
        var areas: [String] = []
        
        if userStats.streakStatistics.currentCommitStreak < 3 {
            areas.append("提高学习连续性")
        }
        
        if userStats.goalCompletionStatistics.completionRatePercentage < 50 {
            areas.append("改善目标完成率")
        }
        
        if userStats.activityStatistics.activityScore < 40 {
            areas.append("增加整体活跃度")
        }
        
        if userStats.goalCompletionStatistics.averageActiveProgressPercentage < 30 {
            areas.append("提高任务执行效率")
        }
        
        return areas
    }
    
    // MARK: - Growth Visualization Data
    
    /// Generate data for growth visualization charts
    func generateGrowthVisualizationData(timeframe: Int = 90) async throws -> GrowthVisualizationData {
        do {
            let commitFrequency = try await statisticsManager.getCommitFrequencyData(days: timeframe)
            let goalCompletion = try await statisticsManager.getGoalCompletionTrend(months: timeframe / 30)
            
            return GrowthVisualizationData(
                commitFrequencyChart: commitFrequency.map { ChartDataPoint(date: $0.date, value: Double($0.commitCount)) },
                goalCompletionChart: goalCompletion.map { ChartDataPoint(date: $0.month, value: $0.completionRatePercentage) },
                activityHeatmap: generateActivityHeatmapData(days: timeframe),
                progressTimeline: try await generateProgressTimelineData(days: timeframe)
            )
            
        } catch {
            throw TrendAnalysisError.visualizationDataFailed(error.localizedDescription)
        }
    }
    
    /// Generate activity heatmap data
    private func generateActivityHeatmapData(days: Int) -> [[Double]] {
        // Generate a 7x(days/7) grid for weekday activity heatmap
        let weeks = days / 7
        var heatmapData: [[Double]] = Array(repeating: Array(repeating: 0.0, count: 7), count: weeks)
        
        // This would be populated with actual activity data
        // For now, return empty structure
        return heatmapData
    }
    
    /// Generate progress timeline data
    private func generateProgressTimelineData(days: Int) async throws -> [ProgressTimelineEvent] {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) ?? endDate
        
        let branches = try await branchRepository.findAll()
        let completedBranches = branches.filter { 
            $0.status == .completed && 
            $0.completedAt != nil && 
            $0.completedAt! >= startDate 
        }
        
        return completedBranches.map { branch in
            ProgressTimelineEvent(
                date: branch.completedAt ?? branch.createdAt,
                type: .goalCompleted,
                title: branch.name,
                description: "完成目标: \(branch.name)"
            )
        }.sorted { $0.date < $1.date }
    }
    
    // MARK: - Error Handling
    
    func clearError() {
        error = nil
    }
}