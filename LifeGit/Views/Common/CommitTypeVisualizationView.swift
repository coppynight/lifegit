import SwiftUI
import SwiftData
import Charts

// 提交类型可视化展示视图
struct CommitTypeVisualizationView: View {
    @StateObject private var analytics: CommitTypeAnalytics
    @State private var selectedVisualization: VisualizationType = .pieChart
    @State private var selectedTimeRange: TimeRange = .month
    
    let commits: [Commit]
    
    init(commits: [Commit], modelContext: ModelContext) {
        self.commits = commits
        self._analytics = StateObject(wrappedValue: CommitTypeAnalytics(modelContext: modelContext))
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // 控制面板
            controlPanel
            
            // 可视化内容
            visualizationContent
            
            // 统计摘要
            statisticsSummary
        }
        .padding()
        .onAppear {
            analytics.analyzeCommitTypes(for: commits)
        }
    }
    
    private var controlPanel: some View {
        VStack(spacing: 12) {
            // 可视化类型选择
            Picker("可视化类型", selection: $selectedVisualization) {
                ForEach(VisualizationType.allCases, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.segmented)
            
            // 时间范围选择
            Picker("时间范围", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.displayName).tag(range)
                }
            }
            .pickerStyle(.segmented)
        }
    }
    
    @ViewBuilder
    private var visualizationContent: some View {
        switch selectedVisualization {
        case .pieChart:
            pieChartView
        case .barChart:
            barChartView
        case .lineChart:
            lineChartView
        case .categoryChart:
            categoryChartView
        }
    }
    
    private var pieChartView: some View {
        VStack {
            Text("提交类型分布")
                .font(.headline)
                .padding(.bottom)
            
            Chart(analytics.typeStatistics.prefix(8), id: \.type) { statistic in
                SectorMark(
                    angle: .value("Count", statistic.count),
                    innerRadius: .ratio(0.4),
                    angularInset: 1.5
                )
                .foregroundStyle(statistic.type.color)
                .opacity(0.8)
            }
            .frame(height: 250)
            .chartLegend(position: .bottom, alignment: .center) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(analytics.typeStatistics.prefix(8), id: \.type) { statistic in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(statistic.type.color)
                                .frame(width: 8, height: 8)
                            Text("\(statistic.type.emoji) \(statistic.type.displayName)")
                                .font(.caption)
                            Text("(\(statistic.count))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
    
    private var barChartView: some View {
        VStack {
            Text("提交类型统计")
                .font(.headline)
                .padding(.bottom)
            
            Chart(analytics.typeStatistics.prefix(10), id: \.type) { statistic in
                BarMark(
                    x: .value("Type", statistic.type.displayName),
                    y: .value("Count", statistic.count)
                )
                .foregroundStyle(statistic.type.color)
                .opacity(0.8)
            }
            .frame(height: 250)
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.caption2)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
    }
    
    private var lineChartView: some View {
        VStack {
            Text("提交趋势")
                .font(.headline)
                .padding(.bottom)
            
            if !analytics.trendData.isEmpty {
                Chart {
                    ForEach(analytics.trendData, id: \.date) { trend in
                        ForEach(Array(trend.typeCounts.keys), id: \.self) { type in
                            LineMark(
                                x: .value("Date", trend.date),
                                y: .value("Count", trend.typeCounts[type] ?? 0)
                            )
                            .foregroundStyle(type.color)
                            .symbol(Circle())
                        }
                    }
                }
                .frame(height: 250)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
            } else {
                Text("暂无趋势数据")
                    .foregroundColor(.secondary)
                    .frame(height: 250)
            }
        }
    }
    
    private var categoryChartView: some View {
        VStack {
            Text("分类统计")
                .font(.headline)
                .padding(.bottom)
            
            Chart(analytics.categoryStatistics, id: \.category) { statistic in
                BarMark(
                    x: .value("Category", statistic.category.displayName),
                    y: .value("Count", statistic.count)
                )
                .foregroundStyle(statistic.category.color)
                .opacity(0.8)
            }
            .frame(height: 250)
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.caption2)
                }
            }
        }
    }
    
    private var statisticsSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("统计摘要")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                CommitStatisticCard(
                    title: "总提交数",
                    value: "\(commits.count)",
                    icon: "number.circle",
                    color: .blue
                )
                
                CommitStatisticCard(
                    title: "使用类型",
                    value: "\(analytics.typeStatistics.count)",
                    icon: "tag.circle",
                    color: .green
                )
                
                if let mostUsed = analytics.typeStatistics.first {
                    CommitStatisticCard(
                        title: "最常用",
                        value: mostUsed.type.displayName,
                        icon: "star.circle",
                        color: mostUsed.type.color
                    )
                }
                
                CommitStatisticCard(
                    title: "多样性",
                    value: String(format: "%.1f%%", analytics.analyzeCommitPatterns().diversityScore * 100),
                    icon: "chart.pie",
                    color: .purple
                )
            }
        }
    }
}

// 统计卡片组件
struct CommitStatisticCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// 可视化类型枚举
enum VisualizationType: CaseIterable {
    case pieChart, barChart, lineChart, categoryChart
    
    var displayName: String {
        switch self {
        case .pieChart: return "饼图"
        case .barChart: return "柱状图"
        case .lineChart: return "趋势图"
        case .categoryChart: return "分类图"
        }
    }
}

// 时间范围枚举
enum TimeRange: CaseIterable {
    case week, month, quarter, year
    
    var displayName: String {
        switch self {
        case .week: return "本周"
        case .month: return "本月"
        case .quarter: return "本季度"
        case .year: return "本年"
        }
    }
    
    var dateRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .week:
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            return (startOfWeek, now)
        case .month:
            let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
            return (startOfMonth, now)
        case .quarter:
            let startOfQuarter = calendar.dateInterval(of: .quarter, for: now)?.start ?? now
            return (startOfQuarter, now)
        case .year:
            let startOfYear = calendar.dateInterval(of: .year, for: now)?.start ?? now
            return (startOfYear, now)
        }
    }
}

#Preview {
    CommitTypeVisualizationView(
        commits: [],
        modelContext: ModelContext(try! ModelContainer(for: Commit.self))
    )
}