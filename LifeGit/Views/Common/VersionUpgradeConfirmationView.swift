import SwiftUI

struct VersionUpgradeConfirmationView: View {
    let pendingUpgrade: PendingVersionUpgrade
    let onConfirm: () async -> Void
    let onDecline: () -> Void
    
    @State private var isConfirming = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    // Version upgrade icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: pendingUpgrade.isImportantMilestone 
                                        ? [.purple, .pink] 
                                        : [.blue, .cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: pendingUpgrade.isImportantMilestone ? "star.fill" : "arrow.up.circle.fill")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .scaleEffect(1.0)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: true)
                    
                    VStack(spacing: 8) {
                        Text(pendingUpgrade.isImportantMilestone ? "🎉 重要里程碑达成!" : "🎯 目标完成!")
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text("恭喜完成目标「\(pendingUpgrade.branch.name)」")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                // Version upgrade info
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("当前版本")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(pendingUpgrade.currentVersion)
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "arrow.right")
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("升级版本")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(pendingUpgrade.suggestedVersion)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(pendingUpgrade.isImportantMilestone ? .purple : .blue)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Upgrade reason
                    VStack(alignment: .leading, spacing: 8) {
                        Text("升级原因")
                            .font(.headline)
                        
                        Text(pendingUpgrade.reason)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    
                    // Milestone badge
                    if pendingUpgrade.isImportantMilestone {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text("重要里程碑")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.yellow.opacity(0.1))
                                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 12) {
                    Button(action: {
                        Task {
                            isConfirming = true
                            await onConfirm()
                            isConfirming = false
                            dismiss()
                        }
                    }) {
                        HStack {
                            if isConfirming {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                            }
                            Text(isConfirming ? "升级中..." : "确认升级")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: pendingUpgrade.isImportantMilestone 
                                    ? [.purple, .pink] 
                                    : [.blue, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                    .disabled(isConfirming)
                    
                    Button(action: {
                        onDecline()
                        dismiss()
                    }) {
                        Text("暂不升级")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .disabled(isConfirming)
                }
            }
            .padding()
            .navigationTitle("版本升级")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
        }
    }
}

// MARK: - Preview

#Preview {
    let sampleBranch = Branch(
        name: "学习SwiftUI",
        branchDescription: "掌握SwiftUI开发技能",
        status: .completed,
        isMaster: false
    )
    
    let pendingUpgrade = PendingVersionUpgrade(
        branch: sampleBranch,
        currentVersion: "v1.2",
        suggestedVersion: "v2.0",
        reason: "高频率记录 (15 次提交)、长期坚持 (21 天)、高完成度 (90%)、重要人生领域",
        isImportantMilestone: true
    )
    
    VersionUpgradeConfirmationView(
        pendingUpgrade: pendingUpgrade,
        onConfirm: {
            print("Confirmed upgrade")
        },
        onDecline: {
            print("Declined upgrade")
        }
    )
}