import SwiftUI

struct CommitListRowView: View {
    let commit: Commit
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Text(commit.type.emoji)
                    .font(.title2)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(DesignSystem.Colors.tertiaryBackground)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(commit.message)
                        .font(.system(size: DesignSystem.Typography.body, weight: DesignSystem.Typography.medium))
                        .foregroundColor(DesignSystem.Colors.primaryText)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    HStack(spacing: 8) {
                        Text(commit.type.displayName)
                            .font(.system(size: DesignSystem.Typography.caption1, weight: DesignSystem.Typography.medium))
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        
                        Text("•")
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                        
                        Text(formatRelativeDate(commit.timestamp))
                            .font(.system(size: DesignSystem.Typography.caption1))
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.clear)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}