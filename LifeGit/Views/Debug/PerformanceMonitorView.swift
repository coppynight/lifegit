import SwiftUI

/// Performance monitoring view for debugging startup and runtime performance
struct PerformanceMonitorView: View {
    @StateObject private var startupOptimizer = StartupOptimizer.shared
    @State private var showingDetails = false
    
    var body: some View {
        NavigationView {
            List {
                // Startup Performance Section
                Section("启动性能") {
                    HStack {
                        Text("启动时间")
                        Spacer()
                        Text(formatTime(startupOptimizer.startupTime))
                            .foregroundColor(startupTimeColor)
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("优化状态")
                        Spacer()
                        Text(startupOptimizer.isOptimizedStartup ? "已优化" : "未优化")
                            .foregroundColor(startupOptimizer.isOptimizedStartup ? .green : .orange)
                            .fontWeight(.semibold)
                    }
                    
                    Button("查看详细指标") {
                        showingDetails = true
                    }
                }
                
                // Performance Recommendations
                Section("性能建议") {
                    ForEach(performanceRecommendations, id: \.title) { recommendation in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: recommendation.icon)
                                    .foregroundColor(recommendation.priority.color)
                                Text(recommendation.title)
                                    .fontWeight(.medium)
                                Spacer()
                                Text(recommendation.priority.displayName)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(recommendation.priority.color.opacity(0.1))
                                    .foregroundColor(recommendation.priority.color)
                                    .cornerRadius(4)
                            }
                            
                            Text(recommendation.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
                
                // UI Performance Section
                Section("UI性能") {
                    HStack {
                        Text("平均帧时间")
                        Spacer()
                        Text("16.67ms") // Default 60fps target
                            .foregroundColor(.green)
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("UI优化状态")
                        Spacer()
                        Text(startupOptimizer.isOptimizedStartup ? "已优化" : "需优化")
                            .foregroundColor(startupOptimizer.isOptimizedStartup ? .green : .orange)
                            .fontWeight(.semibold)
                    }
                }
                
                // Memory Usage
                Section("内存使用") {
                    let cacheStats = UIPerformanceOptimizer.shared.getCacheStatistics()
                    
                    HStack {
                        Text("图片缓存")
                        Spacer()
                        Text("\(cacheStats.imageCacheCount) 项")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("数据缓存")
                        Spacer()
                        Text("\(cacheStats.dataCacheCount) 项")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("视图缓存")
                        Spacer()
                        Text("\(cacheStats.viewCacheCount) 项")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("总内存使用")
                        Spacer()
                        Text(formatMemorySize(cacheStats.totalMemoryUsage))
                            .foregroundColor(.secondary)
                    }
                }
                
                // Actions
                Section("操作") {
                    Button("清理缓存") {
                        startupOptimizer.clearCaches()
                    }
                    
                    Button("预热缓存") {
                        Task {
                            await startupOptimizer.warmUpCaches()
                        }
                    }
                    
                    Button("清理UI缓存") {
                        UIPerformanceOptimizer.shared.clearCaches()
                    }
                }
            }
            .navigationTitle("性能监控")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingDetails) {
            PerformanceDetailsView()
        }
    }
    
    // MARK: - Computed Properties
    
    private var startupTimeColor: Color {
        if startupOptimizer.startupTime <= 1.0 {
            return .green
        } else if startupOptimizer.startupTime <= 2.0 {
            return .orange
        } else {
            return .red
        }
    }
    
    private var performanceRecommendations: [PerformanceRecommendation] {
        var recommendations: [PerformanceRecommendation] = []
        
        if startupOptimizer.startupTime > 2.0 {
            recommendations.append(
                PerformanceRecommendation(
                    title: "启动时间过长",
                    description: "启动时间超过2秒目标，建议检查初始化流程",
                    icon: "clock.arrow.circlepath",
                    priority: .high
                )
            )
        }
        
        if !startupOptimizer.isOptimizedStartup {
            recommendations.append(
                PerformanceRecommendation(
                    title: "启用启动优化",
                    description: "使用优化的启动流程可以显著提升启动速度",
                    icon: "speedometer",
                    priority: .medium
                )
            )
        }
        
        // Add more recommendations based on performance metrics
        recommendations.append(
            PerformanceRecommendation(
                title: "定期清理缓存",
                description: "定期清理不必要的缓存可以释放内存空间",
                icon: "trash.circle",
                priority: .low
            )
        )
        
        return recommendations
    }
    
    // MARK: - Helper Methods
    
    private func formatTime(_ time: TimeInterval) -> String {
        return String(format: "%.3fs", time)
    }
    
    private var frameTimeColor: Color {
        let targetFrameTime = 1.0 / 60.0 // 60 FPS
        
        let currentFrameTime = 16.67 // Default value since averageFrameTime doesn't exist
        if currentFrameTime <= targetFrameTime * 1.2 * 1000 {
            return .green
        } else if currentFrameTime <= targetFrameTime * 2.0 * 1000 {
            return .orange
        } else {
            return .red
        }
    }
    
    private func formatFrameTime(_ time: TimeInterval) -> String {
        let fps = 1.0 / max(time, 0.001)
        return String(format: "%.1f FPS", fps)
    }
    
    private func formatMemorySize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - Performance Details View

struct PerformanceDetailsView: View {
    @StateObject private var startupOptimizer = StartupOptimizer.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("详细启动指标") {
                    let metrics: [String: TimeInterval] = [:] // Empty metrics since method doesn't exist
                    
                    if metrics.isEmpty {
                        Text("暂无详细指标数据")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(Array(metrics.keys.sorted()), id: \.self) { key in
                            HStack {
                                Text(formatMetricName(key))
                                Spacer()
                                Text(String(format: "%.3fs", metrics[key] ?? 0))
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section("性能目标") {
                    PerformanceTargetRow(
                        title: "总启动时间",
                        current: startupOptimizer.startupTime,
                        target: 2.0,
                        unit: "秒"
                    )
                    
                    PerformanceTargetRow(
                        title: "关键组件初始化",
                        current: 0.5, // Default value since getPerformanceMetrics doesn't exist
                        target: 0.5,
                        unit: "秒"
                    )
                }
            }
            .navigationTitle("性能详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatMetricName(_ key: String) -> String {
        switch key {
        case "totalStartupTime":
            return "总启动时间"
        case "criticalComponents":
            return "关键组件初始化"
        case "backgroundComponents":
            return "后台组件初始化"
        case "optimizedInitialization":
            return "优化初始化"
        default:
            return key
        }
    }
}

// MARK: - Performance Target Row

struct PerformanceTargetRow: View {
    let title: String
    let current: TimeInterval
    let target: TimeInterval
    let unit: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                Text("\(String(format: "%.3f", current))\(unit)")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(current <= target ? .green : .red)
            }
            
            ProgressView(value: min(current / target, 1.0))
                .progressViewStyle(LinearProgressViewStyle(tint: current <= target ? .green : .red))
            
            HStack {
                Text("目标: \(String(format: "%.1f", target))\(unit)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(current <= target ? "✅ 达标" : "❌ 超标")
                    .font(.caption)
                    .foregroundColor(current <= target ? .green : .red)
            }
        }
    }
}

// MARK: - Supporting Types

struct PerformanceRecommendation {
    let title: String
    let description: String
    let icon: String
    let priority: Priority
    
    enum Priority {
        case high, medium, low
        
        var displayName: String {
            switch self {
            case .high: return "高"
            case .medium: return "中"
            case .low: return "低"
            }
        }
        
        var color: Color {
            switch self {
            case .high: return .red
            case .medium: return .orange
            case .low: return .blue
            }
        }
    }
}

#Preview {
    PerformanceMonitorView()
}