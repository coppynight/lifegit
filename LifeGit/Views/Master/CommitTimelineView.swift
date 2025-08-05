import SwiftUI

/// Timeline view displaying commits in chronological order
struct CommitTimelineView: View {
    let commits: [Commit]
    
    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(groupedCommits.keys.sorted(by: >), id: \.self) { date in
                if let dayCommits = groupedCommits[date] {
                    CommitTimelineDaySection(
                        date: date,
                        commits: dayCommits
                    )
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Computed Properties
    
    private var groupedCommits: [Date: [Commit]] {
        let calendar = Calendar.current
        return Dictionary(grouping: commits) { commit in
            calendar.startOfDay(for: commit.timestamp)
        }
    }
}

/// Individual day section in the timeline
struct CommitTimelineDaySection: View {
    let date: Date
    let commits: [Commit]
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        return formatter
    }()
    
    private let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Date header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(dateFormatter.string(from: date))
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text(weekdayFormatter.string(from: date))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("\(commits.count)个提交")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
            }
            
            // Commits for this day
            VStack(spacing: 8) {
                ForEach(commits.sorted(by: { $0.timestamp > $1.timestamp })) { commit in
                    CommitTimelineRow(commit: commit)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .padding(.horizontal, 4)
        .padding(.bottom, 8)
    }
}

/// Individual commit row in the timeline
struct CommitTimelineRow: View {
    let commit: Commit
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    var body: some View {
        HStack(spacing: 12) {
            // Commit type icon
            Image(systemName: commitTypeIcon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(commitTypeColor)
                .frame(width: 24, height: 24)
                .background(commitTypeColor.opacity(0.1))
                .cornerRadius(6)
            
            // Commit content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(commit.message)
                        .font(.system(size: 15, weight: .medium))
                        .lineLimit(2)
                    
                    Spacer()
                    
                    Text(timeFormatter.string(from: commit.timestamp))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                // Additional content is already included in the message
                
                // Branch info if not master
                if let branch = commit.branch, !branch.isMaster {
                    HStack {
                        Image(systemName: "git.branch")
                            .font(.system(size: 10))
                        Text(branch.name)
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(8)
    }
    
    // MARK: - Computed Properties
    
    private var commitTypeIcon: String {
        switch commit.type {
        case .taskComplete:
            return "checkmark.circle.fill"
        case .learning:
            return "book.fill"
        case .reflection:
            return "lightbulb.fill"
        case .milestone:
            return "flag.fill"
        }
    }
    
    private var commitTypeColor: Color {
        switch commit.type {
        case .taskComplete:
            return .green
        case .learning:
            return .blue
        case .reflection:
            return .orange
        case .milestone:
            return .purple
        }
    }
}

#Preview {
    let sampleCommits = [
        Commit(
            message: "完成了今天的学习任务 - 学习了SwiftUI的基础知识，完成了第一个小项目",
            type: .taskComplete,
            branchId: UUID()
        ),
        Commit(
            message: "人生感悟 - 今天意识到坚持的重要性，每天进步一点点就是成功",
            type: .reflection,
            branchId: UUID()
        )
    ]
    
    ScrollView {
        CommitTimelineView(commits: sampleCommits)
            .padding()
    }
}