import SwiftUI
import Charts

struct VersionAnalyticsView: View {
    let analysisResult: VersionAnalysisResult
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab selector
                Picker("分析类型", selection: $selectedTab) {
                    Text("概览").tag(0)
                    Text("趋势").tag(1)
                    Text("洞察").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Content based on selected tab
                ScrollView {
                    switch selectedTab {
                    case 0:
                        OverviewSection(analysisResult: analysisResult)
                    case 1:
                        TrendSection(analysisResult: analysisResult)
                    case 2:
                        InsightsSection(analysisResult: analysisResult)
                    default:
                        OverviewSection(analysisResult: analysisResult)
                    }
                }
            }
            .navigationTitle("版本分析")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Overview Section

struct OverviewSection: View {
    let analysisResult: VersionAnalysisResult
    
    var body: some View {
        VStack(spacing: 20) {
            // Current version card
            CurrentVersionCard(analysisResult: analysisResult)
            
            // Statistics grid
            StatisticsGrid(analysisResult: analysisResult)
            
            // Growth metrics
            GrowthMetricsCard(analysisResult: analysisResult)
            
            // Version history chart
            VersionHistoryChart(analysisResult: analysisResult)
        }
        .padding()
    }
}

struct CurrentVersionCard: View {
    let analysisResult: VersionAnalysisResult
    
    var body: some View {
        VStack(spacing: 12) {
            Text("当前版本")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(analysisResult.currentVersion)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            HStack(spacing: 16) {
                VStack {
                    Text("\(analysisResult.totalVersions)")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("总版本数")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                    .frame(height: 30)
                
                VStack {
                    Text("\(analysisResult.importantMilestones)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.purple)
                    Text("重要里程碑")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                    .frame(height: 30)
                
                VStack {
                    Text("\(Int(analysisResult.averageDaysBetweenUpgrades))")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    Text("平均间隔天数")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct StatisticsGrid: View {
    let analysisResult: VersionAnalysisResult
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            AnalyticsStatisticCard(
                icon: "target",
                iconColor: .green,
                value: "\(analysisResult.growthMetrics.achievementGrowth)",
                label: "目标增长",
                description: "累计完成目标增长数"
            )
            
            AnalyticsStatisticCard(
                icon: "doc.text",
                iconColor: .blue,
                value: "\(analysisResult.growthMetrics.commitGrowth)",
                label: "提交增长",
                description: "累计提交记录增长数"
            )
            
            AnalyticsStatisticCard(
                icon: "speedometer",
                iconColor: .orange,
                value: "\(Int(analysisResult.growthMetrics.productivityScore))",
                label: "生产力得分",
                description: "基于完成效率的得分"
            )
            
            AnalyticsStatisticCard(
                icon: "chart.line.uptrend.xyaxis",
                iconColor: .purple,
                value: "\(Int(analysisResult.growthMetrics.consistencyScore))",
                label: "一致性得分",
                description: "成长节奏稳定性得分"
            )
        }
    }
}

struct AnalyticsStatisticCard: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String
    let description: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text(description)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct GrowthMetricsCard: View {
    let analysisResult: VersionAnalysisResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("成长指标")
                .font(.headline)
            
            VStack(spacing: 8) {
                GrowthMetricRow(
                    title: "目标完成增长率",
                    value: "\(Int(analysisResult.growthMetrics.achievementGrowthRate))%",
                    color: .green
                )
                
                GrowthMetricRow(
                    title: "提交记录增长率",
                    value: "\(Int(analysisResult.growthMetrics.commitGrowthRate))%",
                    color: .blue
                )
                
                GrowthMetricRow(
                    title: "生产力得分",
                    value: "\(Int(analysisResult.growthMetrics.productivityScore))/100",
                    color: .orange
                )
                
                GrowthMetricRow(
                    title: "一致性得分",
                    value: "\(Int(analysisResult.growthMetrics.consistencyScore))/100",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct GrowthMetricRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

struct VersionHistoryChart: View {
    let analysisResult: VersionAnalysisResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("版本历史趋势")
                .font(.headline)
            
            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(Array(analysisResult.versionHistory.enumerated()), id: \.element.id) { index, version in
                        LineMark(
                            x: .value("版本", index),
                            y: .value("目标数", version.achievementCount)
                        )
                        .foregroundStyle(.green)
                        
                        PointMark(
                            x: .value("版本", index),
                            y: .value("目标数", version.achievementCount)
                        )
                        .foregroundStyle(version.isImportantMilestone ? .purple : .green)
                        .symbolSize(version.isImportantMilestone ? 100 : 50)
                    }
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        if let index = value.as(Int.self),
                           index < analysisResult.versionHistory.count {
                            AxisValueLabel {
                                Text(analysisResult.versionHistory[index].version)
                                    .font(.caption)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            } else {
                // Fallback for iOS 15
                Text("需要 iOS 16+ 才能显示图表")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

// MARK: - Trend Section

struct TrendSection: View {
    let analysisResult: VersionAnalysisResult
    
    var body: some View {
        VStack(spacing: 20) {
            // Trend indicators
            TrendIndicatorsCard(analysisResult: analysisResult)
            
            // Next upgrade prediction
            NextUpgradePredictionCard(analysisResult: analysisResult)
            
            // Detailed trend analysis
            DetailedTrendAnalysis(analysisResult: analysisResult)
        }
        .padding()
    }
}

struct TrendIndicatorsCard: View {
    let analysisResult: VersionAnalysisResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("趋势指标")
                .font(.headline)
            
            VStack(spacing: 12) {
                TrendIndicatorRow(
                    title: "升级频率",
                    trend: analysisResult.trendAnalysis.frequencyTrend
                )
                
                TrendIndicatorRow(
                    title: "目标完成",
                    trend: analysisResult.trendAnalysis.achievementTrend
                )
                
                TrendIndicatorRow(
                    title: "里程碑频率",
                    trend: analysisResult.trendAnalysis.milestoneTrend
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct TrendIndicatorRow: View {
    let title: String
    let trend: VersionTrendDirection
    
    var body: some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundColor(.secondary)
            
            Spacer()
            
            HStack(spacing: 4) {
                Image(systemName: trend.icon)
                    .font(.caption)
                    .foregroundColor(trend.color)
                
                Text(trend.displayName)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(trend.color)
            }
        }
    }
}

struct NextUpgradePredictionCard: View {
    let analysisResult: VersionAnalysisResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("下次升级预测")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("预计天数")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(analysisResult.trendAnalysis.nextUpgradePrediction.estimatedDays) 天")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("预测可信度")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(analysisResult.trendAnalysis.nextUpgradePrediction.confidence.displayName)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(analysisResult.trendAnalysis.nextUpgradePrediction.confidence.color)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct DetailedTrendAnalysis: View {
    let analysisResult: VersionAnalysisResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("详细趋势分析")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("• 升级频率趋势: \(analysisResult.trendAnalysis.frequencyTrend.displayName)")
                    .font(.body)
                
                Text("• 目标完成趋势: \(analysisResult.trendAnalysis.achievementTrend.displayName)")
                    .font(.body)
                
                Text("• 里程碑频率趋势: \(analysisResult.trendAnalysis.milestoneTrend.displayName)")
                    .font(.body)
                
                Text("• 基于历史数据，预计 \(analysisResult.trendAnalysis.nextUpgradePrediction.estimatedDays) 天后可能迎来下次版本升级")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

// MARK: - Insights Section

struct InsightsSection: View {
    let analysisResult: VersionAnalysisResult
    
    var body: some View {
        VStack(spacing: 16) {
            if analysisResult.insights.isEmpty {
                EmptyInsightsView()
            } else {
                ForEach(Array(analysisResult.insights.enumerated()), id: \.element.title) { index, insight in
                    InsightCard(insight: insight)
                }
            }
        }
        .padding()
    }
}

struct InsightCard: View {
    let insight: VersionInsight
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Insight icon
            Image(systemName: insight.type.icon)
                .font(.title2)
                .foregroundColor(insight.type.color)
                .frame(width: 32, height: 32)
                .background(insight.type.color.opacity(0.1))
                .cornerRadius(8)
            
            // Insight content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(insight.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    // Importance indicator
                    Circle()
                        .fill(insight.importance.color)
                        .frame(width: 8, height: 8)
                }
                
                Text(insight.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct EmptyInsightsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lightbulb")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("暂无洞察")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("继续使用应用，我们将为您提供更多个性化的成长洞察")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

// MARK: - Preview

#Preview {
    let sampleVersions = [
        VersionRecord(
            version: "v2.1",
            upgradedAt: Date(),
            triggerBranchName: "学习SwiftUI",
            versionDescription: "高频率记录、长期坚持、高完成度",
            isImportantMilestone: false,
            achievementCount: 5,
            totalCommitsAtUpgrade: 67
        ),
        VersionRecord(
            version: "v2.0",
            upgradedAt: Date().addingTimeInterval(-30 * 24 * 3600),
            triggerBranchName: "职业转型",
            versionDescription: "重要人生转折点",
            isImportantMilestone: true,
            achievementCount: 3,
            totalCommitsAtUpgrade: 45
        ),
        VersionRecord(
            version: "v1.0",
            upgradedAt: Date().addingTimeInterval(-90 * 24 * 3600),
            triggerBranchName: "Initial Setup",
            versionDescription: "Life Git journey begins",
            isImportantMilestone: false,
            achievementCount: 0,
            totalCommitsAtUpgrade: 0
        )
    ]
    
    let sampleAnalysis = VersionAnalysisResult(
        totalVersions: 3,
        importantMilestones: 1,
        regularUpgrades: 2,
        averageDaysBetweenUpgrades: 45,
        currentVersion: "v2.1",
        growthMetrics: GrowthMetrics(
            achievementGrowth: 5,
            achievementGrowthRate: 150,
            commitGrowth: 67,
            commitGrowthRate: 200,
            productivityScore: 75,
            consistencyScore: 85
        ),
        trendAnalysis: TrendAnalysis(
            frequencyTrend: .increasing,
            achievementTrend: .increasing,
            milestoneTrend: .stable,
            nextUpgradePrediction: NextUpgradePrediction(estimatedDays: 25, confidence: .high)
        ),
        insights: [
            VersionInsight(
                type: .achievement,
                title: "目标完成加速",
                description: "您的目标完成率提升了150%，保持这个势头！",
                importance: .high
            )
        ],
        versionHistory: sampleVersions
    )
    
    VersionAnalyticsView(analysisResult: sampleAnalysis)
}