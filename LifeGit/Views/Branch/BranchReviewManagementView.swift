import SwiftUI
import SwiftData

/// View for managing branch review generation and display
struct BranchReviewManagementView: View {
    let branch: Branch
    @StateObject private var reviewService: BranchReviewService
    @State private var showingReviewDetail = false
    @State private var showingGenerateOptions = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    init(branch: Branch, reviewService: BranchReviewService) {
        self.branch = branch
        self._reviewService = StateObject(wrappedValue: reviewService)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                Text("复盘报告")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if branch.review == nil {
                    generateButton
                } else {
                    HStack(spacing: 8) {
                        regenerateButton
                        deleteButton
                    }
                }
            }
            
            // Content
            if let review = branch.review {
                // Existing review
                BranchReviewCard(review: review) {
                    showingReviewDetail = true
                }
            } else {
                // No review placeholder
                noReviewPlaceholder
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .sheet(isPresented: $showingReviewDetail) {
            if let review = branch.review {
                BranchReviewView(review: review)
            }
        }
        .actionSheet(isPresented: $showingGenerateOptions) {
            generateOptionsActionSheet
        }
        .alert("错误", isPresented: $showingError) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .onReceive(reviewService.$lastError) { error in
            if let error = error {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
    
    // MARK: - Buttons
    
    private var generateButton: some View {
        Button(action: {
            if branch.status == .completed || branch.status == .abandoned {
                showingGenerateOptions = true
            } else {
                generateReview(type: .completion)
            }
        }) {
            HStack(spacing: 4) {
                if reviewService.isGeneratingReview {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "sparkles")
                }
                Text(reviewService.isGeneratingReview ? "生成中..." : "生成复盘")
            }
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .disabled(reviewService.isGeneratingReview)
    }
    
    private var regenerateButton: some View {
        Button(action: {
            Task {
                do {
                    _ = try await reviewService.regenerateReview(for: branch)
                } catch {
                    // Error handled by service
                }
            }
        }) {
            HStack(spacing: 4) {
                if reviewService.isGeneratingReview {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "arrow.clockwise")
                }
                Text(reviewService.isGeneratingReview ? "重新生成中..." : "重新生成")
            }
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .disabled(reviewService.isGeneratingReview)
    }
    
    private var deleteButton: some View {
        Button(action: {
            do {
                try reviewService.deleteReview(for: branch)
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }) {
            Image(systemName: "trash")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color.red.opacity(0.1))
                .foregroundColor(.red)
                .cornerRadius(8)
        }
    }
    
    // MARK: - Placeholder
    
    private var noReviewPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            Text("暂无复盘报告")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("完成或废弃目标后，可以生成AI复盘报告来总结经验和教训")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Action Sheet
    
    private var generateOptionsActionSheet: ActionSheet {
        ActionSheet(
            title: Text("选择复盘类型"),
            message: Text("请选择要生成的复盘报告类型"),
            buttons: [
                .default(Text("完成复盘 ✅")) {
                    generateReview(type: .completion)
                },
                .default(Text("废弃复盘 ❌")) {
                    generateReview(type: .abandonment)
                },
                .cancel(Text("取消"))
            ]
        )
    }
    
    // MARK: - Helper Methods
    
    private func generateReview(type: ReviewType) {
        Task {
            do {
                _ = try await reviewService.generateReview(for: branch, reviewType: type)
            } catch {
                // Error handled by service
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let branch = Branch(
        name: "学习SwiftUI",
        branchDescription: "深入学习SwiftUI框架，掌握现代iOS开发技能",
        status: .completed
    )
    
    // Mock review service
    let mockService = BranchReviewService(
        deepseekClient: DeepseekR1Client(apiKey: "mock"),
        modelContext: ModelContext(try! ModelContainer(for: Branch.self, BranchReview.self))
    )
    
    VStack {
        BranchReviewManagementView(branch: branch, reviewService: mockService)
        Spacer()
    }
    .padding()
    .background(Color(.systemGray6))
}