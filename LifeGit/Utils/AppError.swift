import Foundation

// MARK: - Global App Error Types

/// Main application error enum that encompasses all error types
enum AppError: LocalizedError {
    case dataError(DataError)
    case aiServiceError(AIServiceError)
    case networkError(NetworkError)
    case validationError(ValidationError)
    case systemError(SystemError)
    
    var errorDescription: String? {
        switch self {
        case .dataError(let error):
            return error.errorDescription
        case .aiServiceError(let error):
            return error.errorDescription
        case .networkError(let error):
            return error.errorDescription
        case .validationError(let error):
            return error.errorDescription
        case .systemError(let error):
            return error.errorDescription
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .dataError(let error):
            return error.recoverySuggestion
        case .aiServiceError(let error):
            return error.recoverySuggestion
        case .networkError(let error):
            return error.recoverySuggestion
        case .validationError(let error):
            return error.recoverySuggestion
        case .systemError(let error):
            return error.recoverySuggestion
        }
    }
    
    var severity: ErrorSeverity {
        switch self {
        case .dataError(let error):
            return error.severity
        case .aiServiceError(let error):
            return error.severity
        case .networkError(let error):
            return error.severity
        case .validationError(let error):
            return error.severity
        case .systemError(let error):
            return error.severity
        }
    }
    
    var category: ErrorCategory {
        switch self {
        case .dataError:
            return .data
        case .aiServiceError:
            return .aiService
        case .networkError:
            return .network
        case .validationError:
            return .validation
        case .systemError:
            return .system
        }
    }
}

// MARK: - AI Service Errors

enum AIServiceError: LocalizedError {
    case deepseekError(DeepseekError)
    case taskPlanError(TaskPlanError)
    case networkUnavailable
    case serviceTimeout
    case rateLimitExceeded
    case invalidResponse(String)
    case authenticationFailed
    
    var errorDescription: String? {
        switch self {
        case .deepseekError(let error):
            return error.errorDescription
        case .taskPlanError(let error):
            return error.errorDescription
        case .networkUnavailable:
            return "网络连接不可用"
        case .serviceTimeout:
            return "AI服务响应超时"
        case .rateLimitExceeded:
            return "API调用次数超限"
        case .invalidResponse(let details):
            return "AI服务返回无效响应: \(details)"
        case .authenticationFailed:
            return "AI服务认证失败"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .deepseekError(let error):
            return error.recoverySuggestion
        case .taskPlanError(let error):
            return error.recoverySuggestion
        case .networkUnavailable:
            return "请检查网络连接后重试，或选择手动创建任务计划"
        case .serviceTimeout:
            return "请稍后重试，或选择手动创建任务计划"
        case .rateLimitExceeded:
            return "请等待一段时间后重试"
        case .invalidResponse:
            return "请重试操作，如问题持续存在请选择手动创建"
        case .authenticationFailed:
            return "请检查API密钥配置"
        }
    }
    
    var severity: ErrorSeverity {
        switch self {
        case .deepseekError(let error):
            return error.severity
        case .taskPlanError(let error):
            return error.severity
        case .networkUnavailable, .serviceTimeout:
            return .medium
        case .rateLimitExceeded:
            return .low
        case .invalidResponse, .authenticationFailed:
            return .high
        }
    }
}

// MARK: - Deepseek API Errors

enum DeepseekError: LocalizedError {
    case networkError(Error)
    case unauthorized
    case rateLimited
    case serverError(Int)
    case badRequest(String)
    case invalidAPIKey
    case quotaExceeded
    case modelUnavailable
    case requestTooLarge
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "网络连接错误: \(error.localizedDescription)"
        case .unauthorized:
            return "API认证失败"
        case .rateLimited:
            return "请求频率超限"
        case .serverError(let code):
            return "服务器错误 (代码: \(code))"
        case .badRequest(let message):
            return "请求格式错误: \(message)"
        case .invalidAPIKey:
            return "API密钥无效"
        case .quotaExceeded:
            return "API配额已用完"
        case .modelUnavailable:
            return "AI模型暂时不可用"
        case .requestTooLarge:
            return "请求内容过大"
        case .unknown(let error):
            return "未知错误: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return "请检查网络连接后重试"
        case .unauthorized, .invalidAPIKey:
            return "请检查API密钥配置"
        case .rateLimited:
            return "请等待一段时间后重试"
        case .serverError:
            return "请稍后重试，如问题持续存在请联系技术支持"
        case .badRequest:
            return "请检查输入内容后重试"
        case .quotaExceeded:
            return "请联系管理员增加API配额"
        case .modelUnavailable:
            return "请稍后重试或选择手动创建"
        case .requestTooLarge:
            return "请简化目标描述后重试"
        case .unknown:
            return "请重试操作"
        }
    }
    
    var severity: ErrorSeverity {
        switch self {
        case .networkError, .serverError, .modelUnavailable:
            return .medium
        case .unauthorized, .invalidAPIKey, .quotaExceeded:
            return .high
        case .rateLimited, .requestTooLarge:
            return .low
        case .badRequest, .unknown:
            return .medium
        }
    }
}

// MARK: - Task Plan Errors

enum TaskPlanError: LocalizedError {
    case emptyResponse
    case parsingFailed(String)
    case validationFailed(String)
    case aiServiceError(String)
    case invalidTaskStructure
    case missingRequiredFields([String])
    case taskCountExceeded(Int)
    
    var errorDescription: String? {
        switch self {
        case .emptyResponse:
            return "AI服务返回空响应"
        case .parsingFailed(let details):
            return "解析任务计划失败: \(details)"
        case .validationFailed(let reason):
            return "任务计划验证失败: \(reason)"
        case .aiServiceError(let message):
            return "AI服务错误: \(message)"
        case .invalidTaskStructure:
            return "任务结构无效"
        case .missingRequiredFields(let fields):
            return "缺少必需字段: \(fields.joined(separator: ", "))"
        case .taskCountExceeded(let count):
            return "任务数量超限 (最大50个，当前\(count)个)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .emptyResponse, .parsingFailed, .aiServiceError:
            return "请重试生成任务计划，或选择手动创建"
        case .validationFailed, .invalidTaskStructure, .missingRequiredFields:
            return "请重新生成任务计划或手动创建"
        case .taskCountExceeded:
            return "请简化目标描述以减少任务数量"
        }
    }
    
    var severity: ErrorSeverity {
        switch self {
        case .emptyResponse, .parsingFailed, .aiServiceError:
            return .medium
        case .validationFailed, .invalidTaskStructure, .missingRequiredFields:
            return .high
        case .taskCountExceeded:
            return .low
        }
    }
}

// MARK: - Network Errors

enum NetworkError: LocalizedError {
    case noConnection
    case timeout
    case serverUnavailable
    case invalidURL
    case requestFailed(Error)
    case responseParsingFailed
    
    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "无网络连接"
        case .timeout:
            return "网络请求超时"
        case .serverUnavailable:
            return "服务器不可用"
        case .invalidURL:
            return "无效的网络地址"
        case .requestFailed(let error):
            return "网络请求失败: \(error.localizedDescription)"
        case .responseParsingFailed:
            return "响应解析失败"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .noConnection:
            return "请检查网络连接后重试"
        case .timeout:
            return "请检查网络状况后重试"
        case .serverUnavailable:
            return "请稍后重试"
        case .invalidURL:
            return "请联系技术支持"
        case .requestFailed:
            return "请重试操作"
        case .responseParsingFailed:
            return "请重试操作，如问题持续存在请联系技术支持"
        }
    }
    
    var severity: ErrorSeverity {
        switch self {
        case .noConnection, .timeout:
            return .medium
        case .serverUnavailable:
            return .low
        case .invalidURL, .responseParsingFailed:
            return .high
        case .requestFailed:
            return .medium
        }
    }
}

// MARK: - Validation Errors

enum ValidationError: LocalizedError {
    case emptyInput(String)
    case invalidFormat(String)
    case lengthExceeded(String, Int)
    case invalidCharacters(String)
    case duplicateValue(String)
    case requiredFieldMissing(String)
    
    var errorDescription: String? {
        switch self {
        case .emptyInput(let field):
            return "\(field)不能为空"
        case .invalidFormat(let field):
            return "\(field)格式无效"
        case .lengthExceeded(let field, let maxLength):
            return "\(field)长度超限 (最大\(maxLength)个字符)"
        case .invalidCharacters(let field):
            return "\(field)包含无效字符"
        case .duplicateValue(let field):
            return "\(field)已存在"
        case .requiredFieldMissing(let field):
            return "必需字段\(field)缺失"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .emptyInput:
            return "请输入有效内容"
        case .invalidFormat:
            return "请检查输入格式"
        case .lengthExceeded:
            return "请缩短输入内容"
        case .invalidCharacters:
            return "请移除特殊字符"
        case .duplicateValue:
            return "请使用不同的值"
        case .requiredFieldMissing:
            return "请填写所有必需字段"
        }
    }
    
    var severity: ErrorSeverity {
        return .low
    }
}

// MARK: - System Errors

enum SystemError: LocalizedError {
    case memoryWarning
    case diskSpaceLow
    case permissionDenied(String)
    case backgroundTaskExpired
    case deviceNotSupported
    case osVersionTooOld
    
    var errorDescription: String? {
        switch self {
        case .memoryWarning:
            return "内存不足"
        case .diskSpaceLow:
            return "存储空间不足"
        case .permissionDenied(let permission):
            return "缺少\(permission)权限"
        case .backgroundTaskExpired:
            return "后台任务超时"
        case .deviceNotSupported:
            return "设备不支持"
        case .osVersionTooOld:
            return "系统版本过低"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .memoryWarning:
            return "请关闭其他应用释放内存"
        case .diskSpaceLow:
            return "请清理设备存储空间"
        case .permissionDenied:
            return "请在设置中授予相应权限"
        case .backgroundTaskExpired:
            return "请重新打开应用"
        case .deviceNotSupported:
            return "请使用支持的设备"
        case .osVersionTooOld:
            return "请升级到iOS 17.0或更高版本"
        }
    }
    
    var severity: ErrorSeverity {
        switch self {
        case .memoryWarning, .diskSpaceLow:
            return .medium
        case .permissionDenied, .backgroundTaskExpired:
            return .low
        case .deviceNotSupported, .osVersionTooOld:
            return .high
        }
    }
}

// MARK: - Supporting Types

enum ErrorSeverity {
    case low      // 用户可以继续使用，但功能受限
    case medium   // 影响部分功能，需要用户注意
    case high     // 严重错误，需要立即处理
    
    var priority: Int {
        switch self {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        }
    }
}

enum ErrorCategory {
    case data
    case aiService
    case network
    case validation
    case system
    
    var displayName: String {
        switch self {
        case .data: return "数据"
        case .aiService: return "AI服务"
        case .network: return "网络"
        case .validation: return "验证"
        case .system: return "系统"
        }
    }
}