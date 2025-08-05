import Foundation

enum BranchStatus: String, CaseIterable, Codable {
    case active = "active"
    case completed = "completed"
    case abandoned = "abandoned"
    case master = "master"
    
    var emoji: String {
        switch self {
        case .active: return "🔵"
        case .completed: return "✅"
        case .abandoned: return "❌"
        case .master: return "🏠"
        }
    }
    
    var displayName: String {
        switch self {
        case .active: return "进行中"
        case .completed: return "已完成"
        case .abandoned: return "已废弃"
        case .master: return "主干"
        }
    }
}