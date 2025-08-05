import Foundation
import SwiftUI

/// Manager for handling user feedback and toast notifications
@MainActor
class FeedbackManager: ObservableObject {
    static let shared = FeedbackManager()
    
    @Published var currentFeedback: FeedbackMessage?
    @Published var isShowingFeedback = false
    
    private init() {}
    
    /// Show success feedback
    func showSuccess(title: String, message: String? = nil) {
        showFeedback(FeedbackMessage(
            title: title,
            message: message,
            type: .success,
            duration: 3.0
        ))
    }
    
    /// Show error feedback
    func showError(title: String, message: String? = nil) {
        showFeedback(FeedbackMessage(
            title: title,
            message: message,
            type: .error,
            duration: 4.0
        ))
    }
    
    /// Show warning feedback
    func showWarning(title: String, message: String? = nil) {
        showFeedback(FeedbackMessage(
            title: title,
            message: message,
            type: .warning,
            duration: 3.5
        ))
    }
    
    /// Show info feedback
    func showInfo(title: String, message: String? = nil) {
        showFeedback(FeedbackMessage(
            title: title,
            message: message,
            type: .info,
            duration: 3.0
        ))
    }
    
    private func showFeedback(_ feedback: FeedbackMessage) {
        currentFeedback = feedback
        isShowingFeedback = true
        
        // Auto-dismiss after duration
        Task {
            try await Task.sleep(nanoseconds: UInt64(feedback.duration * 1_000_000_000))
            if currentFeedback?.id == feedback.id {
                dismissFeedback()
            }
        }
    }
    
    /// Dismiss current feedback
    func dismissFeedback() {
        withAnimation {
            isShowingFeedback = false
            currentFeedback = nil
        }
    }
}

/// Feedback message model
struct FeedbackMessage: Identifiable {
    let id = UUID()
    let title: String
    let message: String?
    let type: FeedbackType
    let duration: TimeInterval
}

/// Feedback types
enum FeedbackType {
    case success
    case error
    case warning
    case info
    
    var color: Color {
        switch self {
        case .success: return .green
        case .error: return .red
        case .warning: return .orange
        case .info: return .blue
        }
    }
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }
}

/// Container view for displaying feedback messages
struct FeedbackManagerContainer: View {
    @EnvironmentObject private var feedbackManager: FeedbackManager
    
    var body: some View {
        VStack {
            Spacer()
            
            if feedbackManager.isShowingFeedback,
               let feedback = feedbackManager.currentFeedback {
                FeedbackManagerToast(feedback: feedback)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: feedbackManager.isShowingFeedback)
            }
        }
        .allowsHitTesting(false)
    }
}

/// Individual feedback toast view
struct FeedbackManagerToast: View {
    let feedback: FeedbackMessage
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: feedback.type.icon)
                .foregroundColor(feedback.type.color)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(feedback.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let message = feedback.message {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
        .padding(.bottom, 100) // Above tab bar
    }
}