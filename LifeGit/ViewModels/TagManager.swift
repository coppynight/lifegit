import Foundation
import SwiftData
import SwiftUI

@MainActor
class TagManager: ObservableObject {
    @Published var tags: [Tag] = []
    @Published var filteredTags: [Tag] = []
    @Published var selectedTagType: TagType? = nil
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private let modelContext: ModelContext
    private let user: User
    
    init(modelContext: ModelContext, user: User) {
        self.modelContext = modelContext
        self.user = user
        loadTags()
    }
    
    // MARK: - 数据加载
    func loadTags() {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // 简化查询 - 获取所有标签然后过滤
            let allTags = try modelContext.fetch(FetchDescriptor<Tag>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            ))
            tags = allTags.filter { $0.user?.id == user.id }
            applyFilters()
        } catch {
            errorMessage = "加载标签失败: \(error.localizedDescription)"
        }
    }
    
    // MARK: - 标签CRUD操作
    func createTag(title: String, description: String = "", type: TagType, associatedVersion: String? = nil, isImportant: Bool = false) {
        let newTag = Tag(
            title: title,
            tagDescription: description,
            type: type,
            associatedVersion: associatedVersion,
            isImportant: isImportant
        )
        
        // 建立关联关系
        user.tags.append(newTag)
        
        do {
            try modelContext.save()
            loadTags()
        } catch {
            errorMessage = "创建标签失败: \(error.localizedDescription)"
        }
    }
    
    func updateTag(_ tag: Tag, title: String, description: String, type: TagType, isImportant: Bool) {
        tag.title = title
        tag.tagDescription = description
        tag.type = type
        tag.isImportant = isImportant
        
        do {
            try modelContext.save()
            loadTags()
        } catch {
            errorMessage = "更新标签失败: \(error.localizedDescription)"
        }
    }
    
    func deleteTag(_ tag: Tag) {
        modelContext.delete(tag)
        
        do {
            try modelContext.save()
            loadTags()
        } catch {
            errorMessage = "删除标签失败: \(error.localizedDescription)"
        }
    }
    
    // MARK: - 版本关联逻辑
    func associateTagWithVersion(_ tag: Tag, version: String) {
        tag.associatedVersion = version
        
        do {
            try modelContext.save()
            loadTags()
        } catch {
            errorMessage = "关联版本失败: \(error.localizedDescription)"
        }
    }
    
    func createVersionAssociatedTag(title: String, description: String, type: TagType, version: String) {
        createTag(
            title: title,
            description: description,
            type: type,
            associatedVersion: version,
            isImportant: true
        )
    }
    
    // MARK: - 筛选和搜索
    func applyFilters() {
        var filtered = tags
        
        // 按类型筛选
        if let selectedType = selectedTagType {
            filtered = filtered.filter { $0.type == selectedType }
        }
        
        // 按搜索文本筛选
        if !searchText.isEmpty {
            filtered = filtered.filter { tag in
                tag.title.localizedCaseInsensitiveContains(searchText) ||
                tag.tagDescription.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        filteredTags = filtered
    }
    
    func setTagTypeFilter(_ type: TagType?) {
        selectedTagType = type
        applyFilters()
    }
    
    func setSearchText(_ text: String) {
        searchText = text
        applyFilters()
    }
    
    func clearFilters() {
        selectedTagType = nil
        searchText = ""
        applyFilters()
    }
    
    // MARK: - 统计信息
    var tagsByType: [TagType: [Tag]] {
        Dictionary(grouping: tags) { $0.type }
    }
    
    var importantTags: [Tag] {
        tags.filter { $0.isImportant }
    }
    
    var versionAssociatedTags: [Tag] {
        tags.filter { $0.isVersionAssociated }
    }
    
    func tagsCount(for type: TagType) -> Int {
        tags.filter { $0.type == type }.count
    }
    
    // MARK: - 错误处理
    func clearError() {
        errorMessage = nil
    }
}