import SwiftUI
import SwiftData

/// View for creating new commits with text input and type selection
struct CommitCreationView: View {
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Properties
    let branch: Branch
    @StateObject private var commitManager: CommitManager
    
    // MARK: - State
    @State private var commitMessage = ""
    @State private var selectedType: CommitType = .taskComplete
    @State private var isCreating = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    // MARK: - Focus State
    @FocusState private var isMessageFieldFocused: Bool
    
    // MARK: - Initialization
    init(branch: Branch, commitRepository: CommitRepository, modelContext: ModelContext) {
        self.branch = branch
        self._commitManager = StateObject(wrappedValue: CommitManager(commitRepository: commitRepository, modelContext: modelContext))
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        // Branch Info
                        branchInfoView
                        
                        // Commit Type Selection
                        commitTypeSelectionView
                        
                        // Message Input
                        messageInputView
                        
                        // Quick Actions
                        quickActionsView
                    }
                    .padding()
                }
                
                // Bottom Actions
                bottomActionsView
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
            .onAppear {
                isMessageFieldFocused = true
            }
        }
        .alert("创建失败", isPresented: $showingError) {
            Button("确定") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Button("取消") {
                dismiss()
            }
            .foregroundColor(.blue)
            
            Spacer()
            
            Text("新建提交")
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            Button("保存") {
                Task {
                    await createCommit()
                }
            }
            .foregroundColor(.blue)
            .fontWeight(.semibold)
            .disabled(commitMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isCreating)
        }
        .padding()
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(.separator)),
            alignment: .bottom
        )
    }
    
    // MARK: - Branch Info View
    private var branchInfoView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("提交到分支")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            HStack {
                Text(branch.status.emoji)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(branch.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if !branch.branchDescription.isEmpty {
                        Text(branch.branchDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                Text("\(Int(branch.progress * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Commit Type Selection View
    private var commitTypeSelectionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("提交类型")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(CommitType.allCases, id: \.self) { type in
                    commitTypeButton(for: type)
                }
            }
        }
    }
    
    private func commitTypeButton(for type: CommitType) -> some View {
        Button(action: {
            selectedType = type
            // 根据类型设置默认消息
            if commitMessage.isEmpty {
                commitMessage = getDefaultMessage(for: type)
            }
        }) {
            HStack {
                Text(type.emoji)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(type.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(getTypeDescription(for: type))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                if selectedType == type {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedType == type ? type.color.opacity(0.1) : Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedType == type ? type.color : Color(.systemGray4), lineWidth: selectedType == type ? 2 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Message Input View
    private var messageInputView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("提交信息")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            TextEditor(text: $commitMessage)
                .focused($isMessageFieldFocused)
                .font(.body)
                .padding(12)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
                .frame(minHeight: 100)
            
            HStack {
                Text("\(commitMessage.count)/200")
                    .font(.caption2)
                    .foregroundColor(commitMessage.count > 200 ? .red : .secondary)
                
                Spacer()
                
                if !commitMessage.isEmpty {
                    Button("清空") {
                        commitMessage = ""
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
        }
    }
    
    // MARK: - Quick Actions View
    private var quickActionsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("快速操作")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                quickActionButton(
                    title: "完成了一项任务",
                    icon: "checkmark.circle",
                    type: .taskComplete
                )
                
                quickActionButton(
                    title: "学习了新知识",
                    icon: "book",
                    type: .learning
                )
                
                quickActionButton(
                    title: "记录一些思考",
                    icon: "lightbulb",
                    type: .reflection
                )
                
                quickActionButton(
                    title: "达成了里程碑",
                    icon: "trophy",
                    type: .milestone
                )
            }
        }
    }
    
    private func quickActionButton(title: String, icon: String, type: CommitType) -> some View {
        Button(action: {
            selectedType = type
            commitMessage = getDefaultMessage(for: type)
        }) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(type.color)
                    .font(.title3)
                    .frame(width: 24)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Bottom Actions View
    private var bottomActionsView: some View {
        VStack(spacing: 0) {
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(.separator))
            
            HStack(spacing: 16) {
                Button("取消") {
                    dismiss()
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                Button(action: {
                    Task {
                        await createCommit()
                    }
                }) {
                    HStack {
                        if isCreating {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        }
                        
                        Text(isCreating ? "创建中..." : "创建提交")
                            .font(.body)
                            .fontWeight(.semibold)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    commitMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isCreating
                        ? Color(.systemGray4)
                        : selectedType.color
                )
                .cornerRadius(10)
                .disabled(commitMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isCreating)
            }
            .padding()
            .background(Color(.systemBackground))
        }
    }
    
    // MARK: - Helper Methods
    private func getDefaultMessage(for type: CommitType) -> String {
        switch type {
        case .taskComplete:
            return "✅ 完成了一项任务"
        case .learning:
            return "📚 学习了新知识"
        case .reflection:
            return "🌟 记录了一些思考"
        case .milestone:
            return "🏆 达成了一个里程碑"
        case .habit:
            return "🔄 坚持了一个好习惯"
        case .exercise:
            return "💪 完成了运动锻炼"
        case .reading:
            return "📖 阅读了一些内容"
        case .creativity:
            return "🎨 进行了创意创作"
        case .social:
            return "👥 参与了社交活动"
        case .health:
            return "🏥 关注了健康状况"
        case .finance:
            return "💰 管理了财务状况"
        case .career:
            return "💼 推进了职业发展"
        case .relationship:
            return "💑 维护了人际关系"
        case .travel:
            return "✈️ 体验了旅行经历"
        case .skill:
            return "🛠️ 学习了新技能"
        case .project:
            return "📋 推进了项目进展"
        case .idea:
            return "💡 记录了新想法"
        case .challenge:
            return "⚡ 克服了一个挑战"
        case .gratitude:
            return "🙏 记录了感恩的事"
        case .custom:
            return "⭐ 记录了自定义内容"
        }
    }
    
    private func getTypeDescription(for type: CommitType) -> String {
        switch type {
        case .taskComplete:
            return "记录任务完成情况"
        case .learning:
            return "记录学习收获"
        case .reflection:
            return "记录思考感悟"
        case .milestone:
            return "记录重要成就"
        case .habit:
            return "记录习惯养成"
        case .exercise:
            return "记录运动健身"
        case .reading:
            return "记录阅读心得"
        case .creativity:
            return "记录创意创作"
        case .social:
            return "记录社交活动"
        case .health:
            return "记录健康管理"
        case .finance:
            return "记录财务管理"
        case .career:
            return "记录职业发展"
        case .relationship:
            return "记录人际关系"
        case .travel:
            return "记录旅行体验"
        case .skill:
            return "记录技能学习"
        case .project:
            return "记录项目进展"
        case .idea:
            return "记录想法灵感"
        case .challenge:
            return "记录挑战克服"
        case .gratitude:
            return "记录感恩感谢"
        case .custom:
            return "记录自定义内容"
        }
    }
    
    // MARK: - Actions
    @MainActor
    private func createCommit() async {
        guard !commitMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        isCreating = true
        
        do {
            let _ = try await commitManager.createCommit(
                message: commitMessage.trimmingCharacters(in: .whitespacesAndNewlines),
                type: selectedType,
                branchId: branch.id
            )
            
            // 成功创建后关闭视图
            dismiss()
            
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
        
        isCreating = false
    }
}

// MARK: - Preview
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Branch.self, Commit.self, configurations: config)
    let context = container.mainContext
    
    // Create sample branch
    let branch = Branch(
        name: "学习SwiftUI",
        branchDescription: "掌握SwiftUI开发技能，构建现代iOS应用"
    )
    
    // Create repository
    let repository = SwiftDataCommitRepository(modelContext: context)
    
    CommitCreationView(branch: branch, commitRepository: repository, modelContext: context)
        .modelContainer(container)
}