import Foundation
import SwiftData

// 高级提交筛选器
@MainActor
class AdvancedCommitFilter: ObservableObject {
    // MARK: - Published Properties
    @Published var isFiltering = false
    @Published var searchResults: [Commit] = []
    @Published var currentFilter: CommitFilter = CommitFilter()
    @Published var searchHistory: [String] = []
    @Published var savedFilters: [SavedFilter] = []
    
    // MARK: - Private Properties
    private let modelContext: ModelContext
    private let commitIndex: CommitSearchIndex
    
    // MARK: - Initialization
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.commitIndex = CommitSearchIndex(modelContext: modelContext)
        loadSearchHistory()
        loadSavedFilters()
    }
    
    // MARK: - Filtering Methods
    
    /// Apply advanced filter to commits
    func applyFilter(_ filter: CommitFilter) async {
        isFiltering = true
        currentFilter = filter
        
        defer { isFiltering = false }
        
        do {
            let descriptor = buildFetchDescriptor(from: filter)
            let allCommits = try modelContext.fetch(descriptor)
            
            // Apply additional filtering that can't be done in SwiftData query
            var filteredCommits = allCommits
            
            // Text search
            if !filter.searchText.isEmpty {
                filteredCommits = await performTextSearch(
                    commits: filteredCommits,
                    searchText: filter.searchText,
                    searchOptions: filter.searchOptions
                )
            }
            
            // Custom filters
            if let customFilter = filter.customFilter {
                filteredCommits = filteredCommits.filter(customFilter)
            }
            
            // Sort results
            filteredCommits = sortCommits(filteredCommits, by: filter.sortOption)
            
            // Apply limit
            if filter.limit > 0 {
                filteredCommits = Array(filteredCommits.prefix(filter.limit))
            }
            
            searchResults = filteredCommits
            
            // Update search history
            if !filter.searchText.isEmpty {
                addToSearchHistory(filter.searchText)
            }
            
        } catch {
            print("Filter error: \(error)")
            searchResults = []
        }
    }
    
    /// Quick filter by type
    func quickFilterByType(_ type: CommitType) async {
        var filter = CommitFilter()
        filter.types = [type]
        await applyFilter(filter)
    }
    
    /// Quick filter by category
    func quickFilterByCategory(_ category: CommitCategory) async {
        var filter = CommitFilter()
        filter.categories = [category]
        await applyFilter(filter)
    }
    
    /// Quick filter by date range
    func quickFilterByDateRange(_ range: DateRange) async {
        var filter = CommitFilter()
        let (startDate, endDate) = range.dateRange
        filter.startDate = startDate
        filter.endDate = endDate
        await applyFilter(filter)
    }
    
    /// Search commits with text
    func searchCommits(_ searchText: String, options: SearchOptions = SearchOptions()) async {
        var filter = CommitFilter()
        filter.searchText = searchText
        filter.searchOptions = options
        await applyFilter(filter)
    }
    
    /// Clear current filter
    func clearFilter() {
        currentFilter = CommitFilter()
        searchResults = []
    }
    
    // MARK: - Saved Filters
    
    /// Save current filter
    func saveCurrentFilter(name: String) {
        let savedFilter = SavedFilter(
            id: UUID(),
            name: name,
            filter: currentFilter,
            createdAt: Date()
        )
        
        savedFilters.append(savedFilter)
        saveSavedFilters()
    }
    
    /// Load saved filter
    func loadSavedFilter(_ savedFilter: SavedFilter) async {
        await applyFilter(savedFilter.filter)
    }
    
    /// Delete saved filter
    func deleteSavedFilter(_ savedFilter: SavedFilter) {
        savedFilters.removeAll { $0.id == savedFilter.id }
        saveSavedFilters()
    }
    
    // MARK: - Search History
    
    /// Get search suggestions based on history
    func getSearchSuggestions(for text: String) -> [String] {
        if text.isEmpty {
            return Array(searchHistory.prefix(5))
        }
        
        return searchHistory.filter { $0.localizedCaseInsensitiveContains(text) }
    }
    
    /// Clear search history
    func clearSearchHistory() {
        searchHistory.removeAll()
        saveSearchHistory()
    }
    
    // MARK: - Advanced Search
    
    /// Perform semantic search using AI
    func performSemanticSearch(_ query: String) async -> [Commit] {
        // This would integrate with an AI service for semantic search
        // For now, we'll use enhanced text search
        return await performTextSearch(
            commits: try! modelContext.fetch(FetchDescriptor<Commit>()),
            searchText: query,
            searchOptions: SearchOptions(
                searchInMessage: true,
                searchInType: true,
                fuzzySearch: true,
                semanticSearch: true
            )
        )
    }
    
    /// Get related commits based on similarity
    func getRelatedCommits(to commit: Commit, limit: Int = 10) async -> [Commit] {
        let allCommits = try! modelContext.fetch(FetchDescriptor<Commit>())
        
        // Calculate similarity based on type, content, and timing
        let scoredCommits = allCommits.compactMap { otherCommit -> (Commit, Double)? in
            guard otherCommit.id != commit.id else { return nil }
            
            let score = calculateSimilarityScore(commit, otherCommit)
            return score > 0.3 ? (otherCommit, score) : nil
        }
        
        return scoredCommits
            .sorted { $0.1 > $1.1 }
            .prefix(limit)
            .map { $0.0 }
    }
    
    // MARK: - Private Methods
    
    private func buildFetchDescriptor(from filter: CommitFilter) -> FetchDescriptor<Commit> {
        var predicate: Predicate<Commit>?
        var predicates: [Predicate<Commit>] = []
        
        // Branch filter
        if let branchId = filter.branchId {
            predicates.append(#Predicate { $0.branchId == branchId })
        }
        
        // Type filter
        if !filter.types.isEmpty {
            predicates.append(#Predicate { commit in
                filter.types.contains(commit.type)
            })
        }
        
        // Category filter
        if !filter.categories.isEmpty {
            predicates.append(#Predicate { commit in
                filter.categories.contains(commit.type.category)
            })
        }
        
        // Date range filter
        if let startDate = filter.startDate {
            predicates.append(#Predicate { $0.timestamp >= startDate })
        }
        
        if let endDate = filter.endDate {
            predicates.append(#Predicate { $0.timestamp <= endDate })
        }
        
        // Combine predicates
        if !predicates.isEmpty {
            predicate = predicates.reduce(predicates[0]) { result, next in
                #Predicate<Commit> { commit in
                    result.evaluate(commit) && next.evaluate(commit)
                }
            }
        }
        
        var descriptor = FetchDescriptor<Commit>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        return descriptor
    }
    
    private func performTextSearch(
        commits: [Commit],
        searchText: String,
        searchOptions: SearchOptions
    ) async -> [Commit] {
        let searchTerms = searchText.lowercased().components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        return commits.filter { commit in
            var matches = false
            
            // Search in message
            if searchOptions.searchInMessage {
                let message = commit.message.lowercased()
                if searchOptions.fuzzySearch {
                    matches = matches || searchTerms.allSatisfy { term in
                        message.contains(term) || levenshteinDistance(message, term) <= 2
                    }
                } else {
                    matches = matches || searchTerms.allSatisfy { message.contains($0) }
                }
            }
            
            // Search in type
            if searchOptions.searchInType {
                let typeName = commit.type.displayName.lowercased()
                matches = matches || searchTerms.allSatisfy { typeName.contains($0) }
            }
            
            return matches
        }
    }
    
    private func sortCommits(_ commits: [Commit], by sortOption: SortOption) -> [Commit] {
        switch sortOption {
        case .dateNewest:
            return commits.sorted { $0.timestamp > $1.timestamp }
        case .dateOldest:
            return commits.sorted { $0.timestamp < $1.timestamp }
        case .typeAlphabetical:
            return commits.sorted { $0.type.displayName < $1.type.displayName }
        case .relevance:
            // For relevance, we'd need to implement a scoring system
            return commits
        }
    }
    
    private func calculateSimilarityScore(_ commit1: Commit, _ commit2: Commit) -> Double {
        var score = 0.0
        
        // Type similarity
        if commit1.type == commit2.type {
            score += 0.4
        } else if commit1.type.category == commit2.type.category {
            score += 0.2
        }
        
        // Content similarity (simple word overlap)
        let words1 = Set(commit1.message.lowercased().components(separatedBy: .whitespacesAndNewlines))
        let words2 = Set(commit2.message.lowercased().components(separatedBy: .whitespacesAndNewlines))
        let commonWords = words1.intersection(words2)
        let totalWords = words1.union(words2)
        
        if !totalWords.isEmpty {
            score += 0.3 * (Double(commonWords.count) / Double(totalWords.count))
        }
        
        // Time proximity (commits close in time are more similar)
        let timeDifference = abs(commit1.timestamp.timeIntervalSince(commit2.timestamp))
        let daysDifference = timeDifference / (24 * 60 * 60)
        
        if daysDifference < 7 {
            score += 0.3 * (1.0 - daysDifference / 7.0)
        }
        
        return score
    }
    
    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let a = Array(s1)
        let b = Array(s2)
        
        var matrix = Array(repeating: Array(repeating: 0, count: b.count + 1), count: a.count + 1)
        
        for i in 0...a.count {
            matrix[i][0] = i
        }
        
        for j in 0...b.count {
            matrix[0][j] = j
        }
        
        for i in 1...a.count {
            for j in 1...b.count {
                if a[i-1] == b[j-1] {
                    matrix[i][j] = matrix[i-1][j-1]
                } else {
                    matrix[i][j] = min(
                        matrix[i-1][j] + 1,
                        matrix[i][j-1] + 1,
                        matrix[i-1][j-1] + 1
                    )
                }
            }
        }
        
        return matrix[a.count][b.count]
    }
    
    private func addToSearchHistory(_ searchText: String) {
        let trimmedText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        // Remove if already exists
        searchHistory.removeAll { $0 == trimmedText }
        
        // Add to beginning
        searchHistory.insert(trimmedText, at: 0)
        
        // Keep only last 20 searches
        if searchHistory.count > 20 {
            searchHistory = Array(searchHistory.prefix(20))
        }
        
        saveSearchHistory()
    }
    
    private func loadSearchHistory() {
        if let data = UserDefaults.standard.data(forKey: "commitSearchHistory"),
           let history = try? JSONDecoder().decode([String].self, from: data) {
            searchHistory = history
        }
    }
    
    private func saveSearchHistory() {
        if let data = try? JSONEncoder().encode(searchHistory) {
            UserDefaults.standard.set(data, forKey: "commitSearchHistory")
        }
    }
    
    private func loadSavedFilters() {
        if let data = UserDefaults.standard.data(forKey: "savedCommitFilters"),
           let filters = try? JSONDecoder().decode([SavedFilter].self, from: data) {
            savedFilters = filters
        }
    }
    
    private func saveSavedFilters() {
        if let data = try? JSONEncoder().encode(savedFilters) {
            UserDefaults.standard.set(data, forKey: "savedCommitFilters")
        }
    }
}

// MARK: - Supporting Types

/// Commit filter configuration
struct CommitFilter: Codable {
    var branchId: UUID?
    var types: [CommitType] = []
    var categories: [CommitCategory] = []
    var startDate: Date?
    var endDate: Date?
    var searchText: String = ""
    var searchOptions: SearchOptions = SearchOptions()
    var sortOption: SortOption = .dateNewest
    var limit: Int = 0 // 0 means no limit
    var customFilter: ((Commit) -> Bool)?
    
    // Custom filter is not codable, so we exclude it
    enum CodingKeys: String, CodingKey {
        case branchId, types, categories, startDate, endDate
        case searchText, searchOptions, sortOption, limit
    }
}

/// Search options
struct SearchOptions: Codable {
    var searchInMessage: Bool = true
    var searchInType: Bool = true
    var fuzzySearch: Bool = false
    var semanticSearch: Bool = false
    var caseSensitive: Bool = false
}

/// Sort options
enum SortOption: String, CaseIterable, Codable {
    case dateNewest = "date_newest"
    case dateOldest = "date_oldest"
    case typeAlphabetical = "type_alphabetical"
    case relevance = "relevance"
    
    var displayName: String {
        switch self {
        case .dateNewest: return "最新优先"
        case .dateOldest: return "最旧优先"
        case .typeAlphabetical: return "类型排序"
        case .relevance: return "相关性"
        }
    }
}

/// Saved filter
struct SavedFilter: Codable, Identifiable {
    let id: UUID
    var name: String
    let filter: CommitFilter
    let createdAt: Date
}

/// Date range presets
enum DateRange: CaseIterable {
    case today, yesterday, thisWeek, lastWeek, thisMonth, lastMonth, thisYear, custom
    
    var displayName: String {
        switch self {
        case .today: return "今天"
        case .yesterday: return "昨天"
        case .thisWeek: return "本周"
        case .lastWeek: return "上周"
        case .thisMonth: return "本月"
        case .lastMonth: return "上月"
        case .thisYear: return "今年"
        case .custom: return "自定义"
        }
    }
    
    var dateRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .today:
            let startOfDay = calendar.startOfDay(for: now)
            return (startOfDay, now)
        case .yesterday:
            let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
            let startOfYesterday = calendar.startOfDay(for: yesterday)
            let endOfYesterday = calendar.date(byAdding: .day, value: 1, to: startOfYesterday)!
            return (startOfYesterday, endOfYesterday)
        case .thisWeek:
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            return (startOfWeek, now)
        case .lastWeek:
            let lastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: now)!
            let startOfLastWeek = calendar.dateInterval(of: .weekOfYear, for: lastWeek)?.start ?? lastWeek
            let endOfLastWeek = calendar.date(byAdding: .day, value: 7, to: startOfLastWeek)!
            return (startOfLastWeek, endOfLastWeek)
        case .thisMonth:
            let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
            return (startOfMonth, now)
        case .lastMonth:
            let lastMonth = calendar.date(byAdding: .month, value: -1, to: now)!
            let startOfLastMonth = calendar.dateInterval(of: .month, for: lastMonth)?.start ?? lastMonth
            let endOfLastMonth = calendar.date(byAdding: .month, value: 1, to: startOfLastMonth)!
            return (startOfLastMonth, endOfLastMonth)
        case .thisYear:
            let startOfYear = calendar.dateInterval(of: .year, for: now)?.start ?? now
            return (startOfYear, now)
        case .custom:
            return (now, now) // Will be overridden by user selection
        }
    }
}