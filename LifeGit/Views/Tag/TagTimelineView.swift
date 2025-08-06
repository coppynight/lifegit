import SwiftUI
import SwiftData

struct TagTimelineView: View {
    @ObservedObject var tagManager: TagManager
    @State private var showingCreateTag = false
    @State private var selectedTag: Tag? = nil
    @State private var showingTagDetail = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 筛选和搜索栏
                TagFilterBar(tagManager: tagManager)
                
                if tagManager.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("加载标签中...")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if tagManager.filteredTags.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "tag.circle")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("暂无标签")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Button("创建标签") {
                            showingCreateTag = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // 标签时间线
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(tagManager.filteredTags) { tag in
                                TagTimelineItem(
                                    tag: tag,
                                    onTap: {
                                        selectedTag = tag
                                        showingTagDetail = true
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("人生标签")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreateTag = true
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showingCreateTag) {
                TagCreationView(tagManager: tagManager)
            }
            .sheet(isPresented: $showingTagDetail) {
                if let tag = selectedTag {
                    TagDetailView(tag: tag, tagManager: tagManager)
                }
            }
            .alert("错误", isPresented: .constant(tagManager.errorMessage != nil)) {
                Button("确定") {
                    tagManager.clearError()
                }
            } message: {
                if let error = tagManager.errorMessage {
                    Text(error)
                }
            }
        }
    }
}

struct TagFilterBar: View {
    @ObservedObject var tagManager: TagManager
    
    var body: some View {
        VStack(spacing: 12) {
            // 搜索框
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("搜索标签...", text: Binding(
                    get: { tagManager.searchText },
                    set: { tagManager.setSearchText($0) }
                ))
                .textFieldStyle(.plain)
                
                if !tagManager.searchText.isEmpty {
                    Button {
                        tagManager.setSearchText("")
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            // 类型筛选
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // 全部标签
                    FilterChip(
                        title: "全部",
                        count: tagManager.tags.count,
                        isSelected: tagManager.selectedTagType == nil
                    ) {
                        tagManager.setTagTypeFilter(nil)
                    }
                    
                    // 各类型标签
                    ForEach(TagType.allCases, id: \.self) { type in
                        FilterChip(
                            title: "\(type.emoji) \(type.displayName)",
                            count: tagManager.tagsCount(for: type),
                            isSelected: tagManager.selectedTagType == type
                        ) {
                            tagManager.setTagTypeFilter(type)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
    }
}

struct TagTimelineItem: View {
    let tag: Tag
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // 时间线指示器
                VStack {
                    Circle()
                        .fill(tag.type.color)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                    
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
                .frame(width: 12)
                
                // 标签内容
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(tag.type.emoji)
                            .font(.title2)
                        
                        Text(tag.title)
                            .font(.headline)
                            .fontWeight(tag.isImportant ? .bold : .medium)
                            .multilineTextAlignment(.leading)
                        
                        if tag.isImportant {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }
                        
                        Spacer()
                        
                        Text(tag.formattedDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if !tag.tagDescription.isEmpty {
                        Text(tag.tagDescription)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(3)
                    }
                    
                    HStack {
                        Text(tag.type.displayName)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(tag.type.color.opacity(0.2))
                            .foregroundColor(tag.type.color)
                            .cornerRadius(4)
                        
                        if let version = tag.associatedVersion {
                            Text("版本 \(version)")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        }
                        
                        Spacer()
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EmptyTagsView: View {
    let hasFilters: Bool
    let onCreateTag: () -> Void
    let onClearFilters: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: hasFilters ? "magnifyingglass" : "tag")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text(hasFilters ? "没有找到匹配的标签" : "还没有创建标签")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(hasFilters ? "尝试调整筛选条件或搜索关键词" : "为人生重要时刻创建标签，记录成长轨迹")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            VStack(spacing: 12) {
                Button(hasFilters ? "清除筛选" : "创建第一个标签") {
                    if hasFilters {
                        onClearFilters()
                    } else {
                        onCreateTag()
                    }
                }
                .buttonStyle(.borderedProminent)
                
                if hasFilters {
                    Button("创建新标签") {
                        onCreateTag()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding()
    }
}

#Preview {
    TagTimelineView(tagManager: TagManager(modelContext: ModelContext(try! ModelContainer(for: Tag.self)), user: User()))
}