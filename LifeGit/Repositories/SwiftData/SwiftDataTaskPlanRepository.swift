import Foundation
import SwiftData

/// SwiftData implementation of TaskPlanRepository
@MainActor
class SwiftDataTaskPlanRepository: TaskPlanRepository {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // Default initializer using shared model context
    convenience init() {
        self.init(modelContext: DataManager.shared.modelContext)
    }
    
    func create(_ taskPlan: TaskPlan) async throws {
        do {
            modelContext.insert(taskPlan)
            try modelContext.save()
        } catch {
            throw DataError.creationFailed("Failed to create task plan: \(error.localizedDescription)")
        }
    }
    
    func update(_ taskPlan: TaskPlan) async throws {
        do {
            try modelContext.save()
        } catch {
            throw DataError.updateFailed("Failed to update task plan: \(error.localizedDescription)")
        }
    }
    
    func delete(id: UUID) async throws {
        do {
            let descriptor = FetchDescriptor<TaskPlan>(
                predicate: #Predicate { $0.id == id }
            )
            
            let taskPlans = try modelContext.fetch(descriptor)
            guard let taskPlan = taskPlans.first else {
                throw DataError.notFound("Task plan with id \(id) not found")
            }
            
            modelContext.delete(taskPlan)
            try modelContext.save()
        } catch let error as DataError {
            throw error
        } catch {
            throw DataError.deletionFailed("Failed to delete task plan: \(error.localizedDescription)")
        }
    }
    
    func findById(_ id: UUID) async throws -> TaskPlan? {
        do {
            let descriptor = FetchDescriptor<TaskPlan>(
                predicate: #Predicate { $0.id == id }
            )
            
            let taskPlans = try modelContext.fetch(descriptor)
            return taskPlans.first
        } catch {
            throw DataError.queryFailed("Failed to find task plan by id: \(error.localizedDescription)")
        }
    }
    
    func findByBranchId(_ branchId: UUID) async throws -> TaskPlan? {
        do {
            let descriptor = FetchDescriptor<TaskPlan>(
                predicate: #Predicate { $0.branchId == branchId }
            )
            
            let taskPlans = try modelContext.fetch(descriptor)
            return taskPlans.first
        } catch {
            throw DataError.queryFailed("Failed to find task plan by branch id: \(error.localizedDescription)")
        }
    }
    
    func findAll() async throws -> [TaskPlan] {
        do {
            let descriptor = FetchDescriptor<TaskPlan>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            
            return try modelContext.fetch(descriptor)
        } catch {
            throw DataError.queryFailed("Failed to fetch all task plans: \(error.localizedDescription)")
        }
    }
    
    func findAIGenerated() async throws -> [TaskPlan] {
        do {
            let descriptor = FetchDescriptor<TaskPlan>(
                predicate: #Predicate { $0.isAIGenerated == true },
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            
            return try modelContext.fetch(descriptor)
        } catch {
            throw DataError.queryFailed("Failed to find AI-generated task plans: \(error.localizedDescription)")
        }
    }
    
    func findManuallyCreated() async throws -> [TaskPlan] {
        do {
            let descriptor = FetchDescriptor<TaskPlan>(
                predicate: #Predicate { $0.isAIGenerated == false },
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            
            return try modelContext.fetch(descriptor)
        } catch {
            throw DataError.queryFailed("Failed to find manually created task plans: \(error.localizedDescription)")
        }
    }
    
    func addTaskItem(_ taskItem: TaskItem, to taskPlanId: UUID) async throws {
        do {
            guard let taskPlan = try await findById(taskPlanId) else {
                throw DataError.notFound("Task plan with id \(taskPlanId) not found")
            }
            
            // Set the order index to be the last in the list
            taskItem.orderIndex = taskPlan.tasks.count
            
            modelContext.insert(taskItem)
            taskPlan.tasks.append(taskItem)
            
            try modelContext.save()
        } catch let error as DataError {
            throw error
        } catch {
            throw DataError.updateFailed("Failed to add task item: \(error.localizedDescription)")
        }
    }
    
    func removeTaskItem(taskItemId: UUID, from taskPlanId: UUID) async throws {
        do {
            guard let taskPlan = try await findById(taskPlanId) else {
                throw DataError.notFound("Task plan with id \(taskPlanId) not found")
            }
            
            guard let taskItemIndex = taskPlan.tasks.firstIndex(where: { $0.id == taskItemId }) else {
                throw DataError.notFound("Task item with id \(taskItemId) not found in task plan")
            }
            
            let taskItem = taskPlan.tasks[taskItemIndex]
            taskPlan.tasks.remove(at: taskItemIndex)
            modelContext.delete(taskItem)
            
            // Reorder remaining tasks
            for (index, task) in taskPlan.tasks.enumerated() {
                task.orderIndex = index
            }
            
            try modelContext.save()
        } catch let error as DataError {
            throw error
        } catch {
            throw DataError.updateFailed("Failed to remove task item: \(error.localizedDescription)")
        }
    }
    
    func updateTaskItemsOrder(_ taskItems: [TaskItem], in taskPlanId: UUID) async throws {
        do {
            guard let taskPlan = try await findById(taskPlanId) else {
                throw DataError.notFound("Task plan with id \(taskPlanId) not found")
            }
            
            // Update order indices
            for (index, taskItem) in taskItems.enumerated() {
                taskItem.orderIndex = index
            }
            
            // Update the task plan's tasks array
            taskPlan.tasks = taskItems
            
            try modelContext.save()
        } catch let error as DataError {
            throw error
        } catch {
            throw DataError.updateFailed("Failed to update task items order: \(error.localizedDescription)")
        }
    }
}