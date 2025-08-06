import SwiftUI
import SwiftData

/// Demo view to showcase the branch review system functionality
struct BranchReviewDemoView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var demoCompletedBranch: Branch?
    @State private var demoAbandonedBranch: Branch?
    @State private var reviewService: BranchReviewService?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    headerView
                    
                    // Completed branch demo
                    if let completedBranch = demoCompletedBranch {
                        completedBranchSection(branch: completedBranch)
                    }
                    
                    // Abandoned branch demo
                    if let abandonedBranch = demoAbandonedBranch {
                        abandonedBranchSection(branch: abandonedBranch)
                    }
                    
                    // Feature overview
                    featureOverviewSection
                }
                .padding()
            }
            .navigationTitle("复盘系统演示")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                setupDemoData()
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("AI复盘报告系统")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("智能分析目标执行情况，提供个性化改进建议")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Completed Branch Section
    
    private func completedBranchSection(branch: Branch) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("完成分支复盘")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            Text("分析成功完成的目标，提取成功经验和优化建议")
                .font(.body)
                .foregroundColor(.secondary)
            
            if let reviewService = reviewService {
                BranchReviewManagementView(branch: branch, reviewService: reviewService)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Abandoned Branch Section
    
    private func abandonedBranchSection(branch: Branch) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                Text("废弃分支复盘")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            Text("深度分析废弃原因，提取价值和学习机会")
                .font(.body)
                .foregroundColor(.secondary)
            
            if let reviewService = reviewService {
                AbandonedBranchAnalysisView(branch: branch, review: branch.review, reviewService: reviewService)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Feature Overview
    
    private var featureOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("功能特性")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                featureItem(
                    icon: "sparkles",
                    title: "AI智能分析",
                    description: "使用Deepseek-R1模型深度分析目标执行情况",
                    color: .blue
                )
                
                featureItem(
                    icon: "chart.bar.fill",
                    title: "多维度评分",
                    description: "从时间效率、目标达成、综合表现等维度评估",
                    color: .green
                )
                
                featureItem(
                    icon: "lightbulb.fill",
                    title: "个性化建议",
                    description: "基于个人执行模式提供针对性改进建议",
                    color: .orange
                )
                
                featureItem(
                    icon: "arrow.triangle.2.circlepath",
                    title: "失败模式识别",
                    description: "分析多个废弃分支，识别重复的失败模式",
                    color: .red
                )
                
                featureItem(
                    icon: "diamond.fill",
                    title: "价值提取",
                    description: "从失败中提取有价值的经验和技能",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private func featureItem(icon: String, title: String, description: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Setup Demo Data
    
    private func setupDemoData() {
        // Create demo completed branch
        let completedBranch = Branch(
            name: "学习SwiftUI",
            branchDescription: "深入学习SwiftUI框架，掌握现代iOS开发技能",
            status: .completed,
            createdAt: Calendar.current.date(byAdding: .day, value: -45, to: Date()) ?? Date(),
            progress: 1.0
        )
        completedBranch.completedAt = Calendar.current.date(byAdding: .day, value: -5, to: Date())
        
        // Create demo abandoned branch
        let abandonedBranch = Branch(
            name: "学习机器学习",
            branchDescription: "深入学习机器学习算法和应用",
            status: .abandoned,
            createdAt: Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date(),
            progress: 0.3
        )
        
        // Add some demo commits
        let completedCommits = [
            Commit(message: "完成SwiftUI基础教程学习", type: .taskComplete, timestamp: Calendar.current.date(byAdding: .day, value: -40, to: Date()) ?? Date(), branchId: completedBranch.id),
            Commit(message: "学习了State和Binding的使用", type: .learning, timestamp: Calendar.current.date(byAdding: .day, value: -35, to: Date()) ?? Date(), branchId: completedBranch.id),
            Commit(message: "完成第一个SwiftUI应用", type: .milestone, timestamp: Calendar.current.date(byAdding: .day, value: -20, to: Date()) ?? Date(), branchId: completedBranch.id),
            Commit(message: "SwiftUI的声明式编程思维很有趣", type: .reflection, timestamp: Calendar.current.date(byAdding: .day, value: -10, to: Date()) ?? Date(), branchId: completedBranch.id)
        ]
        
        let abandonedCommits = [
            Commit(message: "了解了机器学习的基本概念", type: .learning, timestamp: Calendar.current.date(byAdding: .day, value: -25, to: Date()) ?? Date(), branchId: abandonedBranch.id),
            Commit(message: "安装了Python和相关库", type: .taskComplete, timestamp: Calendar.current.date(byAdding: .day, value: -20, to: Date()) ?? Date(), branchId: abandonedBranch.id),
            Commit(message: "数学基础比想象中更重要", type: .reflection, timestamp: Calendar.current.date(byAdding: .day, value: -15, to: Date()) ?? Date(), branchId: abandonedBranch.id)
        ]
        
        completedBranch.commits = completedCommits
        abandonedBranch.commits = abandonedCommits
        
        // Create demo task plans
        let completedTaskPlan = TaskPlan(
            branchId: completedBranch.id,
            totalDuration: "约600分钟",
            isAIGenerated: true
        )
        
        let completedTasks = [
            TaskItem(title: "学习SwiftUI基础", taskDescription: "了解SwiftUI的基本概念和语法", estimatedDuration: 120, timeScope: .daily, isAIGenerated: true, orderIndex: 1, isCompleted: true),
            TaskItem(title: "实践State管理", taskDescription: "学习State、Binding等状态管理", estimatedDuration: 180, timeScope: .daily, isAIGenerated: true, orderIndex: 2, isCompleted: true),
            TaskItem(title: "构建完整应用", taskDescription: "使用SwiftUI构建一个完整的应用", estimatedDuration: 300, timeScope: .weekly, isAIGenerated: true, orderIndex: 3, isCompleted: true)
        ]
        
        completedTaskPlan.tasks = completedTasks
        completedBranch.taskPlan = completedTaskPlan
        
        let abandonedTaskPlan = TaskPlan(
            branchId: abandonedBranch.id,
            totalDuration: "约720分钟",
            isAIGenerated: true
        )
        
        let abandonedTasks = [
            TaskItem(title: "学习Python基础", taskDescription: "掌握Python编程基础", estimatedDuration: 240, timeScope: .weekly, isAIGenerated: true, orderIndex: 1, isCompleted: true),
            TaskItem(title: "学习数学基础", taskDescription: "复习线性代数和统计学", estimatedDuration: 360, timeScope: .weekly, isAIGenerated: true, orderIndex: 2, isCompleted: false),
            TaskItem(title: "实践机器学习算法", taskDescription: "实现基本的机器学习算法", estimatedDuration: 480, timeScope: .monthly, isAIGenerated: true, orderIndex: 3, isCompleted: false)
        ]
        
        abandonedTaskPlan.tasks = abandonedTasks
        abandonedBranch.taskPlan = abandonedTaskPlan
        
        // Save to context
        modelContext.insert(completedBranch)
        modelContext.insert(abandonedBranch)
        
        do {
            try modelContext.save()
            demoCompletedBranch = completedBranch
            demoAbandonedBranch = abandonedBranch
            
            // Initialize review service
            let deepseekClient = DeepseekR1Client(apiKey: "demo-api-key")
            reviewService = BranchReviewService(deepseekClient: deepseekClient, modelContext: modelContext)
            
        } catch {
            print("Failed to save demo data: \(error)")
        }
    }
}

// MARK: - Preview

#Preview {
    BranchReviewDemoView()
        .modelContainer(for: [Branch.self, Commit.self, TaskPlan.self, TaskItem.self, BranchReview.self, AbandonmentAnalysis.self, FailurePatternAnalysis.self])
}