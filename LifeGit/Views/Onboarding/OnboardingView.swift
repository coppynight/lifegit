import SwiftUI

/// First-time launch onboarding view that introduces the app concept
struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppStateManager
    @State private var currentPage = 0
    @State private var isCreatingSampleData = false
    
    private let pages = OnboardingPage.allPages
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress indicator
                HStack {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index <= currentPage ? Color.accentColor : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.3), value: currentPage)
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 30)
                
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.5), value: currentPage)
                
                // Navigation buttons
                HStack {
                    if currentPage > 0 {
                        Button("上一步") {
                            withAnimation {
                                currentPage -= 1
                            }
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if currentPage < pages.count - 1 {
                        Button("下一步") {
                            withAnimation {
                                currentPage += 1
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        // Final page - show completion options
                        VStack(spacing: 12) {
                            Button("开始使用") {
                                completeOnboarding(createSampleData: false)
                            }
                            .buttonStyle(.borderedProminent)
                            
                            Button("创建示例目标") {
                                completeOnboarding(createSampleData: true)
                            }
                            .buttonStyle(.bordered)
                            .disabled(isCreatingSampleData)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .navigationTitle("欢迎使用人生Git")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("跳过") {
                        completeOnboarding(createSampleData: false)
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .interactiveDismissDisabled()
    }
    
    private func completeOnboarding(createSampleData: Bool) {
        if createSampleData {
            isCreatingSampleData = true
            Task {
                await SampleDataGenerator.shared.generateSampleData()
                await appState.refreshBranches()
                isCreatingSampleData = false
                dismiss()
            }
        } else {
            dismiss()
        }
    }
}

/// Individual onboarding page view with enhanced animations
struct OnboardingPageView: View {
    let page: OnboardingPage
    @State private var animateIcon = false
    @State private var animateContent = false
    @State private var animateAdditional = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Animated icon with background effect
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.1))
                        .frame(width: 120, height: 120)
                        .scaleEffect(animateIcon ? 1.0 : 0.8)
                        .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2), value: animateIcon)
                    
                    Image(systemName: page.iconName)
                        .font(.system(size: 60, weight: .light))
                        .foregroundColor(.accentColor)
                        .scaleEffect(animateIcon ? 1.0 : 0.5)
                        .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.4), value: animateIcon)
                }
                .padding(.top, 20)
                
                VStack(spacing: 16) {
                    // Animated title
                    Text(page.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .opacity(animateContent ? 1.0 : 0.0)
                        .offset(y: animateContent ? 0 : 20)
                        .animation(.easeOut(duration: 0.6).delay(0.6), value: animateContent)
                    
                    // Animated description
                    Text(page.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 20)
                        .opacity(animateContent ? 1.0 : 0.0)
                        .offset(y: animateContent ? 0 : 20)
                        .animation(.easeOut(duration: 0.6).delay(0.8), value: animateContent)
                }
                
                // Animated additional content
                if let additionalContent = page.additionalContent {
                    additionalContent
                        .padding(.horizontal, 20)
                        .opacity(animateAdditional ? 1.0 : 0.0)
                        .offset(y: animateAdditional ? 0 : 30)
                        .animation(.easeOut(duration: 0.8).delay(1.0), value: animateAdditional)
                }
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            withAnimation {
                animateIcon = true
                animateContent = true
                animateAdditional = true
            }
        }
        .onDisappear {
            animateIcon = false
            animateContent = false
            animateAdditional = false
        }
    }
}

/// Onboarding page data model
struct OnboardingPage {
    let title: String
    let description: String
    let iconName: String
    let additionalContent: AnyView?
    
    init(title: String, description: String, iconName: String, additionalContent: AnyView? = nil) {
        self.title = title
        self.description = description
        self.iconName = iconName
        self.additionalContent = additionalContent
    }
    
    static let allPages: [OnboardingPage] = [
        OnboardingPage(
            title: "欢迎来到人生Git",
            description: "将Git版本控制的概念应用到人生目标管理中，让你的人生更有条理。",
            iconName: "git.branch",
            additionalContent: AnyView(
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "timeline.selection")
                            .foregroundColor(.blue)
                        Text("系统化管理目标")
                            .font(.subheadline)
                    }
                    HStack {
                        Image(systemName: "arrow.branch")
                            .foregroundColor(.green)
                        Text("灵活切换专注点")
                            .font(.subheadline)
                    }
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundColor(.purple)
                        Text("可视化成长历程")
                            .font(.subheadline)
                    }
                }
            )
        ),
        
        OnboardingPage(
            title: "分支管理你的目标",
            description: "每个目标都是一个独立的分支，你可以专注于当前目标，同时保持其他目标的进展。",
            iconName: "arrow.triangle.branch",
            additionalContent: AnyView(
                VStack(spacing: 16) {
                    HStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 12, height: 12)
                        Text("🔵 进行中")
                            .font(.subheadline)
                        Spacer()
                    }
                    HStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 12, height: 12)
                        Text("✅ 已完成")
                            .font(.subheadline)
                        Spacer()
                    }
                    HStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 12, height: 12)
                        Text("❌ 已废弃")
                            .font(.subheadline)
                        Spacer()
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            )
        ),
        
        OnboardingPage(
            title: "AI智能任务规划",
            description: "创建目标时，AI会帮你拆解成具体的任务计划，让目标实现更有章法。",
            iconName: "sparkles",
            additionalContent: AnyView(
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "calendar.day.timeline.left")
                            .foregroundColor(.orange)
                        Text("每日任务")
                            .font(.subheadline)
                        Spacer()
                    }
                    HStack {
                        Image(systemName: "calendar.week.timeline.left")
                            .foregroundColor(.blue)
                        Text("每周任务")
                            .font(.subheadline)
                        Spacer()
                    }
                    HStack {
                        Image(systemName: "calendar.month.timeline.left")
                            .foregroundColor(.purple)
                        Text("每月任务")
                            .font(.subheadline)
                        Spacer()
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            )
        ),
        
        OnboardingPage(
            title: "记录进展，见证成长",
            description: "通过提交记录你的每日进展，完成目标后合并到人生主线，升级你的人生版本。",
            iconName: "arrow.up.right.circle",
            additionalContent: AnyView(
                VStack(spacing: 12) {
                    Text("提交类型")
                        .font(.headline)
                        .padding(.bottom, 8)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        CommitTypeCard(emoji: "✅", title: "任务完成")
                        CommitTypeCard(emoji: "📚", title: "学习记录")
                        CommitTypeCard(emoji: "🌟", title: "生活感悟")
                        CommitTypeCard(emoji: "🏆", title: "里程碑")
                    }
                }
            )
        ),
        
        OnboardingPage(
            title: "开始你的人生Git之旅",
            description: "现在你已经了解了基本概念，可以开始创建你的第一个目标分支了！",
            iconName: "flag.checkered",
            additionalContent: AnyView(
                VStack(spacing: 16) {
                    Text("建议从一个小目标开始")
                        .font(.headline)
                        .foregroundColor(.accentColor)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• 学习一项新技能")
                        Text("• 养成一个好习惯")
                        Text("• 完成一个小项目")
                        Text("• 改善生活质量")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            )
        )
    ]
}

/// Commit type card for onboarding
struct CommitTypeCard: View {
    let emoji: String
    let title: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(emoji)
                .font(.title2)
            Text(title)
                .font(.caption)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppStateManager())
}