import SwiftUI
import SwiftData

// 提交类型自定义和个性化视图
struct CommitTypeCustomizationView: View {
    @StateObject private var analytics: CommitTypeAnalytics
    @State private var selectedTypes: Set<CommitType> = []
    @State private var customTypeConfigs: [CommitTypeConfig] = []
    @State private var showingCustomTypeEditor = false
    @State private var editingConfig: CommitTypeConfig?
    
    @Environment(\.dismiss) private var dismiss
    
    let modelContext: ModelContext
    let onSave: ([CommitTypeConfig]) -> Void
    
    init(modelContext: ModelContext, onSave: @escaping ([CommitTypeConfig]) -> Void) {
        self.modelContext = modelContext
        self.onSave = onSave
        self._analytics = StateObject(wrappedValue: CommitTypeAnalytics(modelContext: modelContext))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 推荐类型区域
                recommendedTypesSection
                
                Divider()
                
                // 所有类型区域
                allTypesSection
                
                Divider()
                
                // 自定义类型区域
                customTypesSection
            }
            .navigationTitle("自定义提交类型")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveConfiguration()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingCustomTypeEditor) {
                CustomTypeEditorView(
                    config: editingConfig,
                    onSave: { config in
                        if let index = customTypeConfigs.firstIndex(where: { $0.id == config.id }) {
                            customTypeConfigs[index] = config
                        } else {
                            customTypeConfigs.append(config)
                        }
                        editingConfig = nil
                    }
                )
            }
        }
        .onAppear {
            loadConfiguration()
        }
    }
    
    private var recommendedTypesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("推荐类型")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("基于使用习惯")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.top)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(analytics.getRecommendedTypes(), id: \.self) { type in
                        CommitTypeChip(
                            type: type,
                            isSelected: selectedTypes.contains(type)
                        ) {
                            toggleTypeSelection(type)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.bottom)
    }
    
    private var allTypesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("所有类型")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(selectedTypes.count == CommitType.allCases.count ? "取消全选" : "全选") {
                    if selectedTypes.count == CommitType.allCases.count {
                        selectedTypes.removeAll()
                    } else {
                        selectedTypes = Set(CommitType.allCases)
                    }
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            .padding(.horizontal)
            .padding(.top)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(CommitCategory.allCases, id: \.self) { category in
                    CategorySection(
                        category: category,
                        types: CommitType.allCases.filter { $0.category == category },
                        selectedTypes: $selectedTypes
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom)
    }
    
    private var customTypesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("自定义类型")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    editingConfig = CommitTypeConfig()
                    showingCustomTypeEditor = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }
            .padding(.horizontal)
            .padding(.top)
            
            if customTypeConfigs.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "star.circle")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    
                    Text("暂无自定义类型")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text("点击上方 + 按钮创建自定义类型")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    ForEach(customTypeConfigs, id: \.id) { config in
                        CustomTypeCard(config: config) {
                            editingConfig = config
                            showingCustomTypeEditor = true
                        } onDelete: {
                            customTypeConfigs.removeAll { $0.id == config.id }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.bottom)
    }
    
    private func toggleTypeSelection(_ type: CommitType) {
        if selectedTypes.contains(type) {
            selectedTypes.remove(type)
        } else {
            selectedTypes.insert(type)
        }
    }
    
    private func loadConfiguration() {
        // 从UserDefaults加载配置
        if let data = UserDefaults.standard.data(forKey: "selectedCommitTypes"),
           let types = try? JSONDecoder().decode(Set<CommitType>.self, from: data) {
            selectedTypes = types
        } else {
            // 默认选择推荐类型
            selectedTypes = Set(analytics.getRecommendedTypes())
        }
        
        if let data = UserDefaults.standard.data(forKey: "customCommitTypes"),
           let configs = try? JSONDecoder().decode([CommitTypeConfig].self, from: data) {
            customTypeConfigs = configs
        }
    }
    
    private func saveConfiguration() {
        // 保存到UserDefaults
        if let data = try? JSONEncoder().encode(selectedTypes) {
            UserDefaults.standard.set(data, forKey: "selectedCommitTypes")
        }
        
        if let data = try? JSONEncoder().encode(customTypeConfigs) {
            UserDefaults.standard.set(data, forKey: "customCommitTypes")
        }
        
        // 回调保存
        let allConfigs = selectedTypes.map { type in
            CommitTypeConfig(
                id: UUID(),
                type: type,
                displayName: type.displayName,
                emoji: type.emoji,
                color: type.color,
                isEnabled: true,
                isCustom: false
            )
        } + customTypeConfigs
        
        onSave(allConfigs)
        dismiss()
    }
}

// 提交类型芯片组件
struct CommitTypeChip: View {
    let type: CommitType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Text(type.emoji)
                    .font(.body)
                
                Text(type.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? type.color.opacity(0.2) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? type.color : Color.clear, lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// 分类区域组件
struct CategorySection: View {
    let category: CommitCategory
    let types: [CommitType]
    @Binding var selectedTypes: Set<CommitType>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(category.emoji)
                    .font(.body)
                
                Text(category.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(category.color.opacity(0.1))
            .cornerRadius(8)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 1), spacing: 6) {
                ForEach(types, id: \.self) { type in
                    HStack {
                        Button(action: {
                            if selectedTypes.contains(type) {
                                selectedTypes.remove(type)
                            } else {
                                selectedTypes.insert(type)
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: selectedTypes.contains(type) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedTypes.contains(type) ? type.color : .secondary)
                                
                                Text(type.emoji)
                                    .font(.caption)
                                
                                Text(type.displayName)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// 自定义类型卡片
struct CustomTypeCard: View {
    let config: CommitTypeConfig
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(config.emoji)
                    .font(.title2)
                
                Spacer()
                
                Menu {
                    Button("编辑", action: onEdit)
                    Button("删除", role: .destructive, action: onDelete)
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.secondary)
                }
            }
            
            Text(config.displayName)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            if let description = config.description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(12)
        .background(config.color.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(config.color.opacity(0.3), lineWidth: 1)
        )
    }
}

// 提交类型配置模型
struct CommitTypeConfig: Codable, Identifiable {
    let id: UUID
    var type: CommitType?
    var displayName: String
    var emoji: String
    var color: Color
    var description: String?
    var isEnabled: Bool
    var isCustom: Bool
    
    init(id: UUID = UUID(),
         type: CommitType? = nil,
         displayName: String = "",
         emoji: String = "⭐",
         color: Color = .blue,
         description: String? = nil,
         isEnabled: Bool = true,
         isCustom: Bool = true) {
        self.id = id
        self.type = type
        self.displayName = displayName
        self.emoji = emoji
        self.color = color
        self.description = description
        self.isEnabled = isEnabled
        self.isCustom = isCustom
    }
}

// Color的Codable扩展
extension Color: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let colorName = try container.decode(String.self)
        
        switch colorName {
        case "red": self = .red
        case "green": self = .green
        case "blue": self = .blue
        case "orange": self = .orange
        case "yellow": self = .yellow
        case "pink": self = .pink
        case "purple": self = .purple
        case "cyan": self = .cyan
        case "mint": self = .mint
        case "teal": self = .teal
        case "indigo": self = .indigo
        case "brown": self = .brown
        case "gray": self = .gray
        default: self = .secondary
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        // 简化的颜色编码，实际应用中可能需要更复杂的实现
        if self == .red { try container.encode("red") }
        else if self == .green { try container.encode("green") }
        else if self == .blue { try container.encode("blue") }
        else if self == .orange { try container.encode("orange") }
        else if self == .yellow { try container.encode("yellow") }
        else if self == .pink { try container.encode("pink") }
        else if self == .purple { try container.encode("purple") }
        else if self == .cyan { try container.encode("cyan") }
        else if self == .mint { try container.encode("mint") }
        else if self == .teal { try container.encode("teal") }
        else if self == .indigo { try container.encode("indigo") }
        else if self == .brown { try container.encode("brown") }
        else if self == .gray { try container.encode("gray") }
        else { try container.encode("secondary") }
    }
}

#Preview {
    CommitTypeCustomizationView(
        modelContext: ModelContext(try! ModelContainer(for: Commit.self))
    ) { configs in
        print("Saved \(configs.count) configurations")
    }
}