import Foundation
import SwiftData

@MainActor
class DataManager: ObservableObject {
    static let shared = DataManager()
    
    private(set) var modelContainer: ModelContainer
    private(set) var modelContext: ModelContext
    
    private init() {
        do {
            // 配置SwiftData模型容器
            let schema = LifeGitModelConfiguration.createSchema()
            let modelConfiguration = LifeGitModelConfiguration.createModelConfiguration()
            
            self.modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            
            self.modelContext = modelContainer.mainContext
            
            // 检查数据迁移
            handleDataMigration()
            
            // 初始化默认数据
            Task {
                await initializeDefaultData()
            }
            
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    // 初始化默认数据
    private func initializeDefaultData() async {
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
                    description: "人生主干分支",
                    status: .active,
                    isMaster: true
                )
                masterBranch.user = defaultUser
                modelContext.insert(masterBranch)
                
                // 保存初始数据
                try modelContext.save()
                
                print("✅ 初始化默认数据完成")
            }
        } catch {
            print("❌ 初始化默认数据失败: \(error)")
        }
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
                    description: "人生主干分支",
                    status: .active,
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
    
    // 数据迁移处理
    func handleDataMigration() {
        let migrationService = DataMigrationService.shared
        
        if migrationService.checkForMigration() {
            Task {
                do {
                    try await migrationService.performMigration(modelContext: modelContext)
                } catch {
                    print("❌ 数据迁移失败: \(error)")
                }
            }
        } else {
            print("📦 数据迁移检查完成 - 无需迁移")
        }
    }
}