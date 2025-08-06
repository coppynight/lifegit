import SwiftUI

/// Compact card view for displaying branch review summary
struct BranchReviewCard: View {
    let review: BranchReview
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Label(review.reviewType.displayName, systemImage: review.reviewType == .completion ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(review.reviewType == .completion ? .green : .red)
                    
                    Spacer()
                    
                    Text(review.createdAt.formatted(.dateTime.month().day()))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Score and summary
                HStack(alignment: .top, spacing: 12) {
                    // Score circle
                    VStack(spacing: 2) {
                        ZStack {
                            Circle()
                                .stroke(colorForScore(review.overallScore).opacity(0.2), lineWidth: 3)
                                .frame(width: 50, height: 50)
                            
                            Circle()
                                .trim(from: 0, to: review.overallScore / 10.0)
                                .stroke(colorForScore(review.overallScore), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                .frame(width: 50, height: 50)
                                .rotationEffect(.degrees(-90))
                            
                            Text(review.formattedOverallScore)
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(colorForScore(review.overallScore))
                        }
                        
                        Text(review.scoreGrade)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    // Summary text
                    VStack(alignment: .leading, spacing: 4) {
                        Text(review.summary)
                            .font(.caption)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                            .foregroundColor(.primary)
                        
                        // Quick stats
                        HStack(spacing: 12) {
                            quickStat(icon: "calendar", value: "\(review.totalDays)天")
                            quickStat(icon: "checkmark.circle", value: "\(review.completedTasks)/\(review.totalTasks)")
                            quickStat(icon: "chart.line.uptrend.xyaxis", value: String(format: "%.1f", review.averageCommitsPerDay))
                        }
                    }
                }
                
                // Action hint
                HStack {
                    Spacer()
                    Text("点击查看详细报告")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func quickStat(icon: String, value: String) -> some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
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

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        BranchReviewCard(review: BranchReview(
            branchId: UUID(),
            reviewType: .completion,
            summary: "这是一个成功完成的目标，通过系统化的任务规划和持续的执行，最终达成了预期目标。",
            achievements: "成就分析",
            challenges: "挑战分析",
            lessonsLearned: "经验教训",
            recommendations: "改进建议",
            nextSteps: "下一步建议",
            timeEfficiencyScore: 8.5,
            goalAchievementScore: 9.2,
            overallScore: 8.8,
            totalDays: 45,
            totalCommits: 67,
            completedTasks: 12,
            totalTasks: 15,
            averageCommitsPerDay: 1.5
        )) {
            print("Review tapped")
        }
        
        BranchReviewCard(review: BranchReview(
            branchId: UUID(),
            reviewType: .abandonment,
            summary: "这个目标由于时间安排冲突和优先级调整而被废弃，但从中学到了重要的经验教训。",
            achievements: "成就分析",
            challenges: "挑战分析",
            lessonsLearned: "经验教训",
            recommendations: "改进建议",
            nextSteps: "下一步建议",
            timeEfficiencyScore: 5.5,
            goalAchievementScore: 3.2,
            overallScore: 4.3,
            totalDays: 23,
            totalCommits: 15,
            completedTasks: 3,
            totalTasks: 10,
            averageCommitsPerDay: 0.7
        )) {
            print("Review tapped")
        }
    }
    .padding()
}