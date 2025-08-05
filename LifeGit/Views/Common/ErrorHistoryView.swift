import SwiftUI

/// View for displaying error history and logs
struct ErrorHistoryView: View {
    @EnvironmentObject private var errorHandler: ErrorHandler
    
    var body: some View {
        NavigationView {
            List {
                if errorHandler.errorHistory.isEmpty {
                    ContentUnavailableView(
                        "无错误记录",
                        systemImage: "checkmark.circle",
                        description: Text("应用运行正常，没有错误记录")
                    )
                } else {
                    ForEach(errorHandler.errorHistory) { errorRecord in
                        ErrorHistoryRow(errorRecord: errorRecord)
                    }
                }
            }
            .navigationTitle("错误历史")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("清除") {
                        errorHandler.clearErrorHistory()
                    }
                    .disabled(errorHandler.errorHistory.isEmpty)
                }
            }
        }
    }
}

/// Individual error history row
struct ErrorHistoryRow: View {
    let errorRecord: ErrorRecord
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(errorRecord.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(errorRecord.timestamp.formatted(.dateTime.month().day().hour().minute()))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    if let message = errorRecord.message {
                        Text("详细信息:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(message)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.leading, 8)
                    }
                    
                    if let context = errorRecord.context {
                        Text("上下文:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(context)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.leading, 8)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
    }
}

/*
#Preview {
    ErrorHistoryView()
        .environmentObject(ErrorHandler.shared)
}
*/