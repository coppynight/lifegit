import SwiftUI

struct ErrorHistoryView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                
                Text("错误日志")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("暂无错误记录")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationTitle("错误日志")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ErrorHistoryView()
}