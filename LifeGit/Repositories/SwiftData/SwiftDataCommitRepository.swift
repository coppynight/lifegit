import Foundation
import SwiftData

/// SwiftData implementation of CommitRepository
@MainActor
class SwiftDataCommitRepository: CommitRepository {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func create(_ commit: Commit) async throws {
        do {
            modelContext.insert(commit)
            try modelContext.save()
        } catch {
            throw DataError.creationFailed("Failed to create commit: \(error.localizedDescription)")
        }
    }
    
    func update(_ commit: Commit) async throws {
        do {
            try modelContext.save()
        } catch {
            throw DataError.updateFailed("Failed to update commit: \(error.localizedDescription)")
        }
    }
    
    func delete(id: UUID) async throws {
        do {
            let descriptor = FetchDescriptor<Commit>(
                predicate: #Predicate { $0.id == id }
            )
            
            let commits = try modelContext.fetch(descriptor)
            guard let commit = commits.first else {
                throw DataError.notFound("Commit with id \(id) not found")
            }
            
            modelContext.delete(commit)
            try modelContext.save()
        } catch let error as DataError {
            throw error
        } catch {
            throw DataError.deletionFailed("Failed to delete commit: \(error.localizedDescription)")
        }
    }
    
    func findById(_ id: UUID) async throws -> Commit? {
        do {
            let descriptor = FetchDescriptor<Commit>(
                predicate: #Predicate { $0.id == id }
            )
            
            let commits = try modelContext.fetch(descriptor)
            return commits.first
        } catch {
            throw DataError.queryFailed("Failed to find commit by id: \(error.localizedDescription)")
        }
    }
    
    func findAll() async throws -> [Commit] {
        do {
            let descriptor = FetchDescriptor<Commit>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            
            return try modelContext.fetch(descriptor)
        } catch {
            throw DataError.queryFailed("Failed to fetch all commits: \(error.localizedDescription)")
        }
    }
    
    func findByBranchId(_ branchId: UUID) async throws -> [Commit] {
        do {
            let descriptor = FetchDescriptor<Commit>(
                predicate: #Predicate { $0.branchId == branchId },
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            
            return try modelContext.fetch(descriptor)
        } catch {
            throw DataError.queryFailed("Failed to find commits by branch id: \(error.localizedDescription)")
        }
    }
    
    func findByType(_ type: CommitType) async throws -> [Commit] {
        do {
            let descriptor = FetchDescriptor<Commit>(
                predicate: #Predicate { $0.type == type },
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            
            return try modelContext.fetch(descriptor)
        } catch {
            throw DataError.queryFailed("Failed to find commits by type: \(error.localizedDescription)")
        }
    }
    
    func findByBranchIdAndType(_ branchId: UUID, type: CommitType) async throws -> [Commit] {
        do {
            let descriptor = FetchDescriptor<Commit>(
                predicate: #Predicate { $0.branchId == branchId && $0.type == type },
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            
            return try modelContext.fetch(descriptor)
        } catch {
            throw DataError.queryFailed("Failed to find commits by branch id and type: \(error.localizedDescription)")
        }
    }
    
    func findByDateRange(from startDate: Date, to endDate: Date) async throws -> [Commit] {
        do {
            let descriptor = FetchDescriptor<Commit>(
                predicate: #Predicate { $0.createdAt >= startDate && $0.createdAt <= endDate },
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            
            return try modelContext.fetch(descriptor)
        } catch {
            throw DataError.queryFailed("Failed to find commits by date range: \(error.localizedDescription)")
        }
    }
    
    func findByBranchIdAndDateRange(_ branchId: UUID, from startDate: Date, to endDate: Date) async throws -> [Commit] {
        do {
            let descriptor = FetchDescriptor<Commit>(
                predicate: #Predicate { 
                    $0.branchId == branchId && 
                    $0.createdAt >= startDate && 
                    $0.createdAt <= endDate 
                },
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            
            return try modelContext.fetch(descriptor)
        } catch {
            throw DataError.queryFailed("Failed to find commits by branch id and date range: \(error.localizedDescription)")
        }
    }
    
    func getCommitCount(for branchId: UUID) async throws -> Int {
        do {
            let descriptor = FetchDescriptor<Commit>(
                predicate: #Predicate { $0.branchId == branchId }
            )
            
            let commits = try modelContext.fetch(descriptor)
            return commits.count
        } catch {
            throw DataError.queryFailed("Failed to get commit count: \(error.localizedDescription)")
        }
    }
    
    func getRecentCommits(limit: Int) async throws -> [Commit] {
        do {
            let descriptor = FetchDescriptor<Commit>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            descriptor.fetchLimit = limit
            
            return try modelContext.fetch(descriptor)
        } catch {
            throw DataError.queryFailed("Failed to get recent commits: \(error.localizedDescription)")
        }
    }
    
    func searchByContent(_ searchText: String) async throws -> [Commit] {
        do {
            let descriptor = FetchDescriptor<Commit>(
                predicate: #Predicate { $0.message.contains(searchText) },
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            
            return try modelContext.fetch(descriptor)
        } catch {
            throw DataError.queryFailed("Failed to search commits by content: \(error.localizedDescription)")
        }
    }
}