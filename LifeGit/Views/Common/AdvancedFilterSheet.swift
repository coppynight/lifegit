import SwiftUI

// 高级筛选器配置界面
struct AdvancedFilterSheet: View {
    @Binding var filter: CommitFilter
    let onApply: (CommitFilter) -> Void
    
    @State private var localFilter: CommitFilter
    @State private var showingDatePicker = false
    @State private var showingCustomDateRange = false
    @State private var filterName = ""
    @State private var showingSaveDialog = false
    
    @Environment(\.dismiss) private var dismiss
    
    init(filter: Binding<CommitFilter>, onApply: @escaping (CommitFilter) -> Void) {
        self._filter = filter
        self.onApply = onApply
        self._localFilter = State(initialValue: filter.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // 文本搜索
                textSearchSection
                
                // 类型筛选
                typeFilterSection
                
                // 分类筛选
                categoryFilterSection
                
                // 日期范围
                dateRangeSection
                
                // 搜索选项
                searchOptionsSection
                
                // 排序和限制
                sortingSection
            }
            .navigationTitle("高级筛选")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("应用筛选") {
                            applyFilter()
                        }
                        
                        Button("保存筛选器") {
                            showingSaveDialog = true
                        }
                        
                        Divider()
                        
                        Button("重置") {
                            resetFilter()
                        }
                    } label: {
                        Text("完成")
                            .fontWeight(.semibold)
                    }
                }
            }
            .alert("保存筛选器", isPresented: $showingSaveDialog) {
                TextField("筛选器名称", text: $filterName)
                
                Button("保存") {
                    saveFilter()
                }
                
                Button("取消", role: .cancel) { }
            } message: {
                Text("为这个筛选器起个名字")
            }
        }
    }
    
    private var textSearchSection: some View {
        Section {
            TextField("搜索文本", text: $localFilter.searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        } header: {
            Text("文本搜索")
        } footer: {
            Text("在提交消息和类型中搜索指定文本")
        }
    }
    
    private var typeFilterSection: some View {
        Section {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(CommitType.allCases, id: \.self) { type in
                    TypeFilterChip(
                        type: type,
                        isSelected: localFilter.types.contains(type)
                    ) {
                        toggleTypeSelection(type)
                    }
                }
            }
        } header: {
            HStack {
                Text("提交类型")
                
                Spacer()
                
                Button(localFilter.types.isEmpty ? "全选" : "清除") {
                    if localFilter.types.isEmpty {
                        localFilter.types = Array(CommitType.allCases)
                    } else {
                        localFilter.types.removeAll()
                    }
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
    }
    
    private var categoryFilterSection: some View {
        Section {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(CommitCategory.allCases, id: \.self) { category in
                    CategoryFilterChip(
                        category: category,
                        isSelected: localFilter.categories.contains(category)
                    ) {
                        toggleCategorySelection(category)
                    }
                }
            }
        } header: {
            HStack {
                Text("提交分类")
                
                Spacer()
                
                Button(localFilter.categories.isEmpty ? "全选" : "清除") {
                    if localFilter.categories.isEmpty {
                        localFilter.categories = Array(CommitCategory.allCases)
                    } else {
                        localFilter.categories.removeAll()
                    }
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
    }
    
    private var dateRangeSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                // 预设日期范围
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                    ForEach(DateRange.allCases.filter { $0 != .custom }, id: \.self) { range in
                        Button(range.displayName) {
                            let (start, end) = range.dateRange
                            localFilter.startDate = start
                            localFilter.endDate = end
                        }
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(isDateRangeSelected(range) ? Color.blue.opacity(0.2) : Color(.systemGray6))
                        .foregroundColor(isDateRangeSelected(range) ? .blue : .primary)
                        .cornerRadius(8)
                    }
                }
                
                // 自定义日期范围
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("自定义日期范围", isOn: $showingCustomDateRange)
                        .font(.subheadline)
                    
                    if showingCustomDateRange {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("开始日期")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                DatePicker("", selection: Binding(
                                    get: { localFilter.startDate ?? Date() },
                                    set: { localFilter.startDate = $0 }
                                ), displayedComponents: .date)
                                .datePickerStyle(.compact)
                            }
                            
                            VStack(alignment: .leading) {
                                Text("结束日期")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                DatePicker("", selection: Binding(
                                    get: { localFilter.endDate ?? Date() },
                                    set: { localFilter.endDate = $0 }
                                ), displayedComponents: .date)
                                .datePickerStyle(.compact)
                            }
                        }
                    }
                }
            }
        } header: {
            Text("日期范围")
        }
    }
    
    private var searchOptionsSection: some View {
        Section {
            Toggle("在消息中搜索", isOn: $localFilter.searchOptions.searchInMessage)
            Toggle("在类型中搜索", isOn: $localFilter.searchOptions.searchInType)
            Toggle("模糊搜索", isOn: $localFilter.searchOptions.fuzzySearch)
            Toggle("区分大小写", isOn: $localFilter.searchOptions.caseSensitive)
        } header: {
            Text("搜索选项")
        } footer: {
            Text("模糊搜索允许匹配相似的词语，区分大小写会精确匹配字母大小写")
        }
    }
    
    private var sortingSection: some View {
        Section {
            Picker("排序方式", selection: $localFilter.sortOption) {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Text(option.displayName).tag(option)
                }
            }
            .pickerStyle(.menu)
            
            HStack {
                Text("结果限制")
                
                Spacer()
                
                TextField("无限制", value: $localFilter.limit, format: .number)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 80)
                    .keyboardType(.numberPad)
            }
        } header: {
            Text("排序和限制")
        } footer: {
            Text("设置为0表示不限制结果数量")
        }
    }
    
    private func toggleTypeSelection(_ type: CommitType) {
        if localFilter.types.contains(type) {
            localFilter.types.removeAll { $0 == type }
        } else {
            localFilter.types.append(type)
        }
    }
    
    private func toggleCategorySelection(_ category: CommitCategory) {
        if localFilter.categories.contains(category) {
            localFilter.categories.removeAll { $0 == category }
        } else {
            localFilter.categories.append(category)
        }
    }
    
    private func isDateRangeSelected(_ range: DateRange) -> Bool {
        let (start, end) = range.dateRange
        return localFilter.startDate == start && localFilter.endDate == end
    }
    
    private func applyFilter() {
        filter = localFilter
        onApply(localFilter)
        dismiss()
    }
    
    private func resetFilter() {
        localFilter = CommitFilter()
    }
    
    private func saveFilter() {
        // This would be handled by the parent view
        // For now, just apply the filter
        applyFilter()
    }
}

// 类型筛选芯片
struct TypeFilterChip: View {
    let type: CommitType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Text(type.emoji)
                    .font(.caption)
                
                Text(type.displayName)
                    .font(.caption2)
                    .lineLimit(1)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? type.color.opacity(0.2) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? type.color : Color.clear, lineWidth: 1)
                    )
            )
            .foregroundColor(isSelected ? type.color : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// 分类筛选芯片
struct CategoryFilterChip: View {
    let category: CommitCategory
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Text(category.emoji)
                    .font(.caption)
                
                Text(category.displayName)
                    .font(.caption2)
                    .lineLimit(1)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? category.color.opacity(0.2) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? category.color : Color.clear, lineWidth: 1)
                    )
            )
            .foregroundColor(isSelected ? category.color : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    AdvancedFilterSheet(
        filter: .constant(CommitFilter())
    ) { _ in
        print("Filter applied")
    }
}