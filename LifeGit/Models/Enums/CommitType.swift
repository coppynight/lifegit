import Foundation
import SwiftUI

enum CommitType: String, CaseIterable, Codable {
    // 原有类型
    case taskComplete = "task_complete"
    case learning = "learning"
    case reflection = "reflection"
    case milestone = "milestone"
    
    // 新增类型
    case habit = "habit"                    // 习惯养成
    case exercise = "exercise"              // 运动健身
    case reading = "reading"                // 阅读记录
    case creativity = "creativity"          // 创意创作
    case social = "social"                  // 社交活动
    case health = "health"                  // 健康管理
    case finance = "finance"                // 财务管理
    case career = "career"                  // 职业发展
    case relationship = "relationship"      // 人际关系
    case travel = "travel"                  // 旅行体验
    case skill = "skill"                    // 技能学习
    case project = "project"                // 项目进展
    case idea = "idea"                      // 想法记录
    case challenge = "challenge"            // 挑战克服
    case gratitude = "gratitude"            // 感恩记录
    case custom = "custom"                  // 自定义类型
    
    var emoji: String {
        switch self {
        case .taskComplete: return "✅"
        case .learning: return "📚"
        case .reflection: return "🌟"
        case .milestone: return "🏆"
        case .habit: return "🔄"
        case .exercise: return "💪"
        case .reading: return "📖"
        case .creativity: return "🎨"
        case .social: return "👥"
        case .health: return "🏥"
        case .finance: return "💰"
        case .career: return "💼"
        case .relationship: return "💑"
        case .travel: return "✈️"
        case .skill: return "🛠️"
        case .project: return "📋"
        case .idea: return "💡"
        case .challenge: return "⚡"
        case .gratitude: return "🙏"
        case .custom: return "⭐"
        }
    }
    
    var displayName: String {
        switch self {
        case .taskComplete: return "任务完成"
        case .learning: return "学习记录"
        case .reflection: return "生活感悟"
        case .milestone: return "里程碑"
        case .habit: return "习惯养成"
        case .exercise: return "运动健身"
        case .reading: return "阅读记录"
        case .creativity: return "创意创作"
        case .social: return "社交活动"
        case .health: return "健康管理"
        case .finance: return "财务管理"
        case .career: return "职业发展"
        case .relationship: return "人际关系"
        case .travel: return "旅行体验"
        case .skill: return "技能学习"
        case .project: return "项目进展"
        case .idea: return "想法记录"
        case .challenge: return "挑战克服"
        case .gratitude: return "感恩记录"
        case .custom: return "自定义"
        }
    }
    
    var color: Color {
        switch self {
        case .taskComplete: return .green
        case .learning: return .blue
        case .reflection: return .purple
        case .milestone: return .orange
        case .habit: return .cyan
        case .exercise: return .red
        case .reading: return .brown
        case .creativity: return .pink
        case .social: return .yellow
        case .health: return .mint
        case .finance: return .green
        case .career: return .indigo
        case .relationship: return .pink
        case .travel: return .teal
        case .skill: return .blue
        case .project: return .gray
        case .idea: return .yellow
        case .challenge: return .red
        case .gratitude: return .purple
        case .custom: return .secondary
        }
    }
    
    var category: CommitCategory {
        switch self {
        case .taskComplete, .milestone, .project:
            return .achievement
        case .learning, .reading, .skill:
            return .learning
        case .reflection, .idea, .gratitude:
            return .personal
        case .habit, .exercise, .health:
            return .lifestyle
        case .social, .relationship:
            return .social
        case .creativity, .travel:
            return .experience
        case .finance, .career:
            return .professional
        case .challenge:
            return .growth
        case .custom:
            return .other
        }
    }
    
    var description: String {
        switch self {
        case .taskComplete: return "记录完成的任务和目标"
        case .learning: return "记录学习过程和收获"
        case .reflection: return "记录生活感悟和思考"
        case .milestone: return "记录重要的人生节点"
        case .habit: return "记录习惯的培养和坚持"
        case .exercise: return "记录运动和健身活动"
        case .reading: return "记录阅读心得和笔记"
        case .creativity: return "记录创意想法和作品"
        case .social: return "记录社交活动和聚会"
        case .health: return "记录健康状况和医疗"
        case .finance: return "记录财务状况和投资"
        case .career: return "记录职业发展和工作"
        case .relationship: return "记录人际关系的发展"
        case .travel: return "记录旅行经历和见闻"
        case .skill: return "记录技能学习和实践"
        case .project: return "记录项目进展和成果"
        case .idea: return "记录灵感和创意想法"
        case .challenge: return "记录克服困难的过程"
        case .gratitude: return "记录感恩和感谢的事情"
        case .custom: return "自定义类型的提交记录"
        }
    }
    
    // 获取推荐的提交类型（基于用户使用频率）
    static func getRecommendedTypes(basedOn recentCommits: [Commit]) -> [CommitType] {
        let typeFrequency = Dictionary(grouping: recentCommits, by: { $0.type })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
        
        let frequentTypes = Array(typeFrequency.prefix(6).map { $0.key })
        let defaultTypes: [CommitType] = [.taskComplete, .learning, .reflection, .milestone]
        
        // 合并常用类型和默认类型，去重
        var recommendedTypes = frequentTypes
        for defaultType in defaultTypes {
            if !recommendedTypes.contains(defaultType) {
                recommendedTypes.append(defaultType)
            }
        }
        
        return Array(recommendedTypes.prefix(8))
    }
}

// 提交类型分类
enum CommitCategory: String, CaseIterable, Codable {
    case achievement = "achievement"    // 成就类
    case learning = "learning"          // 学习类
    case personal = "personal"          // 个人类
    case lifestyle = "lifestyle"        // 生活类
    case social = "social"              // 社交类
    case experience = "experience"      // 体验类
    case professional = "professional"  // 职业类
    case growth = "growth"              // 成长类
    case other = "other"                // 其他类
    
    var displayName: String {
        switch self {
        case .achievement: return "成就"
        case .learning: return "学习"
        case .personal: return "个人"
        case .lifestyle: return "生活"
        case .social: return "社交"
        case .experience: return "体验"
        case .professional: return "职业"
        case .growth: return "成长"
        case .other: return "其他"
        }
    }
    
    var color: Color {
        switch self {
        case .achievement: return .orange
        case .learning: return .blue
        case .personal: return .purple
        case .lifestyle: return .green
        case .social: return .yellow
        case .experience: return .pink
        case .professional: return .indigo
        case .growth: return .red
        case .other: return .gray
        }
    }
    
    var emoji: String {
        switch self {
        case .achievement: return "🏆"
        case .learning: return "📚"
        case .personal: return "🌟"
        case .lifestyle: return "🌱"
        case .social: return "👥"
        case .experience: return "🎨"
        case .professional: return "💼"
        case .growth: return "⚡"
        case .other: return "📝"
        }
    }
}