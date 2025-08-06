import SwiftUI
import SwiftData

// 保存的筛选器管理视图
struct SavedFiltersView: View {
    @ObservedObject var filter: AdvancedCommitFilter
    @State private var showingCreateDialog = false
    @State private var newFilterName = ""
    @State private var selectedFilter: SavedFilter?
    @State private var showingDeleteAlert = false
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                if filter.savedFilters.isEmpty {
                    emptyStateView
                } else {
                    filtersList
                }
            }
            .navigationTitle("保存的筛选器")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("新建") {
                        showingCreateDialog = true
                    }
                }
            }
            .alert("创建筛选器", isPresented: $showingCreateDialog) {
                TextField("筛选器名称", text: $newFilterName)
                
                Button("创建") {
                    createNewFilter()
                }
                
                Button("取消", role: .cancel) {
                    newFilterName = ""
                }
            } message: {
                Text("基于当前筛选条件创建新的保存筛选器")
            }
            .alert("删除筛选器", isPresented: $showingDeleteAlert) {
                Button("删除", role: .destructive) {
                    if let selectedFilter = selectedFilter {
                        filter.deleteSavedFilter(selectedFilter)
                    }
                }
                
                Button("取消", role: .cancel) { }
            } message: {
                Text("确定要删除筛选器 \"\(selectedFilter?.name ?? "")\" 吗？")
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("暂无保存的筛选器")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("创建筛选器可以快速应用常用的搜索条件")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("创建第一个筛选器") {
                showingCreateDialog = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var filtersList: some View {
        List {
            ForEach(filter.savedFilters, id: \.id) { savedFilter in
                SavedFilterRow(
                    savedFilter: savedFilter,
                    onApply: {
                        Task {
                            await filter.loadSavedFilter(savedFilter)
                            dismiss()
                        }
                    },
                    onDelete: {
                        selectedFilter = savedFilter
                        showingDeleteAlert = true
                    }
                )
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private func createNewFilter() {
        guard !newFilterName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        filter.saveCurrentFilter(name: newFilterName)
        newFilterName = ""
    }
}

// 保存的筛选器行
struct SavedFilterRow: View {
    let savedFilter: SavedFilter
    let onApply: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 筛选器名称和操作
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(savedFilter.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("创建于 \(savedFilter.createdAt.formatted(.dateTime.month().day().hour().minute()))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Menu {
                    Button("应用筛选器") {
                        onApply()
                    }
                    
                    Button("删除", role: .destructive) {
                        onDelete()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.secondary)
                }
            }
            
            // 筛选器摘要
            filterSummary
            
            // 应用按钮
            Button("应用此筛选器") {
                onApply()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.vertical, 4)
    }
    
    private var filterSummary: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 搜索文本
            if !savedFilter.filter.searchText.isEmpty {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.blue)
                        .font(.caption)
                    
                    Text("搜索: \(savedFilter.filter.searchText)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // 类型筛选
            if !savedFilter.filter.types.isEmpty {
                HStack {
                    Image(systemName: "tag")
                        .foregroundColor(.green)
                        .font(.caption)
                    
                    Text("类型: \(savedFilter.filter.types.map { $0.displayName }.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            // 分类筛选
            if !savedFilter.filter.categories.isEmpty {
                HStack {
                    Image(systemName: "folder")
                        .foregroundColor(.orange)
                        .font(.caption)
                    
                    Text("分类: \(savedFilter.filter.categories.map { $0.displayName }.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            // 日期范围
            if let startDate = savedFilter.filter.startDate,
               let endDate = savedFilter.filter.endDate {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.purple)
                        .font(.caption)
                    
                    Text("日期: \(startDate.formatted(.dateTime.month().day())) - \(endDate.formatted(.dateTime.month().day()))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // 排序方式
            HStack {
                Image(systemName: "arrow.up.arrow.down")
                    .foregroundColor(.gray)
                    .font(.caption)
                
                Text("排序: \(savedFilter.filter.sortOption.displayName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.leading, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
    SavedFiltersView(
        filter: AdvancedCommitFilter(
            modelContext: ModelContext(try! ModelContainer(for: Commit.self))
        )
    )
}