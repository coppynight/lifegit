import SwiftUI

/// Individual task item row component with completion toggle and editing capabilities
struct TaskItemRowView: View {
    let task: TaskItem
    let onToggle: () -> Void
    
    @State private var isShowingEditSheet = false
    @State private var isShowingDeleteAlert = false
    @State private var isCompleted: Bool
    
    init(task: TaskItem, onToggle: @escaping () -> Void) {
        self.task = task
        self.onToggle = onToggle
        self._isCompleted = State(initialValue: task.isCompleted)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Completion Checkbox
            completionCheckbox
            
            // Task Content
            taskContent
            
            // Action Menu
            actionMenu
        }
        .padding()
        .background(backgroundColor)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: 1)
        )
        .opacity(isCompleted ? 0.7 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isCompleted)
        .sheet(isPresented: $isShowingEditSheet) {
            TaskItemEditView(task: task) { updatedTask in
                // Handle task update
                // This will be implemented in the edit view
            }
        }
        .alert("删除任务", isPresented: $isShowingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                // Handle task deletion
                // This will be implemented when we have the delete functionality
            }
        } message: {
            Text("确定要删除任务 \"\(task.title)\" 吗？此操作无法撤销。")
        }
        .onChange(of: task.isCompleted) { newValue in
            isCompleted = newValue
        }
    }
    
    // MARK: - Completion Checkbox
    
    @ViewBuilder
    private var completionCheckbox: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                isCompleted.toggle()
                onToggle()
            }
        }) {
            ZStack {
                Circle()
                    .fill(isCompleted ? Color.green : Color.clear)
                    .frame(width: 24, height: 24)
                
                Circle()
                    .stroke(isCompleted ? Color.green : Color.secondary, lineWidth: 2)
                    .frame(width: 24, height: 24)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isCompleted ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isCompleted)
    }
    
    // MARK: - Task Content
    
    @ViewBuilder
    private var taskContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Task Title
            Text(task.title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isCompleted ? .secondary : .primary)
                .strikethrough(isCompleted)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            // Task Description
            if !task.taskDescription.isEmpty {
                Text(task.taskDescription)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
            
            // Execution Tips (if available)
            if let executionTips = task.executionTips, !executionTips.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.yellow)
                    
                    Text(executionTips)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.yellow.opacity(0.1))
                .cornerRadius(6)
            }
            
            // Task Metadata
            taskMetadata
        }
    }
    
    @ViewBuilder
    private var taskMetadata: some View {
        HStack(spacing: 12) {
            // Time Scope Badge
            HStack(spacing: 4) {
                Image(systemName: task.timeScope.icon)
                    .font(.system(size: 10))
                Text(task.timeScope.displayName)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(task.timeScope.color)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(task.timeScope.color.opacity(0.1))
            .cornerRadius(4)
            
            // Duration
            if task.estimatedDuration > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                    Text(task.formattedDuration)
                        .font(.system(size: 11))
                }
                .foregroundColor(.secondary)
            }
            
            // AI Generated Badge
            if task.isAIGenerated {
                HStack(spacing: 2) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 9))
                    Text("AI")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundColor(.purple)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.purple.opacity(0.1))
                .cornerRadius(3)
            }
            
            Spacer()
            
            // Completion Status
            if isCompleted, let completedAt = task.completedAt {
                Text("完成于 \(formatCompletionDate(completedAt))")
                    .font(.system(size: 10))
                    .foregroundColor(.green)
            }
        }
    }
    
    // MARK: - Action Menu
    
    @ViewBuilder
    private var actionMenu: some View {
        Menu {
            Button(action: {
                isShowingEditSheet = true
            }) {
                Label("编辑任务", systemImage: "pencil")
            }
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isCompleted.toggle()
                    onToggle()
                }
            }) {
                Label(
                    isCompleted ? "标记为未完成" : "标记为完成",
                    systemImage: isCompleted ? "circle" : "checkmark.circle"
                )
            }
            
            Divider()
            
            Button(role: .destructive, action: {
                isShowingDeleteAlert = true
            }) {
                Label("删除任务", systemImage: "trash")
            }
            
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 24, height: 24)
        }
        .menuStyle(BorderlessButtonMenuStyle())
    }
    
    // MARK: - Computed Properties
    
    private var backgroundColor: Color {
        if isCompleted {
            return Color(.systemGray6)
        } else {
            return Color(.systemBackground)
        }
    }
    
    private var borderColor: Color {
        if isCompleted {
            return Color.green.opacity(0.3)
        } else {
            return Color(.systemGray4)
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatCompletionDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
            return "今天 \(formatter.string(from: date))"
        } else if calendar.isDateInYesterday(date) {
            formatter.dateFormat = "HH:mm"
            return "昨天 \(formatter.string(from: date))"
        } else {
            formatter.dateFormat = "MM/dd HH:mm"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Task Item Edit View

/// Edit view for individual task items
struct TaskItemEditView: View {
    let task: TaskItem
    let onSave: (TaskItem) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String
    @State private var taskDescription: String
    @State private var timeScope: TaskTimeScope
    @State private var estimatedDuration: Int
    @State private var executionTips: String
    
    init(task: TaskItem, onSave: @escaping (TaskItem) -> Void) {
        self.task = task
        self.onSave = onSave
        
        self._title = State(initialValue: task.title)
        self._taskDescription = State(initialValue: task.taskDescription)
        self._timeScope = State(initialValue: task.timeScope)
        self._estimatedDuration = State(initialValue: task.estimatedDuration)
        self._executionTips = State(initialValue: task.executionTips ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("基本信息") {
                    TextField("任务标题", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("任务描述", text: $taskDescription, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                }
                
                Section("时间设置") {
                    Picker("时间维度", selection: $timeScope) {
                        ForEach(TaskTimeScope.allCases, id: \.self) { scope in
                            HStack {
                                Image(systemName: scope.icon)
                                    .foregroundColor(scope.color)
                                Text(scope.displayName)
                            }
                            .tag(scope)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    HStack {
                        Text("预估时长")
                        Spacer()
                        TextField("分钟", value: $estimatedDuration, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .frame(width: 80)
                        Text("分钟")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("执行建议") {
                    TextField("执行建议（可选）", text: $executionTips, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("编辑任务")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveTask()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func saveTask() {
        // Update task properties
        task.title = title
        task.taskDescription = taskDescription
        task.timeScope = timeScope
        task.estimatedDuration = estimatedDuration
        task.executionTips = executionTips.isEmpty ? nil : executionTips
        task.lastModifiedAt = Date()
        
        onSave(task)
        dismiss()
    }
}



#Preview {
    let sampleTask = TaskItem(
        title: "学习Swift基础语法",
        taskDescription: "掌握Swift的基本语法，包括变量、常量、数据类型、控制流等核心概念",
        estimatedDuration: 120,
        timeScope: .daily,
        isAIGenerated: true,
        orderIndex: 1,
        executionTips: "建议使用Xcode Playground进行实践练习"
    )
    
    VStack {
        TaskItemRowView(task: sampleTask) {
            print("Task toggled")
        }
        .padding()
        
        Spacer()
    }
}