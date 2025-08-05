import Foundation
import SwiftUI
import SwiftData

/// Global application state manager
@MainActor
class AppStateManager: ObservableObject {
    // MARK: - Published Properties
    @Published var currentBranch: Branch?
    @Published var branches: [Branch] = []
    @Published var isLoading = false
    @Published var error: DataError?
    @Published var isFirstLaunch = false
    @Published var isShowingBranchList = false
    @Published var selectedCommitFilter: CommitType?
    
    // User preferences
    @Published var preferredStartupView: StartupView = .intelligent
    @Published var lastActiveDate = Date()
    
    // MARK: - Internal Properties (for extensions)
    internal var modelContext: ModelContext?
    internal var branchRepository: BranchRepository?
    internal let userDefaults = UserDefaults.standard
    
    // MARK: - Constants
    internal enum UserDefaultsKeys {
        static let isFirstLaunch = "isFirstLaunch"
        static let preferredStartupView = "preferredStartupView"
        static let lastActiveBranchId = "lastActiveBranchId"
        static let lastActiveDate = "lastActiveDate"
    }
    
    // MARK: - Initialization
    init() {
        loadUserPreferences()
    }
    
    func initialize(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.branchRepository = SwiftDataBranchRepository(modelContext: modelContext)
        
        Task {
            await loadInitialData()
        }
    }
    
    // MARK: - Initial Data Loading
    func loadInitialData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            guard let branchRepository = branchRepository else {
                self.error = DataError.queryFailed("Repository not initialized")
                return
            }
            
            // Check if this is first launch
            isFirstLaunch = !userDefaults.bool(forKey: UserDefaultsKeys.isFirstLaunch)
            
            if isFirstLaunch {
                try await setupFirstLaunch()
            } else {
                try await loadExistingData()
            }
            
            // Update last active date
            updateLastActiveDate()
            
        } catch {
            self.error = DataError.queryFailed("Failed to load initial data: \(error.localizedDescription)")
        }
    }
    
    /// Setup data for first launch
    internal func setupFirstLaunch() async throws {
        guard let branchRepository = branchRepository else { return }
        
        // Create master branch
        let masterBranch = Branch(
            name: "人生主线",
            branchDescription: "记录人生的主要历程和成就",
            status: .active,
            isMaster: true
        )
        
        try await branchRepository.create(masterBranch)
        
        // Load branches after creation
        branches = try await branchRepository.findAll()
        currentBranch = masterBranch
        
        // Mark first launch as completed
        userDefaults.set(true, forKey: UserDefaultsKeys.isFirstLaunch)
        saveCurrentBranchId()
    }
    
    /// Load existing data for returning users
    private func loadExistingData() async throws {
        guard let branchRepository = branchRepository else { return }
        
        // Load all branches
        branches = try await branchRepository.findAll()
        
        // Determine current branch based on startup preference
        currentBranch = try await determineStartupBranch()
    }
    
    /// Determine which branch to show on startup
    private func determineStartupBranch() async throws -> Branch? {
        switch preferredStartupView {
        case .lastViewed:
            return try await getLastViewedBranch()
        case .masterBranch:
            return try await branchRepository?.findMasterBranch()
        case .mostActiveBranch:
            return try await getMostActiveBranch()
        case .intelligent:
            return try await getIntelligentStartupBranch()
        }
    }
    
    /// Get the last viewed branch
    private func getLastViewedBranch() async throws -> Branch? {
        guard let branchRepository = branchRepository else { return nil }
        
        guard let lastBranchIdString = userDefaults.string(forKey: UserDefaultsKeys.lastActiveBranchId),
              let lastBranchId = UUID(uuidString: lastBranchIdString) else {
            return try await branchRepository.findMasterBranch()
        }
        
        return try await branchRepository.findById(lastBranchId)
    }
    
    /// Get the most active branch (most recent commits)
    private func getMostActiveBranch() async throws -> Branch? {
        guard let branchRepository = branchRepository else { return nil }
        
        let activeBranches = try await branchRepository.getActiveBranches()
        
        // For now, return the most recently created active branch
        // In a full implementation, this would consider commit frequency
        if let firstActive = activeBranches.first {
            return firstActive
        } else {
            return try await branchRepository.findMasterBranch()
        }
    }
    
    /// Intelligent startup branch selection
    internal func getIntelligentStartupBranch() async throws -> Branch? {
        guard let branchRepository = branchRepository else { return nil }
        
        // Check if user just completed a goal (show master to celebrate)
        let lastActiveDate = userDefaults.object(forKey: UserDefaultsKeys.lastActiveDate) as? Date ?? Date.distantPast
        let daysSinceLastActive = Calendar.current.dateComponents([.day], from: lastActiveDate, to: Date()).day ?? 0
        
        if daysSinceLastActive > 7 {
            // User hasn't been active for a week, show master branch
            return try await branchRepository.findMasterBranch()
        } else {
            // Show most active branch
            return try await getMostActiveBranch()
        }
    }
    
    // MARK: - Branch Management
    func switchToBranch(_ branch: Branch) {
        currentBranch = branch
        saveCurrentBranchId()
        updateLastActiveDate()
    }
    
    func refreshBranches() async {
        guard let branchRepository = branchRepository else { return }
        
        do {
            branches = try await branchRepository.findAll()
        } catch {
            self.error = DataError.queryFailed("Failed to refresh branches: \(error.localizedDescription)")
        }
    }
    
    func addBranch(_ branch: Branch) {
        branches.insert(branch, at: 0) // Add to beginning for newest first
    }
    
    func removeBranch(_ branch: Branch) {
        branches.removeAll { $0.id == branch.id }
        
        // If removed branch was current, switch to master
        if currentBranch?.id == branch.id {
            Task {
                guard let branchRepository = branchRepository else { return }
                currentBranch = try await branchRepository.findMasterBranch()
                saveCurrentBranchId()
            }
        }
    }
    
    func updateBranch(_ branch: Branch) {
        if let index = branches.firstIndex(where: { $0.id == branch.id }) {
            branches[index] = branch
        }
        
        // Update current branch if it's the same
        if currentBranch?.id == branch.id {
            currentBranch = branch
        }
    }
    
    // MARK: - User Preferences
    func updateStartupPreference(_ preference: StartupView) {
        preferredStartupView = preference
        userDefaults.set(preference.rawValue, forKey: UserDefaultsKeys.preferredStartupView)
    }
    
    private func loadUserPreferences() {
        if let preferenceString = userDefaults.string(forKey: UserDefaultsKeys.preferredStartupView),
           let preference = StartupView(rawValue: preferenceString) {
            preferredStartupView = preference
        }
    }
    
    internal func saveCurrentBranchId() {
        if let currentBranch = currentBranch {
            userDefaults.set(currentBranch.id.uuidString, forKey: UserDefaultsKeys.lastActiveBranchId)
        }
    }
    
    internal func updateLastActiveDate() {
        lastActiveDate = Date()
        userDefaults.set(lastActiveDate, forKey: UserDefaultsKeys.lastActiveDate)
    }
    
    // MARK: - Error Handling
    func clearError() {
        error = nil
    }
    
    // MARK: - Computed Properties
    var activeBranches: [Branch] {
        branches.filter { $0.status == .active && !$0.isMaster }
    }
    
    var completedBranches: [Branch] {
        branches.filter { $0.status == .completed }
    }
    
    var masterBranch: Branch? {
        branches.first { $0.isMaster }
    }
    
    var hasActiveBranches: Bool {
        !activeBranches.isEmpty
    }
    
    // MARK: - Legacy Support
    func getMasterBranch() -> Branch? {
        return masterBranch
    }
}

// MARK: - Supporting Types

/// Startup view preferences
enum StartupView: String, CaseIterable {
    case lastViewed = "lastViewed"
    case masterBranch = "masterBranch"
    case mostActiveBranch = "mostActiveBranch"
    case intelligent = "intelligent"
    
    var displayName: String {
        switch self {
        case .lastViewed:
            return "上次查看的页面"
        case .masterBranch:
            return "始终显示主干"
        case .mostActiveBranch:
            return "最活跃分支"
        case .intelligent:
            return "智能推荐"
        }
    }
    
    var description: String {
        switch self {
        case .lastViewed:
            return "打开应用时显示上次查看的分支"
        case .masterBranch:
            return "始终显示人生主线"
        case .mostActiveBranch:
            return "显示最近最活跃的分支"
        case .intelligent:
            return "根据使用习惯智能选择显示内容"
        }
    }
}