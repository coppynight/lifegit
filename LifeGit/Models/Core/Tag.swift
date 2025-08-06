import Foundation
import SwiftData

@Model
class Tag {
    @Attribute(.unique) var id: UUID
    var title: String
    var tagDescription: String
    var type: TagType
    var createdAt: Date
    var associatedVersion: String? // 关联的版本号
    var isImportant: Bool // 是否为重要标签
    
    // 关联关系
    @Relationship(inverse: \User.tags) var user: User?
    
    init(id: UUID = UUID(),
         title: String,
         tagDescription: String = "",
         type: TagType,
         createdAt: Date = Date(),
         associatedVersion: String? = nil,
         isImportant: Bool = false) {
        self.id = id
        self.title = title
        self.tagDescription = tagDescription
        self.type = type
        self.createdAt = createdAt
        self.associatedVersion = associatedVersion
        self.isImportant = isImportant
    }
    
    // 计算属性
    var displayTitle: String {
        return "\(type.emoji) \(title)"
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: createdAt)
    }
    
    // 是否与版本升级关联
    var isVersionAssociated: Bool {
        return associatedVersion != nil
    }
}