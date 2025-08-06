import SwiftUI
import SwiftData

struct TagCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var tagManager: TagManager
    
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var selectedType: TagType = .milestone
    @State private var isImportant: Bool = false
    @State private var associatedVersion: String = ""
    @State private var shouldAssociateVersion: Bool = false
    
    let editingTag: Tag?
    
    init(tagManager: TagManager, editingTag: Tag? = nil) {
        self.tagManager = tagManager
        self.editingTag = editingTag
        
        if let tag = editingTag {
            _title = State(initialValue: tag.title)
            _description = State(initialValue: tag.tagDescription)
            _selectedType = State(initialValue: tag.type)
            _isImportant = State(initialValue: tag.isImportant)
            _associatedVersion = State(initialValue: tag.associatedVersion ?? "")
            _shouldAssociateVersion = State(initialValue: tag.isVersionAssociated)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("基本信息") {
                    TextField("标签标题", text: $title)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("描述（可选）", text: $description, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                }
                
                Section("标签类型") {
                    Picker("类型", selection: $selectedType) {
                        ForEach(TagType.allCases, id: \.self) { type in
                            HStack {
                                Text(type.emoji)
                                Text(type.displayName)
                                Spacer()
                                Text(type.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
                
                Section("标签属性") {
                    Toggle("重要标签", isOn: $isImportant)
                        .toggleStyle(SwitchToggleStyle(tint: selectedType.color))
                    
                    Toggle("关联版本升级", isOn: $shouldAssociateVersion)
                        .toggleStyle(SwitchToggleStyle(tint: selectedType.color))
                    
                    if shouldAssociateVersion {
                        TextField("版本号", text: $associatedVersion)
                            .textFieldStyle(.roundedBorder)
                            .placeholder(when: associatedVersion.isEmpty) {
                                Text("例如: v2.1")
                                    .foregroundColor(.secondary)
                            }
                    }
                }
                
                Section("预览") {
                    TagPreviewCard(
                        title: title.isEmpty ? "标签标题" : title,
                        description: description,
                        type: selectedType,
                        isImportant: isImportant,
                        associatedVersion: shouldAssociateVersion ? (associatedVersion.isEmpty ? nil : associatedVersion) : nil
                    )
                }
            }
            .navigationTitle(editingTag == nil ? "创建标签" : "编辑标签")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(editingTag == nil ? "创建" : "保存") {
                        saveTag()
                    }
                    .disabled(title.isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func saveTag() {
        let finalVersion = shouldAssociateVersion && !associatedVersion.isEmpty ? associatedVersion : nil
        
        if let editingTag = editingTag {
            tagManager.updateTag(
                editingTag,
                title: title,
                description: description,
                type: selectedType,
                isImportant: isImportant
            )
            
            if shouldAssociateVersion {
                tagManager.associateTagWithVersion(editingTag, version: finalVersion ?? "")
            }
        } else {
            tagManager.createTag(
                title: title,
                description: description,
                type: selectedType,
                associatedVersion: finalVersion,
                isImportant: isImportant
            )
        }
        
        dismiss()
    }
}

struct TagPreviewCard: View {
    let title: String
    let description: String
    let type: TagType
    let isImportant: Bool
    let associatedVersion: String?
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(type.emoji)
                        .font(.title2)
                    
                    Text(title)
                        .font(.headline)
                        .fontWeight(isImportant ? .bold : .medium)
                    
                    if isImportant {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                    
                    Spacer()
                }
                
                if !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    Text(type.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(type.color.opacity(0.2))
                        .foregroundColor(type.color)
                        .cornerRadius(4)
                    
                    if let version = associatedVersion {
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
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

#Preview {
    TagCreationView(tagManager: TagManager(modelContext: ModelContext(try! ModelContainer(for: Tag.self)), user: User()))
}