import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var appState = AppStateManager()
    @StateObject private var errorHandler = ErrorHandler.shared
    @StateObject private var feedbackManager = FeedbackManager.shared
    @StateObject private var networkManager = NetworkStatusManager()
    @State private var selectedTab = 0
    @State private var showingOnboarding = false
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                // Main branch/detail view with navigation
                NavigationStack {
                    VStack(spacing: 0) {
                        // Network status indicator
                        // NetworkStatusView()
                        //     .padding(.horizontal, 16)
                        //     .padding(.top, 4)
                        
                        // Branch switcher header
                        BranchSwitcher()
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .background(Color(.systemBackground))
                        
                        Divider()
                        
                        // Main content area
                        if appState.isLoading {
                            LoadingView()
                        } else if let currentBranch = appState.currentBranch {
                            if currentBranch.isMaster {
                                MasterBranchView()
                            } else {
                                BranchDetailView(branch: currentBranch)
                            }
                        } else {
                            EmptyStateView()
                        }
                    }
                    .navigationBarHidden(true)
                }
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                        .environment(\.symbolVariants, selectedTab == 0 ? .fill : .none)
                    Text("主页")
                }
                .tag(0)
                
                // Branch list view
                NavigationStack {
                    BranchListView()
                }
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "list.bullet.circle.fill" : "list.bullet.circle")
                        .environment(\.symbolVariants, selectedTab == 1 ? .fill : .none)
                    Text("分支")
                }
                .tag(1)
                
                // Statistics placeholder
                NavigationStack {
                    StatisticsPlaceholderView()
                }
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "chart.bar.fill" : "chart.bar")
                        .environment(\.symbolVariants, selectedTab == 2 ? .fill : .none)
                    Text("统计")
                }
                .tag(2)
                
                // Settings placeholder with error history
                NavigationStack {
                    SettingsPlaceholderView()
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                NavigationLink("错误日志") {
                                    ErrorHistoryView()
                                }
                                .font(.caption)
                            }
                        }
                }
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "gearshape.fill" : "gearshape")
                        .environment(\.symbolVariants, selectedTab == 3 ? .fill : .none)
                    Text("设置")
                }
                .tag(3)
            }
            .environmentObject(appState)
            .environmentObject(errorHandler)
            .environmentObject(feedbackManager)
            .environmentObject(networkManager)
            
            // Feedback container for toast notifications
            FeedbackContainer()
        }
        .onAppear {
            // Use optimized initialization for better startup performance
            Task {
                await appState.optimizedInitialize(modelContext: modelContext)
            }
        }
        .onChange(of: appState.isFirstLaunch) { _, isFirstLaunch in
            showingOnboarding = isFirstLaunch
        }
        .fullScreenCover(isPresented: $showingOnboarding) {
            OnboardingView()
                .environmentObject(appState)
        }
        // Global error presentation
        .sheet(isPresented: $errorHandler.isShowingError) {
            if let errorPresentation = errorHandler.currentError {
                NavigationView {
                    ErrorView(presentation: errorPresentation) { action in
                        handleErrorAction(action, for: errorPresentation)
                    }
                    .navigationTitle("错误")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("关闭") {
                                errorHandler.dismissError()
                            }
                        }
                    }
                }
                .presentationDetents([.medium, .large])
            }
        }
        // Legacy error alert (fallback)
        .alert("错误", isPresented: .constant(appState.error != nil)) {
            Button("确定") {
                appState.clearError()
            }
        } message: {
            if let error = appState.error {
                Text(error.localizedDescription)
            }
        }
    }
    
    /// Handle error actions from error presentation
    private func handleErrorAction(_ action: ErrorAction, for presentation: ErrorPresentation) {
        switch action {
        case .dismiss:
            errorHandler.dismissError()
            
        case .retry:
            errorHandler.dismissError()
            // Trigger retry based on error context
            if let context = presentation.context {
                handleRetryForContext(context)
            }
            
        case .waitAndRetry:
            errorHandler.dismissError()
            feedbackManager.showInfo(
                title: "稍后重试",
                message: "请等待一段时间后再次尝试"
            )
            
        case .useOfflineMode:
            errorHandler.dismissError()
            feedbackManager.showInfo(
                title: "离线模式",
                message: "您可以手动创建任务计划"
            )
            
        case .openSettings:
            errorHandler.dismissError()
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsUrl)
            }
            
        case .checkConnection:
            errorHandler.dismissError()
            feedbackManager.showInfo(
                title: "检查网络",
                message: "请确认您的网络连接正常"
            )
            
        case .resetApp:
            errorHandler.dismissError()
            showResetConfirmation()
            
        case .contactSupport:
            errorHandler.dismissError()
            // Open support contact (email, etc.)
            if let emailUrl = URL(string: "mailto:support@lifegit.app") {
                UIApplication.shared.open(emailUrl)
            }
        }
    }
    
    /// Handle retry actions based on context
    private func handleRetryForContext(_ context: String) {
        if context.contains("TaskPlanService") {
            // Retry AI task generation
            feedbackManager.showInfo(
                title: "重新生成",
                message: "正在重新生成任务计划..."
            )
        } else if context.contains("DataManager") {
            // Retry data operation
            feedbackManager.showInfo(
                title: "重新保存",
                message: "正在重新保存数据..."
            )
        }
    }
    
    /// Show app reset confirmation
    private func showResetConfirmation() {
        // This would typically show an action sheet or alert
        // For now, just show a feedback message
        feedbackManager.showWarning(
            title: "重置应用",
            message: "请在设置中删除应用数据或重新安装应用"
        )
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [User.self, Branch.self, Commit.self, TaskPlan.self, TaskItem.self])
}