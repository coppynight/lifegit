import Foundation
import SwiftData

@Model
class BranchReview {
    @Attribute(.unique) var id: UUID
    var branchId: UUID
    var reviewType: ReviewType
    var summary: String // 复盘总结
    var achievements: String // 成就分析
    var challenges: String // 挑战分析
    var lessonsLearned: String // 经验教训
    var recommendations: String // 改进建议
    var nextSteps: String // 下一步建议
    var timeEfficiencyScore: Double // 时间效率评分 (0.0-10.0)
    var goalAchievementScore: Double // 目标达成评分 (0.0-10.0)
    var overallScore: Double // 综合评分 (0.0-10.0)
    var createdAt: Date = Date()
    var isAIGenerated: Bool = true
    
    // 统计数据
    var totalDays: Int // 总天数
    var totalCommits: Int // 总提交数
    var completedTasks: Int // 完成任务数
    var totalTasks: Int // 总任务数
    var averageCommitsPerDay: Double // 平均每日提交数
    
    @Relationship(inverse: \Branch.review) var branch: Branch?
    
    init(id: UUID = UUID(),
         branchId: UUID,
         reviewType: ReviewType,
         summary: String,
         achievements: String,
         challenges: String,
         lessonsLearned: String,
         recommendations: String,
         nextSteps: String,
         timeEfficiencyScore: Double,
         goalAchievementScore: Double,
         overallScore: Double,
         totalDays: Int,
         totalCommits: Int,
         completedTasks: Int,
         totalTasks: Int,
         averageCommitsPerDay: Double,
         createdAt: Date = Date(),
         isAIGenerated: Bool = true) {
        self.id = id
        self.branchId = branchId
        self.reviewType = reviewType
        self.summary = summary
        self.achievements = achievements
        self.challenges = challenges
        self.lessonsLearned = lessonsLearned
        self.recommendations = recommendations
        self.nextSteps = nextSteps
        self.timeEfficiencyScore = timeEfficiencyScore
        self.goalAchievementScore = goalAchievementScore
        self.overallScore = overallScore
        self.totalDays = totalDays
        self.totalCommits = totalCommits
        self.completedTasks = completedTasks
        self.totalTasks = totalTasks
        self.averageCommitsPerDay = averageCommitsPerDay
        self.createdAt = createdAt
        self.isAIGenerated = isAIGenerated
    }
    
    // 计算完成率
    var completionRate: Double {
        guard totalTasks > 0 else { return 0.0 }
        return Double(completedTasks) / Double(totalTasks)
    }
    
    // 格式化评分显示
    var formattedOverallScore: String {
        return String(format: "%.1f", overallScore)
    }
    
    // 获取评分等级
    var scoreGrade: String {
        switch overallScore {
        case 9.0...10.0:
            return "优秀"
        case 7.0..<9.0:
            return "良好"
        case 5.0..<7.0:
            return "一般"
        case 3.0..<5.0:
            return "需改进"
        default:
            return "待提升"
        }
    }
    
    // 获取评分颜色
    var scoreColor: String {
        switch overallScore {
        case 9.0...10.0:
            return "green"
        case 7.0..<9.0:
            return "blue"
        case 5.0..<7.0:
            return "orange"
        case 3.0..<5.0:
            return "red"
        default:
            return "gray"
        }
    }
}

// 复盘类型枚举
enum ReviewType: String, CaseIterable, Codable {
    case completion = "completion" // 完成复盘
    case abandonment = "abandonment" // 废弃复盘
    
    var displayName: String {
        switch self {
        case .completion:
            return "完成复盘"
        case .abandonment:
            return "废弃复盘"
        }
    }
    
    var emoji: String {
        switch self {
        case .completion:
            return "✅"
        case .abandonment:
            return "❌"
        }
    }
}