import SwiftUI

/// Toast notification component using design system
struct ToastView: View {
    let message: String
    let type: ToastType
    let duration: Double
    @Binding var isShowing: Bool
    
    @State private var offset: CGFloat = -100
    
    init(
        message: String,
        type: ToastType = .info,
        duration: Double = 3.0,
        isShowing: Binding<Bool>
    ) {
        self.message = message
        self.type = type
        self.duration = duration
        self._isShowing = isShowing
    }
    
    var body: some View {
        if isShowing {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: type.iconName)
                    .foregroundColor(type.iconColor)
                    .font(.system(size: DesignSystem.Typography.callout, weight: DesignSystem.Typography.medium))
                
                Text(message)
                    .font(.system(size: DesignSystem.Typography.subheadline))
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                Button(action: {
                    withAnimation(DesignSystem.Animation.viewTransition) {
                        isShowing = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .font(.system(size: DesignSystem.Typography.footnote))
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .fill(DesignSystem.Colors.secondaryBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .stroke(type.borderColor, lineWidth: 1)
                    )
            )
            .mediumShadow()
            .offset(y: offset)
            .animation(DesignSystem.Animation.viewTransition, value: offset)
            .onAppear {
                withAnimation(DesignSystem.Animation.viewTransition) {
                    offset = 0
                }
                
                // Auto dismiss
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                    withAnimation(DesignSystem.Animation.viewTransition) {
                        isShowing = false
                    }
                }
            }
            .onDisappear {
                offset = -100
            }
        }
    }
}

/// Toast type enumeration
enum ToastType {
    case success
    case error
    case warning
    case info
    
    var iconName: String {
        switch self {
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "xmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .info:
            return "info.circle.fill"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .success:
            return DesignSystem.Colors.success
        case .error:
            return DesignSystem.Colors.error
        case .warning:
            return DesignSystem.Colors.warning
        case .info:
            return DesignSystem.Colors.info
        }
    }
    
    var borderColor: Color {
        return iconColor.opacity(0.3)
    }
}

/// Toast manager for showing toasts
@MainActor
class ToastManager: ObservableObject {
    @Published var isShowing = false
    @Published var message = ""
    @Published var type: ToastType = .info
    
    func show(_ message: String, type: ToastType = .info) {
        self.message = message
        self.type = type
        self.isShowing = true
        
        // Haptic feedback
        switch type {
        case .success:
            DesignSystem.Haptics.success()
        case .error:
            DesignSystem.Haptics.error()
        case .warning:
            DesignSystem.Haptics.warning()
        case .info:
            DesignSystem.Haptics.light()
        }
    }
    
    func showSuccess(_ message: String) {
        show(message, type: .success)
    }
    
    func showError(_ message: String) {
        show(message, type: .error)
    }
    
    func showWarning(_ message: String) {
        show(message, type: .warning)
    }
    
    func showInfo(_ message: String) {
        show(message, type: .info)
    }
}

/// View modifier for adding toast functionality
struct ToastModifier: ViewModifier {
    @ObservedObject var toastManager: ToastManager
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            VStack {
                if toastManager.isShowing {
                    ToastView(
                        message: toastManager.message,
                        type: toastManager.type,
                        isShowing: $toastManager.isShowing
                    )
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.top, DesignSystem.Spacing.md)
                }
                
                Spacer()
            }
        }
    }
}

extension View {
    func toast(_ toastManager: ToastManager) -> some View {
        self.modifier(ToastModifier(toastManager: toastManager))
    }
}

private struct ToastPreview: View {
    @StateObject private var toastManager = ToastManager()
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            PrimaryButton(title: "显示成功消息") {
                toastManager.showSuccess("操作成功完成！")
            }
            
            PrimaryButton(title: "显示错误消息") {
                toastManager.showError("操作失败，请重试")
            }
            
            PrimaryButton(title: "显示警告消息") {
                toastManager.showWarning("请注意检查输入内容")
            }
            
            PrimaryButton(title: "显示信息消息") {
                toastManager.showInfo("这是一条信息提示")
            }
        }
        .padding()
        .toast(toastManager)
    }
}

struct ToastView_Previews: PreviewProvider {
    static var previews: some View {
        ToastPreview()
    }
}