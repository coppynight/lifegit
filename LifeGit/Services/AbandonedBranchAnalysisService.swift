import Foundation
import SwiftData

/// Service for analyzing abandoned branches and extracting value from failures
@MainActor
class AbandonedBranchAnalysisService: ObservableObject {
    private let deepseekClient: DeepseekR1Client
    private let modelContext: ModelContext
    
    @Published var isAnalyzing = false
    @Published var lastError: Error?
    
    init(deepseekClient: DeepseekR1Client, modelContext: ModelContext) {
        self.deepseekClient = deepseekClient
        self.modelContext = modelContext
    }
    
    /// Generate comprehensive abandonment analysis
    /// - Parameter branch: The abandoned branch to analyze
    /// - Returns: Detailed analysis with failure insights and value extraction
    /// - Throws: Error if analysis generation fails
    func generateAbandonmentAnalysis(for branch: Branch) async throws -> AbandonmentAnalysis {
        isAnalyzing = true
        lastError = nil
        
        defer {
            isAnalyzing = false
        }
        
        do {
            let analysisData = try await deepseekClient.generateAbandonmentAnalysis(for: branch)
            
            let analysis = AbandonmentAnalysis(
                branchId: branch.id,
                failureReasons: analysisData.failureReasons,
                challengesFaced: analysisData.challengesFaced,
                lessonsLearned: analysisData.lessonsLearned,
                valueExtracted: analysisData.valueExtracted,
                preventionStrategies: analysisData.preventionStrategies,
                futureApplications: analysisData.futureApplications,
                emotionalImpact: analysisData.emotionalImpact,
                recoveryRecommendations: analysisData.recoveryRecommendations,
                resilienceScore: analysisData.resilienceScore,
                learningScore: analysisData.learningScore,
                adaptabilityScore: analysisData.adaptabilityScore
            )
            
            // Save to database
            modelContext.insert(analysis)
            try modelContext.save()
            
            return analysis
            
        } catch {
            lastError = error
            throw error
        }
    }
    
    /// Generate failure pattern analysis across multiple abandoned branches
    /// - Parameter branches: List of abandoned branches to analyze
    /// - Returns: Pattern analysis identifying common failure modes
    /// - Throws: Error if analysis fails
    func generateFailurePatternAnalysis(for branches: [Branch]) async throws -> FailurePatternAnalysis {
        guard !branches.isEmpty else {
            throw AbandonmentAnalysisError.noBranchesToAnalyze
        }
        
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        let patternData = try await deepseekClient.generateFailurePatternAnalysis(for: branches)
        
        let analysis = FailurePatternAnalysis(
            analyzedBranches: branches.map { $0.id },
            commonFailureReasons: patternData.commonFailureReasons,
            recurringChallenges: patternData.recurringChallenges,
            behavioralPatterns: patternData.behavioralPatterns,
            systemicIssues: patternData.systemicIssues,
            improvementRecommendations: patternData.improvementRecommendations,
            strengthsIdentified: patternData.strengthsIdentified,
            riskFactors: patternData.riskFactors,
            successPredictors: patternData.successPredictors
        )
        
        modelContext.insert(analysis)
        try modelContext.save()
        
        return analysis
    }
    
    /// Get abandonment analysis for a specific branch
    /// - Parameter branch: The branch to get analysis for
    /// - Returns: AbandonmentAnalysis if exists, nil otherwise
    func getAnalysis(for branch: Branch) -> AbandonmentAnalysis? {
        do {
            let allAnalyses = try modelContext.fetch(FetchDescriptor<AbandonmentAnalysis>())
            return allAnalyses.first { $0.branchId == branch.id }
        } catch {
            print("Failed to fetch abandonment analysis: \(error)")
            return nil
        }
    }
    
    /// Get all abandonment analyses
    /// - Returns: Array of all AbandonmentAnalysis objects
    func getAllAnalyses() -> [AbandonmentAnalysis] {
        let descriptor = FetchDescriptor<AbandonmentAnalysis>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch abandonment analyses: \(error)")
            return []
        }
    }
    
    /// Delete analysis for a branch
    /// - Parameter branch: The branch to delete analysis for
    /// - Throws: Error if deletion fails
    func deleteAnalysis(for branch: Branch) throws {
        guard let analysis = getAnalysis(for: branch) else {
            return
        }
        
        modelContext.delete(analysis)
        try modelContext.save()
    }
}

// MARK: - Data Models

/// Comprehensive analysis of an abandoned branch
@Model
class AbandonmentAnalysis {
    @Attribute(.unique) var id: UUID
    var branchId: UUID
    var failureReasons: [String] // 失败原因列表
    var challengesFaced: [String] // 面临的挑战
    var lessonsLearned: [String] // 学到的教训
    var valueExtracted: [String] // 提取的价值
    var preventionStrategies: [String] // 预防策略
    var futureApplications: [String] // 未来应用
    var emotionalImpact: String // 情感影响分析
    var recoveryRecommendations: String // 恢复建议
    var resilienceScore: Double // 韧性评分 (0-10)
    var learningScore: Double // 学习能力评分 (0-10)
    var adaptabilityScore: Double // 适应性评分 (0-10)
    var createdAt: Date = Date()
    
    init(id: UUID = UUID(),
         branchId: UUID,
         failureReasons: [String],
         challengesFaced: [String],
         lessonsLearned: [String],
         valueExtracted: [String],
         preventionStrategies: [String],
         futureApplications: [String],
         emotionalImpact: String,
         recoveryRecommendations: String,
         resilienceScore: Double,
         learningScore: Double,
         adaptabilityScore: Double,
         createdAt: Date = Date()) {
        self.id = id
        self.branchId = branchId
        self.failureReasons = failureReasons
        self.challengesFaced = challengesFaced
        self.lessonsLearned = lessonsLearned
        self.valueExtracted = valueExtracted
        self.preventionStrategies = preventionStrategies
        self.futureApplications = futureApplications
        self.emotionalImpact = emotionalImpact
        self.recoveryRecommendations = recoveryRecommendations
        self.resilienceScore = resilienceScore
        self.learningScore = learningScore
        self.adaptabilityScore = adaptabilityScore
        self.createdAt = createdAt
    }
    
    // 计算综合恢复力评分
    var overallResilienceScore: Double {
        return (resilienceScore + learningScore + adaptabilityScore) / 3.0
    }
    
    // 获取评分等级
    var resilienceGrade: String {
        switch overallResilienceScore {
        case 8.0...10.0:
            return "优秀"
        case 6.0..<8.0:
            return "良好"
        case 4.0..<6.0:
            return "一般"
        case 2.0..<4.0:
            return "需改进"
        default:
            return "待提升"
        }
    }
}

/// Analysis of failure patterns across multiple abandoned branches
@Model
class FailurePatternAnalysis {
    @Attribute(.unique) var id: UUID
    var analyzedBranches: [UUID] // 分析的分支ID列表
    var commonFailureReasons: [String] // 常见失败原因
    var recurringChallenges: [String] // 重复出现的挑战
    var behavioralPatterns: [String] // 行为模式
    var systemicIssues: [String] // 系统性问题
    var improvementRecommendations: [String] // 改进建议
    var strengthsIdentified: [String] // 识别的优势
    var riskFactors: [String] // 风险因素
    var successPredictors: [String] // 成功预测因子
    var createdAt: Date = Date()
    
    init(id: UUID = UUID(),
         analyzedBranches: [UUID],
         commonFailureReasons: [String],
         recurringChallenges: [String],
         behavioralPatterns: [String],
         systemicIssues: [String],
         improvementRecommendations: [String],
         strengthsIdentified: [String],
         riskFactors: [String],
         successPredictors: [String],
         createdAt: Date = Date()) {
        self.id = id
        self.analyzedBranches = analyzedBranches
        self.commonFailureReasons = commonFailureReasons
        self.recurringChallenges = recurringChallenges
        self.behavioralPatterns = behavioralPatterns
        self.systemicIssues = systemicIssues
        self.improvementRecommendations = improvementRecommendations
        self.strengthsIdentified = strengthsIdentified
        self.riskFactors = riskFactors
        self.successPredictors = successPredictors
        self.createdAt = createdAt
    }
}

// MARK: - API Response Models
// Note: AbandonmentAnalysisData and FailurePatternAnalysisData are defined in DeepseekR1Client.swift

// MARK: - Error Types

enum AbandonmentAnalysisError: Error, LocalizedError {
    case noBranchesToAnalyze
    case analysisGenerationFailed(String)
    case analysisSaveFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .noBranchesToAnalyze:
            return "没有可分析的废弃分支"
        case .analysisGenerationFailed(let message):
            return "分析生成失败: \(message)"
        case .analysisSaveFailed(let message):
            return "分析保存失败: \(message)"
        }
    }
}