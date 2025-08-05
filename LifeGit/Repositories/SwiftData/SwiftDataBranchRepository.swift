import Foundation
import SwiftData

/// SwiftData implementation of BranchRepository
@MainActor
class SwiftDataBranchRepository: BranchRepository {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func create(_ branch: Branch) async throws {
        do {
            modelContext.insert(branch)
            try modelContext.save()
        } catch {
            throw DataError.creationFailed("Failed to create branch: \(error.localizedDescription)")
        }
    }
    
    func update(_ branch: Branch) async throws {
        do {
            try modelContext.save()
        } catch {
            throw DataError.updateFailed("Failed to update branch: \(error.localizedDescription)")
        }
    }
    
    func delete(id: UUID) async throws {
        do {
            let descriptor = FetchDescriptor<Branch>(
                predicate: #Predicate { $0.id == id }
            )
            
            let branches = try modelContext.fetch(descriptor)
            guard let branch = branches.first else {
                throw DataError.notFound("Branch with id \(id) not found")
            }
            
            modelContext.delete(branch)
            try modelContext.save()
        } catch let error as DataError {
            throw error
        } catch {
            throw DataError.deletionFailed("Failed to delete branch: \(error.localizedDescription)")
        }
    }
    
    func findById(_ id: UUID) async throws -> Branch? {
        do {
            let descriptor = FetchDescriptor<Branch>(
                predicate: #Predicate { $0.id == id }
            )
            
            let branches = try modelContext.fetch(descriptor)
            return branches.first
        } catch {
            throw DataError.queryFailed("Failed to find branch by id: \(error.localizedDescription)")
        }
    }
    
    func findAll() async throws -> [Branch] {
        do {
            let descriptor = FetchDescriptor<Branch>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            
            return try modelContext.fetch(descriptor)
        } catch {
            throw DataError.queryFailed("Failed to fetch all branches: \(error.localizedDescription)")
        }
    }
    
    func findByStatus(_ status: BranchStatus) async throws -> [Branch] {
        do {
            let descriptor = FetchDescriptor<Branch>(
                predicate: #Predicate { $0.status == status },
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            
            return try modelContext.fetch(descriptor)
        } catch {
            throw DataError.queryFailed("Failed to find branches by status: \(error.localizedDescription)")
        }
    }
    
    func findMasterBranch() async throws -> Branch? {
        do {
            let descriptor = FetchDescriptor<Branch>(
                predicate: #Predicate { $0.isMaster == true }
            )
            
            let branches = try modelContext.fetch(descriptor)
            return branches.first
        } catch {
            throw DataError.queryFailed("Failed to find master branch: \(error.localizedDescription)")
        }
    }
    
    func findByUserId(_ userId: UUID) async throws -> [Branch] {
        do {
            let descriptor = FetchDescriptor<Branch>(
                predicate: #Predicate { $0.user?.id == userId },
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            
            return try modelContext.fetch(descriptor)
        } catch {
            throw DataError.queryFailed("Failed to find branches by user id: \(error.localizedDescription)")
        }
    }
    
    func getActiveBranches() async throws -> [Branch] {
        return try await findByStatus(.active)
    }
    
    func getCompletedBranches() async throws -> [Branch] {
        return try await findByStatus(.completed)
    }
}