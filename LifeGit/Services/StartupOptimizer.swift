import Foundation
import SwiftUI
import SwiftData

/// Startup performance optimizer for the LifeGit app
@MainActor
class StartupOptimizer: ObservableObject {
    static let shared = StartupOptimizer()
    
    // MARK: - Performance Metrics
    @Published var startupTime: TimeInterval = 0
    @Published var isOptimizedStartup = false
    
    private var startupStartTime: CFAbsoluteTime = 0
    private var initializationTasks: [String: CFAbsoluteTime] = [:]
    
    // MARK: - Lazy Loading Properties
    private var _branchRepository: BranchRepository?
    private var _taskPlanService: TaskPlanService?
    private var _commitRepository: CommitRepository?
    
    private init() {
        startupStartTime = CFAbsoluteTimeGetCurrent()
    }
    
    // MARK: - Startup Optimization
    
    /// Optimized app initialization with lazy loading
    func optimizedInitialization(modelContext: ModelContext) async {
        let taskStartTime = CFAbsoluteTimeGetCurrent()
        
        // Phase 1: Critical path initialization (synchronous)
        await initializeCriticalComponents(modelContext: modelContext)
        
        // Phase 2: Background initialization (asynchronous)
        Task.detached(priority: .background) {
            await self.initializeBackgroundComponents()
        }
        
        // Phase 3: Deferred initialization (when needed)
        setupDeferredInitialization()
        
        let taskEndTime = CFAbsoluteTimeGetCurrent()
        initializationTasks["optimizedInitialization"] = taskEndTime - taskStartTime
        
        calculateStartupTime()
        isOptimizedStartup = true
    }
    
    /// Initialize only critical components needed for first screen
    private func initializeCriticalComponents(modelContext: ModelContext) async {
        let taskStartTime = CFAbsoluteTimeGetCurrent()
        
        // Only initialize what's absolutely necessary for the first screen
        _branchRepository = SwiftDataBranchRepository(modelContext: modelContext)
        
        let taskEndTime = CFAbsoluteTimeGetCurrent()
        initializationTasks["criticalComponents"] = taskEndTime - taskStartTime
    }
    
    /// Initialize non-critical components in background
    private func initializeBackgroundComponents() async {
        let taskStartTime = CFAbsoluteTimeGetCurrent()
        
        // Pre-warm caches and prepare secondary services
        await preloadCommonData()
        await initializeSecondaryServices()
        
        let taskEndTime = CFAbsoluteTimeGetCurrent()
        await MainActor.run {
            initializationTasks["backgroundComponents"] = taskEndTime - taskStartTime
        }
    }
    
    /// Setup deferred initialization for components used later
    private func setupDeferredInitialization() {
        // Components will be initialized when first accessed
        // This is handled by lazy properties
    }
    
    // MARK: - Lazy Service Access
    
    /// Get branch repository with lazy initialization
    func getBranchRepository(modelContext: ModelContext) -> BranchRepository {
        if let repository = _branchRepository {
            return repository
        }
        
        let repository = SwiftDataBranchRepository(modelContext: modelContext)
        _branchRepository = repository
        return repository
    }
    
    /// Get task plan service with lazy initialization
    func getTaskPlanService() -> TaskPlanService {
        if let service = _taskPlanService {
            return service
        }
        
        let service = TaskPlanService(apiKey: "dummy-key")
        _taskPlanService = service
        return service
    }
    
    /// Get commit repository with lazy initialization
    func getCommitRepository(modelContext: ModelContext) -> CommitRepository {
        if let repository = _commitRepository {
            return repository
        }
        
        let repository = SwiftDataCommitRepository(modelContext: modelContext)
        _commitRepository = repository
        return repository
    }
    
    // MARK: - Data Preloading
    
    /// Preload commonly accessed data
    private func preloadCommonData() async {
        // Preload master branch data
        if let repository = _branchRepository {
            do {
                _ = try await repository.findMasterBranch()
            } catch {
                print("⚠️ Failed to preload master branch: \(error)")
            }
        }
    }
    
    /// Initialize secondary services that aren't needed immediately
    private func initializeSecondaryServices() async {
        // Initialize services that will be needed soon but not immediately
        // This can include AI service preparation, cache warming, etc.
    }
    
    // MARK: - Performance Monitoring
    
    /// Calculate total startup time
    private func calculateStartupTime() {
        let currentTime = CFAbsoluteTimeGetCurrent()
        startupTime = currentTime - startupStartTime
        
        print("🚀 Startup Performance Metrics:")
        print("   Total startup time: \(String(format: "%.3f", startupTime))s")
        
        for (task, duration) in initializationTasks {
            print("   \(task): \(String(format: "%.3f", duration))s")
        }
        
        if startupTime > 2.0 {
            print("⚠️ Startup time exceeds 2 second target")
        } else {
            print("✅ Startup time within target")
        }
    }
    
    /// Get performance metrics for debugging
    func getPerformanceMetrics() -> [String: TimeInterval] {
        var metrics = initializationTasks
        metrics["totalStartupTime"] = startupTime
        return metrics
    }
    
    // MARK: - Memory Management
    
    /// Clear cached services to free memory if needed
    func clearCaches() {
        _taskPlanService = nil
        // Keep critical services like repositories
    }
    
    /// Warm up caches for better performance
    func warmUpCaches() async {
        await preloadCommonData()
    }
}

// MARK: - Startup Performance Extensions

extension AppStateManager {
    /// Optimized initialization using StartupOptimizer
    func optimizedInitialize(modelContext: ModelContext) async {
        let optimizer = StartupOptimizer.shared
        
        // Use optimized initialization
        await optimizer.optimizedInitialization(modelContext: modelContext)
        
        // Set up repositories using lazy loading
        self.modelContext = modelContext
        self.branchRepository = optimizer.getBranchRepository(modelContext: modelContext)
        
        // Load only essential data
        await loadEssentialData()
    }
    
    /// Load only the data needed for the first screen
    private func loadEssentialData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Check first launch status (fast operation)
            isFirstLaunch = !userDefaults.bool(forKey: UserDefaultsKeys.isFirstLaunch)
            
            if isFirstLaunch {
                try await setupFirstLaunch()
            } else {
                // Load minimal data for startup
                try await loadMinimalStartupData()
            }
            
            updateLastActiveDate()
            
        } catch {
            self.error = DataError.queryFailed("Failed to load startup data: \(error.localizedDescription)")
        }
    }
    
    /// Load minimal data needed for startup
    private func loadMinimalStartupData() async throws {
        guard let branchRepository = branchRepository else { return }
        
        // Only load the current branch and master branch
        let masterBranch = try await branchRepository.findMasterBranch()
        
        // Determine startup branch without loading all branches
        if let masterBranch = masterBranch {
            currentBranch = try await determineStartupBranchOptimized(masterBranch: masterBranch)
        } else {
            // Fallback to master branch if not found
            currentBranch = nil
        }
        
        // Load full branch list in background
        Task.detached(priority: .background) {
            await self.loadFullBranchListInBackground()
        }
    }
    
    /// Optimized startup branch determination
    private func determineStartupBranchOptimized(masterBranch: Branch) async throws -> Branch? {
        guard let branchRepository = branchRepository else { return masterBranch }
        
        switch preferredStartupView {
        case .masterBranch:
            return masterBranch
            
        case .lastViewed:
            // Try to load last viewed branch, fallback to master if not found
            if let lastBranchIdString = userDefaults.string(forKey: UserDefaultsKeys.lastActiveBranchId),
               let lastBranchId = UUID(uuidString: lastBranchIdString),
               let lastBranch = try? await branchRepository.findById(lastBranchId) {
                return lastBranch
            }
            return masterBranch
            
        case .mostActiveBranch, .intelligent:
            // For these cases, we need to load more data, so start with master
            // and update in background
            Task.detached(priority: .userInitiated) {
                await self.updateCurrentBranchInBackground()
            }
            return masterBranch
        }
    }
    
    /// Load full branch list in background
    private func loadFullBranchListInBackground() async {
        guard let branchRepository = branchRepository else { return }
        
        do {
            let allBranches = try await branchRepository.findAll()
            
            await MainActor.run {
                self.branches = allBranches
            }
        } catch {
            await MainActor.run {
                self.error = DataError.queryFailed("Failed to load branches in background: \(error.localizedDescription)")
            }
        }
    }
    
    /// Update current branch in background based on preferences
    private func updateCurrentBranchInBackground() async {
        guard let branchRepository = branchRepository else { return }
        
        do {
            let activeBranches = try await branchRepository.getActiveBranches()
            
            let optimalBranch: Branch?
            
            switch preferredStartupView {
            case .mostActiveBranch:
                optimalBranch = activeBranches.first
            case .intelligent:
                optimalBranch = try await getIntelligentStartupBranch()
            default:
                optimalBranch = nil
            }
            
            if let branch = optimalBranch {
                await MainActor.run {
                    self.currentBranch = branch
                    self.saveCurrentBranchId()
                }
            }
        } catch {
            // Silently fail for background operations
            print("⚠️ Failed to update current branch in background: \(error)")
        }
    }
}