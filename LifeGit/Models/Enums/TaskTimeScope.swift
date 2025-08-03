import Foundation

enum TaskTimeScope: String, CaseIterable, Codable {
    case daily = "daily"     // 日任务
    case weekly = "weekly"   // 周任务
    case monthly = "monthly" // 月任务
    
    var displayName: String {
        switch self {
        case .daily: return "每日任务"
        case .weekly: return "每周任务"
        case .monthly: return "每月任务"
        }
    }
    
    var emoji: String {
        switch self {
        case .daily: return "📅"
        case .weekly: return "📆"
        case .monthly: return "🗓️"
        }
    }
}