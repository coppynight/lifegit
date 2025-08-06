import SwiftUI
import SwiftData

struct TagDetailView: View {
    let tag: Tag
    @ObservedObject var tagManager: TagManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingEditView = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 标签头部信息
                    TagHeaderSection(tag: tag)
                    
                    // 标签详细信息
                    TagInfoSection(tag: tag)
                    
                    // 版本关联信息
                    if tag.isVersionAssociated {
                        TagVersionSection(tag: tag)
                    }
                    
                    // 统计信息
                    TagStatsSection(tag: tag, tagManager: tagManager)
                }
                .padding()
            }
            .navigationTitle("标签详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showingEditView = true
                        } label: {
                            Label("编辑", systemImage: "pencil")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingEditView) {
                TagCreationView(tagManager: tagManager, editingTag: tag)
            }
            .alert("删除标签", isPresented: $showingDeleteAlert) {
                Button("取消", role: .cancel) { }
                Button("删除", role: .destructive) {
                    tagManager.deleteTag(tag)
                    dismiss()
                }
            } message: {
                Text("确定要删除标签「\(tag.title)」吗？此操作无法撤销。")
            }
        }
    }
}

struct TagHeaderSection: View {
    let tag: Tag
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(tag.type.emoji)
                    .font(.system(size: 40))
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(tag.title)
                            .font(.title2)
                            .fontWeight(tag.isImportant ? .bold : .semibold)
                        
                        if tag.isImportant {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.title3)
                        }
                    }
                    
                    Text(tag.type.displayName)
                        .font(.subheadline)
                        .foregroundColor(tag.type.color)
                        .fontWeight(.medium)
                }
                
                Spacer()
            }
            
            if !tag.tagDescription.isEmpty {
                Text(tag.tagDescription)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(nil)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(tag.type.color.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(tag.type.color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct TagInfoSection: View {
    let tag: Tag
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("基本信息")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                InfoRow(
                    icon: "calendar",
                    title: "创建时间",
                    value: tag.formattedDate,
                    color: .blue
                )
                
                InfoRow(
                    icon: "tag",
                    title: "标签类型",
                    value: tag.type.displayName,
                    color: tag.type.color
                )
                
                InfoRow(
                    icon: tag.isImportant ? "star.fill" : "star",
                    title: "重要程度",
                    value: tag.isImportant ? "重要标签" : "普通标签",
                    color: tag.isImportant ? .yellow : .secondary
                )
            }
        }
    }
}

struct TagVersionSection: View {
    let tag: Tag
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("版本关联")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "arrow.branch")
                        .foregroundColor(.blue)
                        .frame(width: 20)
                    
                    Text("关联版本")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(tag.associatedVersion ?? "未关联")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                }
                
                Text("此标签与版本升级相关联，代表人生的重要节点。")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 28)
            }
            .padding()
            .background(Color.blue.opacity(0.05))
            .cornerRadius(8)
        }
    }
}

struct TagStatsSection: View {
    let tag: Tag
    @ObservedObject var tagManager: TagManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("统计信息")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                InfoRow(
                    icon: "number",
                    title: "同类型标签数量",
                    value: "\(tagManager.tagsCount(for: tag.type)) 个",
                    color: .orange
                )
                
                InfoRow(
                    icon: "clock",
                    title: "创建距今",
                    value: timeAgoString(from: tag.createdAt),
                    color: .green
                )
            }
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        let days = Int(timeInterval / 86400)
        if days > 0 {
            return "\(days) 天前"
        }
        
        let hours = Int(timeInterval / 3600)
        if hours > 0 {
            return "\(hours) 小时前"
        }
        
        let minutes = Int(timeInterval / 60)
        if minutes > 0 {
            return "\(minutes) 分钟前"
        }
        
        return "刚刚"
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    let tag = Tag(
        title: "大学毕业",
        tagDescription: "完成了四年的大学学习，获得了计算机科学学位",
        type: .education,
        associatedVersion: "v2.0",
        isImportant: true
    )
    
    TagDetailView(
        tag: tag,
        tagManager: TagManager(modelContext: ModelContext(try! ModelContainer(for: Tag.self)), user: User())
    )
}