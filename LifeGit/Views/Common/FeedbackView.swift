import SwiftUI
import Network
import CoreGraphics

/// Feedback manager for handling user notifications
@MainActor
class FeedbackViewManager: ObservableObject {
    static let shared = FeedbackViewManager()
    
    @Published var currentFeedback: FeedbackPresentation?
    @Published var isShowingFeedback = false
    @Published var feedbackQueue: [FeedbackPresentation] = []
    
    private init() {}
    
    /// Show success feedback
    /// - Parameters:
    ///   - title: Success title
    ///   - message: Success message
    ///   - duration: Display duration (default: 3 seconds)
    func showSuccess(title: String, message: String? = nil, duration: TimeInterval = 3.0) {
        let feedback = FeedbackPresentation(
            type: .success,
            title: title,
            message: message,
            duration: duration
        )
        presentFeedback(feedback)
    }
    
    /// Show error feedback
    /// - Parameters:
    ///   - title: Error title
    ///   - message: Error message
    ///   - duration: Display duration (default: 4 seconds)
    func showError(title: String, message: String? = nil, duration: TimeInterval = 4.0) {
        let feedback = FeedbackPresentation(
            type: .error,
            title: title,
            message: message,
            duration: duration
        )
        presentFeedback(feedback)
    }
    
    /// Show warning feedback
    /// - Parameters:
    ///   - title: Warning title
    ///   - message: Warning message
    ///   - duration: Display duration (default: 3.5 seconds)
    func showWarning(title: String, message: String? = nil, duration: TimeInterval = 3.5) {
        let feedback = FeedbackPresentation(
            type: .warning,
            title: title,
            message: message,
            duration: duration
        )
        presentFeedback(feedback)
    }
    
    /// Show info feedback
    /// - Parameters:
    ///   - title: Info title
    ///   - message: Info message
    ///   - duration: Display duration (default: 3 seconds)
    func showInfo(title: String, message: String? = nil, duration: TimeInterval = 3.0) {
        let feedback = FeedbackPresentation(
            type: .info,
            title: title,
            message: message,
            duration: duration
        )
        presentFeedback(feedback)
    }
    
    /// Present feedback to user
    private func presentFeedback(_ feedback: FeedbackPresentation) {
        if currentFeedback != nil {
            // Queue the feedback if one is already showing
            feedbackQueue.append(feedback)
        } else {
            currentFeedback = feedback
            isShowingFeedback = true
            
            // Auto-dismiss after duration
            Task {
                try await Task.sleep(nanoseconds: UInt64(feedback.duration * 1_000_000_000))
                dismissCurrentFeedback()
            }
        }
    }
    
    /// Dismiss current feedback and show next in queue
    func dismissCurrentFeedback() {
        currentFeedback = nil
        isShowingFeedback = false
        
        // Show next feedback in queue
        if !feedbackQueue.isEmpty {
            let nextFeedback = feedbackQueue.removeFirst()
            Task {
                // Small delay to allow animation to complete
                try await Task.sleep(nanoseconds: 200_000_000)
                presentFeedback(nextFeedback)
            }
        }
    }
    
    /// Clear all feedback
    func clearAll() {
        currentFeedback = nil
        isShowingFeedback = false
        feedbackQueue.removeAll()
    }
}

/// Feedback presentation model
struct FeedbackPresentation: Identifiable {
    let id = UUID()
    let type: UIFeedbackType
    let title: String
    let message: String?
    let duration: TimeInterval
    let timestamp = Date()
}

/// Types of feedback for UI display
enum UIFeedbackType {
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
    
    var hapticFeedback: UINotificationFeedbackGenerator.FeedbackType {
        switch self {
        case .success: return .success
        case .error: return .error
        case .warning: return .warning
        case .info: return .success
        }
    }
}

/// Toast notification view
struct FeedbackToast: View {
    let presentation: FeedbackPresentation
    let onDismiss: () -> Void
    
    @State private var isVisible = false
    @State private var dragOffset: CGSize = .zero
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: presentation.type.icon)
                .foregroundColor(.white)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(presentation.title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                if let message = presentation.message {
                    Text(message)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .foregroundColor(.white.opacity(0.8))
                    .font(.caption)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(presentation.type.color)
        .cornerRadius(DesignSystem.CornerRadius.medium)
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        .offset(y: isVisible ? 0 : -100)
        .offset(dragOffset)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isVisible)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    let translation = gesture.translation
                    if translation.height < 0 {
                        dragOffset = translation
                    }
                }
                .onEnded { gesture in
                    let translation = gesture.translation
                    if translation.height < -50 {
                        onDismiss()
                    } else {
                        dragOffset = .zero
                    }
                }
        )
        .onAppear {
            // Haptic feedback
            let impactFeedback = UINotificationFeedbackGenerator()
            impactFeedback.notificationOccurred(presentation.type.hapticFeedback)
            
            withAnimation {
                isVisible = true
            }
        }
    }
}

/// Banner notification view for inline display
struct FeedbackBanner: View {
    let presentation: FeedbackPresentation
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: presentation.type.icon)
                .foregroundColor(presentation.type.color)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(presentation.title)
                    .font(.headline)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                if let message = presentation.message {
                    Text(message)
                        .font(.body)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .lineLimit(3)
                }
            }
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
                    .font(.caption)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(presentation.type.color.opacity(0.1))
        .cornerRadius(DesignSystem.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .stroke(presentation.type.color.opacity(0.3), lineWidth: 1)
        )
    }
}

/// Progress feedback view for long-running operations
struct ProgressFeedback: View {
    let title: String
    let message: String?
    let progress: Double
    let onCancel: (() -> Void)?
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    if let message = message {
                        Text(message)
                            .font(.body)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                }
                
                Spacer()
                
                if let onCancel = onCancel {
                    Button("取消", action: onCancel)
                        .font(.body)
                        .foregroundColor(DesignSystem.Colors.error)
                }
            }
            
            ProgressView(value: progress)
                .tint(DesignSystem.Colors.primary)
            
            HStack {
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                Spacer()
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.secondaryBackground)
        .cornerRadius(DesignSystem.CornerRadius.medium)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

/// Enhanced feedback container view for managing feedback display
struct FeedbackContainer: View {
    @ObservedObject var feedbackManager = FeedbackViewManager.shared
    @State private var queueIndicatorOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Main feedback toast
            if let feedback = feedbackManager.currentFeedback, feedbackManager.isShowingFeedback {
                VStack {
                    FeedbackToast(presentation: feedback) {
                        feedbackManager.dismissCurrentFeedback()
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.top, DesignSystem.Spacing.sm)
                    
                    // Queue indicator
                    if !feedbackManager.feedbackQueue.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(0..<min(feedbackManager.feedbackQueue.count, 3), id: \.self) { index in
                                Circle()
                                    .fill(Color.white.opacity(0.6))
                                    .frame(width: 6, height: 6)
                                    .scaleEffect(index == 0 ? 1.2 : 1.0)
                                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true).delay(Double(index) * 0.2), value: queueIndicatorOffset)
                            }
                            
                            if feedbackManager.feedbackQueue.count > 3 {
                                Text("+\(feedbackManager.feedbackQueue.count - 3)")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(12)
                        .padding(.top, 4)
                        .onAppear {
                            queueIndicatorOffset = 1
                        }
                    }
                    
                    Spacer()
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
                .zIndex(1000)
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: feedbackManager.isShowingFeedback)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: feedbackManager.feedbackQueue.count)
    }
}

// MARK: - Network Status Monitor

@MainActor
class FeedbackNetworkStatusManager: ObservableObject {
    @Published var isConnected = true
    @Published var connectionType: ConnectionType = .wifi
    @Published var showNetworkStatus = false
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    init() {
        startMonitoring()
    }
    
    deinit {
        monitor.cancel()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                let wasConnected = self?.isConnected ?? true
                self?.isConnected = path.status == .satisfied
                
                // Determine connection type
                if path.usesInterfaceType(.wifi) {
                    self?.connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self?.connectionType = .cellular
                } else {
                    self?.connectionType = .unknown
                }
                
                // Show status change notification
                if wasConnected != self?.isConnected {
                    self?.showNetworkStatus = true
                    
                    if let isConnected = self?.isConnected {
                        if isConnected {
                            FeedbackViewManager.shared.showSuccess(
                                title: "网络已连接",
                                message: "AI功能现已可用"
                            )
                        } else {
                            FeedbackViewManager.shared.showWarning(
                                title: "网络连接断开",
                                message: "AI功能暂时不可用，您可以手动创建任务"
                            )
                        }
                    }
                    
                    // Hide status after delay
                    Task {
                        try await Task.sleep(nanoseconds: 3_000_000_000)
                        self?.showNetworkStatus = false
                    }
                }
            }
        }
        
        monitor.start(queue: queue)
    }
}

enum ConnectionType {
    case wifi
    case cellular
    case unknown
    
    var displayName: String {
        switch self {
        case .wifi: return "Wi-Fi"
        case .cellular: return "蜂窝网络"
        case .unknown: return "未知"
        }
    }
    
    var icon: String {
        switch self {
        case .wifi: return "wifi"
        case .cellular: return "antenna.radiowaves.left.and.right"
        case .unknown: return "network"
        }
    }
}



// MARK: - Convenience Extensions

extension FeedbackViewManager {
    /// Show AI task generation success
    func showAITaskGenerationSuccess() {
        showSuccess(
            title: "任务计划生成成功",
            message: "AI已为您制定了详细的执行计划"
        )
    }
    
    /// Show AI task generation failure
    func showAITaskGenerationFailure() {
        showError(
            title: "任务计划生成失败",
            message: "请重试或选择手动创建任务计划"
        )
    }
    
    /// Show branch creation success
    func showBranchCreationSuccess(branchName: String) {
        showSuccess(
            title: "目标分支创建成功",
            message: "分支 '\(branchName)' 已创建"
        )
    }
    
    /// Show branch merge success
    func showBranchMergeSuccess(branchName: String) {
        showSuccess(
            title: "目标完成！",
            message: "分支 '\(branchName)' 已成功合并到主干"
        )
    }
    
    /// Show data save success
    func showDataSaveSuccess() {
        showSuccess(
            title: "保存成功",
            message: "您的更改已保存"
        )
    }
    
    /// Show data save failure
    func showDataSaveFailure() {
        showError(
            title: "保存失败",
            message: "请重试保存操作"
        )
    }
}

// MARK: - Preview

/*
#Preview("Feedback Toast") {
    let successPresentation = FeedbackPresentation(
        type: UIFeedbackType.success,
        title: "操作成功",
        message: "您的更改已保存",
        duration: 3.0
    )
    
    VStack(spacing: 20) {
        FeedbackToast(presentation: successPresentation) {
            print("Dismissed")
        }
    }
    .padding()
}
*/

/*
#Preview("Progress Feedback") {
    ProgressFeedback(
        title: "同步数据",
        message: "正在同步您的数据到云端",
        progress: 0.65,
        onCancel: { print("Cancelled") }
    )
    .padding()
}
*/

/*
#Preview("Network Status") {
    NetworkStatusView()
        .padding()
}
*/