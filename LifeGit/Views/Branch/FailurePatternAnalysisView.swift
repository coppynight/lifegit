import SwiftUI
import SwiftData

/// View for displaying failure pattern analysis across multiple abandoned branches
struct FailurePatternAnalysisView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var analysisService: AbandonedBranchAnalysisService
    @Query private var allBranches: [Branch]
    
    private var abandonedBranches: [Branch] {
        allBranches.filter { $0.status == .abandoned }
    }
    @State private var patternAnalysis: FailurePatternAnalysis?
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    init() {
        // Initialize with placeholder - should be injected in real app
        let deepseekClient = DeepseekR1Client(apiKey: "placeholder")
        let modelContext = ModelContext(try! ModelContainer(for: Branch.self, AbandonmentAnalysis.self, FailurePatternAnalysis.self))
        self._analysisService = StateObject(wrappedValue: AbandonedBranchAnalysisService(deepseekClient: deepseekClient, modelContext: modelContext))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    headerView
                    
                    // Analysis content
                    if let analysis = patternAnalysis {
                        analysisContentView(analysis: analysis)
                    } else if abandonedBranches.isEmpty {
                        emptyStateView
                    } else {
                        generateAnalysisPrompt
                    }
                }
                .padding()
            }
            .navigationTitle("失败模式分析")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadExistingAnalysis()
            }
            .alert("错误", isPresented: $showingError) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.downtrend.xyaxis")
                    .font(.title2)
                    .foregroundColor(.red)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("失败模式分析")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("分析 \(abandonedBranches.count) 个废弃分支的共同模式")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Statistics
            if !abandonedBranches.isEmpty {
                statisticsView
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var statisticsView: some View {
        HStack {
            statItem(title: "废弃分支", value: "\(abandonedBranches.count)", color: .red)
            Divider().frame(height: 20)
            statItem(title: "平均执行天数", value: "\(averageExecutionDays)", color: .orange)
            Divider().frame(height: 20)
            statItem(title: "平均完成率", value: "\(Int(averageCompletionRate * 100))%", color: .blue)
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
    
    // MARK: - Analysis Content
    
    private func analysisContentView(analysis: FailurePatternAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Common failure reasons
            analysisSection(
                title: "常见失败原因",
                icon: "exclamationmark.triangle.fill",
                iconColor: .red,
                items: analysis.commonFailureReasons
            )
            
            // Recurring challenges
            analysisSection(
                title: "重复出现的挑战",
                icon: "arrow.triangle.2.circlepath",
                iconColor: .orange,
                items: analysis.recurringChallenges
            )
            
            // Behavioral patterns
            analysisSection(
                title: "行为模式",
                icon: "person.crop.circle.badge.questionmark",
                iconColor: .blue,
                items: analysis.behavioralPatterns
            )
            
            // Systemic issues
            analysisSection(
                title: "系统性问题",
                icon: "gearshape.fill",
                iconColor: .purple,
                items: analysis.systemicIssues
            )
            
            // Improvement recommendations
            analysisSection(
                title: "改进建议",
                icon: "arrow.up.circle.fill",
                iconColor: .green,
                items: analysis.improvementRecommendations
            )
            
            // Strengths identified
            analysisSection(
                title: "识别的优势",
                icon: "star.fill",
                iconColor: .yellow,
                items: analysis.strengthsIdentified
            )
            
            // Risk factors
            analysisSection(
                title: "风险因素",
                icon: "shield.slash.fill",
                iconColor: .red,
                items: analysis.riskFactors
            )
            
            // Success predictors
            analysisSection(
                title: "成功预测因子",
                icon: "target",
                iconColor: .green,
                items: analysis.successPredictors
            )
        }
    }
    
    private func analysisSection(title: String, icon: String, iconColor: Color, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index + 1).")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 20, alignment: .leading)
                        
                        Text(item)
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("暂无废弃分支")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("当你有废弃的分支时，这里会显示失败模式分析")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Generate Analysis Prompt
    
    private var generateAnalysisPrompt: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("生成失败模式分析")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("分析你的 \(abandonedBranches.count) 个废弃分支，识别共同的失败模式和改进机会")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                generatePatternAnalysis()
            }) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "brain.head.profile")
                    }
                    Text(isLoading ? "分析中..." : "开始分析")
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.blue)
                .cornerRadius(8)
            }
            .disabled(isLoading || abandonedBranches.isEmpty)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
    
    // MARK: - Helper Methods
    
    private func loadExistingAnalysis() {
        // Try to load existing analysis
        let descriptor = FetchDescriptor<FailurePatternAnalysis>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            let analyses = try modelContext.fetch(descriptor)
            patternAnalysis = analyses.first
        } catch {
            print("Failed to load existing pattern analysis: \(error)")
        }
    }
    
    private func generatePatternAnalysis() {
        guard !abandonedBranches.isEmpty else { return }
        
        isLoading = true
        
        Task {
            do {
                let analysis = try await analysisService.generateFailurePatternAnalysis(for: abandonedBranches)
                await MainActor.run {
                    patternAnalysis = analysis
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                    isLoading = false
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var averageExecutionDays: Int {
        guard !abandonedBranches.isEmpty else { return 0 }
        
        let totalDays = abandonedBranches.reduce(0) { total, branch in
            let days = Calendar.current.dateComponents([.day], from: branch.createdAt, to: Date()).day ?? 0
            return total + days
        }
        
        return totalDays / abandonedBranches.count
    }
    
    private var averageCompletionRate: Double {
        guard !abandonedBranches.isEmpty else { return 0.0 }
        
        let totalRate = abandonedBranches.reduce(0.0) { total, branch in
            let completedTasks = branch.taskPlan?.tasks.filter { $0.isCompleted }.count ?? 0
            let totalTasks = branch.taskPlan?.tasks.count ?? 0
            let rate = totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) : 0.0
            return total + rate
        }
        
        return totalRate / Double(abandonedBranches.count)
    }
}

// MARK: - Preview

#Preview {
    FailurePatternAnalysisView()
        .modelContainer(for: [Branch.self, AbandonmentAnalysis.self, FailurePatternAnalysis.self])
}