import Foundation
import SwiftData

@MainActor
class DataManager: ObservableObject {
    static let shared = DataManager()
    
    private(set) var modelContainer: ModelContainer
    private(set) var modelContext: ModelContext
    
    // Lazy initialization flags
    private var isDefaultDataInitialized = false
    private var isMigrationChecked = false
    
    private init() {
        do {
            // 配置SwiftData模型容器 - 只做必要的同步初始化
            let schema = LifeGitModelConfiguration.createSchema()
            let modelConfiguration = LifeGitModelConfiguration.createModelConfiguration()
            
            self.modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            
            self.modelContext = modelContainer.mainContext
            
            // 延迟初始化非关键组件
            Task.detached(priority: .background) {
                await self.performBackgroundInitialization()
            }
            
        } catch {
            // 如果是迁移错误，尝试删除旧数据库重新开始
            if let nsError = error as NSError?, nsError.code == 134110 {
                print("⚠️ 检测到数据库迁移错误，正在重置数据库...")
                do {
                    try DataManager.resetDatabaseFiles()
                    
                    // 重新创建ModelContainer
                    let schema = LifeGitModelConfiguration.createSchema()
                    let modelConfiguration = LifeGitModelConfiguration.createModelConfiguration()
                    
                    self.modelContainer = try ModelContainer(
                        for: schema,
                        configurations: [modelConfiguration]
                    )
                    
                    self.modelContext = modelContainer.mainContext
                    
                    print("✅ 数据库重置成功")
                    
                    // 延迟初始化非关键组件
                    Task.detached(priority: .background) {
                        await self.performBackgroundInitialization()
                    }
                    
                } catch {
                    fatalError("Failed to reset and recreate ModelContainer: \(error)")
                }
            } else {
                fatalError("Failed to create ModelContainer: \(error)")
            }
        }
    }
    
    /// 后台执行非关键初始化任务
    private func performBackgroundInitialization() async {
        // 检查数据迁移
        await handleDataMigrationAsync()
        
        // 初始化默认数据
        await initializeDefaultDataAsync()
    }
    
    // 异步初始化默认数据
    private func initializeDefaultDataAsync() async {
        guard !isDefaultDataInitialized else { return }
        
        await MainActor.run {
            Task {
                do {
                    // 检查是否已有用户数据
                    let userDescriptor = FetchDescriptor<User>()
                    let existingUsers = try modelContext.fetch(userDescriptor)
                    
                    if existingUsers.isEmpty {
                        // 创建默认用户
                        let defaultUser = User()
                        modelContext.insert(defaultUser)
                        
                        // 创建主干分支
                        let masterBranch = Branch(
                            name: "master",
                            branchDescription: "人生主干分支",
                            status: .master,
                            isMaster: true
                        )
                        masterBranch.user = defaultUser
                        modelContext.insert(masterBranch)
                        
                        // 保存初始数据
                        try modelContext.save()
                        
                        print("✅ 初始化默认数据完成")
                    }
                    
                    isDefaultDataInitialized = true
                } catch {
                    print("❌ 初始化默认数据失败: \(error)")
                }
            }
        }
    }
    
    // 同步获取默认数据（用于启动时的关键路径）
    func ensureDefaultDataSync() throws {
        guard !isDefaultDataInitialized else { return }
        
        // 检查是否已有用户数据
        let userDescriptor = FetchDescriptor<User>()
        let existingUsers = try modelContext.fetch(userDescriptor)
        
        if existingUsers.isEmpty {
            // 创建默认用户
            let defaultUser = User()
            modelContext.insert(defaultUser)
            
            // 创建主干分支
            let masterBranch = Branch(
                name: "master",
                branchDescription: "人生主干分支",
                status: .active,
                isMaster: true
            )
            masterBranch.user = defaultUser
            modelContext.insert(masterBranch)
            
            // 保存初始数据
            try modelContext.save()
        }
        
        isDefaultDataInitialized = true
    }
    
    // 获取默认用户
    func getDefaultUser() throws -> User {
        do {
            let descriptor = FetchDescriptor<User>()
            let users = try modelContext.fetch(descriptor)
            
            if let user = users.first {
                return user
            } else {
                // 如果没有用户，创建一个新的
                let newUser = User()
                modelContext.insert(newUser)
                try modelContext.save()
                return newUser
            }
        } catch {
            throw DataError.fetchFailure(underlying: error)
        }
    }
    
    // 获取主干分支
    func getMasterBranch() throws -> Branch {
        do {
            let descriptor = FetchDescriptor<Branch>(
                predicate: #Predicate { $0.isMaster == true }
            )
            let branches = try modelContext.fetch(descriptor)
            
            if let masterBranch = branches.first {
                return masterBranch
            } else {
                // 如果没有主干分支，创建一个
                let user = try getDefaultUser()
                let masterBranch = Branch(
                    name: "master",
                    branchDescription: "人生主干分支",
                    status: .master,
                    isMaster: true
                )
                masterBranch.user = user
                modelContext.insert(masterBranch)
                try modelContext.save()
                return masterBranch
            }
        } catch {
            if error is DataError {
                throw error
            } else {
                throw DataError.fetchFailure(underlying: error)
            }
        }
    }
    
    // 保存上下文
    func save() throws {
        do {
            if modelContext.hasChanges {
                try modelContext.save()
            }
        } catch {
            throw DataError.saveFailure(underlying: error)
        }
    }
    
    // 异步数据迁移处理
    private func handleDataMigrationAsync() async {
        guard !isMigrationChecked else { return }
        
        let migrationService = DataMigrationService.shared
        
        if migrationService.checkForMigration() {
            do {
                try await migrationService.performMigration(modelContext: modelContext)
            } catch {
                print("❌ 数据迁移失败: \(error)")
            }
        } else {
            print("📦 数据迁移检查完成 - 无需迁移")
        }
        
        isMigrationChecked = true
    }
    
    // 同步检查迁移（仅在必要时使用）
    func ensureMigrationCheckedSync() {
        guard !isMigrationChecked else { return }
        
        let migrationService = DataMigrationService.shared
        
        if migrationService.checkForMigration() {
            // 对于启动关键路径，只做检查，实际迁移在后台进行
            Task.detached(priority: .userInitiated) {
                do {
                    try await migrationService.performMigration(modelContext: self.modelContext)
                } catch {
                    print("❌ 数据迁移失败: \(error)")
                }
            }
        }
        
        isMigrationChecked = true
    }
    
    // 重置数据库（删除现有数据库文件）
    private static func resetDatabaseFiles() throws {
        let fileManager = FileManager.default
        
        // 获取应用支持目录
        guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, 
                                                  in: .userDomainMask).first else {
            throw DataError.resetFailure(reason: "无法获取应用支持目录")
        }
        
        // SwiftData默认数据库文件路径
        let databaseURL = appSupportURL.appendingPathComponent("default.store")
        let walURL = appSupportURL.appendingPathComponent("default.store-wal")
        let shmURL = appSupportURL.appendingPathComponent("default.store-shm")
        
        // 删除数据库文件
        let filesToDelete = [databaseURL, walURL, shmURL]
        
        for fileURL in filesToDelete {
            if fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.removeItem(at: fileURL)
                print("🗑️ 已删除数据库文件: \(fileURL.lastPathComponent)")
            }
        }
    }
}