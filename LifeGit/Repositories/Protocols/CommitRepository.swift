import Foundation
import SwiftData

/// Protocol defining the interface for commit data operations
protocol CommitRepository {
    /// Create a new commit
    /// - Parameter commit: The commit to create
    /// - Throws: DataError if creation fails
    func create(_ commit: Commit) async throws
    
    /// Update an existing commit
    /// - Parameter commit: The commit to update
    /// - Throws: DataError if update fails
    func update(_ commit: Commit) async throws
    
    /// Delete a commit by ID
    /// - Parameter id: The ID of the commit to delete
    /// - Throws: DataError if deletion fails
    func delete(id: UUID) async throws
    
    /// Find a commit by ID
    /// - Parameter id: The ID of the commit to find
    /// - Returns: The commit if found, nil otherwise
    /// - Throws: DataError if query fails
    func findById(_ id: UUID) async throws -> Commit?
    
    /// Get all commits
    /// - Returns: Array of all commits sorted by creation date (newest first)
    /// - Throws: DataError if query fails
    func findAll() async throws -> [Commit]
    
    /// Find commits by branch ID
    /// - Parameter branchId: The branch ID to filter by
    /// - Returns: Array of commits for the specified branch
    /// - Throws: DataError if query fails
    func findByBranchId(_ branchId: UUID) async throws -> [Commit]
    
    /// Find commits by type
    /// - Parameter type: The commit type to filter by
    /// - Returns: Array of commits with the specified type
    /// - Throws: DataError if query fails
    func findByType(_ type: CommitType) async throws -> [Commit]
    
    /// Find commits by branch ID and type
    /// - Parameters:
    ///   - branchId: The branch ID to filter by
    ///   - type: The commit type to filter by
    /// - Returns: Array of commits matching both criteria
    /// - Throws: DataError if query fails
    func findByBranchIdAndType(_ branchId: UUID, type: CommitType) async throws -> [Commit]
    
    /// Find commits within a date range
    /// - Parameters:
    ///   - startDate: The start date of the range
    ///   - endDate: The end date of the range
    /// - Returns: Array of commits within the date range
    /// - Throws: DataError if query fails
    func findByDateRange(from startDate: Date, to endDate: Date) async throws -> [Commit]
    
    /// Find commits by branch ID within a date range
    /// - Parameters:
    ///   - branchId: The branch ID to filter by
    ///   - startDate: The start date of the range
    ///   - endDate: The end date of the range
    /// - Returns: Array of commits matching the criteria
    /// - Throws: DataError if query fails
    func findByBranchIdAndDateRange(_ branchId: UUID, from startDate: Date, to endDate: Date) async throws -> [Commit]
    
    /// Get commit count for a branch
    /// - Parameter branchId: The branch ID to count commits for
    /// - Returns: Number of commits in the branch
    /// - Throws: DataError if query fails
    func getCommitCount(for branchId: UUID) async throws -> Int
    
    /// Get recent commits (last N commits)
    /// - Parameter limit: Maximum number of commits to return
    /// - Returns: Array of recent commits
    /// - Throws: DataError if query fails
    func getRecentCommits(limit: Int) async throws -> [Commit]
    
    /// Search commits by content
    /// - Parameter searchText: Text to search for in commit messages
    /// - Returns: Array of commits containing the search text
    /// - Throws: DataError if query fails
    func searchByContent(_ searchText: String) async throws -> [Commit]
}