import SwiftUI

struct VersionTimelineView: View {
    let versionHistory: [VersionRecord]
    @State private var selectedVersion: VersionRecord?
    @State private var showingVersionDetail = false
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(versionHistory.enumerated()), id: \.element.id) { index, version in
                    VersionTimelineItemView(
                        version: version,
                        isLatest: index == 0,
                        isFirst: index == versionHistory.count - 1,
                        onTap: {
                            selectedVersion = version
                            showingVersionDetail = true
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle("版本历史")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingVersionDetail) {
            if let version = selectedVersion {
                VersionDetailView(version: version)
            }
        }
    }
}

struct VersionTimelineItemView: View {
    let version: VersionRecord
    let isLatest: Bool
    let isFirst: Bool
    let onTap: () -> Void
    
    @State private var isGlowing = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Timeline connector
            VStack(spacing: 0) {
                // Top line (hidden for first item)
                if !isLatest {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: 2, height: 20)
                }
                
                // Version node
                ZStack {
                    // Outer glow effect for important milestones
                    if version.isImportantMilestone {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [.purple.opacity(0.6), .clear],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 25
                                )
                            )
                            .frame(width: 50, height: 50)
                            .scaleEffect(isGlowing ? 1.2 : 1.0)
                            .opacity(isGlowing ? 0.8 : 0.4)
                            .animation(
                                .easeInOut(duration: 2.0)
                                .repeatForever(autoreverses: true),
                                value: isGlowing
                            )
                    }
                    
                    // Main version circle
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
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    
                    // Version icon
                    Image(systemName: version.isImportantMilestone ? "star.fill" : "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
                
                // Bottom line (hidden for last item)
                if !isFirst {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: 2, height: 20)
                }
            }
            
            // Version content
            VStack(alignment: .leading, spacing: 8) {
                // Version header
                HStack {
                    Text(version.version)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(version.isImportantMilestone ? .purple : .primary)
                    
                    if isLatest {
                        Text("当前")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(4)
                    }
                    
                    if version.isImportantMilestone {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                    
                    Spacer()
                    
                    Text(version.upgradedAt.formatted(.dateTime.month().day().hour().minute()))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Trigger branch
                Text("完成目标: \(version.triggerBranchName)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                // Description
                Text(version.versionDescription)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                
                // Statistics
                HStack(spacing: 16) {
                    VersionStatisticItem(
                        icon: "target",
                        value: "\(version.achievementCount)",
                        label: "完成目标"
                    )
                    
                    VersionStatisticItem(
                        icon: "doc.text",
                        value: "\(version.totalCommitsAtUpgrade)",
                        label: "总提交"
                    )
                }
                .padding(.top, 4)
            }
            .padding(.vertical, 12)
            .onTapGesture {
                onTap()
            }
        }
        .onAppear {
            if version.isImportantMilestone {
                isGlowing = true
            }
        }
    }
}

struct VersionStatisticItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    let sampleVersions = [
        VersionRecord(
            version: "v2.1",
            upgradedAt: Date(),
            triggerBranchName: "学习SwiftUI",
            versionDescription: "高频率记录 (15 次提交)、长期坚持 (21 天)、高完成度 (90%)",
            isImportantMilestone: false,
            achievementCount: 3,
            totalCommitsAtUpgrade: 45
        ),
        VersionRecord(
            version: "v2.0",
            upgradedAt: Date().addingTimeInterval(-30 * 24 * 3600),
            triggerBranchName: "职业转型",
            versionDescription: "重要人生转折点，成功转入技术行业",
            isImportantMilestone: true,
            achievementCount: 2,
            totalCommitsAtUpgrade: 30
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
    
    NavigationView {
        VersionTimelineView(versionHistory: sampleVersions)
    }
}