import SwiftUI

struct StatisticsPlaceholderView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                
                Text("统计功能")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("详细的统计分析功能正在开发中，敬请期待！")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationTitle("统计")
        }
    }
}

#Preview {
    StatisticsPlaceholderView()
}