import Foundation
import SwiftData

class DataMigrationService {
    static let shared = DataMigrationService()
    
    private let currentSchemaVersion = "1.0.0"
    private let schemaVersionKey = "LifeGitSchemaVersion"
    
    private init() {}
    
    // 检查是否需要数据迁移
    func checkForMigration() -> Bool {
        let savedVersion = UserDefaults.standard.string(forKey: schemaVersionKey)
        
        if savedVersion == nil {
            // 首次启动，设置当前版本
            UserDefaults.standard.set(currentSchemaVersion, forKey: schemaVersionKey)
            return false
        }
        
        return savedVersion != currentSchemaVersion
    }
    
    // 执行数据迁移
    func performMigration(modelContext: ModelContext) async throws {
        let savedVersion = UserDefaults.standard.string(forKey: schemaVersionKey) ?? "0.0.0"
        
        print("🔄 开始数据迁移: \(savedVersion) -> \(currentSchemaVersion)")
        
        // 根据版本执行相应的迁移策略
        switch savedVersion {
        case "0.0.0":
            // 从无版本迁移到1.0.0
            try await migrateToV1_0_0(modelContext: modelContext)
        default:
            print("⚠️ 未知的数据版本: \(savedVersion)")
        }
        
        // 更新版本号
        UserDefaults.standard.set(currentSchemaVersion, forKey: schemaVersionKey)
        print("✅ 数据迁移完成")
    }
    
    // 迁移到版本1.0.0
    private func migrateToV1_0_0(modelContext: ModelContext) async throws {
        // MVP版本的基础迁移
        // 确保所有必要的默认数据存在
        
        // 检查用户数据
        let userDescriptor = FetchDescriptor<User>()
        let users = try modelContext.fetch(userDescriptor)
        
        if users.isEmpty {
            let defaultUser = User()
            modelContext.insert(defaultUser)
        }
        
        // 检查主干分支
        let masterDescriptor = FetchDescriptor<Branch>(
            predicate: #Predicate { $0.isMaster == true }
        )
        let masterBranches = try modelContext.fetch(masterDescriptor)
        
        if masterBranches.isEmpty {
            let user = try modelContext.fetch(userDescriptor).first!
            let masterBranch = Branch(
                name: "master",
                description: "人生主干分支",
                status: .active,
                isMaster: true
            )
            masterBranch.user = user
            modelContext.insert(masterBranch)
        }
        
        try modelContext.save()
    }
    
    // 备份数据（为未来版本准备）
    func backupData() throws {
        // 在实际迁移前备份数据
        // MVP版本暂时不实现复杂的备份逻辑
        print("📦 数据备份完成（MVP版本跳过）")
    }
    
    // 恢复数据（为未来版本准备）
    func restoreData() throws {
        // 从备份恢复数据
        // MVP版本暂时不实现
        print("📦 数据恢复完成（MVP版本跳过）")
    }
}