import Foundation

/// Cache service for statistics data
@MainActor
class StatisticsCache: ObservableObject {
    // MARK: - Cache Storage
    private var cache: [String: CacheEntry] = [:]
    private let cacheExpirationInterval: TimeInterval = 300 // 5 minutes
    
    // MARK: - Cache Entry
    private struct CacheEntry {
        let data: Any
        let timestamp: Date
        let expirationInterval: TimeInterval
        
        var isExpired: Bool {
            Date().timeIntervalSince(timestamp) > expirationInterval
        }
    }
    
    // MARK: - Generic Cache Methods
    
    /// Store data in cache with key
    /// - Parameters:
    ///   - data: Data to cache
    ///   - key: Cache key
    ///   - expirationInterval: Custom expiration interval (optional)
    func store<T>(_ data: T, forKey key: String, expirationInterval: TimeInterval? = nil) {
        let expiration = expirationInterval ?? cacheExpirationInterval
        let entry = CacheEntry(
            data: data,
            timestamp: Date(),
            expirationInterval: expiration
        )
        cache[key] = entry
    }
    
    /// Retrieve data from cache
    /// - Parameter key: Cache key
    /// - Returns: Cached data if valid, nil otherwise
    func retrieve<T>(_ type: T.Type, forKey key: String) -> T? {
        guard let entry = cache[key], !entry.isExpired else {
            // Remove expired entry
            cache.removeValue(forKey: key)
            return nil
        }
        
        return entry.data as? T
    }
    
    /// Check if cache contains valid data for key
    /// - Parameter key: Cache key
    /// - Returns: True if valid data exists
    func contains(key: String) -> Bool {
        guard let entry = cache[key] else { return false }
        
        if entry.isExpired {
            cache.removeValue(forKey: key)
            return false
        }
        
        return true
    }
    
    /// Remove data from cache
    /// - Parameter key: Cache key
    func remove(key: String) {
        cache.removeValue(forKey: key)
    }
    
    /// Clear all cached data
    func clearAll() {
        cache.removeAll()
    }
    
    /// Clear expired entries
    func clearExpired() {
        let expiredKeys = cache.compactMap { key, entry in
            entry.isExpired ? key : nil
        }
        
        for key in expiredKeys {
            cache.removeValue(forKey: key)
        }
    }
    
    // MARK: - Statistics-Specific Cache Keys
    
    enum CacheKey {
        static let userStatistics = "user_statistics"
        static let branchStatistics = "branch_statistics"
        static let commitStatistics = "commit_statistics"
        static let goalCompletionStatistics = "goal_completion_statistics"
        static let activityStatistics = "activity_statistics"
        static let streakStatistics = "streak_statistics"
        
        // Branch-specific statistics
        static func branchStatistics(branchId: UUID) -> String {
            return "branch_statistics_\(branchId.uuidString)"
        }
        
        // Time-based statistics
        static func dailyStatistics(date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return "daily_statistics_\(formatter.string(from: date))"
        }
        
        static func weeklyStatistics(weekStart: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return "weekly_statistics_\(formatter.string(from: weekStart))"
        }
        
        static func monthlyStatistics(month: Int, year: Int) -> String {
            return "monthly_statistics_\(year)_\(month)"
        }
    }
    
    // MARK: - Statistics-Specific Methods
    
    /// Store user statistics
    func storeUserStatistics(_ statistics: UserStatistics) {
        store(statistics, forKey: CacheKey.userStatistics)
    }
    
    /// Retrieve user statistics
    func retrieveUserStatistics() -> UserStatistics? {
        return retrieve(UserStatistics.self, forKey: CacheKey.userStatistics)
    }
    
    /// Store branch-specific statistics
    func storeBranchStatistics(_ statistics: BranchStatistics, forBranch branchId: UUID) {
        store(statistics, forKey: CacheKey.branchStatistics(branchId: branchId))
    }
    
    /// Retrieve branch-specific statistics
    func retrieveBranchStatistics(forBranch branchId: UUID) -> BranchStatistics? {
        return retrieve(BranchStatistics.self, forKey: CacheKey.branchStatistics(branchId: branchId))
    }
    
    /// Store daily statistics
    func storeDailyStatistics(_ statistics: DailyStatistics, for date: Date) {
        store(statistics, forKey: CacheKey.dailyStatistics(date: date), expirationInterval: 86400) // 24 hours
    }
    
    /// Retrieve daily statistics
    func retrieveDailyStatistics(for date: Date) -> DailyStatistics? {
        return retrieve(DailyStatistics.self, forKey: CacheKey.dailyStatistics(date: date))
    }
    
    // MARK: - Cache Management
    
    /// Get cache size (number of entries)
    var cacheSize: Int {
        return cache.count
    }
    
    /// Get cache memory usage estimate (in bytes)
    var estimatedMemoryUsage: Int {
        // This is a rough estimate
        return cache.count * 1024 // Assume 1KB per entry on average
    }
    
    /// Perform cache maintenance (remove expired entries)
    func performMaintenance() {
        clearExpired()
    }
}

// MARK: - Daily Statistics Structure

/// Daily statistics data structure
struct DailyStatistics {
    let date: Date
    let commitsCount: Int
    let branchesCreated: Int
    let tasksCompleted: Int
    let timeSpent: TimeInterval
    let mostActiveHour: Int
    let commitTypes: [CommitType: Int]
    
    var hasActivity: Bool {
        commitsCount > 0 || branchesCreated > 0 || tasksCompleted > 0
    }
    
    var activityScore: Double {
        let commitScore = Double(commitsCount) * 1.0
        let branchScore = Double(branchesCreated) * 5.0
        let taskScore = Double(tasksCompleted) * 2.0
        
        return commitScore + branchScore + taskScore
    }
}