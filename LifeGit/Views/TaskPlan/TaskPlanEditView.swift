import SwiftUI

/// Comprehensive task plan editing interface with add, delete, and reorder capabilities
struct TaskPlanEditView: View {
    let taskPlan: TaskPlan
    let onSave: (TaskPlan) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var taskPlanManager: TaskPlanManager
    
    @State private var totalDuration: String
    @State private var tasks: [TaskItem]
    @State private var isShowingAddTaskSheet = false
    @State private var editingTask: TaskItem?
    @State private var draggedTask: TaskItem?
    @State private var hasChanges = false
    @State private var isSaving = false
    @State private var showingDiscardAlert = false
    
    init(taskPlan: TaskPlan, onSave: @escaping (TaskPlan) -> Void) {
        self.taskPlan = taskPlan
        self.onSave = onSave
        
        self._totalDuration = State(initialValue: taskPlan.totalDuration)
        self._tasks = State(initialValue: taskPlan.orderedTasks)
        self._taskPlanManager = StateObject(wrappedValue: TaskPlanManager(
            taskPlanRepository: SwiftDataTaskPlanRepository(),
            taskPlanService: TaskPlanService(apiKey: ""), // TODO: Get from config
            aiErrorHandler: AIServiceErrorHandler()
        ))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header Section
                headerSection
                
                // Task List
                taskListSection
            }
            .navigationTitle("编辑任务计划")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        if hasChanges {
                            showingDiscardAlert = true
                        } else {
                            dismiss()
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        Task {
                            await saveChanges()
                        }
                    }
                    .disabled(!hasChanges || isSaving)
                }
            }
            .sheet(isPresented: $isShowingAddTaskSheet) {
                AddTaskView { newTask in
                    addTask(newTask)
                }
            }
            .sheet(item: $editingTask) { task in
                TaskItemEditView(task: task) { updatedTask in
                    updateTask(updatedTask)
                }
            }
            .alert("放弃更改", isPresented: $showingDiscardAlert) {
                Button("取消", role: .cancel) { }
                Button("放弃", role: .destructive) {
                    dismiss()
                }
            } message: {
                Text("您有未保存的更改，确定要放弃吗？")
            }
        }
    }
    
    // MARK: - Header Section
    
    @ViewBuilder
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Plan Overview
            VStack(alignment: .leading, spacing: 8) {
                Text("任务计划概览")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                HStack {
                    TextField("预计总时长", text: $totalDuration)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: totalDuration) { _ in
                            hasChanges = true
                        }
                    
                    Button(action: {
                        isShowingAddTaskSheet = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                            Text("添加任务")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                }
            }
            
            // Statistics
            HStack(spacing: 20) {
                StatisticItem(
                    title: "总任务",
                    value: "\(tasks.count)",
                    icon: "list.bullet",
                    color: .blue
                )
                
                StatisticItem(
                    title: "预估时长",
                    value: formatTotalDuration(),
                    icon: "clock.fill",
                    color: .orange
                )
                
                StatisticItem(
                    title: "平均时长",
                    value: formatAverageDuration(),
                    icon: "chart.bar.fill",
                    color: .green
                )
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    // MARK: - Task List Section
    
    @ViewBuilder
    private var taskListSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section Header
            HStack {
                Text("任务列表")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("长按拖拽重排序")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Task List
            if tasks.isEmpty {
                emptyTaskListView
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(tasks, id: \.id) { task in
                            EditableTaskRowView(
                                task: task,
                                onEdit: {
                                    editingTask = task
                                },
                                onDelete: {
                                    deleteTask(task)
                                }
                            )
                            .onDrag {
                                draggedTask = task
                                return NSItemProvider(object: task.id.uuidString as NSString)
                            }
                            .onDrop(of: [.text], delegate: TaskDropDelegate(
                                task: task,
                                tasks: $tasks,
                                draggedTask: $draggedTask,
                                onReorder: {
                                    hasChanges = true
                                    updateTaskOrder()
                                }
                            ))
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    @ViewBuilder
    private var emptyTaskListView: some View {
        VStack(spacing: 20) {
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("暂无任务")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("点击上方\"添加任务\"按钮开始创建任务")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                isShowingAddTaskSheet = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                    Text("添加第一个任务")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.blue)
                .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Helper Methods
    
    private func addTask(_ task: TaskItem) {
        task.orderIndex = tasks.count
        tasks.append(task)
        hasChanges = true
    }
    
    private func updateTask(_ task: TaskItem) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
            hasChanges = true
        }
    }
    
    private func deleteTask(_ task: TaskItem) {
        tasks.removeAll { $0.id == task.id }
        updateTaskOrder()
        hasChanges = true
    }
    
    private func updateTaskOrder() {
        for (index, task) in tasks.enumerated() {
            task.orderIndex = index
        }
    }
    
    private func saveChanges() async {
        isSaving = true
        defer { isSaving = false }
        
        do {
            // Update task plan properties
            taskPlan.totalDuration = totalDuration
            taskPlan.lastModifiedAt = Date()
            
            // Update task plan with new tasks
            try await taskPlanManager.updateTaskPlan(taskPlan, totalDuration: totalDuration)
            
            // Reorder tasks if needed
            if tasks != taskPlan.orderedTasks {
                try await taskPlanManager.reorderTaskItems(tasks, in: taskPlan)
            }
            
            onSave(taskPlan)
            dismiss()
            
        } catch {
            print("Failed to save task plan: \(error)")
        }
    }
    
    private func formatTotalDuration() -> String {
        let totalMinutes = tasks.reduce(0) { $0 + $1.estimatedDuration }
        return formatDuration(totalMinutes)
    }
    
    private func formatAverageDuration() -> String {
        guard !tasks.isEmpty else { return "0分钟" }
        let averageMinutes = tasks.reduce(0) { $0 + $1.estimatedDuration } / tasks.count
        return formatDuration(averageMinutes)
    }
    
    private func formatDuration(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)分钟"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours)小时"
            } else {
                return "\(hours)小时\(remainingMinutes)分钟"
            }
        }
    }
}

// MARK: - Supporting Views

/// Statistic item for the header section
struct StatisticItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(color)
                
                Text(value)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
}

/// Editable task row with edit and delete actions
struct EditableTaskRowView: View {
    let task: TaskItem
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Drag Handle
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
            
            // Task Content
            VStack(alignment: .leading, spacing: 6) {
                Text(task.title)
                    .font(.system(size: 16, weight: .medium))
                    .lineLimit(2)
                
                if !task.taskDescription.isEmpty {
                    Text(task.taskDescription)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                // Task Metadata
                HStack(spacing: 12) {
                    // Time Scope
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
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                        Text(task.formattedDuration)
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
            
            // Action Buttons
            HStack(spacing: 8) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                        .frame(width: 32, height: 32)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .frame(width: 32, height: 32)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
}

/// Add new task view
struct AddTaskView: View {
    let onAdd: (TaskItem) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var timeScope: TaskTimeScope = .daily
    @State private var estimatedDuration = 60
    @State private var executionTips = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("基本信息") {
                    TextField("任务标题", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("任务描述", text: $description, axis: .vertical)
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
            .navigationTitle("添加任务")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("添加") {
                        addTask()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func addTask() {
        let newTask = TaskItem(
            title: title,
            taskDescription: description,
            estimatedDuration: estimatedDuration,
            timeScope: timeScope,
            isAIGenerated: false,
            orderIndex: 0, // Will be set by parent
            executionTips: executionTips.isEmpty ? nil : executionTips
        )
        
        onAdd(newTask)
        dismiss()
    }
}

// MARK: - Drag and Drop Support

/// Drop delegate for task reordering
struct TaskDropDelegate: DropDelegate {
    let task: TaskItem
    @Binding var tasks: [TaskItem]
    @Binding var draggedTask: TaskItem?
    let onReorder: () -> Void
    
    func performDrop(info: DropInfo) -> Bool {
        guard let draggedTask = draggedTask else { return false }
        
        if draggedTask.id != task.id {
            let fromIndex = tasks.firstIndex { $0.id == draggedTask.id } ?? 0
            let toIndex = tasks.firstIndex { $0.id == task.id } ?? 0
            
            withAnimation(.default) {
                tasks.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
                onReorder()
            }
        }
        
        self.draggedTask = nil
        return true
    }
    
    func dropEntered(info: DropInfo) {
        guard let draggedTask = draggedTask else { return }
        
        if draggedTask.id != task.id {
            let fromIndex = tasks.firstIndex { $0.id == draggedTask.id } ?? 0
            let toIndex = tasks.firstIndex { $0.id == task.id } ?? 0
            
            if fromIndex != toIndex {
                withAnimation(.default) {
                    tasks.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
                }
            }
        }
    }
}

// MARK: - Extensions



#Preview {
    let sampleTaskPlan = TaskPlan(
        branchId: UUID(),
        totalDuration: "4-6周",
        isAIGenerated: true
    )
    
    TaskPlanEditView(taskPlan: sampleTaskPlan) { updatedPlan in
        print("Task plan updated")
    }
}