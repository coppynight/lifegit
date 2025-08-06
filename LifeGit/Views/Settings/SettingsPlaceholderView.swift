import SwiftUI

struct SettingsPlaceholderView: View {
    @State private var showingHomepagePreferences = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    NavigationLink(destination: HomepagePreferencesView()) {
                        SettingsRow(
                            icon: "house.circle",
                            title: "首页偏好设置",
                            subtitle: "自定义应用启动时显示的内容",
                            iconColor: .blue
                        )
                    }
                } header: {
                    Text("显示设置")
                }
                
                Section {
                    SettingsRow(
                        icon: "bell.circle",
                        title: "通知设置",
                        subtitle: "管理提醒和通知偏好",
                        iconColor: .orange
                    )
                    
                    SettingsRow(
                        icon: "icloud.circle",
                        title: "数据同步",
                        subtitle: "iCloud 同步设置（即将推出）",
                        iconColor: .cyan,
                        isDisabled: true
                    )
                } header: {
                    Text("数据设置")
                }
                
                Section {
                    SettingsRow(
                        icon: "brain.head.profile",
                        title: "AI 助手设置",
                        subtitle: "配置 AI 任务拆解偏好",
                        iconColor: .purple
                    )
                    
                    SettingsRow(
                        icon: "chart.line.uptrend.xyaxis.circle",
                        title: "统计偏好",
                        subtitle: "自定义统计显示内容",
                        iconColor: .green
                    )
                } header: {
                    Text("功能设置")
                }
                
                Section {
                    SettingsRow(
                        icon: "questionmark.circle",
                        title: "帮助与支持",
                        subtitle: "使用指南和常见问题",
                        iconColor: .gray
                    )
                    
                    SettingsRow(
                        icon: "info.circle",
                        title: "关于人生Git",
                        subtitle: "版本信息和开发团队",
                        iconColor: .gray
                    )
                } header: {
                    Text("帮助")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("人生Git v1.0")
                            .font(.headline)
                        
                        Text("将Git版本控制的概念应用到人生目标管理中，让每个目标都成为独立的分支，系统化地管理和追踪您的人生进展。")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("设置")
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let iconColor: Color
    var isDisabled: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isDisabled ? .gray : iconColor)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(isDisabled ? .gray : .primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            if isDisabled {
                Text("即将推出")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
            } else {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .opacity(isDisabled ? 0.6 : 1.0)
    }
}

#Preview {
    SettingsPlaceholderView()
}