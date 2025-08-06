import Foundation
import SwiftData

/// Smart homepage manager that provides intelligent content recommendations
@MainActor
class SmartHomepageManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var recommendedBranch: Branch?
    @Published var homepageMode: HomepageMode = .intelligent
    @Published var isAnalyzing = false
    
    // MARK: - Private Properties
    private let modelContext: ModelContext
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Constants
    private enum UserDefaultsKeys {
        static let homepageMode = "homepageMode"
        static let lastAnalysisDate = "lastAnalysisDate"
        static let userBehaviorData = "userBehaviorData"
    }
    
    // MARK: - Initialization
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadHomepageMode()
    }
    
    // MARK: - Public Methods
    
    /// Get recommended branch based on current homepage mode
    func getRecommendedBranch() async -> Branch? {
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        do {
            let branch = try await determineRecommendedBranch()
            await MainActor.run {
                self.recommendedBranch = branch
            }
            return branch
        } catch {
            print("Error getting recommended branch: \(error)")
            return nil
        }
    }
    
    /// Update homepage mode preference
    func updateHomepageMode(_ mode: HomepageMode) {
        homepageMode = mode
        userDefaults.set(mode.rawValue, forKey: UserDefaultsKeys.homepageMode)
        
        // Immediately update recommendation
        Task {
            await getRecommendedBranch()
        }
    }
    
    /// Record user behavior for learning
    func recordUserBehavior(_ behavior: UserBehavior) {
        var behaviorData = getUserBehaviorData()
        behaviorData.append(behavior)
        
        // Keep only last 100 behaviors to prevent unlimited growth
        if behaviorData.count > 100 {
            behaviorData = Array(behaviorData.suffix(100))
        }
        
        saveBehaviorData(behaviorData)
    }
    
    /// Analyze branch activity and return sorted branches by activity score
    func analyzeBranchActivity() async throws -> [BranchActivityScore] {
        let branches = try await getAllBranches()
        var activityScores: [BranchActivityScore] = []
        
        for branch in branches {
            let score = try await calculateActivityScore(for: branch)
            activityScores.append(BranchActivityScore(branch: branch, score: score))
        }
        
        return activityScores.sorted { $0.score > $1.score }
    }
    
    // MARK: - Private Methods
    
    private func determineRecommendedBranch() async throws -> Branch? {
        switch homepageMode {
        case .lastViewed:
            return try await getLastViewedBranch()
        case .masterBranch:
            return try await getMasterBranch()
        case .mostActiveBranch:
            return try await getMostActiveBranch()
        case .intelligent:
            return try await getIntelligentRecommendation()
        }
    }
    
    private func getLastViewedBranch() async throws -> Branch? {
        let behaviorData = getUserBehaviorData()
        
        // Find the most recent branch view behavior
        let recentBranchViews = behaviorData
            .filter { $0.type == .branchView }
            .sorted { $0.timestamp > $1.timestamp }
        
        guard let lastView = recentBranchViews.first,
              let branchId = lastView.branchId else {
            return try await getMasterBranch()
        }
        
        return try await getBranchById(branchId)
    }
    
    private func getMasterBranch() async throws -> Branch? {
        let descriptor = FetchDescriptor<Branch>(
            predicate: #Predicate<Branch> { $0.isMaster == true }
        )
        
        let branches = try modelContext.fetch(descriptor)
        return branches.first
    }
    
    private func getMostActiveBranch() async throws -> Branch? {
        let activityScores = try await analyzeBranchActivity()
        
        // Return the most active non-master branch, or master if no active branches
        let activeBranch = activityScores.first { !$0.branch.isMaster }
        if let branch = activeBranch?.branch {
            return branch
        } else {
            return try await getMasterBranch()
        }
    }
    
    private func getIntelligentRecommendation() async throws -> Branch? {
        let behaviorData = getUserBehaviorData()
        let now = Date()
        
        // Check user's recent activity patterns
        let recentBehaviors = behaviorData.filter { 
            now.timeIntervalSince($0.timestamp) < 7 * 24 * 3600 // Last 7 days
        }
        
        // If user hasn't been active recently, show master branch
        if recentBehaviors.isEmpty {
            return try await getMasterBranch()
        }
        
        // Check if user just completed a goal (show master to celebrate)
        let recentCompletions = recentBehaviors.filter { $0.type == .branchCompleted }
        if !recentCompletions.isEmpty {
            return try await getMasterBranch()
        }
        
        // Check time of day patterns
        let currentHour = Calendar.current.component(.hour, from: now)
        let preferredBranch = try await getBranchForTimeOfDay(currentHour, behaviorData: behaviorData)
        if let preferred = preferredBranch {
            return preferred
        }
        
        // Default to most active branch
        return try await getMostActiveBranch()
    }
    
    private func getBranchForTimeOfDay(_ hour: Int, behaviorData: [UserBehavior]) async throws -> Branch? {
        // Analyze user's historical behavior patterns by time of day
        let timeBasedBehaviors = behaviorData.filter { behavior in
            let behaviorHour = Calendar.current.component(.hour, from: behavior.timestamp)
            return abs(behaviorHour - hour) <= 2 // Within 2 hours
        }
        
        // Find most frequently accessed branch during this time
        var branchFrequency: [UUID: Int] = [:]
        for behavior in timeBasedBehaviors {
            if let branchId = behavior.branchId {
                branchFrequency[branchId, default: 0] += 1
            }
        }
        
        guard let mostFrequentBranchId = branchFrequency.max(by: { $0.value < $1.value })?.key else {
            return nil
        }
        
        return try await getBranchById(mostFrequentBranchId)
    }
    
    private func calculateActivityScore(for branch: Branch) async throws -> Double {
        var score: Double = 0.0
        
        // Base score for active branches
        if branch.status == .active {
            score += 10.0
        }
        
        // Recent commits boost score
        let recentCommits = branch.commits.filter { commit in
            Date().timeIntervalSince(commit.timestamp) < 7 * 24 * 3600 // Last 7 days
        }
        score += Double(recentCommits.count) * 2.0
        
        // Progress boost
        score += branch.progress * 5.0
        
        // Task completion rate
        if branch.totalTasksCount > 0 {
            let completionRate = Double(branch.completedTasksCount) / Double(branch.totalTasksCount)
            score += completionRate * 3.0
        }
        
        // Recency factor (newer branches get slight boost)
        let daysSinceCreation = Date().timeIntervalSince(branch.createdAt) / (24 * 3600)
        if daysSinceCreation < 30 {
            score += (30 - daysSinceCreation) / 30 * 2.0
        }
        
        // Master branch gets special treatment
        if branch.isMaster {
            score += 1.0 // Small boost to ensure it's always considered
        }
        
        return score
    }
    
    private func getAllBranches() async throws -> [Branch] {
        let descriptor = FetchDescriptor<Branch>()
        return try modelContext.fetch(descriptor)
    }
    
    private func getBranchById(_ id: UUID) async throws -> Branch? {
        let descriptor = FetchDescriptor<Branch>(
            predicate: #Predicate<Branch> { $0.id == id }
        )
        
        let branches = try modelContext.fetch(descriptor)
        return branches.first
    }
    
    private func loadHomepageMode() {
        if let modeString = userDefaults.string(forKey: UserDefaultsKeys.homepageMode),
           let mode = HomepageMode(rawValue: modeString) {
            homepageMode = mode
        }
    }
    
    private func getUserBehaviorData() -> [UserBehavior] {
        guard let data = userDefaults.data(forKey: UserDefaultsKeys.userBehaviorData),
              let behaviors = try? JSONDecoder().decode([UserBehavior].self, from: data) else {
            return []
        }
        return behaviors
    }
    
    private func saveBehaviorData(_ behaviors: [UserBehavior]) {
        if let data = try? JSONEncoder().encode(behaviors) {
            userDefaults.set(data, forKey: UserDefaultsKeys.userBehaviorData)
        }
    }
}

// MARK: - Supporting Types

/// Homepage display modes
enum HomepageMode: String, CaseIterable {
    case lastViewed = "lastViewed"
    case masterBranch = "masterBranch"
    case mostActiveBranch = "mostActiveBranch"
    case intelligent = "intelligent"
    
    var displayName: String {
        switch self {
        case .lastViewed:
            return "上次查看页面"
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

/// User behavior tracking for learning
struct UserBehavior: Codable {
    let id: UUID
    let type: BehaviorType
    let timestamp: Date
    let branchId: UUID?
    let duration: TimeInterval? // How long user spent on this action
    
    init(type: BehaviorType, branchId: UUID? = nil, duration: TimeInterval? = nil) {
        self.id = UUID()
        self.type = type
        self.timestamp = Date()
        self.branchId = branchId
        self.duration = duration
    }
}

/// Types of user behaviors to track
enum BehaviorType: String, Codable {
    case branchView = "branchView"
    case branchSwitch = "branchSwitch"
    case commitCreated = "commitCreated"
    case branchCompleted = "branchCompleted"
    case branchCreated = "branchCreated"
    case appLaunched = "appLaunched"
}

/// Branch activity score for ranking
struct BranchActivityScore {
    let branch: Branch
    let score: Double
}