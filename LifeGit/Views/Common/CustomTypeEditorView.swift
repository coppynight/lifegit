import SwiftUI

// 自定义提交类型编辑器
struct CustomTypeEditorView: View {
    @State private var displayName: String = ""
    @State private var emoji: String = "⭐"
    @State private var selectedColor: Color = .blue
    @State private var description: String = ""
    @State private var showingEmojiPicker = false
    
    @Environment(\.dismiss) private var dismiss
    
    let config: CommitTypeConfig?
    let onSave: (CommitTypeConfig) -> Void
    
    private let availableColors: [Color] = [
        .red, .green, .blue, .orange, .yellow, .pink,
        .purple, .cyan, .mint, .teal, .indigo, .brown, .gray
    ]
    
    private let commonEmojis = [
        "⭐", "🌟", "✨", "💫", "🔥", "💡", "🎯", "🚀",
        "💪", "🎨", "📝", "💭", "🎉", "🏆", "🎪", "🌈",
        "🔮", "💎", "🎭", "🎪", "🎨", "🎵", "🎸", "🎤"
    ]
    
    var isValid: Bool {
        !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !emoji.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationView {
            Form {
                // 预览区域
                previewSection
                
                // 基本信息
                basicInfoSection
                
                // 外观设置
                appearanceSection
                
                // 描述
                descriptionSection
            }
            .navigationTitle(config == nil ? "创建自定义类型" : "编辑自定义类型")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveCustomType()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }
            }
            .sheet(isPresented: $showingEmojiPicker) {
                EmojiPickerView(selectedEmoji: $emoji)
            }
        }
        .onAppear {
            loadConfiguration()
        }
    }
    
    private var previewSection: some View {
        Section {
            HStack {
                Spacer()
                
                VStack(spacing: 12) {
                    // 预览图标
                    ZStack {
                        Circle()
                            .fill(selectedColor)
                            .frame(width: 60, height: 60)
                        
                        Text(emoji)
                            .font(.largeTitle)
                    }
                    
                    // 预览名称
                    Text(displayName.isEmpty ? "自定义类型" : displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    // 预览描述
                    if !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 20)
        } header: {
            Text("预览")
        }
    }
    
    private var basicInfoSection: some View {
        Section {
            HStack {
                Text("名称")
                    .foregroundColor(.primary)
                
                Spacer()
                
                TextField("输入类型名称", text: $displayName)
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(PlainTextFieldStyle())
            }
            
            HStack {
                Text("图标")
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    showingEmojiPicker = true
                }) {
                    HStack(spacing: 8) {
                        Text(emoji)
                            .font(.title2)
                        
                        Text("选择")
                            .font(.body)
                            .foregroundColor(.blue)
                    }
                }
            }
        } header: {
            Text("基本信息")
        }
    }
    
    private var appearanceSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text("颜色")
                    .foregroundColor(.primary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                    ForEach(availableColors, id: \.self) { color in
                        Button(action: {
                            selectedColor = color
                        }) {
                            Circle()
                                .fill(color)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: selectedColor == color ? 2 : 0)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text("外观")
        }
    }
    
    private var descriptionSection: some View {
        Section {
            TextField("输入类型描述（可选）", text: $description, axis: .vertical)
                .lineLimit(3...6)
        } header: {
            Text("描述")
        } footer: {
            Text("描述将帮助你更好地理解这个自定义类型的用途")
                .font(.caption)
        }
    }
    
    private func loadConfiguration() {
        if let config = config {
            displayName = config.displayName
            emoji = config.emoji
            selectedColor = config.color
            description = config.description ?? ""
        }
    }
    
    private func saveCustomType() {
        let newConfig = CommitTypeConfig(
            id: config?.id ?? UUID(),
            type: nil,
            displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines),
            emoji: emoji,
            color: selectedColor,
            description: description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : description.trimmingCharacters(in: .whitespacesAndNewlines),
            isEnabled: true,
            isCustom: true
        )
        
        onSave(newConfig)
        dismiss()
    }
}

// Emoji选择器视图
struct EmojiPickerView: View {
    @Binding var selectedEmoji: String
    @Environment(\.dismiss) private var dismiss
    
    private let emojiCategories: [EmojiCategory] = [
        EmojiCategory(name: "常用", emojis: ["⭐", "🌟", "✨", "💫", "🔥", "💡", "🎯", "🚀"]),
        EmojiCategory(name: "表情", emojis: ["😀", "😃", "😄", "😁", "😆", "😅", "😂", "🤣"]),
        EmojiCategory(name: "手势", emojis: ["👍", "👎", "👌", "✌️", "🤞", "🤟", "🤘", "🤙"]),
        EmojiCategory(name: "活动", emojis: ["⚽", "🏀", "🏈", "⚾", "🎾", "🏐", "🏉", "🎱"]),
        EmojiCategory(name: "物品", emojis: ["📱", "💻", "⌨️", "🖥️", "🖨️", "📷", "📹", "🎥"]),
        EmojiCategory(name: "符号", emojis: ["❤️", "💛", "💚", "💙", "💜", "🖤", "🤍", "🤎"])
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    ForEach(emojiCategories, id: \.name) { category in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(category.name)
                                .font(.headline)
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 12) {
                                ForEach(category.emojis, id: \.self) { emoji in
                                    Button(action: {
                                        selectedEmoji = emoji
                                        dismiss()
                                    }) {
                                        Text(emoji)
                                            .font(.largeTitle)
                                            .frame(width: 40, height: 40)
                                            .background(
                                                Circle()
                                                    .fill(selectedEmoji == emoji ? Color.blue.opacity(0.2) : Color.clear)
                                            )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("选择图标")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct EmojiCategory {
    let name: String
    let emojis: [String]
}

#Preview {
    CustomTypeEditorView(config: nil) { config in
        print("Saved config: \(config)")
    }
}