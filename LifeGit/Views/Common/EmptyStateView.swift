import SwiftUI

/// Enhanced empty state view with better user guidance and onboarding
struct EmptyStateView: View {
    @EnvironmentObject private var appState: AppStateManager
    @EnvironmentObject private var feedbackManager: FeedbackManager
    @State private var showingCreateBranch = false
    @State private var showingOnboarding = false
    @State private var animateIcon = false
    @State private var animateContent = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer(minLength: 40)
                
                // Animated welcome section
                VStack(spacing: 24) {
                    // Animated icon with background
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.opacity(0.1))
                            .frame(width: 120, height: 120)
                            .scaleEffect(animateIcon ? 1.0 : 0.8)
                            .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2), value: animateIcon)
                        
                        Image(systemName: "git.branch")
                            .font(.system(size: 48, weight: .light))
                            .foregroundColor(.accentColor)
                            .scaleEffect(animateIcon ? 1.0 : 0.5)
                            .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.4), value: animateIcon)
                    }
                    
                    VStack(spacing: 12) {
                        Text(welcomeTitle)
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .opacity(animateContent ? 1.0 : 0.0)
                            .offset(y: animateContent ? 0 : 20)
                            .animation(.easeOut(duration: 0.6).delay(0.6), value: animateContent)
                        
                        Text(welcomeSubtitle)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                            .opacity(animateContent ? 1.0 : 0.0)
                            .offset(y: animateContent ? 0 : 20)
                            .animation(.easeOut(duration: 0.6).delay(0.8), value: animateContent)
                    }
                }
                
                // Quick start guide
                VStack(spacing: 20) {
                    HStack {
                        Image(systemName: "lightbulb")
                            .foregroundColor(.orange)
                        Text("快速开始")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    
                    VStack(spacing: 16) {
                        QuickStartStep(
                            number: 1,
                            title: "创建第一个目标",
                            description: "从一个小目标开始，比如学习新技能或养成好习惯",
                            icon: "target",
                            color: .blue
                        )
                        
                        QuickStartStep(
                            number: 2,
                            title: "AI生成任务计划",
                            description: "AI会帮您将目标拆解成具体可执行的任务",
                            icon: "sparkles",
                            color: .purple
                        )
                        
                        QuickStartStep(
                            number: 3,
                            title: "记录每日进展",
                            description: "通过提交记录您的学习和进展，积少成多",
                            icon: "checkmark.circle",
                            color: .green
                        )
                    }
                }
                .padding(20)
                .background(Color(.systemGray6))
                .cornerRadius(16)
                .opacity(animateContent ? 1.0 : 0.0)
                .offset(y: animateContent ? 0 : 30)
                .animation(.easeOut(duration: 0.8).delay(1.0), value: animateContent)
                
                // Action buttons
                VStack(spacing: 16) {
                    // Primary action - Create branch
                    Button(action: createFirstBranch) {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                            Text("创建我的第一个目标")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: Color.accentColor.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    // Secondary actions
                    HStack(spacing: 12) {
                        Button(action: showOnboarding) {
                            HStack(spacing: 8) {
                                Image(systemName: "questionmark.circle")
                                Text("使用指南")
                            }
                            .font(.system(size: 16, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .foregroundColor(.primary)
                            .cornerRadius(10)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        
                        Button(action: viewAllBranches) {
                            HStack(spacing: 8) {
                                Image(systemName: "list.bullet")
                                Text("查看分支")
                            }
                            .font(.system(size: 16, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .foregroundColor(.primary)
                            .cornerRadius(10)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                .opacity(animateContent ? 1.0 : 0.0)
                .offset(y: animateContent ? 0 : 30)
                .animation(.easeOut(duration: 0.8).delay(1.2), value: animateContent)
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .onAppear {
            animateIcon = true
            animateContent = true
        }
        .sheet(isPresented: $showingCreateBranch) {
            CreateBranchView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingOnboarding) {
            OnboardingView()
                .environmentObject(appState)
        }
    }
    
    // MARK: - Computed Properties
    
    private var welcomeTitle: String {
        if appState.branches.isEmpty {
            return "开始您的人生Git之旅"
        } else {
            return "选择一个分支开始工作"
        }
    }
    
    private var welcomeSubtitle: String {
        if appState.branches.isEmpty {
            return "将您的人生目标像代码一样管理，\n每个目标都是一个独立的分支，\n完成后合并到人生主干。"
        } else {
            return "您有 \(appState.branches.count) 个分支，\n选择一个分支继续您的目标，\n或创建新的目标分支。"
        }
    }
    
    // MARK: - Actions
    
    private func createFirstBranch() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        showingCreateBranch = true
        
        // Show encouraging message for first-time users
        if appState.branches.isEmpty {
            feedbackManager.showInfo(
                title: "创建第一个目标",
                message: "从一个小目标开始，AI会帮您制定详细计划"
            )
        }
    }
    
    private func showOnboarding() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        showingOnboarding = true
    }
    
    private func viewAllBranches() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Switch to branch list tab
        // This would typically be handled by the parent view
        feedbackManager.showInfo(
            title: "查看分支",
            message: "点击底部的\"分支\"标签查看所有分支"
        )
    }
}

/// Quick start step component
struct QuickStartStep: View {
    let number: Int
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            // Step number and icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 48, height: 48)
                
                VStack(spacing: 2) {
                    Text("\(number)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(color)
                    
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(color)
                }
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
    }
}

/// Placeholder for create branch view
struct CreateBranchView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("创建新目标")
                    .font(.title)
                    .padding()
                
                Text("这里将是创建分支的界面")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("新目标")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("创建") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    EmptyStateView()
        .environmentObject(AppStateManager())
}