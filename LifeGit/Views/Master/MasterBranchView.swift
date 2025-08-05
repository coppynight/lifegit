import SwiftUI
import SwiftData

struct MasterBranchView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appState: AppStateManager
    @Query private var commits: [Commit]
    @State private var selectedTimeRange: TimeRange = .all
    
    init() {
        // Query commits for master branch, sorted by date descending
        _commits = Query(
            filter: #Predicate<Commit> { commit in
                commit.branch?.isMaster == true
            },
            sort: \Commit.timestamp,
            order: .reverse
        )
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header with version info
                masterHeaderView
                
                // Statistics cards
                statisticsCardsView
                
                // Timeline section
                timelineSection
                
                // Quick actions
                quickActionsView
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .background(Color(.systemBackground))
        .refreshable {
            await appState.refreshBranches()
        }
    }
    
    // MARK: - Header View
    
    private var masterHeaderView: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("人生主线")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("记录人生的主要历程和成就")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("v\(currentVersion)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    
                    Text("当前版本")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
        }
    }
    
    // MARK: - Statistics Cards
    
    private var statisticsCardsView: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            StatisticCard(
                title: "活跃分支",
                value: "\(appState.activeBranches.count)",
                icon: "git.branch.circle.fill",
                color: .green
            )
            
            StatisticCard(
                title: "已完成",
                value: "\(appState.completedBranches.count)",
                icon: "checkmark.circle.fill",
                color: .blue
            )
            
            StatisticCard(
                title: "总提交",
                value: "\(commits.count)",
                icon: "doc.text.fill",
                color: .orange
            )
            
            StatisticCard(
                title: "连续天数",
                value: "\(consecutiveDays)",
                icon: "flame.fill",
                color: .red
            )
        }
    }
    
    // MARK: - Timeline Section
    
    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("提交时间线")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Time range picker
                Picker("时间范围", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.displayName).tag(range)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .font(.subheadline)
            }
            
            if filteredCommits.isEmpty {
                EmptyTimelineView()
            } else {
                CommitTimelineView(commits: filteredCommits)
            }
        }
    }
    
    // MARK: - Quick Actions
    
    private var quickActionsView: some View {
        VStack(spacing: 12) {
            Text("快速操作")
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 8) {
                Button(action: {
                    // TODO: Navigate to branch creation
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                        Text("创建新目标分支")
                            .font(.system(size: 16, weight: .medium))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                
                Button(action: {
                    // TODO: Navigate to commit creation
                }) {
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 20))
                        Text("记录人生里程碑")
                            .font(.system(size: 16, weight: .medium))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .foregroundColor(.blue)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var currentVersion: String {
        let completedCount = appState.completedBranches.count
        let majorVersion = completedCount / 10 + 1
        let minorVersion = completedCount % 10
        return "\(majorVersion).\(minorVersion)"
    }
    
    private var consecutiveDays: Int {
        // Calculate consecutive days with commits
        let calendar = Calendar.current
        let today = Date()
        var consecutiveCount = 0
        
        for i in 0..<365 { // Check up to a year
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            let hasCommitOnDate = commits.contains { commit in
                calendar.isDate(commit.timestamp, inSameDayAs: date)
            }
            
            if hasCommitOnDate {
                consecutiveCount += 1
            } else if i > 0 { // Don't break on first day if no commit today
                break
            }
        }
        
        return consecutiveCount
    }
    
    private var filteredCommits: [Commit] {
        let calendar = Calendar.current
        let now = Date()
        
        return commits.filter { commit in
            switch selectedTimeRange {
            case .all:
                return true
            case .week:
                return calendar.dateInterval(of: .weekOfYear, for: now)?.contains(commit.timestamp) ?? false
            case .month:
                return calendar.dateInterval(of: .month, for: now)?.contains(commit.timestamp) ?? false
            case .year:
                return calendar.dateInterval(of: .year, for: now)?.contains(commit.timestamp) ?? false
            }
        }
    }
}

// MARK: - Supporting Views

struct StatisticCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 32, height: 32)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minHeight: 88, maxHeight: 88) // 固定高度确保一致性
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct EmptyTimelineView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
            
            Text("暂无提交记录")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("开始创建分支并记录进展吧")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Supporting Types

enum TimeRange: CaseIterable {
    case all, week, month, year
    
    var displayName: String {
        switch self {
        case .all: return "全部"
        case .week: return "本周"
        case .month: return "本月"
        case .year: return "本年"
        }
    }
}

#Preview {
    NavigationStack {
        MasterBranchView()
            .environmentObject(AppStateManager())
    }
    .modelContainer(for: [User.self, Branch.self, Commit.self, TaskPlan.self, TaskItem.self])
}