import SwiftUI

/// Filter chip component for category selection using design system
struct FilterChip: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            DesignSystem.Haptics.filterChanged()
            onTap()
        }) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                Text(title)
                    .font(.system(size: DesignSystem.Typography.footnote, weight: DesignSystem.Typography.medium))
                
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: DesignSystem.Typography.caption1, weight: DesignSystem.Typography.semibold))
                        .foregroundColor(isSelected ? .white : DesignSystem.Colors.secondaryText)
                        .padding(.horizontal, DesignSystem.Spacing.xs)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                                .fill(isSelected ? Color.white.opacity(0.3) : DesignSystem.Colors.tertiaryBackground)
                        )
                }
            }
            .foregroundColor(isSelected ? .white : DesignSystem.Colors.primaryText)
            .padding(.horizontal, DesignSystem.Spacing.sm + DesignSystem.Spacing.xs)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                    .fill(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.tertiaryBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                    .stroke(isSelected ? DesignSystem.Colors.primary : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(DesignSystem.Animation.buttonTap, value: isSelected)
    }
}

#Preview {
    HStack {
        FilterChip(title: "全部", count: 5, isSelected: true) {}
        FilterChip(title: "活跃", count: 3, isSelected: false) {}
        FilterChip(title: "已完成", count: 0, isSelected: false) {}
    }
    .padding()
}