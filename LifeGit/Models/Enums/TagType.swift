import Foundation
import SwiftUI

enum TagType: String, CaseIterable, Codable {
    case milestone = "milestone"
    case birthday = "birthday"
    case career = "career"
    case relationship = "relationship"
    case education = "education"
    case achievement = "achievement"
    
    var emoji: String {
        switch self {
        case .milestone: return "🎯"
        case .birthday: return "🎂"
        case .career: return "💼"
        case .relationship: return "💑"
        case .education: return "🎓"
        case .achievement: return "🏆"
        }
    }
    
    var displayName: String {
        switch self {
        case .milestone: return "里程碑"
        case .birthday: return "生日"
        case .career: return "职业"
        case .relationship: return "感情"
        case .education: return "教育"
        case .achievement: return "成就"
        }
    }
    
    var color: Color {
        switch self {
        case .milestone: return .orange
        case .birthday: return .pink
        case .career: return .blue
        case .relationship: return .red
        case .education: return .green
        case .achievement: return .yellow
        }
    }
    
    var description: String {
        switch self {
        case .milestone: return "人生重要成就"
        case .birthday: return "年龄标记"
        case .career: return "工作变化"
        case .relationship: return "感情状态变化"
        case .education: return "教育成就"
        case .achievement: return "特殊成就"
        }
    }
}