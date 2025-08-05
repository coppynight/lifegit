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
    @Published var loadingState: LoadingState?
    
    // MARK: - Private Properties
    private let taskPlanRepository: TaskPlanRepository
    private let taskPlanService: TaskPlanService
    private let aiErrorHandler: AIServiceErrorHandler
    private let errorHandler = ErrorHandler.shared
    private let feedbackManager = FeedbackManager.shared
    
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
        loadingState = .aiTaskGeneration
        defer { 
            isGenerating = false
            loadingState = nil
        }
        
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
            
            // Show success feedback
            feedbackManager.showSuccess(title: "AI任务计划生成成功", message: "已为您生成详细的任务计划")
            
            return taskPlan
            
        } catch {
            // Handle AI service errors
            let errorInfo = aiErrorHandler.handleError(error, context: "TaskPlanManager.generateTaskPlan")
            
            if errorInfo.canRetry && aiErrorHandler.shouldRetry() {
                // Show retry feedback
                feedbackManager.showInfo(
                    title: "重试中",
                    message: "AI服务暂时不可用，正在重试..."
                )
                
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
                // Show fallback feedback
                feedbackManager.showWarning(
                    title: "AI服务不可用",
                    message: "已为您创建手动任务计划，您可以稍后编辑"
                )
                
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
            let error = TaskPlanManagerError.invalidTaskPlan("Task plan has no associated branch")
            errorHandler.handle(AppError.validationError(.requiredFieldMissing("关联分支")), 
                              context: "TaskPlanManager.regenerateTaskPlan")
            throw error
        }
        
        isGenerating = true
        loadingState = .aiTaskGeneration
        defer { 
            isGenerating = false
            loadingState = nil
        }
        
        do {
            // Delete existing task plan
            try await taskPlanRepository.delete(id: taskPlan.id)
            
            // Generate new task plan
            let newTaskPlan = try await generateTaskPlan(
                goalTitle: branch.name,
                goalDescription: branch.branchDescription,
                branchId: branch.id
            )
            
            feedbackManager.showSuccess(
                title: "任务计划已重新生成",
                message: "新的任务计划已准备就绪"
            )
            
            return newTaskPlan
            
        } catch {
            let managerError = TaskPlanManagerError.regenerationFailed(error.localizedDescription)
            errorHandler.handle(AppError.aiServiceError(.taskPlanError(.validationFailed(error.localizedDescription))), 
                              context: "TaskPlanManager.regenerateTaskPlan")
            self.error = managerError
            throw managerError
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
            taskDescription: "请根据目标描述制定具体的执行步骤：\(goalDescription)",
            estimatedDuration: 60,
            timeScope: .daily,
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
        loadingState = .savingData
        defer { 
            isEditing = false
            loadingState = nil
        }
        
        do {
            taskPlan.totalDuration = totalDuration
            try await taskPlanRepository.update(taskPlan)
            
            feedbackManager.showSuccess(title: "任务计划已保存", message: "您的更改已成功保存")
            
        } catch {
            let managerError = TaskPlanManagerError.updateFailed(error.localizedDescription)
            errorHandler.handle(AppError.dataError(.saveFailure(underlying: error)), 
                              context: "TaskPlanManager.updateTaskPlan")
            self.error = managerError
            feedbackManager.showError(title: "保存失败", message: "无法保存任务计划，请重试")
            throw managerError
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
                taskDescription: description,
                estimatedDuration: estimatedDuration,
                timeScope: timeScope,
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
            taskItem.taskDescription = description
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
            let wasCompleted = taskItem.isCompleted
            taskItem.isCompleted.toggle()
            
            if taskItem.isCompleted {
                taskItem.completedAt = Date()
            } else {
                taskItem.completedAt = nil
            }
            
            // Find and update the task plan
            guard let taskPlan = try await findTaskPlanContaining(taskItem) else {
                let error = TaskPlanManagerError.taskPlanNotFound("Task plan containing task item not found")
                errorHandler.handle(AppError.dataError(.taskPlanNotFound(id: taskItem.id)), 
                                  context: "TaskPlanManager.toggleTaskCompletion")
                throw error
            }
            
            try await taskPlanRepository.update(taskPlan)
            
            // Show appropriate feedback
            if taskItem.isCompleted {
                feedbackManager.showSuccess(
                    title: "任务已完成",
                    message: "'\(taskItem.title)' 已标记为完成"
                )
            } else {
                feedbackManager.showInfo(
                    title: "任务已重新打开",
                    message: "'\(taskItem.title)' 已标记为未完成"
                )
            }
            
        } catch {
            let managerError = TaskPlanManagerError.taskCompletionFailed(error.localizedDescription)
            errorHandler.handle(AppError.dataError(.saveFailure(underlying: error)), 
                              context: "TaskPlanManager.toggleTaskCompletion")
            self.error = managerError
            throw managerError
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
enum TaskPlanManagerError: Error, LocalizedError, Equatable {
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