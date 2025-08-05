import SwiftUI

/// Enhanced loading view with progress tracking and cancellation support
struct LoadingStateView: View {
    let state: LoadingState
    let onCancel: (() -> Void)?
    
    init(state: LoadingState, onCancel: (() -> Void)? = nil) {
        self.state = state
        self.onCancel = onCancel
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Loading Animation
            ZStack {
                Circle()
                    .stroke(DesignSystem.Colors.primary.opacity(0.2), lineWidth: 4)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: state.progress ?? 0.3)
                    .stroke(
                        DesignSystem.Colors.primary,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: false), value: state.progress)
                
                if let progress = state.progress {
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(DesignSystem.Colors.primary)
                }
            }
            
            // Loading Content
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text(state.title)
                    .font(.headline)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                if let message = state.message {
                    Text(message)
                        .font(.body)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                }
                
                if let detail = state.detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Cancel Button
            if let onCancel = onCancel, state.isCancellable {
                Button("取消") {
                    onCancel()
                }
                .font(.body)
                .foregroundColor(DesignSystem.Colors.error)
            }
        }
        .padding(DesignSystem.Spacing.xl)
        .background(DesignSystem.Colors.background)
        .cornerRadius(DesignSystem.CornerRadius.large)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

/// AI Task Generation specific loading view
struct AITaskGenerationLoadingView: View {
    @State private var currentStep = 0
    @State private var animationTimer: Timer?
    let onCancel: (() -> Void)?
    
    private let steps = [
        "分析目标内容...",
        "生成任务结构...",
        "优化任务安排...",
        "完成任务计划..."
    ]
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // AI Animation
            ZStack {
                // Outer ring
                Circle()
                    .stroke(DesignSystem.Colors.primary.opacity(0.2), lineWidth: 3)
                    .frame(width: 80, height: 80)
                
                // Inner animated ring
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            colors: [DesignSystem.Colors.primary, DesignSystem.Colors.primary.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(Double(currentStep) * 90))
                    .animation(.easeInOut(duration: 1), value: currentStep)
                
                // AI Icon
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundColor(DesignSystem.Colors.primary)
                    .scaleEffect(1.2)
            }
            
            // Step Information
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text("AI正在生成任务计划")
                    .font(.headline)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text(steps[currentStep])
                    .font(.body)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
                
                Text("这通常需要5-10秒")
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
            }
            
            // Progress Dots
            HStack(spacing: 8) {
                ForEach(0..<steps.count, id: \.self) { index in
                    Circle()
                        .fill(index <= currentStep ? DesignSystem.Colors.primary : DesignSystem.Colors.primary.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut(duration: 0.3), value: currentStep)
                }
            }
            
            // Cancel Button
            if let onCancel = onCancel {
                Button("取消生成") {
                    onCancel()
                }
                .font(.body)
                .foregroundColor(DesignSystem.Colors.error)
                .padding(.top, DesignSystem.Spacing.sm)
            }
        }
        .padding(DesignSystem.Spacing.xl)
        .background(DesignSystem.Colors.background)
        .cornerRadius(DesignSystem.CornerRadius.large)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .onAppear {
            startAnimation()
        }
        .onDisappear {
            stopAnimation()
        }
    }
    
    private func startAnimation() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            withAnimation {
                currentStep = (currentStep + 1) % steps.count
            }
        }
    }
    
    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
}

/// Inline loading indicator for smaller spaces
struct InlineLoadingView: View {
    let message: String
    let showProgress: Bool
    let progress: Double?
    
    init(message: String = "加载中...", showProgress: Bool = false, progress: Double? = nil) {
        self.message = message
        self.showProgress = showProgress
        self.progress = progress
    }
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            if showProgress, let progress = progress {
                ProgressView(value: progress)
                    .frame(width: 40)
                    .tint(DesignSystem.Colors.primary)
            } else {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(DesignSystem.Colors.primary)
            }
            
            Text(message)
                .font(.body)
                .foregroundColor(DesignSystem.Colors.secondaryText)
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.secondaryBackground)
        .cornerRadius(DesignSystem.CornerRadius.medium)
    }
}

/// Loading overlay for full screen coverage
struct LoadingOverlay: View {
    let state: LoadingState
    let onCancel: (() -> Void)?
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            LoadingStateView(state: state, onCancel: onCancel)
                .padding(DesignSystem.Spacing.xl)
        }
    }
}

// MARK: - Loading State Model

struct LoadingState {
    let title: String
    let message: String?
    let detail: String?
    let progress: Double?
    let isCancellable: Bool
    
    init(
        title: String,
        message: String? = nil,
        detail: String? = nil,
        progress: Double? = nil,
        isCancellable: Bool = false
    ) {
        self.title = title
        self.message = message
        self.detail = detail
        self.progress = progress
        self.isCancellable = isCancellable
    }
    
    // Predefined loading states
    static let aiTaskGeneration = LoadingState(
        title: "生成任务计划",
        message: "AI正在为您的目标制定详细的执行计划",
        detail: "这通常需要5-10秒",
        isCancellable: true
    )
    
    static let savingData = LoadingState(
        title: "保存数据",
        message: "正在保存您的更改"
    )
    
    static let loadingBranches = LoadingState(
        title: "加载分支",
        message: "正在获取您的目标分支"
    )
    
    static let mergingBranch = LoadingState(
        title: "合并分支",
        message: "正在将完成的目标合并到主干"
    )
    
    static func dataSync(progress: Double) -> LoadingState {
        LoadingState(
            title: "同步数据",
            message: "正在同步您的数据到云端",
            progress: progress,
            isCancellable: true
        )
    }
}

// MARK: - Preview

#Preview("Loading State View") {
    LoadingStateView(
        state: .aiTaskGeneration,
        onCancel: { print("Cancelled") }
    )
    .padding()
}

#Preview("AI Task Generation") {
    AITaskGenerationLoadingView(onCancel: { print("Cancelled") })
        .padding()
}

#Preview("Inline Loading") {
    VStack(spacing: 20) {
        InlineLoadingView()
        InlineLoadingView(message: "正在保存...", showProgress: true, progress: 0.6)
    }
    .padding()
}

#Preview("Loading Overlay") {
    ZStack {
        Color.gray.opacity(0.1)
            .ignoresSafeArea()
        
        LoadingOverlay(
            state: .aiTaskGeneration,
            onCancel: { print("Cancelled") }
        )
    }
}