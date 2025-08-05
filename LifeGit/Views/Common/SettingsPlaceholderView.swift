import SwiftUI

/// Placeholder view for settings tab
struct SettingsPlaceholderView: View {
    var body: some View {
        List {
            Section {
                VStack(spacing: 24) {
                    // Icon
                    Image(systemName: "gear")
                        .font(.system(size: 64, weight: .light))
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 8) {
                        Text("设置")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("即将推出")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("这里将提供应用设置、数据管理、主题选择等功能")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            }
            .listRowBackground(Color.clear)
            
            #if DEBUG
            Section("开发工具") {
                NavigationLink("调试工具") {
                    Text("调试工具")
                }
                
                NavigationLink("示例数据生成器") {
                    Text("示例数据生成器")
                }
            }
            #endif
        }
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationView {
        SettingsPlaceholderView()
    }
}