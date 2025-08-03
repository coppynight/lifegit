import Foundation
import Network

/// Handler for AI service errors and offline mode support
class AIServiceErrorHandler: ObservableObject {
    @Published var isOnline = true
    @Published var lastError: AIServiceError?
    @Published var retryCount = 0
    
    private let networkMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "NetworkMonitor")
    private let maxRetries = 3
    
    init() {
        startNetworkMonitoring()
    }
    
    deinit {
        networkMonitor.cancel()
    }
    
    /// Start monitoring network connectivity
    private func startNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isOnline = path.status == .satisfied
            }
        }
        networkMonitor.start(queue: monitorQueue)
    }
    
    /// Handle AI service errors with appropriate user feedback
    /// - Parameter error: The error that occurred
    /// - Returns: User-friendly error message and suggested action
    func handleError(_ error: Error) -> AIServiceErrorInfo {
        let errorInfo: AIServiceErrorInfo
        
        switch error {
        case let deepseekError as DeepseekError:
            errorInfo = handleDeepseekError(deepseekError)
        case let taskPlanError as TaskPlanError:
            errorInfo = handleTaskPlanError(taskPlanError)
        default:
            errorInfo = AIServiceErrorInfo(
                title: "未知错误",
                message: "发生了未知错误，请稍后重试",
                action: .retry,
                canRetry: true
            )
        }
        
        lastError = AIServiceError(
            originalError: error,
            errorInfo: errorInfo,
            timestamp: Date()
        )
        
        return errorInfo
    }
    
    /// Handle Deepseek API specific errors
    private func handleDeepseekError(_ error: DeepseekError) -> AIServiceErrorInfo {
        switch error {
        case .networkError:
            return AIServiceErrorInfo(
                title: "网络连接失败",
                message: isOnline ? "无法连接到AI服务，请检查网络连接" : "当前处于离线状态，您可以手动创建任务计划",
                action: isOnline ? .retry : .useOfflineMode,
                canRetry: isOnline
            )
            
        case .unauthorized:
            return AIServiceErrorInfo(
                title: "认证失败",
                message: "API密钥无效，请检查配置",
                action: .checkSettings,
                canRetry: false
            )
            
        case .rateLimited:
            return AIServiceErrorInfo(
                title: "请求过于频繁",
                message: "AI服务请求次数超限，请稍后重试",
                action: .waitAndRetry,
                canRetry: true
            )
            
        case .serverError:
            return AIServiceErrorInfo(
                title: "服务器错误",
                message: "AI服务暂时不可用，请稍后重试",
                action: .retry,
                canRetry: true
            )
            
        case .badRequest(let message):
            return AIServiceErrorInfo(
                title: "请求格式错误",
                message: "请求参数有误：\(message)",
                action: .useOfflineMode,
                canRetry: false
            )
            
        default:
            return AIServiceErrorInfo(
                title: "AI服务错误",
                message: error.localizedDescription,
                action: .useOfflineMode,
                canRetry: true
            )
        }
    }
    
    /// Handle task plan service specific errors
    private func handleTaskPlanError(_ error: TaskPlanError) -> AIServiceErrorInfo {
        switch error {
        case .emptyResponse:
            return AIServiceErrorInfo(
                title: "AI响应为空",
                message: "AI服务没有返回有效的任务计划，请重试",
                action: .retry,
                canRetry: true
            )
            
        case .parsingFailed:
            return AIServiceErrorInfo(
                title: "解析失败",
                message: "无法解析AI生成的任务计划，请重试",
                action: .retry,
                canRetry: true
            )
            
        case .validationFailed(let message):
            return AIServiceErrorInfo(
                title: "任务计划验证失败",
                message: "生成的任务计划不完整：\(message)",
                action: .retry,
                canRetry: true
            )
            
        case .aiServiceError(let message):
            return AIServiceErrorInfo(
                title: "AI服务错误",
                message: message,
                action: .useOfflineMode,
                canRetry: true
            )
            
        default:
            return AIServiceErrorInfo(
                title: "任务计划生成失败",
                message: error.localizedDescription,
                action: .useOfflineMode,
                canRetry: true
            )
        }
    }
    
    /// Attempt to retry the failed operation
    /// - Parameter operation: The operation to retry
    /// - Returns: True if retry should be attempted, false otherwise
    func shouldRetry() -> Bool {
        guard retryCount < maxRetries else {
            return false
        }
        
        retryCount += 1
        return true
    }
    
    /// Reset retry count after successful operation
    func resetRetryCount() {
        retryCount = 0
        lastError = nil
    }
    
    /// Get retry delay based on current retry count (exponential backoff)
    func getRetryDelay() -> TimeInterval {
        let baseDelay = 2.0
        return baseDelay * pow(2.0, Double(retryCount - 1))
    }
    
    /// Create a manual task plan when AI service is unavailable
    func createManualTaskPlan(goalTitle: String, goalDescription: String) -> TaskPlan {
        let taskPlan = TaskPlan(
            branchId: UUID(), // This will be set by the caller
            totalDuration: "手动创建的任务计划",
            isAIGenerated: false
        )
        
        // Create a basic task structure for manual editing
        let defaultTask = TaskItem(
            title: "开始执行：\(goalTitle)",
            description: "请根据目标描述制定具体的执行步骤：\(goalDescription)",
            timeScope: .daily,
            estimatedDuration: 60,
            orderIndex: 0,
            executionTips: "这是一个手动创建的任务，请根据实际情况修改任务内容和时间安排"
        )
        
        taskPlan.tasks = [defaultTask]
        return taskPlan
    }
}

// MARK: - Data Models

/// AI service error information for user display
struct AIServiceErrorInfo {
    let title: String
    let message: String
    let action: ErrorAction
    let canRetry: Bool
}

/// Possible actions user can take when error occurs
enum ErrorAction {
    case retry
    case waitAndRetry
    case useOfflineMode
    case checkSettings
}

/// Complete AI service error with context
struct AIServiceError {
    let originalError: Error
    let errorInfo: AIServiceErrorInfo
    let timestamp: Date
}

// MARK: - Extensions

extension ErrorAction {
    var actionTitle: String {
        switch self {
        case .retry:
            return "重试"
        case .waitAndRetry:
            return "稍后重试"
        case .useOfflineMode:
            return "手动创建"
        case .checkSettings:
            return "检查设置"
        }
    }
    
    var actionDescription: String {
        switch self {
        case .retry:
            return "立即重新尝试生成任务计划"
        case .waitAndRetry:
            return "等待一段时间后重新尝试"
        case .useOfflineMode:
            return "手动创建任务计划，稍后可以重新生成"
        case .checkSettings:
            return "检查AI服务配置和网络连接"
        }
    }
}