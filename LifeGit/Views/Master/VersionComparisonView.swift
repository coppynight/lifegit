import SwiftUI

struct VersionComparisonView: View {
    let comparison: VersionComparison
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with version comparison
                    VersionComparisonHeader(comparison: comparison)
                    
                    // Time difference
                    TimeDifferenceCard(comparison: comparison)
                    
                    // Metrics comparison
                    MetricsComparisonCard(comparison: comparison)
                    
                    // Performance analysis
                    PerformanceAnalysisCard(comparison: comparison)
                    
                    // Detailed breakdown
                    DetailedBreakdownCard(comparison: comparison)
                }
                .padding()
            }
            .navigationTitle("版本对比")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct VersionComparisonHeader: View {
    let comparison: VersionComparison
    
    var body: some View {
        HStack(spacing: 32) {
            // Version 1
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            comparison.version1.isImportantMilestone
                                ? LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 60, height: 60)
                    
                    Text(comparison.version1.version)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                Text(comparison.version1.upgradedAt.formatted(.dateTime.month().day()))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if comparison.version1.isImportantMilestone {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                }
            }
            
            // Comparison arrow
            VStack(spacing: 4) {
                Image(systemName: "arrow.right")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("对比")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Version 2
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            comparison.version2.isImportantMilestone
                                ? LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 60, height: 60)
                    
                    Text(comparison.version2.version)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                Text(comparison.version2.upgradedAt.formatted(.dateTime.month().day()))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if comparison.version2.isImportantMilestone {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct TimeDifferenceCard: View {
    let comparison: VersionComparison
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("时间间隔")
                .font(.headline)
            
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
                
                Text("\(comparison.timeDifference) 天")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("从 \(comparison.version1.version)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("到 \(comparison.version2.version)")
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

struct MetricsComparisonCard: View {
    let comparison: VersionComparison
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("指标对比")
                .font(.headline)
            
            VStack(spacing: 12) {
                MetricComparisonRow(
                    title: "完成目标数",
                    value1: comparison.version1.achievementCount,
                    value2: comparison.version2.achievementCount,
                    difference: comparison.achievementDifference,
                    icon: "target",
                    color: .green
                )
                
                MetricComparisonRow(
                    title: "总提交数",
                    value1: comparison.version1.totalCommitsAtUpgrade,
                    value2: comparison.version2.totalCommitsAtUpgrade,
                    difference: comparison.commitDifference,
                    icon: "doc.text",
                    color: .blue
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct MetricComparisonRow: View {
    let title: String
    let value1: Int
    let value2: Int
    let difference: Int
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                Spacer()
            }
            
            HStack {
                // Value 1
                VStack(alignment: .leading, spacing: 2) {
                    Text("起始")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(value1)")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                // Arrow and difference
                VStack(spacing: 2) {
                    Image(systemName: difference >= 0 ? "arrow.up" : "arrow.down")
                        .foregroundColor(difference >= 0 ? .green : .red)
                        .font(.caption)
                    
                    Text(difference >= 0 ? "+\(difference)" : "\(difference)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(difference >= 0 ? .green : .red)
                }
                
                Spacer()
                
                // Value 2
                VStack(alignment: .trailing, spacing: 2) {
                    Text("结束")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(value2)")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct PerformanceAnalysisCard: View {
    let comparison: VersionComparison
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("效率分析")
                .font(.headline)
            
            VStack(spacing: 8) {
                PerformanceMetricRow(
                    title: "日均完成目标",
                    value: comparison.achievementRate,
                    unit: "个/天",
                    color: .green
                )
                
                PerformanceMetricRow(
                    title: "日均提交记录",
                    value: comparison.commitRate,
                    unit: "次/天",
                    color: .blue
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct PerformanceMetricRow: View {
    let title: String
    let value: Double
    let unit: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(String(format: "%.2f %@", value, unit))
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

struct DetailedBreakdownCard: View {
    let comparison: VersionComparison
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("详细分析")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                DetailRow(
                    title: "版本类型变化",
                    content: versionTypeAnalysis
                )
                
                DetailRow(
                    title: "成长速度",
                    content: growthSpeedAnalysis
                )
                
                DetailRow(
                    title: "效率评估",
                    content: efficiencyAnalysis
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private var versionTypeAnalysis: String {
        let type1 = comparison.version1.isImportantMilestone ? "重要里程碑" : "常规升级"
        let type2 = comparison.version2.isImportantMilestone ? "重要里程碑" : "常规升级"
        
        if comparison.version1.isImportantMilestone == comparison.version2.isImportantMilestone {
            return "两个版本都是\(type1)"
        } else {
            return "从\(type1)发展到\(type2)"
        }
    }
    
    private var growthSpeedAnalysis: String {
        let achievementRate = comparison.achievementRate
        
        if achievementRate > 0.5 {
            return "高速成长期，目标完成效率很高"
        } else if achievementRate > 0.2 {
            return "稳定成长期，保持良好的进步节奏"
        } else if achievementRate > 0 {
            return "缓慢成长期，建议提高目标完成频率"
        } else {
            return "成长停滞期，需要重新审视目标设定"
        }
    }
    
    private var efficiencyAnalysis: String {
        let commitRate = comparison.commitRate
        
        if commitRate > 2.0 {
            return "记录频率很高，保持了良好的反思习惯"
        } else if commitRate > 1.0 {
            return "记录频率适中，建议继续保持"
        } else if commitRate > 0.5 {
            return "记录频率偏低，可以增加日常反思"
        } else {
            return "记录频率很低，建议养成定期记录的习惯"
        }
    }
}

struct DetailRow: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text(content)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Preview

#Preview {
    let version1 = VersionRecord(
        version: "v1.5",
        upgradedAt: Date().addingTimeInterval(-60 * 24 * 3600),
        triggerBranchName: "健身计划",
        versionDescription: "建立了良好的运动习惯",
        isImportantMilestone: false,
        achievementCount: 2,
        totalCommitsAtUpgrade: 25
    )
    
    let version2 = VersionRecord(
        version: "v2.0",
        upgradedAt: Date().addingTimeInterval(-30 * 24 * 3600),
        triggerBranchName: "职业转型",
        versionDescription: "成功转入技术行业，重要人生转折点",
        isImportantMilestone: true,
        achievementCount: 5,
        totalCommitsAtUpgrade: 67
    )
    
    let comparison = VersionComparison(
        version1: version1,
        version2: version2,
        timeDifference: 30,
        achievementDifference: 3,
        commitDifference: 42,
        achievementRate: 0.1,
        commitRate: 1.4
    )
    
    VersionComparisonView(comparison: comparison)
}