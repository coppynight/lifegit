import SwiftUI

/// Scale button style for interactive feedback
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Error presentation view for displaying errors to users
struct ErrorView: View {
    let presentation: ErrorPresentation
    let onAction: (ErrorAction) -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Enhanced Error Icon and Title with animation
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(colorForSeverity(presentation.severity).opacity(0.1))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: iconForSeverity(presentation.severity))
                            .font(.system(size: 36, weight: .medium))
                            .foregroundColor(colorForSeverity(presentation.severity))
                    }
                    
                    VStack(spacing: 8) {
                        Text(presentation.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text(severityDescription(presentation.severity))
                            .font(.subheadline)
                            .foregroundColor(colorForSeverity(presentation.severity))
                            .fontWeight(.medium)
                    }
                }
                
                // Enhanced Error Message with better formatting
                VStack(spacing: 12) {
                    Text(presentation.message)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                        .lineSpacing(2)
                    
                    if let context = presentation.context {
                        HStack(spacing: 6) {
                            Image(systemName: "location")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(friendlyContextName(context))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
                
                // Enhanced Recovery Suggestion with tips
                if let suggestion = presentation.recoverySuggestion {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "lightbulb")
                                .foregroundColor(.orange)
                            Text("解决建议")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        
                        Text(suggestion)
                            .font(.callout)
                            .multilineTextAlignment(.leading)
                            .foregroundColor(.primary)
                            .lineSpacing(2)
                        
                        // Additional helpful tips based on error category
                        if let tips = helpfulTips(for: presentation.category) {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(tips, id: \.self) { tip in
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                            .padding(.top, 2)
                                        
                                        Text(tip)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.leading)
                                        
                                        Spacer()
                                    }
                                }
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(16)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                // Enhanced Action Buttons with better styling
                VStack(spacing: 16) {
                    // Primary actions
                    ForEach(presentation.actions.filter { $0.style == .primary }, id: \.self) { action in
                        Button(action: {
                            // Haptic feedback
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                            
                            onAction(action)
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: action.systemImage)
                                    .font(.system(size: 16, weight: .semibold))
                                Text(action.title)
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    
                    // Secondary actions in a grid
                    let secondaryActions = presentation.actions.filter { $0.style == .secondary }
                    if !secondaryActions.isEmpty {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: min(secondaryActions.count, 2)), spacing: 12) {
                            ForEach(secondaryActions, id: \.self) { action in
                                Button(action: {
                                    // Haptic feedback
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                    impactFeedback.impactOccurred()
                                    
                                    onAction(action)
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: action.systemImage)
                                            .font(.system(size: 14, weight: .medium))
                                        Text(action.title)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color(.systemGray6))
                                    .foregroundColor(.primary)
                                    .cornerRadius(10)
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                        }
                    }
                    
                    // Destructive actions
                    ForEach(presentation.actions.filter { $0.style == .destructive }, id: \.self) { action in
                        Button(action: {
                            // Haptic feedback
                            let notificationFeedback = UINotificationFeedbackGenerator()
                            notificationFeedback.notificationOccurred(.warning)
                            
                            onAction(action)
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: action.systemImage)
                                    .font(.system(size: 16, weight: .medium))
                                Text(action.title)
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                
                // Enhanced timestamp with relative time
                VStack(spacing: 4) {
                    Text("发生时间")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(presentation.timestamp.formatted(.relative(presentation: .named)))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fontWeight(.medium)
                }
                .padding(.top, 8)
            }
            .padding(24)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
    }
    
    // MARK: - Helper Methods
    
    private func severityDescription(_ severity: ErrorSeverity) -> String {
        switch severity {
        case .low:
            return "轻微问题"
        case .medium:
            return "需要注意"
        case .high:
            return "严重错误"
        }
    }
    
    private func friendlyContextName(_ context: String) -> String {
        if context.contains("TaskPlanService") {
            return "AI任务规划服务"
        } else if context.contains("DataManager") {
            return "数据管理"
        } else if context.contains("BranchManager") {
            return "分支管理"
        } else if context.contains("CommitManager") {
            return "提交管理"
        } else {
            return context
        }
    }
    
    private func helpfulTips(for category: ErrorCategory) -> [String]? {
        switch category {
        case .network:
            return [
                "确保设备已连接到互联网",
                "尝试切换到其他网络（如移动数据）",
                "检查是否有防火墙或代理设置阻止连接"
            ]
        case .aiService:
            return [
                "AI服务偶尔会繁忙，稍后重试通常能解决",
                "您可以手动创建任务计划作为替代方案",
                "检查网络连接是否稳定"
            ]
        case .data:
            return [
                "确保设备有足够的存储空间",
                "尝试重启应用",
                "如果问题持续，可能需要重新安装应用"
            ]
        case .validation:
            return [
                "检查输入的内容是否符合要求",
                "确保所有必填字段都已填写",
                "避免使用特殊字符或过长的文本"
            ]
        case .system:
            return [
                "尝试重启应用",
                "确保iOS系统版本兼容",
                "检查设备是否有足够的内存"
            ]
        }
    }
    
    private func iconForSeverity(_ severity: ErrorSeverity) -> String {
        switch severity {
        case .low:
            return "info.circle.fill"
        case .medium:
            return "exclamationmark.triangle.fill"
        case .high:
            return "xmark.circle.fill"
        }
    }
    
    private func colorForSeverity(_ severity: ErrorSeverity) -> Color {
        switch severity {
        case .low:
            return .blue
        case .medium:
            return .orange
        case .high:
            return .red
        }
    }
}

/// Compact error banner for inline display
struct ErrorBanner: View {
    let presentation: ErrorPresentation
    let onDismiss: () -> Void
    let onAction: ((ErrorAction) -> Void)?
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconForSeverity(presentation.severity))
                .foregroundColor(colorForSeverity(presentation.severity))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(presentation.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(presentation.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            if let primaryAction = presentation.actions.first(where: { $0.style == .primary }) {
                Button(primaryAction.title) {
                    onAction?(primaryAction)
                }
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(6)
            }
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(colorForSeverity(presentation.severity).opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(colorForSeverity(presentation.severity).opacity(0.3), lineWidth: 1)
        )
    }
    
    private func iconForSeverity(_ severity: ErrorSeverity) -> String {
        switch severity {
        case .low:
            return "info.circle"
        case .medium:
            return "exclamationmark.triangle"
        case .high:
            return "xmark.circle"
        }
    }
    
    private func colorForSeverity(_ severity: ErrorSeverity) -> Color {
        switch severity {
        case .low:
            return .blue
        case .medium:
            return .orange
        case .high:
            return .red
        }
    }
}

/// Toast notification for quick error feedback
struct ErrorToast: View {
    let presentation: ErrorPresentation
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconForSeverity(presentation.severity))
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(presentation.title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(presentation.message)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding()
        .background(colorForSeverity(presentation.severity))
        .cornerRadius(12)
        .shadow(radius: 8)
        .scaleEffect(isVisible ? 1 : 0.8)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isVisible = true
            }
        }
    }
    
    private func iconForSeverity(_ severity: ErrorSeverity) -> String {
        switch severity {
        case .low:
            return "info.circle.fill"
        case .medium:
            return "exclamationmark.triangle.fill"
        case .high:
            return "xmark.circle.fill"
        }
    }
    
    private func colorForSeverity(_ severity: ErrorSeverity) -> Color {
        switch severity {
        case .low:
            return .blue
        case .medium:
            return .orange
        case .high:
            return .red
        }
    }
}



// MARK: - Extensions

extension ErrorCategory: CaseIterable {
    public static var allCases: [ErrorCategory] {
        return [.data, .aiService, .network, .validation, .system]
    }
}

extension ErrorSeverity: CaseIterable {
    public static var allCases: [ErrorSeverity] {
        return [.low, .medium, .high]
    }
}

// MARK: - Preview

#Preview {
    let samplePresentation = ErrorPresentation(
        id: UUID(),
        title: "网络连接失败",
        message: "无法连接到AI服务，请检查网络连接后重试",
        severity: .medium,
        category: .network,
        context: "TaskPlanService.generateTaskPlan",
        recoverySuggestion: "请检查网络连接后重试，或选择手动创建任务计划",
        actions: [.retry, .useOfflineMode, .dismiss],
        timestamp: Date()
    )
    
    VStack(spacing: 20) {
        ErrorView(presentation: samplePresentation) { action in
            print("Action: \(action)")
        }
        
        ErrorBanner(presentation: samplePresentation, onDismiss: {}) { action in
            print("Action: \(action)")
        }
        
        ErrorToast(presentation: samplePresentation)
    }
    .padding()
}