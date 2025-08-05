import SwiftUI

/// Custom text field component using design system
struct CustomTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let isRequired: Bool
    let errorMessage: String?
    
    @FocusState private var isFocused: Bool
    
    init(
        title: String,
        placeholder: String,
        text: Binding<String>,
        isRequired: Bool = false,
        errorMessage: String? = nil
    ) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.isRequired = isRequired
        self.errorMessage = errorMessage
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            // Title
            HStack {
                Text(title)
                    .font(.system(size: DesignSystem.Typography.subheadline, weight: DesignSystem.Typography.medium))
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                if isRequired {
                    Text("*")
                        .foregroundColor(DesignSystem.Colors.error)
                }
            }
            
            // Text Field
            TextField(placeholder, text: $text)
                .font(.system(size: DesignSystem.Typography.body))
                .foregroundColor(DesignSystem.Colors.primaryText)
                .padding(.horizontal, DesignSystem.Spacing.sm)
                .padding(.vertical, DesignSystem.Spacing.sm + 2)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                        .fill(DesignSystem.Colors.secondaryBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                        .stroke(borderColor, lineWidth: 1)
                )
                .focused($isFocused)
                .animation(DesignSystem.Animation.buttonTap, value: isFocused)
            
            // Error Message
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.system(size: DesignSystem.Typography.caption1))
                    .foregroundColor(DesignSystem.Colors.error)
            }
        }
    }
    
    private var borderColor: Color {
        if let _ = errorMessage {
            return DesignSystem.Colors.error
        } else if isFocused {
            return DesignSystem.Colors.primary
        } else {
            return Color.clear
        }
    }
}

/// Custom text editor component using design system
struct CustomTextEditor: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let minHeight: CGFloat
    let isRequired: Bool
    let errorMessage: String?
    
    @FocusState private var isFocused: Bool
    
    init(
        title: String,
        placeholder: String,
        text: Binding<String>,
        minHeight: CGFloat = 100,
        isRequired: Bool = false,
        errorMessage: String? = nil
    ) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.minHeight = minHeight
        self.isRequired = isRequired
        self.errorMessage = errorMessage
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            // Title
            HStack {
                Text(title)
                    .font(.system(size: DesignSystem.Typography.subheadline, weight: DesignSystem.Typography.medium))
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                if isRequired {
                    Text("*")
                        .foregroundColor(DesignSystem.Colors.error)
                }
            }
            
            // Text Editor
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .fill(DesignSystem.Colors.secondaryBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .stroke(borderColor, lineWidth: 1)
                    )
                    .frame(minHeight: minHeight)
                
                if text.isEmpty {
                    Text(placeholder)
                        .font(.system(size: DesignSystem.Typography.body))
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                        .padding(.horizontal, DesignSystem.Spacing.sm + 4)
                        .padding(.vertical, DesignSystem.Spacing.sm + 6)
                        .allowsHitTesting(false)
                }
                
                TextEditor(text: $text)
                    .font(.system(size: DesignSystem.Typography.body))
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .padding(.horizontal, DesignSystem.Spacing.sm)
                    .padding(.vertical, DesignSystem.Spacing.sm + 2)
                    .background(Color.clear)
                    .focused($isFocused)
                    .scrollContentBackground(.hidden)
            }
            .animation(DesignSystem.Animation.buttonTap, value: isFocused)
            
            // Error Message
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.system(size: DesignSystem.Typography.caption1))
                    .foregroundColor(DesignSystem.Colors.error)
            }
        }
    }
    
    private var borderColor: Color {
        if let _ = errorMessage {
            return DesignSystem.Colors.error
        } else if isFocused {
            return DesignSystem.Colors.primary
        } else {
            return Color.clear
        }
    }
}

#Preview {
    VStack(spacing: DesignSystem.Spacing.lg) {
        CustomTextField(
            title: "目标名称",
            placeholder: "请输入目标名称",
            text: .constant(""),
            isRequired: true
        )
        
        CustomTextField(
            title: "目标名称",
            placeholder: "请输入目标名称",
            text: .constant("学习SwiftUI"),
            errorMessage: "目标名称不能为空"
        )
        
        CustomTextEditor(
            title: "目标描述",
            placeholder: "请详细描述你的目标...",
            text: .constant(""),
            isRequired: true
        )
    }
    .padding()
}