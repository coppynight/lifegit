import SwiftUI

/// Progress bar component using design system
struct ProgressBar: View {
    let progress: Double // 0.0 to 1.0
    let height: CGFloat
    let showPercentage: Bool
    let animated: Bool
    
    @State private var animatedProgress: Double = 0
    
    init(
        progress: Double,
        height: CGFloat = 8,
        showPercentage: Bool = false,
        animated: Bool = true
    ) {
        self.progress = max(0, min(1, progress))
        self.height = height
        self.showPercentage = showPercentage
        self.animated = animated
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            if showPercentage {
                HStack {
                    Text("进度")
                        .font(.system(size: DesignSystem.Typography.caption1, weight: DesignSystem.Typography.medium))
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    Spacer()
                    
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: DesignSystem.Typography.caption1, weight: DesignSystem.Typography.semibold))
                        .foregroundColor(DesignSystem.Colors.primary)
                }
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(DesignSystem.Colors.tertiaryBackground)
                        .frame(height: height)
                    
                    // Progress fill
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(progressColor)
                        .frame(width: geometry.size.width * (animated ? animatedProgress : progress), height: height)
                        .animation(DesignSystem.Animation.progressUpdate, value: animatedProgress)
                }
            }
            .frame(height: height)
            .onAppear {
                if animated {
                    withAnimation(DesignSystem.Animation.progressUpdate) {
                        animatedProgress = progress
                    }
                }
            }
            .onChange(of: progress) { _, newValue in
                if animated {
                    withAnimation(DesignSystem.Animation.progressUpdate) {
                        animatedProgress = newValue
                    }
                } else {
                    animatedProgress = newValue
                }
            }
        }
    }
    
    private var progressColor: Color {
        if progress >= 1.0 {
            return DesignSystem.Colors.success
        } else if progress >= 0.7 {
            return DesignSystem.Colors.primary
        } else if progress >= 0.3 {
            return DesignSystem.Colors.warning
        } else {
            return DesignSystem.Colors.error
        }
    }
}

/// Circular progress indicator using design system
struct CircularProgressIndicator: View {
    let progress: Double // 0.0 to 1.0
    let size: CGFloat
    let lineWidth: CGFloat
    let showPercentage: Bool
    
    init(
        progress: Double,
        size: CGFloat = 60,
        lineWidth: CGFloat = 6,
        showPercentage: Bool = true
    ) {
        self.progress = max(0, min(1, progress))
        self.size = size
        self.lineWidth = lineWidth
        self.showPercentage = showPercentage
    }
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(DesignSystem.Colors.tertiaryBackground, lineWidth: lineWidth)
                .frame(width: size, height: size)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    progressColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(DesignSystem.Animation.progressUpdate, value: progress)
            
            // Percentage text
            if showPercentage {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: size * 0.2, weight: DesignSystem.Typography.semibold))
                    .foregroundColor(progressColor)
            }
        }
    }
    
    private var progressColor: Color {
        if progress >= 1.0 {
            return DesignSystem.Colors.success
        } else if progress >= 0.7 {
            return DesignSystem.Colors.primary
        } else if progress >= 0.3 {
            return DesignSystem.Colors.warning
        } else {
            return DesignSystem.Colors.error
        }
    }
}

/// Task completion progress component
struct TaskProgressIndicator: View {
    let completedTasks: Int
    let totalTasks: Int
    let compact: Bool
    
    init(completedTasks: Int, totalTasks: Int, compact: Bool = false) {
        self.completedTasks = completedTasks
        self.totalTasks = totalTasks
        self.compact = compact
    }
    
    private var progress: Double {
        guard totalTasks > 0 else { return 0 }
        return Double(completedTasks) / Double(totalTasks)
    }
    
    var body: some View {
        if compact {
            HStack(spacing: DesignSystem.Spacing.xs) {
                Text("\(completedTasks)/\(totalTasks)")
                    .font(.system(size: DesignSystem.Typography.caption1, weight: DesignSystem.Typography.medium))
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                CircularProgressIndicator(
                    progress: progress,
                    size: 16,
                    lineWidth: 2,
                    showPercentage: false
                )
            }
        } else {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                HStack {
                    Text("任务完成情况")
                        .font(.system(size: DesignSystem.Typography.subheadline, weight: DesignSystem.Typography.medium))
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Spacer()
                    
                    Text("\(completedTasks)/\(totalTasks)")
                        .font(.system(size: DesignSystem.Typography.subheadline, weight: DesignSystem.Typography.semibold))
                        .foregroundColor(DesignSystem.Colors.primary)
                }
                
                ProgressBar(progress: progress, showPercentage: true)
            }
        }
    }
}

#Preview {
    VStack(spacing: DesignSystem.Spacing.lg) {
        ProgressBar(progress: 0.3, showPercentage: true)
        ProgressBar(progress: 0.7, showPercentage: true)
        ProgressBar(progress: 1.0, showPercentage: true)
        
        HStack(spacing: DesignSystem.Spacing.lg) {
            CircularProgressIndicator(progress: 0.3)
            CircularProgressIndicator(progress: 0.7)
            CircularProgressIndicator(progress: 1.0)
        }
        
        TaskProgressIndicator(completedTasks: 3, totalTasks: 10)
        
        HStack {
            TaskProgressIndicator(completedTasks: 5, totalTasks: 8, compact: true)
            TaskProgressIndicator(completedTasks: 10, totalTasks: 10, compact: true)
        }
    }
    .padding()
}