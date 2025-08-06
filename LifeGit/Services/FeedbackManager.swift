import Foundation
import SwiftUI

@MainActor
class FeedbackManager: ObservableObject {
    static let shared = FeedbackManager()
    
    @Published var feedbacks: [FeedbackMessage] = []
    
    private init() {}
    
    func showInfo(title: String, message: String) {
        let feedback = FeedbackMessage(type: .info, title: title, message: message)
        feedbacks.append(feedback)
        
        // Auto dismiss after 3 seconds
        Task {
            try await Task.sleep(nanoseconds: 3_000_000_000)
            dismissFeedback(feedback)
        }
    }
    
    func showWarning(title: String, message: String) {
        let feedback = FeedbackMessage(type: .warning, title: title, message: message)
        feedbacks.append(feedback)
        
        // Auto dismiss after 4 seconds
        Task {
            try await Task.sleep(nanoseconds: 4_000_000_000)
            dismissFeedback(feedback)
        }
    }
    
    func showError(title: String, message: String) {
        let feedback = FeedbackMessage(type: .error, title: title, message: message)
        feedbacks.append(feedback)
        
        // Auto dismiss after 5 seconds
        Task {
            try await Task.sleep(nanoseconds: 5_000_000_000)
            dismissFeedback(feedback)
        }
    }
    
    func showSuccess(title: String, message: String) {
        let feedback = FeedbackMessage(type: .success, title: title, message: message)
        feedbacks.append(feedback)
        
        // Auto dismiss after 3 seconds
        Task {
            try await Task.sleep(nanoseconds: 3_000_000_000)
            dismissFeedback(feedback)
        }
    }
    
    private func dismissFeedback(_ feedback: FeedbackMessage) {
        feedbacks.removeAll { $0.id == feedback.id }
    }
}

struct FeedbackMessage: Identifiable {
    let id = UUID()
    let type: FeedbackType
    let title: String
    let message: String
    let timestamp = Date()
}

enum FeedbackType {
    case info
    case warning
    case error
    case success
    
    var color: Color {
        switch self {
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        case .success: return .green
        }
    }
    
    var icon: String {
        switch self {
        case .info: return "info.circle"
        case .warning: return "exclamationmark.triangle"
        case .error: return "xmark.circle"
        case .success: return "checkmark.circle"
        }
    }
}