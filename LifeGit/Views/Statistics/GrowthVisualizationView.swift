import SwiftUI
import SwiftData
import Charts

/// View for displaying growth trends and visualization
struct GrowthVisualizationView: View {
    @StateObject private var statisticsManager: StatisticsManager
    @StateObject private var trendAnalyzer: TrendAnalyzer
    
    @State private var userStatistics: UserStatistics?
    @State private var growthTrends: GrowthTrendAnalysis?
    @State private var efficiencyAnalysis: PersonalEfficiencyAnalysis?
    @State private var isLoading = false
    @State private var error: Error?
    @State private var selectedTimeframe = 90
    
    private let timeframeOptions = [30, 60, 90, 180]
    
    init(
        statisticsManager: StatisticsManager,
        trendAnalyzer: TrendAnalyzer
    ) {
        self._statisticsManager = StateObject(wrappedValue: statisticsManager)
        self._trendAnalyzer = StateObject(wrappedValue: trendAnalyzer)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Timeframe Selector
                    timeframeSelectorView
                    
                    if isLoading {
                        loadingView
                    } else if let error = error {
                        errorView(error)
                    } else {
                        contentView
                    }
                }
                .padding()
            }
            .navigationTitle("成长可视化")
            .refreshable {
                await loadData()
            }
        }
        .task {
            await loadData()
        }
    }
    
    // MARK: - Timeframe Selector
    
    private var timeframeSelectorView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("分析时间范围")
                .font(.headline)
            
            Picker("时间范围", selection: $selectedTimeframe) {
                ForEach(timeframeOptions, id: \.self) { days in
                    Text("\(days)天").tag(days)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedTimeframe) { _, _ in
                Task {
                    await loadData()
                }
            }
        }
    }
    
    // MARK: - Content Views
    
    @ViewBuilder
    private var contentView: some View {
        if let userStats = userStatistics {
            overallStatsView(userStats)
        }
        
        if let trends = growthTrends {
            growthTrendsView(trends)
        }
        
        if let efficiency = efficiencyAnalysis {
            efficiencyAnalysisView(efficiency)
        }
    }
    
    // MARK: - Overall Statistics View
    
    private func overallStatsView(_ stats: UserStatistics) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("整体统计")
                .font(.title2)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                GrowthStatCard(
                    title: "用户等级",
                    value: stats.userLevel.displayName,
                    subtitle: stats.userLevel.emoji,
                    color: .blue
                )
                
                GrowthStatCard(
                    title: "参与度评分",
                    value: String(format: "%.0f", stats.engagementScore),
                    subtitle: "分",
                    color: .green
                )
                
                GrowthStatCard(
                    title: "活跃分支",
                    value: "\(stats.branchStatistics.activeBranches)",
                    subtitle: "个",
                    color: .orange
                )
                
                GrowthStatCard(
                    title: "完成率",
                    value: String(format: "%.1f%%", stats.goalCompletionStatistics.completionRatePercentage),
                    subtitle: "目标完成",
                    color: .purple
                )
                
                GrowthStatCard(
                    title: "连续天数",
                    value: "\(stats.streakStatistics.currentCommitStreak)",
                    subtitle: "天",
                    color: .red
                )
                
                GrowthStatCard(
                    title: "总提交数",
                    value: "\(stats.commitStatistics.totalCommits)",
                    subtitle: "次",
                    color: .cyan
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Growth Trends View
    
    private func growthTrendsView(_ trends: GrowthTrendAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("成长趋势分析")
                .font(.title2)
                .fontWeight(.semibold)
            
            // Overall Growth Score
            HStack {
                VStack(alignment: .leading) {
                    Text("整体成长评分")
                        .font(.headline)
                    Text(String(format: "%.1f", trends.overallGrowthScore))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(colorForScore(trends.overallGrowthScore))
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(trends.growthLevel.displayName)
                        .font(.title3)
                        .fontWeight(.medium)
                    Text(trends.growthLevel.emoji)
                        .font(.largeTitle)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            // Key Insights
            if !trends.keyInsights.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("关键洞察")
                        .font(.headline)
                    
                    ForEach(trends.keyInsights, id: \.self) { insight in
                        HStack(alignment: .top) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            Text(insight)
                                .font(.body)
                                .multilineTextAlignment(.leading)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            
            // Trend Details
            trendDetailsView(trends)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func trendDetailsView(_ trends: GrowthTrendAnalysis) -> some View {
        VStack(spacing: 12) {
            // Commit Trends
            TrendRowView(
                title: "提交活动",
                trend: trends.commitTrends.trendDirection,
                value: String(format: "%.1f", trends.commitTrends.averageCommitsPerDay),
                subtitle: "次/天",
                change: trends.commitTrends.formattedChangePercentage
            )
            
            // Goal Completion Trends
            TrendRowView(
                title: "目标完成",
                trend: trends.goalCompletionTrends.overallTrend,
                value: String(format: "%.1f%%", trends.goalCompletionTrends.averageCompletionRatePercentage),
                subtitle: "完成率",
                change: trends.goalCompletionTrends.formattedImprovementPercentage
            )
            
            // Productivity Trends
            TrendRowView(
                title: "生产力",
                trend: trends.productivityTrends.overallTrend,
                value: String(format: "%.1f", trends.productivityTrends.averageProductivityScore),
                subtitle: "分",
                change: trends.productivityTrends.formattedChangePercentage
            )
            
            // Skill Development
            TrendRowView(
                title: "技能发展",
                trend: trends.skillDevelopmentTrends.learningTrend,
                value: String(format: "%.1f%%", trends.skillDevelopmentTrends.learningFrequency),
                subtitle: "学习频率",
                change: nil
            )
        }
    }
    
    // MARK: - Efficiency Analysis View
    
    private func efficiencyAnalysisView(_ efficiency: PersonalEfficiencyAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("个人效率分析")
                .font(.title2)
                .fontWeight(.semibold)
            
            // Efficiency Score
            HStack {
                VStack(alignment: .leading) {
                    Text("效率评分")
                        .font(.headline)
                    Text(String(format: "%.1f", efficiency.overallEfficiencyScore))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(colorForScore(efficiency.overallEfficiencyScore))
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(efficiency.efficiencyLevel.displayName)
                        .font(.title3)
                        .fontWeight(.medium)
                    Text(efficiency.efficiencyLevel.emoji)
                        .font(.largeTitle)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            // Time Patterns
            timePatternView(efficiency.timePatterns)
            
            // Suggestions
            if !efficiency.suggestions.isEmpty {
                suggestionsView(efficiency.suggestions)
            }
            
            // Strengths and Improvements
            strengthsAndImprovementsView(efficiency)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func timePatternView(_ patterns: TimePatterns) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("时间模式")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("最佳时段")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(patterns.mostProductiveHourFormatted)
                        .font(.title3)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("最佳日期")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(patterns.mostProductiveDayName)
                        .font(.title3)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private func suggestionsView(_ suggestions: [EfficiencySuggestion]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("改进建议")
                .font(.headline)
            
            ForEach(suggestions.prefix(3), id: \.title) { suggestion in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(suggestion.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text(suggestion.priority.displayName)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(suggestion.priorityColor).opacity(0.2))
                                .foregroundColor(Color(suggestion.priorityColor))
                                .cornerRadius(4)
                        }
                        
                        Text(suggestion.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private func strengthsAndImprovementsView(_ efficiency: PersonalEfficiencyAnalysis) -> some View {
        HStack(alignment: .top, spacing: 16) {
            // Strengths
            VStack(alignment: .leading, spacing: 8) {
                Text("优势")
                    .font(.headline)
                    .foregroundColor(.green)
                
                ForEach(efficiency.strengths.prefix(3), id: \.self) { strength in
                    HStack(alignment: .top) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text(strength)
                            .font(.caption)
                            .multilineTextAlignment(.leading)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Improvements
            VStack(alignment: .leading, spacing: 8) {
                Text("改进点")
                    .font(.headline)
                    .foregroundColor(.orange)
                
                ForEach(efficiency.improvementAreas.prefix(3), id: \.self) { area in
                    HStack(alignment: .top) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        Text(area)
                            .font(.caption)
                            .multilineTextAlignment(.leading)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    // MARK: - Helper Views
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("分析成长趋势中...")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    private func errorView(_ error: Error) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            
            Text("分析失败")
                .font(.headline)
            
            Text(error.localizedDescription)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("重试") {
                Task {
                    await loadData()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding()
    }
    
    // MARK: - Helper Methods
    
    private func colorForScore(_ score: Double) -> Color {
        switch score {
        case 0..<20:
            return .red
        case 20..<40:
            return .orange
        case 40..<60:
            return .yellow
        case 60..<80:
            return .blue
        case 80...100:
            return .green
        default:
            return .gray
        }
    }
    
    private func loadData() async {
        isLoading = true
        error = nil
        
        do {
            // Load user statistics
            let stats = try await statisticsManager.collectUserStatistics(forceRefresh: true)
            await MainActor.run {
                self.userStatistics = stats
            }
            
            // Load growth trends
            let trends = try await trendAnalyzer.analyzeGrowthTrends(timeframe: selectedTimeframe)
            await MainActor.run {
                self.growthTrends = trends
            }
            
            // Load efficiency analysis
            let efficiency = try await trendAnalyzer.analyzePersonalEfficiency()
            await MainActor.run {
                self.efficiencyAnalysis = efficiency
            }
            
        } catch {
            await MainActor.run {
                self.error = error
            }
        }
        
        await MainActor.run {
            self.isLoading = false
        }
    }
}

// MARK: - Supporting Views

struct GrowthStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(alignment: .bottom, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 1)
    }
}

struct TrendRowView: View {
    let title: String
    let trend: TrendDirection
    let value: String
    let subtitle: String
    let change: String?
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack(spacing: 4) {
                    Text(value)
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Text(trend.emoji)
                        .font(.caption)
                    
                    Text(trend.displayName)
                        .font(.caption)
                        .foregroundColor(Color(trend.color))
                }
                
                if let change = change {
                    Text(change)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    // 简化 Preview，避免复杂的依赖注入
    Text("Growth Visualization View")
        .navigationTitle("成长可视化")
}