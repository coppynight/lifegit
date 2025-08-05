import SwiftUI
import UIKit

/// 人生Git应用的设计系统配置
/// 定义了应用的颜色、字体、间距、动画和触觉反馈等设计元素
struct DesignSystem {
    
    // MARK: - Colors
    struct Colors {
        // MARK: - Primary Colors
        static let primary = Color.blue
        static let primaryLight = Color.blue.opacity(0.7)
        static let primaryDark = Color.blue.opacity(0.9)
        
        // MARK: - Branch Status Colors
        static let branchActive = Color.blue
        static let branchCompleted = Color.green
        static let branchAbandoned = Color.red
        
        // MARK: - Commit Type Colors (matching existing CommitType.color implementation)
        static let commitTaskComplete = Color.green
        static let commitLearning = Color.blue
        static let commitReflection = Color.purple
        static let commitMilestone = Color.orange
        
        // MARK: - Background Colors
        static let background = Color(.systemBackground)
        static let secondaryBackground = Color(.secondarySystemBackground)
        static let tertiaryBackground = Color(.tertiarySystemBackground)
        
        // MARK: - Text Colors
        static let primaryText = Color(.label)
        static let secondaryText = Color(.secondaryLabel)
        static let tertiaryText = Color(.tertiaryLabel)
        
        // MARK: - Accent Colors
        static let accent = Color.accentColor
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let info = Color.blue
        
        // MARK: - AI Related Colors
        static let aiGenerated = Color.purple
        static let aiGeneratedLight = Color.purple.opacity(0.1)
    }
    
    // MARK: - Typography
    struct Typography {
        // MARK: - Font Sizes
        static let largeTitle: CGFloat = 34
        static let title1: CGFloat = 28
        static let title2: CGFloat = 22
        static let title3: CGFloat = 20
        static let headline: CGFloat = 17
        static let body: CGFloat = 17
        static let callout: CGFloat = 16
        static let subheadline: CGFloat = 15
        static let footnote: CGFloat = 13
        static let caption1: CGFloat = 12
        static let caption2: CGFloat = 11
        
        // MARK: - Font Weights
        static let ultraLight = Font.Weight.ultraLight
        static let thin = Font.Weight.thin
        static let light = Font.Weight.light
        static let regular = Font.Weight.regular
        static let medium = Font.Weight.medium
        static let semibold = Font.Weight.semibold
        static let bold = Font.Weight.bold
        static let heavy = Font.Weight.heavy
        static let black = Font.Weight.black
        
        // MARK: - Predefined Font Styles
        static let navigationTitle = Font.system(size: title2, weight: bold)
        static let sectionHeader = Font.system(size: headline, weight: semibold)
        static let branchName = Font.system(size: title3, weight: medium)
        static let commitMessage = Font.system(size: body, weight: regular)
        static let taskTitle = Font.system(size: callout, weight: medium)
        static let taskDescription = Font.system(size: footnote, weight: regular)
        static let statusLabel = Font.system(size: caption1, weight: medium)
        static let timestamp = Font.system(size: caption2, weight: regular)
    }
    
    // MARK: - Spacing
    struct Spacing {
        // MARK: - Base Spacing Units
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        
        // MARK: - Component Specific Spacing
        static let cardPadding: CGFloat = md
        static let sectionSpacing: CGFloat = lg
        static let itemSpacing: CGFloat = sm
        static let buttonPadding: CGFloat = sm
        static let chipPadding: CGFloat = xs
        
        // MARK: - Layout Margins
        static let screenMargin: CGFloat = md
        static let contentMargin: CGFloat = md
        static let listItemMargin: CGFloat = sm
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 4
        static let medium: CGFloat = 8
        static let large: CGFloat = 12
        static let extraLarge: CGFloat = 16
        
        // MARK: - Component Specific
        static let button: CGFloat = medium
        static let card: CGFloat = large
        static let chip: CGFloat = small
        static let sheet: CGFloat = extraLarge
    }
    
    // MARK: - Shadows
    struct Shadow {
        static let small = Shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        static let medium = Shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
        static let large = Shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }
    
    // MARK: - Animation
    struct Animation {
        // MARK: - Duration
        static let fast: Double = 0.2
        static let normal: Double = 0.3
        static let slow: Double = 0.5
        
        // MARK: - Easing
        static let easeInOut = SwiftUI.Animation.easeInOut
        static let easeIn = SwiftUI.Animation.easeIn
        static let easeOut = SwiftUI.Animation.easeOut
        static let spring = SwiftUI.Animation.spring()
        static let bouncy = SwiftUI.Animation.bouncy
        
        // MARK: - Predefined Animations
        static let buttonTap = SwiftUI.Animation.easeInOut(duration: fast)
        static let viewTransition = SwiftUI.Animation.easeInOut(duration: normal)
        static let branchSwitch = SwiftUI.Animation.spring(duration: normal)
        static let progressUpdate = SwiftUI.Animation.easeOut(duration: slow)
        static let merge = SwiftUI.Animation.bouncy(duration: slow)
    }
    
    // MARK: - Haptic Feedback
    struct Haptics {
        private static let impactLight = UIImpactFeedbackGenerator(style: .light)
        private static let impactMedium = UIImpactFeedbackGenerator(style: .medium)
        private static let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
        private static let notification = UINotificationFeedbackGenerator()
        private static let selection = UISelectionFeedbackGenerator()
        
        // MARK: - Impact Feedback
        static func light() {
            impactLight.impactOccurred()
        }
        
        static func medium() {
            impactMedium.impactOccurred()
        }
        
        static func heavy() {
            impactHeavy.impactOccurred()
        }
        
        // MARK: - Notification Feedback
        static func success() {
            notification.notificationOccurred(.success)
        }
        
        static func warning() {
            notification.notificationOccurred(.warning)
        }
        
        static func error() {
            notification.notificationOccurred(.error)
        }
        
        // MARK: - Selection Feedback
        static func selectionChanged() {
            selection.selectionChanged()
        }
        
        // MARK: - Context-Specific Feedback
        static func branchSwitch() {
            medium()
        }
        
        static func commitCreated() {
            success()
        }
        
        static func taskCompleted() {
            success()
        }
        
        static func branchMerged() {
            heavy()
        }
        
        static func buttonTap() {
            light()
        }
        
        static func filterChanged() {
            selectionChanged()
        }
    }
}

// MARK: - View Extensions for Design System
extension View {
    
    // MARK: - Color Modifiers
    func primaryBackground() -> some View {
        self.background(DesignSystem.Colors.background)
    }
    
    func secondaryBackground() -> some View {
        self.background(DesignSystem.Colors.secondaryBackground)
    }
    
    func cardBackground() -> some View {
        self.background(DesignSystem.Colors.secondaryBackground)
            .cornerRadius(DesignSystem.CornerRadius.card)
    }
    
    // MARK: - Typography Modifiers
    func navigationTitleStyle() -> some View {
        self.font(DesignSystem.Typography.navigationTitle)
            .foregroundColor(DesignSystem.Colors.primaryText)
    }
    
    func sectionHeaderStyle() -> some View {
        self.font(DesignSystem.Typography.sectionHeader)
            .foregroundColor(DesignSystem.Colors.primaryText)
    }
    
    func branchNameStyle() -> some View {
        self.font(DesignSystem.Typography.branchName)
            .foregroundColor(DesignSystem.Colors.primaryText)
    }
    
    func commitMessageStyle() -> some View {
        self.font(DesignSystem.Typography.commitMessage)
            .foregroundColor(DesignSystem.Colors.primaryText)
    }
    
    func taskTitleStyle() -> some View {
        self.font(DesignSystem.Typography.taskTitle)
            .foregroundColor(DesignSystem.Colors.primaryText)
    }
    
    func taskDescriptionStyle() -> some View {
        self.font(DesignSystem.Typography.taskDescription)
            .foregroundColor(DesignSystem.Colors.secondaryText)
    }
    
    func statusLabelStyle() -> some View {
        self.font(DesignSystem.Typography.statusLabel)
            .foregroundColor(DesignSystem.Colors.secondaryText)
    }
    
    func timestampStyle() -> some View {
        self.font(DesignSystem.Typography.timestamp)
            .foregroundColor(DesignSystem.Colors.tertiaryText)
    }
    
    // MARK: - Shadow Modifiers
    func smallShadow() -> some View {
        let shadow = DesignSystem.Shadow.small
        return self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
    
    func mediumShadow() -> some View {
        let shadow = DesignSystem.Shadow.medium
        return self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
    
    func largeShadow() -> some View {
        let shadow = DesignSystem.Shadow.large
        return self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
    
    // MARK: - Animation Modifiers
    func buttonTapAnimation() -> some View {
        self.animation(DesignSystem.Animation.buttonTap, value: UUID())
    }
    
    func viewTransitionAnimation() -> some View {
        self.animation(DesignSystem.Animation.viewTransition, value: UUID())
    }
    
    // MARK: - Haptic Feedback Modifiers
    func onTapWithHaptic(perform action: @escaping () -> Void) -> some View {
        self.onTapGesture {
            DesignSystem.Haptics.buttonTap()
            action()
        }
    }
    
    func onTapWithSelectionHaptic(perform action: @escaping () -> Void) -> some View {
        self.onTapGesture {
            DesignSystem.Haptics.selectionChanged()
            action()
        }
    }
}

// MARK: - Color Extensions for Branch Status
extension BranchStatus {
    var color: Color {
        switch self {
        case .active:
            return DesignSystem.Colors.branchActive
        case .completed:
            return DesignSystem.Colors.branchCompleted
        case .abandoned:
            return DesignSystem.Colors.branchAbandoned
        case .master:
            return DesignSystem.Colors.primary
        }
    }
}

// Note: CommitType already has a color property defined in CommitType.swift