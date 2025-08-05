import SwiftUI

/// Card view component using design system
struct CardView<Content: View>: View {
    let content: Content
    let padding: CGFloat
    let hasShadow: Bool
    let onTap: (() -> Void)?
    
    init(
        padding: CGFloat = DesignSystem.Spacing.md,
        hasShadow: Bool = true,
        onTap: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.padding = padding
        self.hasShadow = hasShadow
        self.onTap = onTap
    }
    
    var body: some View {
        Group {
            if let onTap = onTap {
                Button(action: {
                    DesignSystem.Haptics.buttonTap()
                    onTap()
                }) {
                    cardContent
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                cardContent
            }
        }
    }
    
    private var cardContent: some View {
        content
            .padding(padding)
            .background(DesignSystem.Colors.secondaryBackground)
            .cornerRadius(DesignSystem.CornerRadius.card)
            .conditionalModifier(hasShadow) { view in
                view.smallShadow()
            }
    }
}

/// Section card with header
struct SectionCard<Content: View>: View {
    let title: String
    let subtitle: String?
    let content: Content
    let headerAction: (() -> Void)?
    let headerActionTitle: String?
    
    init(
        title: String,
        subtitle: String? = nil,
        headerActionTitle: String? = nil,
        headerAction: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.headerActionTitle = headerActionTitle
        self.headerAction = headerAction
        self.content = content()
    }
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text(title)
                            .sectionHeaderStyle()
                        
                        if let subtitle = subtitle {
                            Text(subtitle)
                                .font(.system(size: DesignSystem.Typography.caption1))
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                    }
                    
                    Spacer()
                    
                    if let headerAction = headerAction, let headerActionTitle = headerActionTitle {
                        Button(action: {
                            DesignSystem.Haptics.buttonTap()
                            headerAction()
                        }) {
                            Text(headerActionTitle)
                                .font(.system(size: DesignSystem.Typography.subheadline, weight: DesignSystem.Typography.medium))
                                .foregroundColor(DesignSystem.Colors.primary)
                        }
                    }
                }
                
                // Content
                content
            }
        }
    }
}

/// Info card for displaying key-value information
struct InfoCard: View {
    let items: [(String, String)]
    let title: String?
    
    init(title: String? = nil, items: [(String, String)]) {
        self.title = title
        self.items = items
    }
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                if let title = title {
                    Text(title)
                        .sectionHeaderStyle()
                }
                
                VStack(spacing: DesignSystem.Spacing.sm) {
                    ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                        HStack {
                            Text(item.0)
                                .font(.system(size: DesignSystem.Typography.subheadline))
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            
                            Spacer()
                            
                            Text(item.1)
                                .font(.system(size: DesignSystem.Typography.subheadline, weight: DesignSystem.Typography.medium))
                                .foregroundColor(DesignSystem.Colors.primaryText)
                        }
                        
                        if index < items.count - 1 {
                            Divider()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Helper View Modifier
extension View {
    @ViewBuilder
    func conditionalModifier<T: View>(
        _ condition: Bool,
        transform: (Self) -> T
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: DesignSystem.Spacing.lg) {
            CardView {
                VStack(alignment: .leading) {
                    Text("基础卡片")
                        .font(.headline)
                    Text("这是一个基础的卡片组件示例")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
            
            CardView(onTap: {
                print("Card tapped")
            }) {
                HStack {
                    Text("可点击卡片")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
            
            SectionCard(
                title: "任务计划",
                subtitle: "AI生成 · 3个任务",
                headerActionTitle: "编辑",
                headerAction: {
                    print("Edit tapped")
                }
            ) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("• 学习SwiftUI基础")
                    Text("• 完成项目原型")
                    Text("• 进行用户测试")
                }
                .font(.body)
            }
            
            InfoCard(
                title: "分支信息",
                items: [
                    ("状态", "进行中"),
                    ("创建时间", "2024-01-15"),
                    ("进度", "60%"),
                    ("提交数", "12")
                ]
            )
        }
        .padding()
    }
}