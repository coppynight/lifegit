import SwiftUI

struct VersionDetailView: View {
    let version: VersionRecord
    @Environment(\.dismiss) private var dismiss
    @State private var showingCelebration = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with version info
                    VStack(spacing: 16) {
                        // Version badge
                        ZStack {
                            Circle()
                                .fill(
                                    version.isImportantMilestone
                                        ? LinearGradient(
                                            colors: [.purple, .pink],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                        : LinearGradient(
                                            colors: [.blue, .cyan],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                )
                                .frame(width: 80, height: 80)
                                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                            
                            VStack(spacing: 2) {
                                Text(version.version)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                if version.isImportantMilestone {
                                    Image(systemName: "star.fill")
                                        .font(.caption)
                                        .foregroundColor(.yellow)
                                }
                            }
                        }
                        
                        VStack(spacing: 8) {
                            Text(version.isImportantMilestone ? "🎉 重要里程碑" : "🎯 版本升级")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(version.upgradedAt.formatted(.dateTime.weekday(.wide).month().day().year().hour().minute()))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Trigger information
                    VStack(alignment: .leading, spacing: 12) {
                        Text("触发目标")
                            .font(.headline)
                        
                        HStack {
                            Image(systemName: "target")
                                .foregroundColor(.blue)
                            Text(version.triggerBranchName)
                                .font(.body)
                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // Achievement description
                    VStack(alignment: .leading, spacing: 12) {
                        Text("成就描述")
                            .font(.headline)
                        
                        Text(version.versionDescription)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    
                    // Statistics grid
                    VStack(alignment: .leading, spacing: 12) {
                        Text("升级时统计")
                            .font(.headline)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            StatisticCard(
                                icon: "target",
                                iconColor: .green,
                                value: "\(version.achievementCount)",
                                label: "完成目标",
                                description: "累计完成的目标数量"
                            )
                            
                            StatisticCard(
                                icon: "doc.text",
                                iconColor: .blue,
                                value: "\(version.totalCommitsAtUpgrade)",
                                label: "总提交数",
                                description: "升级时的总提交记录"
                            )
                            
                            StatisticCard(
                                icon: "calendar",
                                iconColor: .orange,
                                value: "\(daysSinceUpgrade)",
                                label: "天数",
                                description: "距离升级已过天数"
                            )
                            
                            StatisticCard(
                                icon: version.isImportantMilestone ? "star.fill" : "checkmark.circle",
                                iconColor: version.isImportantMilestone ? .yellow : .purple,
                                value: version.isImportantMilestone ? "重要" : "常规",
                                label: "里程碑",
                                description: version.isImportantMilestone ? "重要人生节点" : "常规版本升级"
                            )
                        }
                    }
                    
                    // Version comparison (if not the first version)
                    if version.majorVersion > 1 || version.minorVersion > 0 {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("版本信息")
                                .font(.headline)
                            
                            VStack(spacing: 8) {
                                HStack {
                                    Text("主版本号:")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("\(version.majorVersion)")
                                        .fontWeight(.medium)
                                }
                                
                                HStack {
                                    Text("次版本号:")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("\(version.minorVersion)")
                                        .fontWeight(.medium)
                                }
                                
                                HStack {
                                    Text("版本类型:")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(version.isImportantMilestone ? "主要版本" : "次要版本")
                                        .fontWeight(.medium)
                                        .foregroundColor(version.isImportantMilestone ? .purple : .blue)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                    
                    // Celebration button for important milestones
                    if version.isImportantMilestone {
                        Button(action: {
                            showingCelebration = true
                        }) {
                            HStack {
                                Image(systemName: "party.popper")
                                Text("重播庆祝动画")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.purple, .pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("版本详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingCelebration) {
            VersionCelebrationView(version: version)
        }
    }
    
    private var daysSinceUpgrade: Int {
        let days = Calendar.current.dateComponents([.day], from: version.upgradedAt, to: Date()).day ?? 0
        return max(0, days)
    }
}

struct StatisticCard: View {
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

// MARK: - Preview

#Preview {
    let sampleVersion = VersionRecord(
        version: "v2.0",
        upgradedAt: Date().addingTimeInterval(-30 * 24 * 3600),
        triggerBranchName: "职业转型",
        versionDescription: "高频率记录 (25 次提交)、长期坚持 (45 天)、高完成度 (95%)、重要人生领域",
        isImportantMilestone: true,
        achievementCount: 3,
        totalCommitsAtUpgrade: 67
    )
    
    VersionDetailView(version: sampleVersion)
}