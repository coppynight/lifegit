import Foundation
import SwiftData

/// Service for managing branch review generation and storage
@MainActor
class BranchReviewService: ObservableObject {
    private let deepseekClient: DeepseekR1Client
    private let modelContext: ModelContext
    
    @Published var isGeneratingReview = false
    @Published var lastError: Error?
    
    init(deepseekClient: DeepseekR1Client, modelContext: ModelContext) {
        self.deepseekClient = deepseekClient
        self.modelContext = modelContext
    }
    
    /// Generate and save branch review
    /// - Parameters:
    ///   - branch: The branch to review
    ///   - reviewType: Type of review (completion or abandonment)
    /// - Returns: Generated BranchReview object
    /// - Throws: Error if generation or saving fails
    func generateReview(for branch: Branch, reviewType: ReviewType) async throws -> BranchReview {
        isGeneratingReview = true
        lastError = nil
        
        defer {
            isGeneratingReview = false
        }
        
        do {
            // Generate review using AI
            let reviewData = try await deepseekClient.generateBranchReview(for: branch, reviewType: reviewType)
            
            // Calculate statistics
            let statistics = calculateBranchStatistics(for: branch)
            
            // Create BranchReview object
            let review = BranchReview(
                branchId: branch.id,
                reviewType: reviewType,
                summary: reviewData.summary,
                achievements: reviewData.achievements,
                challenges: reviewData.challenges,
                lessonsLearned: reviewData.lessonsLearned,
                recommendations: reviewData.recommendations,
                nextSteps: reviewData.nextSteps,
                timeEfficiencyScore: reviewData.timeEfficiencyScore,
                goalAchievementScore: reviewData.goalAchievementScore,
                overallScore: reviewData.overallScore,
                totalDays: statistics.totalDays,
                totalCommits: statistics.totalCommits,
                completedTasks: statistics.completedTasks,
                totalTasks: statistics.totalTasks,
                averageCommitsPerDay: statistics.averageCommitsPerDay
            )
            
            // Save to database
            modelContext.insert(review)
            branch.review = review
            
            try modelContext.save()
            
            return review
            
        } catch {
            lastError = error
            throw error
        }
    }
    
    /// Regenerate existing review
    /// - Parameters:
    ///   - branch: The branch with existing review
    /// - Returns: Updated BranchReview object
    /// - Throws: Error if regeneration fails
    func regenerateReview(for branch: Branch) async throws -> BranchReview {
        guard let existingReview = branch.review else {
            throw BranchReviewError.noExistingReview
        }
        
        // Delete existing review
        modelContext.delete(existingReview)
        branch.review = nil
        
        // Generate new review
        return try await generateReview(for: branch, reviewType: existingReview.reviewType)
    }
    
    /// Get review for branch if exists
    /// - Parameter branch: The branch to get review for
    /// - Returns: BranchReview if exists, nil otherwise
    func getReview(for branch: Branch) -> BranchReview? {
        return branch.review
    }
    
    /// Delete review for branch
    /// - Parameter branch: The branch to delete review for
    /// - Throws: Error if deletion fails
    func deleteReview(for branch: Branch) throws {
        guard let review = branch.review else {
            return
        }
        
        modelContext.delete(review)
        branch.review = nil
        try modelContext.save()
    }
    
    /// Calculate branch statistics for review
    private func calculateBranchStatistics(for branch: Branch) -> BranchReviewStatistics {
        let totalDays = Calendar.current.dateComponents([.day], from: branch.createdAt, to: Date()).day ?? 0
        let totalCommits = branch.commits.count
        let completedTasks = branch.taskPlan?.tasks.filter { $0.isCompleted }.count ?? 0
        let totalTasks = branch.taskPlan?.tasks.count ?? 0
        let averageCommitsPerDay = totalDays > 0 ? Double(totalCommits) / Double(totalDays) : 0.0
        
        return BranchReviewStatistics(
            totalDays: totalDays,
            totalCommits: totalCommits,
            completedTasks: completedTasks,
            totalTasks: totalTasks,
            averageCommitsPerDay: averageCommitsPerDay
        )
    }
    
    /// Get all reviews for user
    /// - Returns: Array of all BranchReview objects
    func getAllReviews() -> [BranchReview] {
        let descriptor = FetchDescriptor<BranchReview>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch reviews: \(error)")
            return []
        }
    }
    
    /// Get reviews by type
    /// - Parameter reviewType: Type of reviews to fetch
    /// - Returns: Array of BranchReview objects of specified type
    func getReviews(ofType reviewType: ReviewType) -> [BranchReview] {
        let descriptor = FetchDescriptor<BranchReview>(
            predicate: #Predicate { $0.reviewType == reviewType },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch reviews of type \(reviewType): \(error)")
            return []
        }
    }
}

// MARK: - Supporting Types

/// Branch statistics for review generation
private struct BranchReviewStatistics {
    let totalDays: Int
    let totalCommits: Int
    let completedTasks: Int
    let totalTasks: Int
    let averageCommitsPerDay: Double
}

/// Errors specific to branch review operations
enum BranchReviewError: Error, LocalizedError {
    case noExistingReview
    case reviewGenerationFailed(String)
    case reviewSaveFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .noExistingReview:
            return "没有找到现有的复盘报告"
        case .reviewGenerationFailed(let message):
            return "复盘报告生成失败: \(message)"
        case .reviewSaveFailed(let message):
            return "复盘报告保存失败: \(message)"
        }
    }
}