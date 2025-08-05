import SwiftUI

/// Placeholder view for statistics tab
struct StatisticsPlaceholderView: View {
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: "chart.bar")
                .font(.system(size: 64, weight: .light))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("统计功能")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("即将推出")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Text("这里将显示你的目标完成情况、时间分布等统计信息")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .navigationTitle("统计")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationView {
        StatisticsPlaceholderView()
    }
}