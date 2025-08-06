import SwiftUI

struct MasterBranchView: View {
    @EnvironmentObject private var appState: AppStateManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "tree.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    
                    Text("人生主线")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("记录您的人生历程和成就")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Stats
                HStack(spacing: 20) {
                    MasterStatCard(
                        title: "完成目标",
                        value: "\(appState.completedBranches.count)",
                        icon: "checkmark.circle.fill",
                        color: .green
                    )
                    
                    MasterStatCard(
                        title: "活跃分支",
                        value: "\(appState.activeBranches.count)",
                        icon: "circle.fill",
                        color: .blue
                    )
                    
                    MasterStatCard(
                        title: "总分支",
                        value: "\(appState.branches.count - 1)", // Exclude master
                        icon: "tree.fill",
                        color: .orange
                    )
                }
                .padding(.horizontal)
                
                // Recent activity placeholder
                VStack(alignment: .leading, spacing: 12) {
                    Text("最近活动")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Text("暂无活动记录")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                
                Spacer()
            }
        }
        .background(Color(.systemBackground))
    }
}

struct MasterStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    MasterBranchView()
        .environmentObject(AppStateManager())
}