import SwiftUI
import SwiftData

// 高级提交搜索界面
struct AdvancedCommitSearchView: View {
    @StateObject private var filter: AdvancedCommitFilter
    @State private var showingFilterSheet = false
    @State private var showingSavedFilters = false
    @State private var searchText = ""
    @State private var selectedDateRange: DateRange = .thisMonth
    @State private var customStartDate = Date()
    @State private var customEndDate = Date()
    @State private var selectedTypes: Set<CommitType> = []
    @State private var selectedCategories: Set<CommitCategory> = []
    @State private var sortOption: SortOption = .dateNewest
    @State private var searchOptions = SearchOptions()
    
    @Environment(\.dismiss) private var dismiss
    
    let modelContext: ModelContext
    let onCommitSelected: ((Commit) -> Void)?
    
    init(modelContext: ModelContext, onCommitSelected: ((Commit) -> Void)? = nil) {
        self.modelContext = modelContext
        self.onCommitSelected = onCommitSelected
        self._filter = StateObject(wrappedValue: AdvancedCommitFilter(modelContext: modelContext))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 搜索栏
                searchBar
                
                // 快速筛选器
                quickFilters
                
                Divider()
                
                // 搜索结果
                searchResults
            }
            .navigationTitle("高级搜索")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("高级筛选") {
                            showingFilterSheet = true
                        }
                        
                        Button("保存的筛选器") {
                            showingSavedFilters = true
                        }
                        
                        Divider()
                        
                        Button("清除筛选") {
                            clearAllFilters()
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $showingFilterSheet) {
                AdvancedFilterSheet(
                    filter: $filter.currentFilter,
                    onApply: { newFilter in
                        Task {
                            await filter.applyFilter(newFilter)
                        }
                    }
                )
            }
            .sheet(isPresented: $showingSavedFilters) {
                SavedFiltersView(filter: filter)
            }
        }
        .onAppear {
            // 应用默认筛选器
            Task {
                await filter.quickFilterByDateRange(.thisMonth)
            }
        }
    }
    
    private var searchBar: some View {
        VStack(spacing: 12) {
            // 主搜索框
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("搜索提交内容...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onSubmit {
                        performSearch()
                    }
                
                if !searchText.isEmpty {
                    Button("清除") {
                        searchText = ""
                        filter.clearFilter()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            // 搜索建议
            if !searchText.isEmpty {
                searchSuggestions
            }
        }
        .padding()
    }
    
    private var searchSuggestions: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(filter.getSearchSuggestions(for: searchText), id: \.self) { suggestion in
                    Button(suggestion) {
                        searchText = suggestion
                        performSearch()
                    }
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var quickFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // 日期范围筛选
                Menu {
                    ForEach(DateRange.allCases, id: \.self) { range in
                        Button(range.displayName) {
                            selectedDateRange = range
                            Task {
                                await filter.quickFilterByDateRange(range)
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                        Text(selectedDateRange.displayName)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                
                // 类型筛选
                ForEach([CommitType.taskComplete, .learning, .reflection, .milestone], id: \.self) { type in
                    Button(action: {
                        Task {
                            await filter.quickFilterByType(type)
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text(type.emoji)
                            Text(type.displayName)
                        }
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(filter.currentFilter.types.contains(type) ? type.color.opacity(0.2) : Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // 分类筛选
                ForEach([CommitCategory.achievement, .learning, .personal], id: \.self) { category in
                    Button(action: {
                        Task {
                            await filter.quickFilterByCategory(category)
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text(category.emoji)
                            Text(category.displayName)
                        }
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(filter.currentFilter.categories.contains(category) ? category.color.opacity(0.2) : Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    private var searchResults: some View {
        Group {
            if filter.isFiltering {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    
                    Text("搜索中...")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filter.searchResults.isEmpty {
                emptyResultsView
            } else {
                resultsList
            }
        }
    }
    
    private var emptyResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("未找到匹配的提交")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("尝试调整搜索条件或筛选器")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("清除所有筛选") {
                clearAllFilters()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var resultsList: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 结果统计
            HStack {
                Text("找到 \(filter.searchResults.count) 个结果")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // 排序选择
                Menu {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Button(option.displayName) {
                            sortOption = option
                            applySorting()
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("排序")
                        Image(systemName: "arrow.up.arrow.down")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            Divider()
            
            // 结果列表
            List {
                ForEach(filter.searchResults, id: \.id) { commit in
                    SearchResultRow(commit: commit, searchText: searchText) {
                        onCommitSelected?(commit)
                        dismiss()
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
            }
            .listStyle(PlainListStyle())
        }
    }
    
    private func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        Task {
            await filter.searchCommits(searchText, options: searchOptions)
        }
    }
    
    private func clearAllFilters() {
        searchText = ""
        selectedDateRange = .thisMonth
        selectedTypes.removeAll()
        selectedCategories.removeAll()
        filter.clearFilter()
    }
    
    private func applySorting() {
        var currentFilter = filter.currentFilter
        currentFilter.sortOption = sortOption
        
        Task {
            await filter.applyFilter(currentFilter)
        }
    }
}

// 搜索结果行
struct SearchResultRow: View {
    let commit: Commit
    let searchText: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // 提交信息
                HStack(alignment: .top, spacing: 12) {
                    // 类型图标
                    ZStack {
                        Circle()
                            .fill(commit.type.color.opacity(0.2))
                            .frame(width: 32, height: 32)
                        
                        Text(commit.type.emoji)
                            .font(.body)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        // 高亮搜索文本
                        HighlightedText(
                            text: commit.message,
                            highlight: searchText,
                            font: .body,
                            highlightColor: .yellow
                        )
                        
                        HStack {
                            Text(commit.type.displayName)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(commit.type.color.opacity(0.1))
                                .foregroundColor(commit.type.color)
                                .cornerRadius(4)
                            
                            Text(commit.timestamp.formatted(.relative(presentation: .named)))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                    }
                    
                    Spacer()
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// 高亮文本组件
struct HighlightedText: View {
    let text: String
    let highlight: String
    let font: Font
    let highlightColor: Color
    
    var body: some View {
        if highlight.isEmpty {
            Text(text)
                .font(font)
        } else {
            let parts = text.components(separatedBy: highlight)
            
            if parts.count > 1 {
                HStack(spacing: 0) {
                    ForEach(0..<parts.count, id: \.self) { index in
                        Group {
                            Text(parts[index])
                                .font(font)
                            
                            if index < parts.count - 1 {
                                Text(highlight)
                                    .font(font)
                                    .background(highlightColor.opacity(0.3))
                                    .cornerRadius(2)
                            }
                        }
                    }
                }
            } else {
                Text(text)
                    .font(font)
            }
        }
    }
}

#Preview {
    AdvancedCommitSearchView(
        modelContext: ModelContext(try! ModelContainer(for: Commit.self))
    )
}