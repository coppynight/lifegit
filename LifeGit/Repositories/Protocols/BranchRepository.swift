import Foundation
import SwiftData

/// Protocol defining the interface for branch data operations
protocol BranchRepository {
    /// The model context for data operations
    var modelContext: ModelContext { get }
    /// Create a new branch
    /// - Parameter branch: The branch to create
    /// - Throws: DataError if creation fails
    func create(_ branch: Branch) async throws
    
    /// Update an existing branch
    /// - Parameter branch: The branch to update
    /// - Throws: DataError if update fails
    func update(_ branch: Branch) async throws
    
    /// Delete a branch by ID
    /// - Parameter id: The ID of the branch to delete
    /// - Throws: DataError if deletion fails
    func delete(id: UUID) async throws
    
    /// Find a branch by ID
    /// - Parameter id: The ID of the branch to find
    /// - Returns: The branch if found, nil otherwise
    /// - Throws: DataError if query fails
    func findById(_ id: UUID) async throws -> Branch?
    
    /// Get all branches
    /// - Returns: Array of all branches
    /// - Throws: DataError if query fails
    func findAll() async throws -> [Branch]
    
    /// Find branches by status
    /// - Parameter status: The status to filter by
    /// - Returns: Array of branches with the specified status
    /// - Throws: DataError if query fails
    func findByStatus(_ status: BranchStatus) async throws -> [Branch]
    
    /// Find the master branch
    /// - Returns: The master branch if it exists
    /// - Throws: DataError if query fails
    func findMasterBranch() async throws -> Branch?
    
    /// Find branches by user ID
    /// - Parameter userId: The user ID to filter by
    /// - Returns: Array of branches belonging to the user
    /// - Throws: DataError if query fails
    func findByUserId(_ userId: UUID) async throws -> [Branch]
    
    /// Get active branches (status = .active)
    /// - Returns: Array of active branches
    /// - Throws: DataError if query fails
    func getActiveBranches() async throws -> [Branch]
    
    /// Get completed branches (status = .completed)
    /// - Returns: Array of completed branches
    /// - Throws: DataError if query fails
    func getCompletedBranches() async throws -> [Branch]
}