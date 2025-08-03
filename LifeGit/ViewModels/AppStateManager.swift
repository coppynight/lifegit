import Foundation
import SwiftUI
import SwiftData

@MainActor
class AppStateManager: ObservableObject {
    @Published var currentBranch: Branch?
    @Published var isShowingBranchList = false
    @Published var selectedCommitFilter: CommitType?
    
    private var modelContext: ModelContext?
    
    func initialize(modelContext: ModelContext) {
        self.modelContext = modelContext
        setupInitialData()
    }
    
    func switchToBranch(_ branch: Branch) {
        currentBranch = branch
        // 保存用户偏好
        UserDefaults.standard.set(branch.id.uuidString, forKey: "lastActiveBranch")
    }
    
    private func setupInitialData() {
        guard let modelContext = modelContext else { return }
        
        // 检查是否已有用户数据
        let userDescriptor = FetchDescriptor<User>()
        let users = try? modelContext.fetch(userDescriptor)
        
        if users?.isEmpty ?? true {
            // 创建初始用户和主干分支
            let user = User()
            let masterBranch = Branch(
                name: "master",
                branchDescription: "人生主干",
                status: .active
            )
            
            user.branches.append(masterBranch)
            masterBranch.user = user
            
            modelContext.insert(user)
            modelContext.insert(masterBranch)
            
            try? modelContext.save()
            
            currentBranch = masterBranch
        }
    }
    
    func getMasterBranch() -> Branch? {
        guard let modelContext = modelContext else { return nil }
        
        let branchDescriptor = FetchDescriptor<Branch>(
            predicate: #Predicate { $0.name == "master" }
        )
        
        return try? modelContext.fetch(branchDescriptor).first
    }
}