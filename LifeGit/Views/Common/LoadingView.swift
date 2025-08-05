import SwiftUI

/// Enhanced loading view with better animations and user guidance
struct LoadingView: View {
    let message: String
    let showProgress: Bool
    let progress: Double?
    let tips: [String]
    
    @State private var animationOffset: CGFloat = 0
    @State private var currentTipIndex = 0
    @State private var showTip = false
    
    init(
        message: String = "加载中...",
        showProgress: Bool = false,
        progress: Double? = nil,
        tips: [String] = []
    ) {
        self.message = message
        self.showProgress = showProgress
        self.progress = progress
        self.tips = tips.isEmpty ? LoadingView.defaultTips : tips
    }
    
    var body: some View {
        VStack(spacing: 32) {
            // Enhanced loading animation
            VStack(spacing: 24) {
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(DesignSystem.Colors.primary.opacity(0.2), lineWidth: 4)
                        .frame(width: 80, height: 80)
                    
                    // Animated progress circle
                    Circle()
                        .trim(from: 0, to: showProgress ? (progress ?? 0.3) : 0.3)
                        .stroke(
                            DesignSystem.Colors.primary,
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(animationOffset))
                        .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: animationOffset)
                    
                    // Center icon or progress indicator
                    if showProgress, let progress = progress {
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.primary)
                    } else {
                        Image(systemName: "sparkles")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.primary)
                            .scaleEffect(showTip ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: showTip)
                    }
                }
                
                // Loading message
                Text(message)
                    .font(.system(size: DesignSystem.Typography.headline, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .multilineTextAlignment(.center)
                
                // Progress bar for specific operations
                if showProgress, let progress = progress {
                    VStack(spacing: 8) {
                        ProgressView(value: progress)
                            .progressViewStyle(LinearProgressViewStyle(tint: DesignSystem.Colors.primary))
                            .frame(width: 200)
                        
                        Text("进度: \(Int(progress * 100))%")
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                }
            }
            
            // Helpful tips with rotation
            if !tips.isEmpty {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "lightbulb")
                            .foregroundColor(.orange)
                            .font(.system(size: 16))
                        
                        Text("小贴士")
                            .font(.system(size: DesignSystem.Typography.subheadline, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        Spacer()
                    }
                    
                    Text(tips[currentTipIndex])
                        .font(.system(size: DesignSystem.Typography.callout))
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .opacity(showTip ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.5), value: showTip)
                }
                .padding(16)
                .background(DesignSystem.Colors.secondaryBackground)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            }
            
            Spacer()
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Colors.background)
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Start rotation animation
        animationOffset = 360
        showTip = true
        
        // Rotate tips every 3 seconds
        if tips.count > 1 {
            Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.3)) {
                    showTip = false
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    currentTipIndex = (currentTipIndex + 1) % tips.count
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showTip = true
                    }
                }
            }
        }
    }
    
    // Default helpful tips
    static let defaultTips = [
        "人生Git让您像管理代码一样管理人生目标",
        "每个目标都是一个独立的分支，可以专注执行",
        "AI会帮您将大目标拆解成可执行的小任务",
        "完成目标后合并到主干，见证人生版本升级",
        "提交记录您的每日进展，积少成多实现目标"
    ]
}

/// Specialized loading views for different contexts
extension LoadingView {
    /// Loading view for AI task generation
    static func aiTaskGeneration(progress: Double? = nil) -> LoadingView {
        LoadingView(
            message: "AI正在为您生成任务计划...",
            showProgress: progress != nil,
            progress: progress,
            tips: [
                "AI会根据您的目标生成详细的任务计划",
                "任务会按日、周、月的维度进行组织",
                "您可以随时修改AI生成的任务计划",
                "如果AI服务不可用，您也可以手动创建任务"
            ]
        )
    }
    
    /// Loading view for data operations
    static func dataOperation(message: String = "正在保存数据...") -> LoadingView {
        LoadingView(
            message: message,
            tips: [
                "所有数据都安全保存在您的设备上",
                "数据会自动备份，无需担心丢失",
                "您可以随时查看和修改已保存的数据"
            ]
        )
    }
    
    /// Loading view for app initialization
    static func appInitialization() -> LoadingView {
        LoadingView(
            message: "正在初始化应用...",
            tips: [
                "首次启动需要初始化数据结构",
                "我们正在为您创建人生主干分支",
                "初始化完成后即可开始创建目标"
            ]
        )
    }
    
    /// Loading view for branch operations
    static func branchOperation(message: String = "正在处理分支...") -> LoadingView {
        LoadingView(
            message: message,
            tips: [
                "分支让您可以同时管理多个目标",
                "完成的目标可以合并到人生主干",
                "您可以随时在不同分支间切换"
            ]
        )
    }
}

#Preview {
    LoadingView()
}

#Preview("Custom Message") {
    LoadingView(message: "正在初始化...")
}