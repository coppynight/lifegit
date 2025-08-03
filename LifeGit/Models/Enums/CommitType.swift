import Foundation
import SwiftUI

enum CommitType: String, CaseIterable, Codable {
    case taskComplete = "task_complete"
    case learning = "learning"
    case reflection = "reflection"
    case milestone = "milestone"
    
    var emoji: String {
        switch self {
        case .taskComplete: return "✅"
        case .learning: return "📚"
        case .reflection: return "🌟"
        case .milestone: return "🏆"
        }
    }
    
    var displayName: String {
        switch self {
        case .taskComplete: return "任务完成"
        case .learning: return "学习记录"
        case .reflection: return "生活感悟"
        case .milestone: return "里程碑"
        }
    }
    
    var color: Color {
        switch self {
        case .taskComplete: return .green
        case .learning: return .blue
        case .reflection: return .purple
        case .milestone: return .orange
        }
    }
}