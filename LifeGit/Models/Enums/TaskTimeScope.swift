import Foundation
import SwiftUI

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
    
    var shortName: String {
        switch self {
        case .daily: return "日"
        case .weekly: return "周"
        case .monthly: return "月"
        }
    }
    
    var icon: String {
        switch self {
        case .daily:
            return "sun.max.fill"
        case .weekly:
            return "calendar.badge.clock"
        case .monthly:
            return "calendar.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .daily:
            return .orange
        case .weekly:
            return .blue
        case .monthly:
            return .purple
        }
    }
}