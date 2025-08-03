import Foundation

enum DataError: LocalizedError {
    case userNotFound
    case masterBranchNotFound
    case branchNotFound(id: UUID)
    case taskPlanNotFound(id: UUID)
    case commitNotFound(id: UUID)
    case saveFailure(underlying: Error)
    case fetchFailure(underlying: Error)
    case migrationFailure(underlying: Error)
    case invalidData(reason: String)
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "未找到用户数据"
        case .masterBranchNotFound:
            return "未找到主干分支"
        case .branchNotFound(let id):
            return "未找到分支: \(id)"
        case .taskPlanNotFound(let id):
            return "未找到任务计划: \(id)"
        case .commitNotFound(let id):
            return "未找到提交记录: \(id)"
        case .saveFailure(let underlying):
            return "保存数据失败: \(underlying.localizedDescription)"
        case .fetchFailure(let underlying):
            return "获取数据失败: \(underlying.localizedDescription)"
        case .migrationFailure(let underlying):
            return "数据迁移失败: \(underlying.localizedDescription)"
        case .invalidData(let reason):
            return "数据无效: \(reason)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .userNotFound, .masterBranchNotFound:
            return "请尝试重新启动应用以初始化默认数据"
        case .saveFailure, .fetchFailure:
            return "请检查设备存储空间并重试"
        case .migrationFailure:
            return "请联系技术支持或重新安装应用"
        case .invalidData:
            return "请检查输入数据的格式和完整性"
        default:
            return "请重试操作，如问题持续存在请联系技术支持"
        }
    }
}