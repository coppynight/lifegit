import Foundation
import SwiftData

/// Protocol defining the interface for task plan data operations
protocol TaskPlanRepository {
    /// The model context for data operations
    var modelContext: ModelContext { get }
    /// Create a new task plan
    /// - Parameter taskPlan: The task plan to create
    /// - Throws: DataError if creation fails
    func create(_ taskPlan: TaskPlan) async throws
    
    /// Update an existing task plan
    /// - Parameter taskPlan: The task plan to update
    /// - Throws: DataError if update fails
    func update(_ taskPlan: TaskPlan) async throws
    
    /// Delete a task plan by ID
    /// - Parameter id: The ID of the task plan to delete
    /// - Throws: DataError if deletion fails
    func delete(id: UUID) async throws
    
    /// Find a task plan by ID
    /// - Parameter id: The ID of the task plan to find
    /// - Returns: The task plan if found, nil otherwise
    /// - Throws: DataError if query fails
    func findById(_ id: UUID) async throws -> TaskPlan?
    
    /// Find task plan by branch ID
    /// - Parameter branchId: The branch ID to find task plan for
    /// - Returns: The task plan for the branch if found, nil otherwise
    /// - Throws: DataError if query fails
    func findByBranchId(_ branchId: UUID) async throws -> TaskPlan?
    
    /// Get all task plans
    /// - Returns: Array of all task plans
    /// - Throws: DataError if query fails
    func findAll() async throws -> [TaskPlan]
    
    /// Find AI-generated task plans
    /// - Returns: Array of AI-generated task plans
    /// - Throws: DataError if query fails
    func findAIGenerated() async throws -> [TaskPlan]
    
    /// Find manually created task plans
    /// - Returns: Array of manually created task plans
    /// - Throws: DataError if query fails
    func findManuallyCreated() async throws -> [TaskPlan]
    
    /// Add task item to task plan
    /// - Parameters:
    ///   - taskItem: The task item to add
    ///   - taskPlanId: The ID of the task plan to add to
    /// - Throws: DataError if operation fails
    func addTaskItem(_ taskItem: TaskItem, to taskPlanId: UUID) async throws
    
    /// Remove task item from task plan
    /// - Parameters:
    ///   - taskItemId: The ID of the task item to remove
    ///   - taskPlanId: The ID of the task plan to remove from
    /// - Throws: DataError if operation fails
    func removeTaskItem(taskItemId: UUID, from taskPlanId: UUID) async throws
    
    /// Update task items order in task plan
    /// - Parameters:
    ///   - taskItems: Array of task items in new order
    ///   - taskPlanId: The ID of the task plan to update
    /// - Throws: DataError if operation fails
    func updateTaskItemsOrder(_ taskItems: [TaskItem], in taskPlanId: UUID) async throws
}