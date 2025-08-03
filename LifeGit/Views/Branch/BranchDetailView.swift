import SwiftUI
import SwiftData

struct BranchDetailView: View {
    let branch: Branch
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 分支信息头部
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(branch.status.emoji)
                            .font(.title)
                        Text(branch.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                    
                    Text(branch.branchDescription)
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    // 进度条
                    ProgressView(value: branch.progress)
                        .progressViewStyle(LinearProgressViewStyle())
                    
                    Text("进度: \(Int(branch.progress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // 任务计划区域
                VStack(alignment: .leading, spacing: 12) {
                    Text("任务计划")
                        .font(.headline)
                    
                    if let taskPlan = branch.taskPlan {
                        Text("总时长: \(taskPlan.totalDuration)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("任务数量: \(taskPlan.tasks.count)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("暂无任务计划")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Button("生成AI任务计划") {
                            // TODO: 生成任务计划
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // 提交历史
                VStack(alignment: .leading, spacing: 12) {
                    Text("提交历史")
                        .font(.headline)
                    
                    if branch.commits.isEmpty {
                        Text("暂无提交记录")
                            .font(.body)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(branch.commits.sorted { $0.timestamp > $1.timestamp }.prefix(5)) { commit in
                            HStack {
                                Text(commit.type.emoji)
                                VStack(alignment: .leading) {
                                    Text(commit.message)
                                        .font(.body)
                                    Text(commit.timestamp.formatted(.relative(presentation: .named)))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding()
        }
        .navigationTitle(branch.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("提交") {
                    // TODO: 创建新提交
                }
            }
        }
    }
}

#Preview {
    let branch = Branch(name: "学习Swift", branchDescription: "掌握Swift编程语言")
    
    NavigationStack {
        BranchDetailView(branch: branch)
    }
    .modelContainer(for: [User.self, Branch.self, Commit.self, TaskPlan.self, TaskItem.self])
}