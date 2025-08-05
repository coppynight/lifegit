import SwiftUI

/// Display view for task plans with interactive task items
struct TaskPlanDisplayView: View {
    let taskPlan: TaskPlan
    @State private var expandedSections: Set<TaskTimeScope> = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Task plan header
            taskPlanHeaderView
            
            // Task sections
            LazyVStack(spacing: 12) {
                ForEach(Array(groupedTasks.keys).sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { scope in
                    if let scopeTasks = groupedTasks[scope], !scopeTasks.isEmpty {
                        TaskSectionView(
                            scope: scope,
                            tasks: scopeTasks,
                            isExpanded: expandedSections.contains(scope),
                            onToggleExpansion: {
                                toggleSection(scope)
                            },
                            onTaskToggle: { task in
                                // TODO: Implement task toggle functionality
                            }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Task Plan Header
    
    private var taskPlanHeaderView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI任务计划")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("由AI生成的详细任务分解")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    // TODO: Regenerate task plan
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                }
            }
            
            // Task plan statistics
            HStack(spacing: 20) {
                StatItem(
                    title: "总任务",
                    value: "\(taskPlan.tasks.count)",
                    icon: "list.bullet",
                    color: .blue
                )
                
                StatItem(
                    title: "已完成",
                    value: "\(completedTasksCount)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                StatItem(
                    title: "预计时长",
                    value: taskPlan.totalDuration,
                    icon: "clock.fill",
                    color: .orange
                )
                
                Spacer()
            }
            
            // Progress bar
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("完成进度")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(Int(completionProgress * 100))%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                
                ProgressView(value: completionProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .scaleEffect(y: 1.5)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    
    private func toggleSection(_ scope: TaskTimeScope) {
        if expandedSections.contains(scope) {
            expandedSections.remove(scope)
        } else {
            expandedSections.insert(scope)
        }
    }
    
    // MARK: - Computed Properties
    
    private var groupedTasks: [TaskTimeScope: [TaskItem]] {
        Dictionary(grouping: taskPlan.tasks) { $0.timeScope }
    }
    
    private var completedTasksCount: Int {
        taskPlan.tasks.filter { $0.isCompleted }.count
    }
    
    private var completionProgress: Double {
        guard !taskPlan.tasks.isEmpty else { return 0 }
        return Double(completedTasksCount) / Double(taskPlan.tasks.count)
    }
}



/// Small statistic item
struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)
                
                Text(value)
                    .font(.system(size: 14, weight: .semibold))
            }
            
            Text(title)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
    }
}



#Preview {
    let sampleTaskPlan = TaskPlan(
        branchId: UUID(),
        totalDuration: "4-6周"
    )
    
    ScrollView {
        TaskPlanDisplayView(taskPlan: sampleTaskPlan)
            .padding()
    }
}