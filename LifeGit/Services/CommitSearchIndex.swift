import Foundation
import SwiftData

// 提交搜索索引和缓存机制
@MainActor
class CommitSearchIndex: ObservableObject {
    // MARK: - Properties
    private let modelContext: ModelContext
    private var searchIndex: [String: Set<UUID>] = [:]
    private var commitCache: [UUID: Commit] = [:]
    private var lastIndexUpdate: Date = Date.distantPast
    private let indexUpdateInterval: TimeInterval = 300 // 5 minutes
    
    // MARK: - Initialization
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        Task {
            await buildSearchIndex()
        }
    }
    
    // MARK: - Public Methods
    
    /// Search commits using the index
    func searchCommits(query: String, limit: Int = 50) async -> [Commit] {
        await updateIndexIfNeeded()
        
        let searchTerms = query.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        guard !searchTerms.isEmpty else { return [] }
        
        // Find commits that match all search terms
        var matchingCommitIds: Set<UUID> = []
        
        for (index, term) in searchTerms.enumerated() {
            let termMatches = findMatchingCommitIds(for: term)
            
            if index == 0 {
                matchingCommitIds = termMatches
            } else {
                matchingCommitIds = matchingCommitIds.intersection(termMatches)
            }
            
            // Early exit if no matches
            if matchingCommitIds.isEmpty {
                break
            }
        }
        
        // Convert IDs to commits and sort by relevance
        let commits = matchingCommitIds.compactMap { commitCache[$0] }
        let scoredCommits = commits.map { commit in
            (commit, calculateRelevanceScore(commit: commit, query: query))
        }
        
        return scoredCommits
            .sorted { $0.1 > $1.1 }
            .prefix(limit)
            .map { $0.0 }
    }
    
    /// Get search suggestions
    func getSearchSuggestions(for query: String, limit: Int = 10) -> [String] {
        let lowercaseQuery = query.lowercased()
        
        // Get suggestions from indexed terms
        let suggestions = searchIndex.keys
            .filter { $0.hasPrefix(lowercaseQuery) }
            .sorted()
            .prefix(limit)
        
        return Array(suggestions)
    }
    
    /// Force rebuild the search index
    func rebuildIndex() async {
        await buildSearchIndex()
    }
    
    /// Add commit to index
    func addCommitToIndex(_ commit: Commit) {
        commitCache[commit.id] = commit
        indexCommit(commit)
        lastIndexUpdate = Date()
    }
    
    /// Remove commit from index
    func removeCommitFromIndex(_ commitId: UUID) {
        if let commit = commitCache[commitId] {
            removeCommitFromSearchIndex(commit)
            commitCache.removeValue(forKey: commitId)
        }
        lastIndexUpdate = Date()
    }
    
    /// Update commit in index
    func updateCommitInIndex(_ commit: Commit) {
        if let oldCommit = commitCache[commit.id] {
            removeCommitFromSearchIndex(oldCommit)
        }
        
        commitCache[commit.id] = commit
        indexCommit(commit)
        lastIndexUpdate = Date()
    }
    
    // MARK: - Private Methods
    
    private func updateIndexIfNeeded() async {
        let timeSinceLastUpdate = Date().timeIntervalSince(lastIndexUpdate)
        
        if timeSinceLastUpdate > indexUpdateInterval {
            await buildSearchIndex()
        }
    }
    
    private func buildSearchIndex() async {
        do {
            let descriptor = FetchDescriptor<Commit>(
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            let commits = try modelContext.fetch(descriptor)
            
            // Clear existing index
            searchIndex.removeAll()
            commitCache.removeAll()
            
            // Build new index
            for commit in commits {
                commitCache[commit.id] = commit
                indexCommit(commit)
            }
            
            lastIndexUpdate = Date()
            
        } catch {
            print("Failed to build search index: \(error)")
        }
    }
    
    private func indexCommit(_ commit: Commit) {
        // Index commit message
        let messageTerms = extractSearchTerms(from: commit.message)
        for term in messageTerms {
            addToIndex(term: term, commitId: commit.id)
        }
        
        // Index commit type
        let typeTerms = extractSearchTerms(from: commit.type.displayName)
        for term in typeTerms {
            addToIndex(term: term, commitId: commit.id)
        }
        
        // Index commit category
        let categoryTerms = extractSearchTerms(from: commit.type.category.displayName)
        for term in categoryTerms {
            addToIndex(term: term, commitId: commit.id)
        }
        
        // Index date components
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "zh_CN")
        
        // Year
        dateFormatter.dateFormat = "yyyy"
        addToIndex(term: dateFormatter.string(from: commit.timestamp), commitId: commit.id)
        
        // Month
        dateFormatter.dateFormat = "MM"
        addToIndex(term: dateFormatter.string(from: commit.timestamp), commitId: commit.id)
        
        // Month name
        dateFormatter.dateFormat = "MMMM"
        addToIndex(term: dateFormatter.string(from: commit.timestamp), commitId: commit.id)
        
        // Weekday
        dateFormatter.dateFormat = "EEEE"
        addToIndex(term: dateFormatter.string(from: commit.timestamp), commitId: commit.id)
    }
    
    private func removeCommitFromSearchIndex(_ commit: Commit) {
        // Remove from all index entries
        for (term, commitIds) in searchIndex {
            var updatedIds = commitIds
            updatedIds.remove(commit.id)
            
            if updatedIds.isEmpty {
                searchIndex.removeValue(forKey: term)
            } else {
                searchIndex[term] = updatedIds
            }
        }
    }
    
    private func addToIndex(term: String, commitId: UUID) {
        let lowercaseTerm = term.lowercased()
        
        if searchIndex[lowercaseTerm] == nil {
            searchIndex[lowercaseTerm] = Set<UUID>()
        }
        
        searchIndex[lowercaseTerm]?.insert(commitId)
        
        // Also add prefixes for better search suggestions
        for i in 1..<lowercaseTerm.count {
            let prefix = String(lowercaseTerm.prefix(i))
            if searchIndex[prefix] == nil {
                searchIndex[prefix] = Set<UUID>()
            }
            searchIndex[prefix]?.insert(commitId)
        }
    }
    
    private func extractSearchTerms(from text: String) -> [String] {
        let cleanText = text.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .joined(separator: " ")
        
        // Split by various separators
        let separators = CharacterSet.whitespacesAndNewlines
            .union(.punctuationCharacters)
            .union(.symbols)
        
        let terms = cleanText.components(separatedBy: separators)
            .filter { !$0.isEmpty && $0.count > 1 }
        
        return terms
    }
    
    private func findMatchingCommitIds(for term: String) -> Set<UUID> {
        let lowercaseTerm = term.lowercased()
        
        // Exact match
        if let exactMatch = searchIndex[lowercaseTerm] {
            return exactMatch
        }
        
        // Prefix match
        var matches: Set<UUID> = []
        for (indexTerm, commitIds) in searchIndex {
            if indexTerm.hasPrefix(lowercaseTerm) {
                matches = matches.union(commitIds)
            }
        }
        
        // Fuzzy match (if no exact or prefix matches)
        if matches.isEmpty {
            for (indexTerm, commitIds) in searchIndex {
                if levenshteinDistance(indexTerm, lowercaseTerm) <= 2 {
                    matches = matches.union(commitIds)
                }
            }
        }
        
        return matches
    }
    
    private func calculateRelevanceScore(commit: Commit, query: String) -> Double {
        let queryTerms = query.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        var score = 0.0
        let message = commit.message.lowercased()
        let typeName = commit.type.displayName.lowercased()
        
        for term in queryTerms {
            // Exact match in message (highest score)
            if message.contains(term) {
                score += 10.0
                
                // Bonus for match at beginning
                if message.hasPrefix(term) {
                    score += 5.0
                }
            }
            
            // Match in type name
            if typeName.contains(term) {
                score += 5.0
            }
            
            // Fuzzy match
            let messageWords = message.components(separatedBy: .whitespacesAndNewlines)
            for word in messageWords {
                if levenshteinDistance(word, term) <= 1 {
                    score += 2.0
                }
            }
        }
        
        // Recency bonus (more recent commits get higher scores)
        let daysSinceCommit = Date().timeIntervalSince(commit.timestamp) / (24 * 60 * 60)
        let recencyBonus = max(0, 10.0 - daysSinceCommit * 0.1)
        score += recencyBonus
        
        return score
    }
    
    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let a = Array(s1)
        let b = Array(s2)
        
        guard a.count > 0 && b.count > 0 else {
            return max(a.count, b.count)
        }
        
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
}

// MARK: - Search Statistics

extension CommitSearchIndex {
    /// Get search index statistics
    func getIndexStatistics() -> SearchIndexStatistics {
        return SearchIndexStatistics(
            totalCommits: commitCache.count,
            totalTerms: searchIndex.count,
            lastUpdated: lastIndexUpdate,
            indexSize: calculateIndexSize()
        )
    }
    
    private func calculateIndexSize() -> Int {
        var size = 0
        for (term, commitIds) in searchIndex {
            size += term.count + commitIds.count * 16 // UUID is 16 bytes
        }
        return size
    }
}

struct SearchIndexStatistics {
    let totalCommits: Int
    let totalTerms: Int
    let lastUpdated: Date
    let indexSize: Int // in bytes
    
    var indexSizeFormatted: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(indexSize))
    }
}