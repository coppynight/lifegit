import SwiftUI

/// Primary button component using design system
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    let isLoading: Bool
    let isDisabled: Bool
    
    init(
        title: String,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            if !isLoading && !isDisabled {
                DesignSystem.Haptics.buttonTap()
                action()
            }
        }) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                } else {
                    Text(title)
                        .font(.system(size: DesignSystem.Typography.callout, weight: DesignSystem.Typography.semibold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Spacing.sm + 2)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                    .fill(buttonBackgroundColor)
            )
        }
        .disabled(isLoading || isDisabled)
        .animation(DesignSystem.Animation.buttonTap, value: isLoading)
        .animation(DesignSystem.Animation.buttonTap, value: isDisabled)
    }
    
    private var buttonBackgroundColor: Color {
        if isDisabled {
            return DesignSystem.Colors.secondaryText.opacity(0.3)
        } else if isLoading {
            return DesignSystem.Colors.primary.opacity(0.7)
        } else {
            return DesignSystem.Colors.primary
        }
    }
}

/// Secondary button component using design system
struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    let isDisabled: Bool
    
    init(
        title: String,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isDisabled = isDisabled
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            if !isDisabled {
                DesignSystem.Haptics.buttonTap()
                action()
            }
        }) {
            Text(title)
                .font(.system(size: DesignSystem.Typography.callout, weight: DesignSystem.Typography.medium))
                .foregroundColor(isDisabled ? DesignSystem.Colors.tertiaryText : DesignSystem.Colors.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.sm + 2)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                        .stroke(
                            isDisabled ? DesignSystem.Colors.tertiaryText : DesignSystem.Colors.primary,
                            lineWidth: 1
                        )
                )
        }
        .disabled(isDisabled)
        .animation(DesignSystem.Animation.buttonTap, value: isDisabled)
    }
}

/// Destructive button component using design system
struct DestructiveButton: View {
    let title: String
    let action: () -> Void
    let isDisabled: Bool
    
    init(
        title: String,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isDisabled = isDisabled
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            if !isDisabled {
                DesignSystem.Haptics.warning()
                action()
            }
        }) {
            Text(title)
                .font(.system(size: DesignSystem.Typography.callout, weight: DesignSystem.Typography.semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.sm + 2)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                        .fill(isDisabled ? DesignSystem.Colors.error.opacity(0.3) : DesignSystem.Colors.error)
                )
        }
        .disabled(isDisabled)
        .animation(DesignSystem.Animation.buttonTap, value: isDisabled)
    }
}

#Preview {
    VStack(spacing: DesignSystem.Spacing.md) {
        PrimaryButton(title: "主要按钮") {}
        PrimaryButton(title: "加载中", isLoading: true) {}
        PrimaryButton(title: "禁用状态", isDisabled: true) {}
        
        SecondaryButton(title: "次要按钮") {}
        SecondaryButton(title: "禁用状态", isDisabled: true) {}
        
        DestructiveButton(title: "删除按钮") {}
        DestructiveButton(title: "禁用状态", isDisabled: true) {}
    }
    .padding()
}