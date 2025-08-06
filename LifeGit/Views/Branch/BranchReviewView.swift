import SwiftUI

/// View for displaying branch review report
struct BranchReviewView: View {
    let review: BranchReview
    @State private var selectedSection: ReviewSection = .summary
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header with scores
                    reviewHeaderView
                    
                    // Section selector
                    sectionSelectorView
                    
                    // Content based on selected section
                    selectedSectionContent
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("复盘报告")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Header View
    
    private var reviewHeaderView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Review type and date
            HStack {
                Label(review.reviewType.displayName, systemImage: review.reviewType == .completion ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.headline)
                    .foregroundColor(review.reviewType == .completion ? .green : .red)
                
                Spacer()
                
                Text(review.createdAt.formatted(.dateTime.month().day().hour().minute()))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Overall score card
            overallScoreCard
            
            // Statistics row
            statisticsRow
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var overallScoreCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("综合评分")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(alignment: .bottom, spacing: 4) {
                    Text(review.formattedOverallScore)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(colorForScore(review.overallScore))
                    
                    Text("/ 10.0")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                
                Text(review.scoreGrade)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(colorForScore(review.overallScore).opacity(0.1))
                    .foregroundColor(colorForScore(review.overallScore))
                    .cornerRadius(4)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 8) {
                scoreRow(title: "时间效率", score: review.timeEfficiencyScore)
                scoreRow(title: "目标达成", score: review.goalAchievementScore)
            }
        }
    }
    
    private func scoreRow(title: String, score: Double) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(String(format: "%.1f", score))
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(colorForScore(score))
        }
    }
    
    private var statisticsRow: some View {
        HStack {
            statisticItem(title: "执行天数", value: "\(review.totalDays)", unit: "天")
            Divider().frame(height: 20)
            statisticItem(title: "总提交", value: "\(review.totalCommits)", unit: "次")
            Divider().frame(height: 20)
            statisticItem(title: "任务完成", value: "\(review.completedTasks)/\(review.totalTasks)", unit: "")
            Divider().frame(height: 20)
            statisticItem(title: "日均提交", value: String(format: "%.1f", review.averageCommitsPerDay), unit: "次")
        }
    }
    
    private func statisticItem(title: String, value: String, unit: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            if !unit.isEmpty {
                Text(unit)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Section Selector
    
    private var sectionSelectorView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ReviewSection.allCases, id: \.self) { section in
                    Button(action: {
                        selectedSection = section
                    }) {
                        Text(section.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedSection == section ? Color.accentColor : Color(.systemGray5))
                            .foregroundColor(selectedSection == section ? .white : .primary)
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Section Content
    
    @ViewBuilder
    private var selectedSectionContent: some View {
        switch selectedSection {
        case .summary:
            reviewSectionCard(title: "复盘总结", content: review.summary, icon: "doc.text")
        case .achievements:
            reviewSectionCard(title: "成就分析", content: review.achievements, icon: "star.fill")
        case .challenges:
            reviewSectionCard(title: "挑战分析", content: review.challenges, icon: "exclamationmark.triangle.fill")
        case .lessons:
            reviewSectionCard(title: "经验教训", content: review.lessonsLearned, icon: "lightbulb.fill")
        case .recommendations:
            reviewSectionCard(title: "改进建议", content: review.recommendations, icon: "arrow.up.circle.fill")
        case .nextSteps:
            reviewSectionCard(title: "下一步建议", content: review.nextSteps, icon: "arrow.right.circle.fill")
        }
    }
    
    private func reviewSectionCard(title: String, content: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            Text(content)
                .font(.body)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Helper Functions
    
    private func colorForScore(_ score: Double) -> Color {
        switch score {
        case 9.0...10.0:
            return .green
        case 7.0..<9.0:
            return .blue
        case 5.0..<7.0:
            return .orange
        case 3.0..<5.0:
            return .red
        default:
            return .gray
        }
    }
}

// MARK: - Supporting Types

enum ReviewSection: CaseIterable {
    case summary
    case achievements
    case challenges
    case lessons
    case recommendations
    case nextSteps
    
    var displayName: String {
        switch self {
        case .summary:
            return "总结"
        case .achievements:
            return "成就"
        case .challenges:
            return "挑战"
        case .lessons:
            return "经验"
        case .recommendations:
            return "建议"
        case .nextSteps:
            return "下一步"
        }
    }
}

// MARK: - Preview

#Preview {
    BranchReviewView(review: BranchReview(
        branchId: UUID(),
        reviewType: .completion,
        summary: "这是一个成功完成的目标，通过系统化的任务规划和持续的执行，最终达成了预期目标。整个过程展现了良好的时间管理能力和执行力。",
        achievements: "1. 按时完成了所有核心任务\n2. 建立了良好的学习习惯\n3. 提升了专业技能水平\n4. 获得了团队认可",
        challenges: "1. 初期任务规划不够详细\n2. 中期遇到技术难点\n3. 时间安排偶有冲突\n4. 需要平衡工作和学习",
        lessonsLearned: "1. 详细的任务规划是成功的关键\n2. 遇到困难时要及时寻求帮助\n3. 保持持续学习的心态很重要\n4. 时间管理需要不断优化",
        recommendations: "1. 在未来的目标中加强前期规划\n2. 建立更好的时间管理系统\n3. 定期回顾和调整执行策略\n4. 保持学习和成长的动力",
        nextSteps: "1. 将学到的经验应用到新目标中\n2. 继续深化相关技能\n3. 寻找更有挑战性的目标\n4. 分享经验帮助他人",
        timeEfficiencyScore: 8.5,
        goalAchievementScore: 9.2,
        overallScore: 8.8,
        totalDays: 45,
        totalCommits: 67,
        completedTasks: 12,
        totalTasks: 15,
        averageCommitsPerDay: 1.5
    ))
}