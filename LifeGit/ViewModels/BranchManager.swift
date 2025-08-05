import Foundation
import SwiftData

/// Manager for branch-related business logic
@MainActor
class BranchManager: ObservableObject {
    // MARK: - Published Properties
    @Published var isCreatingBranch = false
    @Published var isMergingBranch = false
    @Published var isGeneratingTaskPlan = false
    @Published var error: BranchManagerError?
    
    // MARK: - Private Properties
    private let branchRepository: BranchRepository
    private let taskPlanRepository: TaskPlanRepository
    private let commitRepository: CommitRepository
    private let taskPlanService: TaskPlanService
    private let aiErrorHandler: AIServiceErrorHandler
    
    // MARK: - Initialization
    init(
        branchRepository: BranchRepository,
        taskPlanRepository: TaskPlanRepository,
        commitRepository: CommitRepository,
        taskPlanService: TaskPlanService,
        aiErrorHandler: AIServiceErrorHandler
    ) {
        self.branchRepository = branchRepository
        self.taskPlanRepository = taskPlanRepository
        self.commitRepository = commitRepository
        self.aiErrorHandler = aiErrorHandler
        self.taskPlanService = taskPlanService
    }
    
    // MARK: - Branch Creation
    /// Create a new branch with AI-generated task plan
    /// - Parameters:
    ///   - name: Branch name/goal title
    ///   - description: Detailed goal description
    ///   - userId: ID of the user creating the branch
    ///   - timeframe: Expected completion timeframe (optional)
    /// - Returns: Created branch with task plan
    func createBranch(
        name: String,
        description: String,
        userId: UUID,
        timeframe: String? = nil
    ) async throws -> Branch {
        isCreatingBranch = true
        defer { isCreatingBranch = false }
        
        do {
            // Create the branch
            let branch = Branch(
                name: name,
                branchDescription: description,
                status: .active,
                isMaster: false
            )
            
            try await branchRepository.create(branch)
            
            // Generate task plan with AI
            let taskPlan = try await generateTaskPlan(
                for: branch,
                goalTitle: name,
                goalDescription: description,
                timeframe: timeframe
            )
            
            // Associate task plan with branch
            branch.taskPlan = taskPlan
            try await branchRepository.update(branch)
            
            return branch
            
        } catch {
            self.error = BranchManagerError.creationFailed(error.localizedDescription)
            throw error
        }
    }
    
    /// Create a branch with manual task plan (fallback when AI fails)
    /// - Parameters:
    ///   - name: Branch name/goal title
    ///   - description: Detailed goal description
    ///   - userId: ID of the user creating the branch
    /// - Returns: Created branch with basic task plan
    func createBranchWithManualTaskPlan(
        name: String,
        description: String,
        userId: UUID
    ) async throws -> Branch {
        isCreatingBranch = true
        defer { isCreatingBranch = false }
        
        do {
            // Create the branch
            let branch = Branch(
                name: name,
                branchDescription: description,
                status: .active,
                isMaster: false
            )
            
            try await branchRepository.create(branch)
            
            // Create manual task plan
            let taskPlan = aiErrorHandler.createManualTaskPlan(
                goalTitle: name,
                goalDescription: description
            )
            taskPlan.branchId = branch.id
            
            try await taskPlanRepository.create(taskPlan)
            
            // Associate task plan with branch
            branch.taskPlan = taskPlan
            try await branchRepository.update(branch)
            
            return branch
            
        } catch {
            self.error = BranchManagerError.creationFailed(error.localizedDescription)
            throw error
        }
    }
    
    // MARK: - Task Plan Generation
    /// Generate AI task plan for a branch
    private func generateTaskPlan(
        for branch: Branch,
        goalTitle: String,
        goalDescription: String,
        timeframe: String?
    ) async throws -> TaskPlan {
        isGeneratingTaskPlan = true
        defer { isGeneratingTaskPlan = false }
        
        do {
            // Generate task plan with AI
            let aiTaskPlan = try await taskPlanService.generateTaskPlan(
                goalTitle: goalTitle,
                goalDescription: goalDescription,
                timeframe: timeframe
            )
            
            // Convert to domain model
            let taskPlan = taskPlanService.convertToTaskPlan(aiTaskPlan, branchId: branch.id)
            
            // Save task plan
            try await taskPlanRepository.create(taskPlan)
            
            // Reset retry count on success
            aiErrorHandler.resetRetryCount()
            
            return taskPlan
            
        } catch {
            // Handle AI service errors
            let errorInfo = aiErrorHandler.handleError(error)
            
            if errorInfo.canRetry && aiErrorHandler.shouldRetry() {
                // Wait and retry
                let delay = aiErrorHandler.getRetryDelay()
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                
                return try await generateTaskPlan(
                    for: branch,
                    goalTitle: goalTitle,
                    goalDescription: goalDescription,
                    timeframe: timeframe
                )
            } else {
                // Fallback to manual task plan
                let manualTaskPlan = aiErrorHandler.createManualTaskPlan(
                    goalTitle: goalTitle,
                    goalDescription: goalDescription
                )
                manualTaskPlan.branchId = branch.id
                
                try await taskPlanRepository.create(manualTaskPlan)
                return manualTaskPlan
            }
        }
    }
    
    /// Regenerate task plan for existing branch
    /// - Parameter branch: Branch to regenerate task plan for
    func regenerateTaskPlan(for branch: Branch) async throws {
        guard let existingTaskPlan = branch.taskPlan else {
            throw BranchManagerError.noTaskPlan("Branch has no existing task plan")
        }
        
        isGeneratingTaskPlan = true
        defer { isGeneratingTaskPlan = false }
        
        do {
            // Delete existing task plan
            try await taskPlanRepository.delete(id: existingTaskPlan.id)
            
            // Generate new task plan
            let newTaskPlan = try await generateTaskPlan(
                for: branch,
                goalTitle: branch.name,
                goalDescription: branch.branchDescription,
                timeframe: nil
            )
            
            // Update branch reference
            branch.taskPlan = newTaskPlan
            try await branchRepository.update(branch)
            
        } catch {
            self.error = BranchManagerError.taskPlanGenerationFailed(error.localizedDescription)
            throw error
        }
    }
    
    // MARK: - Branch Merging
    /// Merge a completed branch to master
    /// - Parameter branch: Branch to merge
    func mergeBranch(_ branch: Branch) async throws {
        guard branch.status == .completed else {
            throw BranchManagerError.invalidBranchState("Branch must be completed before merging")
        }
        
        guard !branch.isMaster else {
            throw BranchManagerError.invalidOperation("Cannot merge master branch")
        }
        
        isMergingBranch = true
        defer { isMergingBranch = false }
        
        do {
            // Get master branch
            guard let masterBranch = try await branchRepository.findMasterBranch() else {
                throw BranchManagerError.masterBranchNotFound("Master branch not found")
            }
            
            // Create merge commit in master branch
            let mergeCommit = Commit(
                message: "合并目标: \(branch.name)",
                type: .milestone,
                branchId: masterBranch.id
            )
            
            try await commitRepository.create(mergeCommit)
            
            // Update branch status to merged (we can add this status later)
            // For now, we'll keep it as completed
            branch.completedAt = Date()
            try await branchRepository.update(branch)
            
        } catch {
            self.error = BranchManagerError.mergeFailed(error.localizedDescription)
            throw error
        }
    }
    
    // MARK: - Branch Abandonment
    /// Abandon a branch (mark as abandoned)
    /// - Parameter branch: Branch to abandon
    func abandonBranch(_ branch: Branch) async throws {
        guard !branch.isMaster else {
            throw BranchManagerError.invalidOperation("Cannot abandon master branch")
        }
        
        do {
            branch.status = .abandoned
            try await branchRepository.update(branch)
            
        } catch {
            self.error = BranchManagerError.abandonFailed(error.localizedDescription)
            throw error
        }
    }
    
    // MARK: - Branch Completion
    /// Mark a branch as completed
    /// - Parameter branch: Branch to complete
    func completeBranch(_ branch: Branch) async throws {
        guard branch.status == .active else {
            throw BranchManagerError.invalidBranchState("Only active branches can be completed")
        }
        
        do {
            branch.status = .completed
            branch.completedAt = Date()
            try await branchRepository.update(branch)
            
            // Create completion commit
            let completionCommit = Commit(
                message: "🎉 完成目标: \(branch.name)",
                type: .milestone,
                branchId: branch.id
            )
            
            try await commitRepository.create(completionCommit)
            
        } catch {
            self.error = BranchManagerError.completionFailed(error.localizedDescription)
            throw error
        }
    }
    
    // MARK: - Branch Statistics
    /// Get branch statistics
    /// - Parameter branch: Branch to get statistics for
    /// - Returns: Branch statistics
    func getBranchStatistics(_ branch: Branch) async throws -> BranchStatistics {
        do {
            let commitCount = try await commitRepository.getCommitCount(for: branch.id)
            let taskPlan = try await taskPlanRepository.findByBranchId(branch.id)
            
            let completedTasks = taskPlan?.completedTasksCount ?? 0
            let totalTasks = taskPlan?.tasks.count ?? 0
            let progress = totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) : 0.0
            
            return BranchStatistics(
                commitCount: commitCount,
                totalTasks: totalTasks,
                completedTasks: completedTasks,
                progress: progress,
                estimatedDuration: taskPlan?.totalEstimatedDuration ?? 0
            )
            
        } catch {
            throw BranchManagerError.statisticsCalculationFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Error Handling
    func clearError() {
        error = nil
    }
}

// MARK: - Supporting Types

/// Branch statistics data
struct BranchStatistics {
    let commitCount: Int
    let totalTasks: Int
    let completedTasks: Int
    let progress: Double
    let estimatedDuration: Int
}

/// Branch manager specific errors
enum BranchManagerError: Error, LocalizedError {
    case creationFailed(String)
    case taskPlanGenerationFailed(String)
    case mergeFailed(String)
    case abandonFailed(String)
    case completionFailed(String)
    case invalidBranchState(String)
    case invalidOperation(String)
    case masterBranchNotFound(String)
    case noTaskPlan(String)
    case statisticsCalculationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .creationFailed(let message):
            return "分支创建失败: \(message)"
        case .taskPlanGenerationFailed(let message):
            return "任务计划生成失败: \(message)"
        case .mergeFailed(let message):
            return "分支合并失败: \(message)"
        case .abandonFailed(let message):
            return "分支废弃失败: \(message)"
        case .completionFailed(let message):
            return "分支完成失败: \(message)"
        case .invalidBranchState(let message):
            return "分支状态无效: \(message)"
        case .invalidOperation(let message):
            return "无效操作: \(message)"
        case .masterBranchNotFound(let message):
            return "主干分支未找到: \(message)"
        case .noTaskPlan(let message):
            return "无任务计划: \(message)"
        case .statisticsCalculationFailed(let message):
            return "统计计算失败: \(message)"
        }
    }
}