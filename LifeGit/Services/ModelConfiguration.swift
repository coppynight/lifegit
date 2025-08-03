import Foundation
import SwiftData

struct LifeGitModelConfiguration {
    
    // 创建SwiftData Schema
    static func createSchema() -> Schema {
        return Schema([
            User.self,
            Branch.self,
            Commit.self,
            TaskPlan.self,
            TaskItem.self
        ])
    }
    
    // 创建模型配置
    static func createModelConfiguration(isStoredInMemoryOnly: Bool = false) -> ModelConfiguration {
        let schema = createSchema()
        
        return ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: isStoredInMemoryOnly,
            allowsSave: true
        )
    }
    
    // 创建用于测试的内存配置
    static func createInMemoryConfiguration() -> ModelConfiguration {
        return createModelConfiguration(isStoredInMemoryOnly: true)
    }
    
    // 获取所有模型类型
    static var allModelTypes: [any PersistentModel.Type] {
        return [
            User.self,
            Branch.self,
            Commit.self,
            TaskPlan.self,
            TaskItem.self
        ]
    }
}