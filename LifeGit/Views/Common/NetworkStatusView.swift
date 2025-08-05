import SwiftUI

/// Network status indicator view for better user awareness
struct NetworkStatusView: View {
    @EnvironmentObject private var networkManager: NetworkStatusManager
    @State private var showingDetails = false
    @State private var animateIcon = false
    
    var body: some View {
        Group {
            if !networkManager.isConnected {
                // Offline indicator
                HStack(spacing: 8) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .scaleEffect(animateIcon ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: animateIcon)
                    
                    Text("离线模式")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button("详情") {
                        showingDetails = true
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.orange)
                .cornerRadius(8)
                .onAppear {
                    animateIcon = true
                }
                .onTapGesture {
                    showingDetails = true
                }
            } else if networkManager.isExpensive {
                // Expensive network warning
                HStack(spacing: 8) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text("使用移动数据")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button("设置") {
                        showingDetails = true
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.blue)
                .cornerRadius(8)
                .onTapGesture {
                    showingDetails = true
                }
            }
        }
        .sheet(isPresented: $showingDetails) {
            NetworkStatusDetailView()
                .environmentObject(networkManager)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }
}

/// Detailed network status view
struct NetworkStatusDetailView: View {
    @EnvironmentObject private var networkManager: NetworkStatusManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Status icon and title
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(statusColor.opacity(0.1))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: statusIcon)
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(statusColor)
                    }
                    
                    VStack(spacing: 8) {
                        Text(statusTitle)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(statusDescription)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                // Network details
                VStack(spacing: 16) {
                    NetworkDetailRow(
                        icon: "wifi",
                        title: "网络连接",
                        value: networkManager.isConnected ? "已连接" : "未连接",
                        color: networkManager.isConnected ? .green : .red
                    )
                    
                    if networkManager.isConnected {
                        NetworkDetailRow(
                            icon: "antenna.radiowaves.left.and.right",
                            title: "连接类型",
                            value: networkManager.isExpensive ? "移动数据" : "WiFi",
                            color: networkManager.isExpensive ? .orange : .blue
                        )
                        
                        NetworkDetailRow(
                            icon: "speedometer",
                            title: "网络质量",
                            value: networkQualityText,
                            color: networkQualityColor
                        )
                    }
                }
                .padding(20)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Recommendations
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "lightbulb")
                            .foregroundColor(.orange)
                        Text("建议")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(recommendations, id: \.self) { recommendation in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                    .padding(.top, 2)
                                
                                Text(recommendation)
                                    .font(.callout)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                        }
                    }
                }
                .padding(20)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding(24)
            .navigationTitle("网络状态")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var statusIcon: String {
        if !networkManager.isConnected {
            return "wifi.slash"
        } else if networkManager.isExpensive {
            return "antenna.radiowaves.left.and.right"
        } else {
            return "wifi"
        }
    }
    
    private var statusColor: Color {
        if !networkManager.isConnected {
            return .red
        } else if networkManager.isExpensive {
            return .orange
        } else {
            return .green
        }
    }
    
    private var statusTitle: String {
        if !networkManager.isConnected {
            return "网络未连接"
        } else if networkManager.isExpensive {
            return "使用移动数据"
        } else {
            return "网络连接正常"
        }
    }
    
    private var statusDescription: String {
        if !networkManager.isConnected {
            return "当前设备未连接到网络，AI功能将不可用"
        } else if networkManager.isExpensive {
            return "正在使用移动数据，AI功能可能产生流量费用"
        } else {
            return "网络连接稳定，所有功能正常可用"
        }
    }
    
    private var networkQualityText: String {
        // This would be based on actual network quality metrics
        if networkManager.isConnected {
            return networkManager.isExpensive ? "良好" : "优秀"
        } else {
            return "无连接"
        }
    }
    
    private var networkQualityColor: Color {
        if networkManager.isConnected {
            return networkManager.isExpensive ? .orange : .green
        } else {
            return .red
        }
    }
    
    private var recommendations: [String] {
        if !networkManager.isConnected {
            return [
                "检查WiFi连接或移动数据设置",
                "尝试重新连接网络",
                "您仍可以手动创建和管理任务",
                "网络恢复后AI功能将自动可用"
            ]
        } else if networkManager.isExpensive {
            return [
                "连接WiFi以节省流量费用",
                "在设置中可关闭移动数据下的AI功能",
                "当前可正常使用所有功能",
                "建议在WiFi环境下使用AI功能"
            ]
        } else {
            return [
                "网络连接良好，可正常使用所有功能",
                "AI任务生成响应速度较快",
                "数据同步和备份正常工作",
                "享受完整的应用体验"
            ]
        }
    }
}

/// Network detail row component
struct NetworkDetailRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

/*
#Preview {
    VStack(spacing: 20) {
        NetworkStatusView()
        NetworkStatusView()
    }
    .padding()
}
*/