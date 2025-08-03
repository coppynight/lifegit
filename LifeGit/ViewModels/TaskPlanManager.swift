import Foundation
import SwiftData

/// Manager for task plan related operations
@MainActor
class TaskPlanManager: ObservableObject {
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var isGenerating = false
    @Published var isEditing = false
    @Published var error: TaskPlanManagerError?
    
    // MARK: - Private Properties
    private let taskPlanRepository: TaskPlanRepository
    private let taskPlanService: TaskPlanService
    private let aiErrorHandler: AIServiceErrorHandler
    
    // MARK: - Initialization
    init(
        taskPlanRepository: TaskPlanRepository,
        taskPlanService: TaskPlanService,
        aiErrorHandler: AIServiceErrorHandler
    ) {
        self.taskPlanRepository = taskPlanRepository
        self.taskPlanService = taskPlanService
        self.aiErrorHandler = aiErrorHandler
    }
    
    // MARK: - Task Plan Generation
    /// Generate a new task plan using AI
    /// - Parameters:
    ///   - goalTitle: Title of the goal
    ///   - goalDescription: Detailed description of the goal
    ///   - branchId: ID of the branch this task plan belongs to
    ///   - timeframe: Expected completion timeframe (optional)
    /// - Returns: Generated task plan
    func generateTaskPlan(
        goalTitle: String,
        goalDescription: String,
        branchId: UUID,
        timeframe: String? = nil
    ) async throws -> TaskPlan {
        isGenerating = true
        defer { isGenerating = false }
        
        do {
            // Generate task plan with AI
            let aiTaskPlan = try await taskPlanService.generateTaskPlan(
                goalTitle: goalTitle,
                goalDescription: goalDescription,
                timeframe: timeframe
            )
            
            // Convert to domain model
            let taskPlan = taskPlanService.convertToTaskPlan(aiTaskPlan, branchId: branchId)
            
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
                    goalTitle: goalTitle,
                    goalDescription: goalDescription,
                    branchId: branchId,
                    timeframe: timeframe
                )
            } else {
                // Fallback to manual task plan
                let manualTaskPlan = createManualTaskPlan(
                    goalTitle: goalTitle,
                    goalDescription: goalDescription,
                    branchId: branchId
                )
                
                try await taskPlanRepository.create(manualTaskPlan)
                return manualTaskPlan
            }
        }
    }
    
    /// Regenerate an existing task plan
    /// - Parameter taskPlan: Existing task plan to regenerate
    /// - Returns: New task plan
    func regenerateTaskPlan(_ taskPlan: TaskPlan) async throws -> TaskPlan {
        guard let branch = taskPlan.branch else {
            throw TaskPlanManagerError.invalidTaskPlan("Task plan has no associated branch")
        }
        
        isGenerating = true
        defer { isGenerating = false }
        
        do {
            // Delete existing task plan
            try await taskPlanRepository.delete(id: taskPlan.id)
            
            // Generate new task plan
            return try await generateTaskPlan(
                goalTitle: branch.name,
                goalDescription: branch.description,
                branchId: branch.id
            )
            
        } catch {
            self.error = TaskPlanManagerError.regenerationFailed(error.localizedDescription)
            throw error
        }
    }
    
    /// Create a manual task plan (fallback when AI fails)
    private func createManualTaskPlan(
        goalTitle: String,
        goalDescription: String,
        branchId: UUID
    ) -> TaskPlan {
        let taskPlan = TaskPlan(
            branchId: branchId,
            totalDuration: "手动创建的任务计划",
            isAIGenerated: false
        )
        
        // Create a basic task structure for manual editing
        let defaultTask = TaskItem(
            title: "开始执行：\(goalTitle)",
            description: "请根据目标描述制定具体的执行步骤：\(goalDescription)",
            timeScope: .daily,
            estimatedDuration: 60,
            orderIndex: 0,
            executionTips: "这是一个手动创建的任务，请根据实际情况修改任务内容和时间安排"
        )
        
        taskPlan.tasks = [defaultTask]
        return taskPlan
    }
    
    // MARK: - Task Plan Editing
    /// Update task plan details
    /// - Parameters:
    ///   - taskPlan: Task plan to update
    ///   - totalDuration: New total duration description
    func updateTaskPlan(_ taskPlan: TaskPlan, totalDuration: String) async throws {
        isEditing = true
        defer { isEditing = false }
        
        do {
            taskPlan.totalDuration = totalDuration
            try await taskPlanRepository.update(taskPlan)
            
        } catch {
            self.error = TaskPlanManagerError.updateFailed(error.localizedDescription)
            throw error
        }
    }
    
    // MARK: - Task Item Management
    /// Add a new task item to task plan
    /// - Parameters:
    ///   - taskPlan: Task plan to add task to
    ///   - title: Task title
    ///   - description: Task description
    ///   - timeScope: Time scope for the task
    ///   - estimatedDuration: Estimated duration in minutes
    ///   - executionTips: Optional execution tips
    func addTaskItem(
        to taskPlan: TaskPlan,
        title: String,
        description: String,
        timeScope: TaskTimeScope,
        estimatedDuration: Int,
        executionTips: String? = nil
    ) async throws {
        isEditing = true
        defer { isEditing = false }
        
        do {
            let taskItem = TaskItem(
                title: title,
                description: description,
                timeScope: timeScope,
                estimatedDuration: estimatedDuration,
                orderIndex: taskPlan.tasks.count,
                executionTips: executionTips
            )
            
            try await taskPlanRepository.addTaskItem(taskItem, to: taskPlan.id)
            
        } catch {
            self.error = TaskPlanManagerError.taskItemAddFailed(error.localizedDescription)
            throw error
        }
    }
    
    /// Update an existing task item
    /// - Parameters:
    ///   - taskItem: Task item to update
    ///   - title: New title
    ///   - description: New description
    ///   - timeScope: New time scope
    ///   - estimatedDuration: New estimated duration
    ///   - executionTips: New execution tips
    func updateTaskItem(
        _ taskItem: TaskItem,
        title: String,
        description: String,
        timeScope: TaskTimeScope,
        estimatedDuration: Int,
        executionTips: String?
    ) async throws {
        isEditing = true
        defer { isEditing = false }
        
        do {
            taskItem.title = title
            taskItem.description = description
            taskItem.timeScope = timeScope
            taskItem.estimatedDuration = estimatedDuration
            taskItem.executionTips = executionTips
            
            // Find the task plan that contains this task item
            guard let taskPlan = try await findTaskPlanContaining(taskItem) else {
                throw TaskPlanManagerError.taskPlanNotFound("Task plan containing task item not found")
            }
            
            try await taskPlanRepository.update(taskPlan)
            
        } catch {
            self.error = TaskPlanManagerError.taskItemUpdateFailed(error.localizedDescription)
            throw error
        }
    }
    
    /// Remove a task item from task plan
    /// - Parameters:
    ///   - taskItem: Task item to remove
    ///   - taskPlan: Task plan to remove from
    func removeTaskItem(_ taskItem: TaskItem, from taskPlan: TaskPlan) async throws {
        isEditing = true
        defer { isEditing = false }
        
        do {
            try await taskPlanRepository.removeTaskItem(taskItemId: taskItem.id, from: taskPlan.id)
            
        } catch {
            self.error = TaskPlanManagerError.taskItemRemoveFailed(error.localizedDescription)
            throw error
        }
    }
    
    /// Reorder task items in task plan
    /// - Parameters:
    ///   - taskItems: Task items in new order
    ///   - taskPlan: Task plan to reorder
    func reorderTaskItems(_ taskItems: [TaskItem], in taskPlan: TaskPlan) async throws {
        isEditing = true
        defer { isEditing = false }
        
        do {
            try await taskPlanRepository.updateTaskItemsOrder(taskItems, in: taskPlan.id)
            
        } catch {
            self.error = TaskPlanManagerError.reorderFailed(error.localizedDescription)
            throw error
        }
    }
    
    // MARK: - Task Completion
    /// Toggle task completion status
    /// - Parameter taskItem: Task item to toggle
    func toggleTaskCompletion(_ taskItem: TaskItem) async throws {
        isEditing = true
        defer { isEditing = false }
        
        do {
            taskItem.isCompleted.toggle()
            
            if taskItem.isCompleted {
                taskItem.completedAt = Date()
            } else {
                taskItem.completedAt = nil
            }
            
            // Find and update the task plan
            guard let taskPlan = try await findTaskPlanContaining(taskItem) else {
                throw TaskPlanManagerError.taskPlanNotFound("Task plan containing task item not found")
            }
            
            try await taskPlanRepository.update(taskPlan)
            
        } catch {
            self.error = TaskPlanManagerError.taskCompletionFailed(error.localizedDescription)
            throw error
        }
    }
    
    // MARK: - Task Plan Queries
    /// Get task plan by branch ID
    /// - Parameter branchId: Branch ID to find task plan for
    /// - Returns: Task plan if found
    func getTaskPlan(for branchId: UUID) async throws -> TaskPlan? {
        isLoading = true
        defer { isLoading = false }
        
        do {
            return try await taskPlanRepository.findByBranchId(branchId)
        } catch {
            self.error = TaskPlanManagerError.queryFailed(error.localizedDescription)
            throw error
        }
    }
    
    /// Find task plan containing a specific task item
    private func findTaskPlanContaining(_ taskItem: TaskItem) async throws -> TaskPlan? {
        let allTaskPlans = try await taskPlanRepository.findAll()
        return allTaskPlans.first { taskPlan in
            taskPlan.tasks.contains { $0.id == taskItem.id }
        }
    }
    
    // MARK: - Statistics
    /// Calculate task plan progress
    /// - Parameter taskPlan: Task plan to calculate progress for
    /// - Returns: Progress statistics
    func calculateProgress(for taskPlan: TaskPlan) -> TaskPlanProgress {
        let totalTasks = taskPlan.tasks.count
        let completedTasks = taskPlan.completedTasksCount
        let progress = totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) : 0.0
        
        let totalEstimatedDuration = taskPlan.totalEstimatedDuration
        let completedDuration = taskPlan.tasks
            .filter { $0.isCompleted }
            .reduce(0) { $0 + $1.estimatedDuration }
        
        return TaskPlanProgress(
            totalTasks: totalTasks,
            completedTasks: completedTasks,
            progress: progress,
            totalEstimatedDuration: totalEstimatedDuration,
            completedDuration: completedDuration
        )
    }
    
    // MARK: - Error Handling
    func clearError() {
        error = nil
    }
}

// MARK: - Supporting Types

/// Task plan progress statistics
struct TaskPlanProgress {
    let totalTasks: Int
    let completedTasks: Int
    let progress: Double
    let totalEstimatedDuration: Int
    let completedDuration: Int
    
    var remainingTasks: Int {
        totalTasks - completedTasks
    }
    
    var remainingDuration: Int {
        totalEstimatedDuration - completedDuration
    }
    
    var isCompleted: Bool {
        progress >= 1.0
    }
}

/// Task plan manager specific errors
enum TaskPlanManagerError: Error, LocalizedError {
    case generationFailed(String)
    case regenerationFailed(String)
    case updateFailed(String)
    case taskItemAddFailed(String)
    case taskItemUpdateFailed(String)
    case taskItemRemoveFailed(String)
    case reorderFailed(String)
    case taskCompletionFailed(String)
    case queryFailed(String)
    case invalidTaskPlan(String)
    case taskPlanNotFound(String)
    
    var errorDescription: String? {
        switch self {
        case .generationFailed(let message):
            return "任务计划生成失败: \(message)"
        case .regenerationFailed(let message):
            return "任务计划重新生成失败: \(message)"
        case .updateFailed(let message):
            return "任务计划更新失败: \(message)"
        case .taskItemAddFailed(let message):
            return "任务项添加失败: \(message)"
        case .taskItemUpdateFailed(let message):
            return "任务项更新失败: \(message)"
        case .taskItemRemoveFailed(let message):
            return "任务项删除失败: \(message)"
        case .reorderFailed(let message):
            return "任务重排序失败: \(message)"
        case .taskCompletionFailed(let message):
            return "任务完成状态更新失败: \(message)"
        case .queryFailed(let message):
            return "任务计划查询失败: \(message)"
        case .invalidTaskPlan(let message):
            return "无效的任务计划: \(message)"
        case .taskPlanNotFound(let message):
            return "任务计划未找到: \(message)"
        }
    }
}