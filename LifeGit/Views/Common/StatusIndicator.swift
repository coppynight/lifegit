import SwiftUI

/// Status indicator component using design system
struct StatusIndicator: View {
    let status: BranchStatus
    let showText: Bool
    
    init(status: BranchStatus, showText: Bool = true) {
        self.status = status
        self.showText = showText
    }
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            // Status dot
            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)
            
            if showText {
                Text(status.displayName)
                    .font(.system(size: DesignSystem.Typography.caption1, weight: DesignSystem.Typography.medium))
                    .foregroundColor(status.color)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                .fill(status.color.opacity(0.1))
        )
    }
}

/// Commit type indicator component using design system
struct CommitTypeIndicator: View {
    let commitType: CommitType
    let showText: Bool
    
    init(commitType: CommitType, showText: Bool = true) {
        self.commitType = commitType
        self.showText = showText
    }
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            // Type emoji
            Text(commitType.emoji)
                .font(.system(size: DesignSystem.Typography.caption1))
            
            if showText {
                Text(commitType.displayName)
                    .font(.system(size: DesignSystem.Typography.caption1, weight: DesignSystem.Typography.medium))
                    .foregroundColor(commitType.color)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                .fill(commitType.color.opacity(0.1))
        )
    }
}

/// AI generated indicator component
struct AIGeneratedIndicator: View {
    let showText: Bool
    
    init(showText: Bool = true) {
        self.showText = showText
    }
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: "sparkles")
                .font(.system(size: DesignSystem.Typography.caption1))
                .foregroundColor(DesignSystem.Colors.aiGenerated)
            
            if showText {
                Text("AI生成")
                    .font(.system(size: DesignSystem.Typography.caption1, weight: DesignSystem.Typography.medium))
                    .foregroundColor(DesignSystem.Colors.aiGenerated)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                .fill(DesignSystem.Colors.aiGeneratedLight)
        )
    }
}

#Preview {
    VStack(spacing: DesignSystem.Spacing.md) {
        HStack {
            StatusIndicator(status: .active)
            StatusIndicator(status: .completed)
            StatusIndicator(status: .abandoned)
        }
        
        HStack {
            StatusIndicator(status: .active, showText: false)
            StatusIndicator(status: .completed, showText: false)
            StatusIndicator(status: .abandoned, showText: false)
        }
        
        HStack {
            CommitTypeIndicator(commitType: .taskComplete)
            CommitTypeIndicator(commitType: .learning)
        }
        
        HStack {
            CommitTypeIndicator(commitType: .reflection, showText: false)
            CommitTypeIndicator(commitType: .milestone, showText: false)
        }
        
        AIGeneratedIndicator()
        AIGeneratedIndicator(showText: false)
    }
    .padding()
}