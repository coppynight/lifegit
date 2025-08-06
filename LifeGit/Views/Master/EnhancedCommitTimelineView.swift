import SwiftUI

/// Enhanced timeline view displaying commits with tag markers
struct EnhancedCommitTimelineView: View {
    let commits: [Commit]
    let tags: [Tag]
    
    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(groupedTimelineItems.keys.sorted(by: >), id: \.self) { date in
                if let dayItems = groupedTimelineItems[date] {
                    EnhancedTimelineDaySection(
                        date: date,
                        items: dayItems
                    )
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Computed Properties
    
    private var groupedTimelineItems: [Date: [TimelineItem]] {
        let calendar = Calendar.current
        var items: [TimelineItem] = []
        
        // Add commits as timeline items
        for commit in commits {
            items.append(TimelineItem.commit(commit))
        }
        
        // Add tags as timeline items
        for tag in tags {
            items.append(TimelineItem.tag(tag))
        }
        
        // Group by date
        return Dictionary(grouping: items) { item in
            calendar.startOfDay(for: item.date)
        }
    }
}

/// Timeline item that can be either a commit or a tag
enum TimelineItem {
    case commit(Commit)
    case tag(Tag)
    
    var date: Date {
        switch self {
        case .commit(let commit):
            return commit.timestamp
        case .tag(let tag):
            return tag.createdAt
        }
    }
    
    var id: UUID {
        switch self {
        case .commit(let commit):
            return commit.id
        case .tag(let tag):
            return tag.id
        }
    }
}

/// Enhanced day section with both commits and tags
struct EnhancedTimelineDaySection: View {
    let date: Date
    let items: [TimelineItem]
    
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
                
                HStack(spacing: 8) {
                    if commitCount > 0 {
                        Text("\(commitCount)个提交")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray5))
                            .cornerRadius(8)
                    }
                    
                    if tagCount > 0 {
                        Text("\(tagCount)个标签")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
            
            // Timeline items for this day
            VStack(spacing: 8) {
                ForEach(sortedItems, id: \.id) { item in
                    switch item {
                    case .commit(let commit):
                        CommitTimelineRow(commit: commit)
                    case .tag(let tag):
                        TagTimelineMarker(tag: tag)
                    }
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
    
    private var sortedItems: [TimelineItem] {
        items.sorted { $0.date > $1.date }
    }
    
    private var commitCount: Int {
        items.filter { if case .commit = $0 { return true } else { return false } }.count
    }
    
    private var tagCount: Int {
        items.filter { if case .tag = $0 { return true } else { return false } }.count
    }
}

/// Special marker for tags in the timeline
struct TagTimelineMarker: View {
    let tag: Tag
    @State private var isGlowing = false
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    var body: some View {
        HStack(spacing: 12) {
            // Tag marker with special glow effect
            ZStack {
                // Glow effect for important tags
                if tag.isImportant {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [tag.type.color.opacity(0.6), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 25
                            )
                        )
                        .frame(width: 50, height: 50)
                        .scaleEffect(isGlowing ? 1.2 : 1.0)
                        .opacity(isGlowing ? 0.8 : 0.4)
                        .animation(
                            .easeInOut(duration: 2.5)
                            .repeatForever(autoreverses: true),
                            value: isGlowing
                        )
                }
                
                // Main tag icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [tag.type.color, tag.type.color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                    
                    Text(tag.type.emoji)
                        .font(.system(size: 18))
                }
                
                // Star indicator for important tags
                if tag.isImportant {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "star.fill")
                                .font(.system(size: 8))
                                .foregroundColor(.yellow)
                                .background(
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 12, height: 12)
                                )
                        }
                        Spacer()
                    }
                    .frame(width: 32, height: 32)
                }
            }
            
            // Tag content
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(tag.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(tag.type.color)
                    
                    Spacer()
                    
                    Text(timeFormatter.string(from: tag.createdAt))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                if !tag.tagDescription.isEmpty {
                    Text(tag.tagDescription)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack(spacing: 8) {
                    // Tag type indicator
                    HStack {
                        Image(systemName: "tag.fill")
                            .font(.system(size: 10))
                        Text(tag.type.displayName)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(tag.type.color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(tag.type.color.opacity(0.1))
                    .cornerRadius(4)
                    
                    // Version association indicator
                    if let version = tag.associatedVersion {
                        HStack {
                            Image(systemName: "arrow.branch")
                                .font(.system(size: 10))
                            Text("版本 \(version)")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                    }
                    
                    // Important tag indicator
                    if tag.isImportant {
                        HStack {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                            Text("重要")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.yellow.opacity(0.1))
                        .cornerRadius(4)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [
                    tag.type.color.opacity(0.08),
                    tag.type.color.opacity(0.03)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        colors: [
                            tag.type.color.opacity(0.3),
                            tag.type.color.opacity(0.1)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 1.5
                )
        )
        .onAppear {
            if tag.isImportant {
                isGlowing = true
            }
        }
    }
}

#Preview {
    let sampleCommits = [
        Commit(
            message: "完成了今天的学习任务",
            type: .taskComplete,
            branchId: UUID()
        )
    ]
    
    let sampleTags = [
        Tag(
            title: "大学毕业",
            tagDescription: "完成了四年的大学学习",
            type: .education,
            associatedVersion: "v2.0",
            isImportant: true
        )
    ]
    
    ScrollView {
        EnhancedCommitTimelineView(commits: sampleCommits, tags: sampleTags)
            .padding()
    }
}