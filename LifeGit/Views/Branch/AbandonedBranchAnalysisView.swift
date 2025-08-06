import SwiftUI
import SwiftData

/// Specialized view for analyzing abandoned branches and extracting value
struct AbandonedBranchAnalysisView: View {
    let branch: Branch
    let review: BranchReview?
    @StateObject private var reviewService: BranchReviewService
    @State private var showingFullReview = false
    @State private var showingValueExtraction = false
    
    init(branch: Branch, review: BranchReview?, reviewService: BranchReviewService) {
        self.branch = branch
        self.review = review
        self._reviewService = StateObject(wrappedValue: reviewService)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            abandonmentHeaderView
            
            // Analysis sections
            if let review = review {
                // Failure analysis
                failureAnalysisSection(review: review)
                
                // Value extraction
                valueExtractionSection(review: review)
                
                // Learning opportunities
                learningOpportunitiesSection(review: review)
                
                // Prevention strategies
                preventionStrategiesSection(review: review)
            } else {
                // Generate analysis prompt
                generateAnalysisPrompt
            }
        }
        .padding()
        .sheet(isPresented: $showingFullReview) {
            if let review = review {
                BranchReviewView(review: review)
            }
        }
        .sheet(isPresented: $showingValueExtraction) {
            ValueExtractionWorksheetView(branch: branch, review: review)
        }
    }
    
    // MARK: - Header
    
    private var abandonmentHeaderView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.red)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("已废弃分支")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(branch.name)
                        .font(.title3)
                        .fontWeight(.bold)
                }
                
                Spacer()
            }
            
            // Abandonment stats
            abandonmentStatsView
        }
        .padding()
        .background(Color.red.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var abandonmentStatsView: some View {
        HStack {
            statItem(title: "执行天数", value: "\(executionDays)", color: .orange)
            Divider().frame(height: 20)
            statItem(title: "完成任务", value: "\(completedTasks)/\(totalTasks)", color: .blue)
            Divider().frame(height: 20)
            statItem(title: "提交数", value: "\(branch.commits.count)", color: .green)
            Divider().frame(height: 20)
            statItem(title: "完成度", value: "\(Int(completionRate * 100))%", color: .purple)
        }
    }
    
    private func statItem(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Analysis Sections
    
    private func failureAnalysisSection(review: BranchReview) -> some View {
        analysisCard(
            title: "失败原因分析",
            icon: "exclamationmark.triangle.fill",
            iconColor: .red,
            content: review.challenges,
            actionTitle: "查看详细分析",
            action: { showingFullReview = true }
        )
    }
    
    private func valueExtractionSection(review: BranchReview) -> some View {
        analysisCard(
            title: "价值提取",
            icon: "diamond.fill",
            iconColor: .blue,
            content: review.achievements.isEmpty ? "从这次经历中仍然获得了宝贵的经验和认知。" : review.achievements,
            actionTitle: "提取价值工作表",
            action: { showingValueExtraction = true }
        )
    }
    
    private func learningOpportunitiesSection(review: BranchReview) -> some View {
        analysisCard(
            title: "学习机会",
            icon: "lightbulb.fill",
            iconColor: .orange,
            content: review.lessonsLearned,
            actionTitle: "应用到新目标",
            action: { /* TODO: Apply lessons to new goals */ }
        )
    }
    
    private func preventionStrategiesSection(review: BranchReview) -> some View {
        analysisCard(
            title: "预防策略",
            icon: "shield.fill",
            iconColor: .green,
            content: review.recommendations,
            actionTitle: "制定预防计划",
            action: { /* TODO: Create prevention plan */ }
        )
    }
    
    private func analysisCard(title: String, icon: String, iconColor: Color, content: String, actionTitle: String, action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            Text(content)
                .font(.body)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
            
            Button(action: action) {
                HStack {
                    Text(actionTitle)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .foregroundColor(.blue)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Generate Analysis Prompt
    
    private var generateAnalysisPrompt: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("深度分析废弃原因")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("让AI帮你分析废弃原因，提取价值，并制定预防策略")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                generateAbandonmentAnalysis()
            }) {
                HStack {
                    if reviewService.isGeneratingReview {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "brain.head.profile")
                    }
                    Text(reviewService.isGeneratingReview ? "分析中..." : "生成废弃分析")
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.red)
                .cornerRadius(8)
            }
            .disabled(reviewService.isGeneratingReview)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
    
    // MARK: - Helper Methods
    
    private func generateAbandonmentAnalysis() {
        Task {
            do {
                _ = try await reviewService.generateReview(for: branch, reviewType: .abandonment)
            } catch {
                // Error handled by service
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var executionDays: Int {
        Calendar.current.dateComponents([.day], from: branch.createdAt, to: Date()).day ?? 0
    }
    
    private var completedTasks: Int {
        branch.taskPlan?.tasks.filter { $0.isCompleted }.count ?? 0
    }
    
    private var totalTasks: Int {
        branch.taskPlan?.tasks.count ?? 0
    }
    
    private var completionRate: Double {
        guard totalTasks > 0 else { return 0.0 }
        return Double(completedTasks) / Double(totalTasks)
    }
}

// MARK: - Value Extraction Worksheet

struct ValueExtractionWorksheetView: View {
    let branch: Branch
    let review: BranchReview?
    @Environment(\.dismiss) private var dismiss
    @State private var extractedValues: [String] = []
    @State private var applicableSkills: [String] = []
    @State private var futureApplications: [String] = []
    @State private var newValue = ""
    @State private var newSkill = ""
    @State private var newApplication = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Introduction
                    introductionSection
                    
                    // Extracted values
                    valueSection(
                        title: "提取的价值",
                        items: $extractedValues,
                        newItem: $newValue,
                        placeholder: "例如：学会了时间管理的重要性",
                        color: .blue
                    )
                    
                    // Applicable skills
                    valueSection(
                        title: "可应用技能",
                        items: $applicableSkills,
                        newItem: $newSkill,
                        placeholder: "例如：项目规划能力",
                        color: .green
                    )
                    
                    // Future applications
                    valueSection(
                        title: "未来应用",
                        items: $futureApplications,
                        newItem: $newApplication,
                        placeholder: "例如：在下个目标中提前做好时间规划",
                        color: .orange
                    )
                }
                .padding()
            }
            .navigationTitle("价值提取工作表")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveValueExtraction()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private var introductionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("从失败中提取价值")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("虽然目标「\(branch.name)」被废弃了，但这段经历仍然有价值。让我们一起提取其中的价值，为未来的成功做准备。")
                .font(.body)
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func valueSection(title: String, items: Binding<[String]>, newItem: Binding<String>, placeholder: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            // Existing items
            ForEach(Array(items.wrappedValue.enumerated()), id: \.offset) { index, item in
                HStack {
                    Text("• \(item)")
                        .font(.body)
                    
                    Spacer()
                    
                    Button(action: {
                        items.wrappedValue.remove(at: index)
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.red)
                    }
                }
                .padding(.vertical, 4)
            }
            
            // Add new item
            HStack {
                TextField(placeholder, text: newItem)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: {
                    if !newItem.wrappedValue.isEmpty {
                        items.wrappedValue.append(newItem.wrappedValue)
                        newItem.wrappedValue = ""
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(color)
                        .font(.title2)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private func saveValueExtraction() {
        // TODO: Save the extracted values to the review or create a separate model
        print("Saving value extraction:")
        print("Values: \(extractedValues)")
        print("Skills: \(applicableSkills)")
        print("Applications: \(futureApplications)")
    }
}

// MARK: - Preview

#Preview {
    let branch = Branch(
        name: "学习机器学习",
        branchDescription: "深入学习机器学习算法和应用",
        status: .abandoned
    )
    
    let review = BranchReview(
        branchId: branch.id,
        reviewType: .abandonment,
        summary: "由于时间安排冲突和学习难度超出预期，这个目标最终被废弃。但在过程中仍然学到了很多基础知识。",
        achievements: "掌握了Python基础语法，了解了机器学习的基本概念",
        challenges: "学习时间不足，数学基础薄弱，缺乏实践项目经验",
        lessonsLearned: "需要更好的时间规划，应该先补强数学基础，寻找合适的学习伙伴很重要",
        recommendations: "下次学习技术类目标时，先评估基础知识储备，制定更详细的学习计划",
        nextSteps: "先补强数学基础，然后重新制定机器学习学习计划",
        timeEfficiencyScore: 4.5,
        goalAchievementScore: 2.8,
        overallScore: 3.6,
        totalDays: 30,
        totalCommits: 12,
        completedTasks: 3,
        totalTasks: 15,
        averageCommitsPerDay: 0.4
    )
    
    let mockService = BranchReviewService(
        deepseekClient: DeepseekR1Client(apiKey: "mock"),
        modelContext: ModelContext(try! ModelContainer(for: Branch.self, BranchReview.self))
    )
    
    AbandonedBranchAnalysisView(branch: branch, review: review, reviewService: mockService)
}