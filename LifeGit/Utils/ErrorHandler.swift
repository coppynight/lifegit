import Foundation
import OSLog
import SwiftUI

/// Global error handler for the application
@MainActor
class ErrorHandler: ObservableObject {
    static let shared = ErrorHandler()
    
    @Published var currentError: ErrorPresentation?
    @Published var errorHistory: [ErrorLogEntry] = []
    @Published var isShowingError = false
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "LifeGit", category: "ErrorHandler")
    private let maxHistoryCount = 100
    
    private init() {}
    
    // MARK: - Public Interface
    
    /// Handle an error with automatic logging and user presentation
    /// - Parameters:
    ///   - error: The error to handle
    ///   - context: Additional context about where the error occurred
    ///   - shouldPresent: Whether to show the error to the user immediately
    func handle(_ error: Error, context: String? = nil, shouldPresent: Bool = true) {
        let appError = convertToAppError(error)
        let logEntry = createLogEntry(appError, context: context)
        
        // Log the error
        logError(logEntry)
        
        // Add to history
        addToHistory(logEntry)
        
        // Present to user if requested
        if shouldPresent {
            presentError(appError, context: context)
        }
    }
    
    /// Handle an error silently (logging only, no user presentation)
    /// - Parameters:
    ///   - error: The error to handle
    ///   - context: Additional context about where the error occurred
    func handleSilently(_ error: Error, context: String? = nil) {
        handle(error, context: context, shouldPresent: false)
    }
    
    /// Present an error to the user
    /// - Parameters:
    ///   - error: The error to present
    ///   - context: Additional context
    func presentError(_ error: AppError, context: String? = nil) {
        let presentation = createErrorPresentation(error, context: context)
        currentError = presentation
        isShowingError = true
    }
    
    /// Dismiss the current error presentation
    func dismissError() {
        currentError = nil
        isShowingError = false
    }
    
    /// Clear error history
    func clearHistory() {
        errorHistory.removeAll()
    }
    
    /// Clear error history (alias for ErrorHistoryView)
    func clearErrorHistory() {
        clearHistory()
    }
    
    /// Get errors by category
    /// - Parameter category: The error category to filter by
    /// - Returns: Array of error log entries
    func getErrors(by category: ErrorCategory) -> [ErrorLogEntry] {
        return errorHistory.filter { $0.category == category }
    }
    
    /// Get errors by severity
    /// - Parameter severity: The error severity to filter by
    /// - Returns: Array of error log entries
    func getErrors(by severity: ErrorSeverity) -> [ErrorLogEntry] {
        return errorHistory.filter { $0.severity == severity }
    }
    
    /// Get recent errors (last 24 hours)
    /// - Returns: Array of recent error log entries
    func getRecentErrors() -> [ErrorLogEntry] {
        let dayAgo = Date().addingTimeInterval(-24 * 60 * 60)
        return errorHistory.filter { $0.timestamp > dayAgo }
    }
    
    // MARK: - Private Methods
    
    /// Convert any error to AppError
    private func convertToAppError(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        
        // Try to categorize common system errors
        if let nsError = error as? NSError {
            switch nsError.domain {
            case NSURLErrorDomain:
                return .networkError(.requestFailed(error))
            case NSCocoaErrorDomain:
                if nsError.code == NSFileReadNoSuchFileError || nsError.code == NSFileNoSuchFileError {
                    return .dataError(.fetchFailure(underlying: error))
                }
                return .systemError(.permissionDenied(nsError.localizedDescription))
            default:
                break
            }
        }
        
        // Default to system error
        return .systemError(.backgroundTaskExpired)
    }
    
    /// Create a log entry for an error
    private func createLogEntry(_ error: AppError, context: String?) -> ErrorLogEntry {
        return ErrorLogEntry(
            id: UUID(),
            error: error,
            context: context,
            timestamp: Date(),
            severity: error.severity,
            category: error.category
        )
    }
    
    /// Log error using OSLog
    private func logError(_ entry: ErrorLogEntry) {
        let message = """
        [ERROR] \(entry.category.displayName) - \(entry.severity)
        Description: \(entry.error.localizedDescription)
        Context: \(entry.context ?? "N/A")
        Timestamp: \(entry.timestamp)
        """
        
        switch entry.severity {
        case .low:
            logger.info("\(message)")
        case .medium:
            logger.notice("\(message)")
        case .high:
            logger.error("\(message)")
        }
    }
    
    /// Add error to history with size management
    private func addToHistory(_ entry: ErrorLogEntry) {
        errorHistory.insert(entry, at: 0)
        
        // Keep history size manageable
        if errorHistory.count > maxHistoryCount {
            errorHistory.removeLast()
        }
    }
    
    /// Create error presentation for UI
    private func createErrorPresentation(_ error: AppError, context: String?) -> ErrorPresentation {
        let actions = createErrorActions(for: error)
        
        return ErrorPresentation(
            id: UUID(),
            title: getErrorTitle(error),
            message: error.localizedDescription ?? "发生了未知错误",
            severity: error.severity,
            category: error.category,
            context: context,
            recoverySuggestion: error.recoverySuggestion,
            actions: actions,
            timestamp: Date()
        )
    }
    
    /// Get appropriate title for error
    private func getErrorTitle(_ error: AppError) -> String {
        switch error.category {
        case .data:
            return "数据错误"
        case .aiService:
            return "AI服务错误"
        case .network:
            return "网络错误"
        case .validation:
            return "输入验证错误"
        case .system:
            return "系统错误"
        }
    }
    
    /// Create appropriate actions for error
    private func createErrorActions(for error: AppError) -> [ErrorAction] {
        var actions: [ErrorAction] = []
        
        // Always add dismiss action
        actions.append(.dismiss)
        
        // Add specific actions based on error type
        switch error {
        case .aiServiceError(let aiError):
            switch aiError {
            case .networkUnavailable, .serviceTimeout:
                actions.insert(.retry, at: 0)
                actions.insert(.useOfflineMode, at: 1)
            case .rateLimitExceeded:
                actions.insert(.waitAndRetry, at: 0)
            case .authenticationFailed:
                actions.insert(.openSettings, at: 0)
            default:
                actions.insert(.retry, at: 0)
            }
            
        case .networkError:
            actions.insert(.retry, at: 0)
            actions.insert(.checkConnection, at: 1)
            
        case .dataError(let dataError):
            switch dataError {
            case .saveFailure, .fetchFailure:
                actions.insert(.retry, at: 0)
            case .userNotFound, .masterBranchNotFound:
                actions.insert(.resetApp, at: 0)
            default:
                actions.insert(.retry, at: 0)
            }
            
        case .validationError:
            // Validation errors usually don't need retry
            break
            
        case .systemError(let systemError):
            switch systemError {
            case .memoryWarning, .diskSpaceLow:
                actions.insert(.openSettings, at: 0)
            case .permissionDenied:
                actions.insert(.openSettings, at: 0)
            default:
                break
            }
        }
        
        return actions
    }
}

// MARK: - Data Models

/// Error presentation model for UI
struct ErrorPresentation: Identifiable {
    let id: UUID
    let title: String
    let message: String
    let severity: ErrorSeverity
    let category: ErrorCategory
    let context: String?
    let recoverySuggestion: String?
    let actions: [ErrorAction]
    let timestamp: Date
}

/// Error log entry for history tracking
struct ErrorLogEntry: Identifiable {
    let id: UUID
    let error: AppError
    let context: String?
    let timestamp: Date
    let severity: ErrorSeverity
    let category: ErrorCategory
}

/// Error record for history view (alias for ErrorLogEntry)
typealias ErrorRecord = ErrorLogEntry

extension ErrorLogEntry {
    var title: String {
        switch error.category {
        case .data:
            return "数据错误"
        case .aiService:
            return "AI服务错误"
        case .network:
            return "网络错误"
        case .validation:
            return "输入验证错误"
        case .system:
            return "系统错误"
        }
    }
    
    var message: String? {
        return error.localizedDescription
    }
}

/// Available error actions
enum ErrorAction: CaseIterable {
    case dismiss
    case retry
    case waitAndRetry
    case useOfflineMode
    case openSettings
    case checkConnection
    case resetApp
    case contactSupport
    
    var title: String {
        switch self {
        case .dismiss:
            return "确定"
        case .retry:
            return "重试"
        case .waitAndRetry:
            return "稍后重试"
        case .useOfflineMode:
            return "手动创建"
        case .openSettings:
            return "打开设置"
        case .checkConnection:
            return "检查网络"
        case .resetApp:
            return "重置应用"
        case .contactSupport:
            return "联系支持"
        }
    }
    
    var systemImage: String {
        switch self {
        case .dismiss:
            return "checkmark"
        case .retry:
            return "arrow.clockwise"
        case .waitAndRetry:
            return "clock"
        case .useOfflineMode:
            return "pencil"
        case .openSettings:
            return "gear"
        case .checkConnection:
            return "wifi"
        case .resetApp:
            return "arrow.counterclockwise"
        case .contactSupport:
            return "questionmark.circle"
        }
    }
    
    var style: ErrorActionStyle {
        switch self {
        case .dismiss:
            return .secondary
        case .retry, .waitAndRetry, .useOfflineMode:
            return .primary
        case .openSettings, .checkConnection:
            return .secondary
        case .resetApp:
            return .destructive
        case .contactSupport:
            return .secondary
        }
    }
}

enum ErrorActionStyle {
    case primary
    case secondary
    case destructive
}

// MARK: - Extensions

extension ErrorHandler {
    /// Convenience method for handling data errors
    func handleDataError(_ error: DataError, context: String? = nil) {
        handle(AppError.dataError(error), context: context)
    }
    
    /// Convenience method for handling AI service errors
    func handleAIServiceError(_ error: AIServiceError, context: String? = nil) {
        handle(AppError.aiServiceError(error), context: context)
    }
    
    /// Convenience method for handling network errors
    func handleNetworkError(_ error: NetworkError, context: String? = nil) {
        handle(AppError.networkError(error), context: context)
    }
    
    /// Convenience method for handling validation errors
    func handleValidationError(_ error: ValidationError, context: String? = nil) {
        handle(AppError.validationError(error), context: context)
    }
    
    /// Convenience method for handling system errors
    func handleSystemError(_ error: SystemError, context: String? = nil) {
        handle(AppError.systemError(error), context: context)
    }
}

// MARK: - Error Statistics

extension ErrorHandler {
    /// Get error statistics for analytics
    var errorStatistics: ErrorStatistics {
        let total = errorHistory.count
        let byCategory = Dictionary(grouping: errorHistory) { $0.category }
        let bySeverity = Dictionary(grouping: errorHistory) { $0.severity }
        let recent = getRecentErrors().count
        
        return ErrorStatistics(
            totalErrors: total,
            recentErrors: recent,
            errorsByCategory: byCategory.mapValues { $0.count },
            errorsBySeverity: bySeverity.mapValues { $0.count },
            mostCommonCategory: byCategory.max { $0.value.count < $1.value.count }?.key,
            averageErrorsPerDay: calculateAverageErrorsPerDay()
        )
    }
    
    private func calculateAverageErrorsPerDay() -> Double {
        guard !errorHistory.isEmpty else { return 0 }
        
        let oldestError = errorHistory.last?.timestamp ?? Date()
        let daysSinceOldest = Date().timeIntervalSince(oldestError) / (24 * 60 * 60)
        
        return daysSinceOldest > 0 ? Double(errorHistory.count) / daysSinceOldest : 0
    }
}

struct ErrorStatistics {
    let totalErrors: Int
    let recentErrors: Int
    let errorsByCategory: [ErrorCategory: Int]
    let errorsBySeverity: [ErrorSeverity: Int]
    let mostCommonCategory: ErrorCategory?
    let averageErrorsPerDay: Double
}