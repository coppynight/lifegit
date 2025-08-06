import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appState: AppStateManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 20) {
                Image(systemName: "tree")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("欢迎使用人生Git")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("将Git版本控制的概念应用到人生目标管理中")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            Button(action: {
                dismiss()
            }) {
                Text("开始使用")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 50)
        }
        .background(Color(.systemBackground))
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppStateManager())
}