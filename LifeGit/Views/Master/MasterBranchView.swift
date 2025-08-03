import SwiftUI
import SwiftData

struct MasterBranchView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appState: AppStateManager
    
    var body: some View {
        VStack(spacing: 20) {
            // 标题
            HStack {
                Text("人生主干")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("v1.0")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            // 主要内容区域
            ScrollView {
                VStack(spacing: 16) {
                    // 欢迎信息
                    VStack(alignment: .leading, spacing: 8) {
                        Text("欢迎使用人生Git")
                            .font(.headline)
                        
                        Text("开始创建你的第一个目标分支，让AI帮你制定详细的任务计划。")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // 快速操作
                    Button(action: {
                        // TODO: 创建新分支
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("创建新目标")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .navigationTitle("主干")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        MasterBranchView()
            .environmentObject(AppStateManager())
    }
    .modelContainer(for: [User.self, Branch.self, Commit.self, TaskPlan.self, TaskItem.self])
}