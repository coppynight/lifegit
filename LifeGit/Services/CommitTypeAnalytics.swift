import Foundation
import SwiftData
import SwiftUI

// 提交类型统计和分析服务
@MainActor
class CommitTypeAnalytics: ObservableObject {
    @Published var typeStatistics: [CommitTypeStatistic] = []
    @Published var categoryStatistics: [CommitCategoryStatistic] = []
    @Published var trendData: [CommitTypeTrend] = []
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // 分析提交类型统计
    func analyzeCommitTypes(for commits: [Commit]) {
        // 按类型统计
        let typeGroups = Dictionary(grouping: commits, by: { $0.type })
        typeStatistics = typeGroups.map { type, commits in
            CommitTypeStatistic(
                type: type,
                count: commits.count,
                percentage: Double(commits.count) / Double(commits.count) * 100,
                lastUsed: commits.max(by: { $0.timestamp < $1.timestamp })?.timestamp ?? Date(),
                averageInterval: calculateAverageInterval(for: commits)
            )
        }.sorted { $0.count > $1.count }
        
        // 按分类统计
        let categoryGroups = Dictionary(grouping: commits, by: { $0.type.category })
        categoryStatistics = categoryGroups.map { category, commits in
            CommitCategoryStatistic(
                category: category,
                count: commits.count,
                percentage: Double(commits.count) / Double(commits.count) * 100,
                types: Set(commits.map { $0.type })
            )
        }.sorted { $0.count > $1.count }
        
        // 生成趋势数据
        generateTrendData(for: commits)
    }
    
    // 获取用户偏好的提交类型
    func getUserPreferredTypes(limit: Int = 6) -> [CommitType] {
        return Array(typeStatistics.prefix(limit).map { $0.type })
    }
    
    // 获取推荐的提交类型（基于时间和使用频率）
    func getRecommendedTypes(for branch: Branch? = nil) -> [CommitType] {
        var commits: [Commit] = []
        
        if let branch = branch {
            // 如果指定分支，分析该分支的提交模式
            commits = branch.commits
        } else {
            // 否则分析所有提交
            let descriptor = FetchDescriptor<Commit>(
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            commits = (try? modelContext.fetch(descriptor)) ?? []
        }
        
        // 获取最近30天的提交
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let recentCommits = commits.filter { $0.timestamp >= thirtyDaysAgo }
        
        return CommitType.getRecommendedTypes(basedOn: recentCommits)
    }
    
    // 分析提交模式
    func analyzeCommitPatterns() -> CommitPatternAnalysis {
        let descriptor = FetchDescriptor<Commit>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        let allCommits = (try? modelContext.fetch(descriptor)) ?? []
        
        return CommitPatternAnalysis(
            totalCommits: allCommits.count,
            averageCommitsPerDay: calculateAverageCommitsPerDay(commits: allCommits),
            mostActiveHour: findMostActiveHour(commits: allCommits),
            mostActiveDay: findMostActiveDay(commits: allCommits),
            longestStreak: calculateLongestStreak(commits: allCommits),
            currentStreak: calculateCurrentStreak(commits: allCommits),
            diversityScore: calculateDiversityScore(commits: allCommits)
        )
    }
    
    // 生成个性化建议
    func generatePersonalizedSuggestions() -> [CommitTypeSuggestion] {
        let patterns = analyzeCommitPatterns()
        var suggestions: [CommitTypeSuggestion] = []
        
        // 基于多样性评分给出建议
        if patterns.diversityScore < 0.3 {
            suggestions.append(CommitTypeSuggestion(
                type: .creativity,
                reason: "尝试记录一些创意想法，增加提交的多样性",
                priority: .high
            ))
        }
        
        // 基于使用频率给出建议
        let underusedTypes = CommitType.allCases.filter { type in
            !typeStatistics.contains { $0.type == type }
        }
        
        if !underusedTypes.isEmpty {
            let suggestedType = underusedTypes.randomElement() ?? .reflection
            suggestions.append(CommitTypeSuggestion(
                type: suggestedType,
                reason: "尝试使用\(suggestedType.displayName)类型，丰富你的记录",
                priority: .medium
            ))
        }
        
        return suggestions
    }
    
    // MARK: - Private Methods
    
    private func calculateAverageInterval(for commits: [Commit]) -> TimeInterval {
        guard commits.count > 1 else { return 0 }
        
        let sortedCommits = commits.sorted { $0.timestamp < $1.timestamp }
        var totalInterval: TimeInterval = 0
        
        for i in 1..<sortedCommits.count {
            totalInterval += sortedCommits[i].timestamp.timeIntervalSince(sortedCommits[i-1].timestamp)
        }
        
        return totalInterval / Double(sortedCommits.count - 1)
    }
    
    private func generateTrendData(for commits: [Commit]) {
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let recentCommits = commits.filter { $0.timestamp >= thirtyDaysAgo }
        
        // 按天分组
        let dayGroups = Dictionary(grouping: recentCommits) { commit in
            calendar.startOfDay(for: commit.timestamp)
        }
        
        trendData = dayGroups.map { date, dayCommits in
            let typeGroups = Dictionary(grouping: dayCommits, by: { $0.type })
            return CommitTypeTrend(
                date: date,
                typeCounts: typeGroups.mapValues { $0.count }
            )
        }.sorted { $0.date < $1.date }
    }
    
    private func calculateAverageCommitsPerDay(commits: [Commit]) -> Double {
        guard !commits.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let firstCommit = commits.min { $0.timestamp < $1.timestamp }?.timestamp ?? Date()
        let daysSinceFirst = calendar.dateComponents([.day], from: firstCommit, to: Date()).day ?? 1
        
        return Double(commits.count) / Double(max(daysSinceFirst, 1))
    }
    
    private func findMostActiveHour(commits: [Commit]) -> Int {
        let hourGroups = Dictionary(grouping: commits) { commit in
            Calendar.current.component(.hour, from: commit.timestamp)
        }
        
        return hourGroups.max { $0.value.count < $1.value.count }?.key ?? 9
    }
    
    private func findMostActiveDay(commits: [Commit]) -> Int {
        let dayGroups = Dictionary(grouping: commits) { commit in
            Calendar.current.component(.weekday, from: commit.timestamp)
        }
        
        return dayGroups.max { $0.value.count < $1.value.count }?.key ?? 1
    }
    
    private func calculateLongestStreak(commits: [Commit]) -> Int {
        guard !commits.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let commitDays = Set(commits.map { calendar.startOfDay(for: $0.timestamp) })
        let sortedDays = commitDays.sorted()
        
        var longestStreak = 1
        var currentStreak = 1
        
        for i in 1..<sortedDays.count {
            let previousDay = sortedDays[i-1]
            let currentDay = sortedDays[i]
            
            if calendar.dateComponents([.day], from: previousDay, to: currentDay).day == 1 {
                currentStreak += 1
                longestStreak = max(longestStreak, currentStreak)
            } else {
                currentStreak = 1
            }
        }
        
        return longestStreak
    }
    
    private func calculateCurrentStreak(commits: [Commit]) -> Int {
        guard !commits.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let commitDays = Set(commits.map { calendar.startOfDay(for: $0.timestamp) })
        
        var streak = 0
        var checkDate = today
        
        while commitDays.contains(checkDate) {
            streak += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }
        
        return streak
    }
    
    private func calculateDiversityScore(commits: [Commit]) -> Double {
        guard !commits.isEmpty else { return 0 }
        
        let uniqueTypes = Set(commits.map { $0.type }).count
        let totalTypes = CommitType.allCases.count
        
        return Double(uniqueTypes) / Double(totalTypes)
    }
}

// MARK: - Data Models

struct CommitTypeStatistic {
    let type: CommitType
    let count: Int
    let percentage: Double
    let lastUsed: Date
    let averageInterval: TimeInterval
}

struct CommitCategoryStatistic {
    let category: CommitCategory
    let count: Int
    let percentage: Double
    let types: Set<CommitType>
}

struct CommitTypeTrend {
    let date: Date
    let typeCounts: [CommitType: Int]
}

struct CommitPatternAnalysis {
    let totalCommits: Int
    let averageCommitsPerDay: Double
    let mostActiveHour: Int
    let mostActiveDay: Int
    let longestStreak: Int
    let currentStreak: Int
    let diversityScore: Double
}

struct CommitTypeSuggestion {
    let type: CommitType
    let reason: String
    let priority: SuggestionPriority
}