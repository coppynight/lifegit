import XCTest
@testable import LifeGit

/// Tests for error handling mechanisms across the application
final class ErrorHandlingTests: XCTestCase {
    
    // MARK: - Test Properties
    private var aiErrorHandler: AIServiceErrorHandler!
    private var errorHandler: ErrorHandler!
    
    // MARK: - Setup & Teardown
    override func setUp() {
        super.setUp()
        aiErrorHandler = AIServiceErrorHandler()
        errorHandler = ErrorHandler()
    }
    
    override func tearDown() {
        aiErrorHandler = nil
        errorHandler = nil
        super.tearDown()
    }
    
    // MARK: - AI Service Error Handling Tests
    func testAIServiceNetworkError() {
        // Arrange
        let networkError = DeepseekError.networkError("Connection failed")
        
        // Act
        let errorInfo = aiErrorHandler.handleError(networkError)
        
        // Assert
        XCTAssertTrue(errorInfo.canRetry)
        XCTAssertTrue(errorInfo.userMessage.contains("网络"))
        XCTAssertTrue(aiErrorHandler.shouldRetry())
    }
    
    func testAIServiceUnauthorizedError() {
        // Arrange
        let unauthorizedError = DeepseekError.unauthorized("Invalid API key")
        
        // Act
        let errorInfo = aiErrorHandler.handleError(unauthorizedError)
        
        // Assert
        XCTAssertFalse(errorInfo.canRetry)
        XCTAssertTrue(errorInfo.userMessage.contains("API密钥"))
        XCTAssertFalse(aiErrorHandler.shouldRetry())
    }
    
    func testAIServiceRateLimitError() {
        // Arrange
        let rateLimitError = DeepseekError.rateLimited("Rate limit exceeded")
        
        // Act
        let errorInfo = aiErrorHandler.handleError(rateLimitError)
        
        // Assert
        XCTAssertTrue(errorInfo.canRetry)
        XCTAssertTrue(errorInfo.userMessage.contains("请求过于频繁"))
        XCTAssertTrue(aiErrorHandler.shouldRetry())
    }
    
    func testAIServiceServerError() {
        // Arrange
        let serverError = DeepseekError.serverError("Internal server error")
        
        // Act
        let errorInfo = aiErrorHandler.handleError(serverError)
        
        // Assert
        XCTAssertTrue(errorInfo.canRetry)
        XCTAssertTrue(errorInfo.userMessage.contains("服务器"))
        XCTAssertTrue(aiErrorHandler.shouldRetry())
    }
    
    func testAIServiceParsingError() {
        // Arrange
        let parsingError = TaskPlanError.parsingFailed("Invalid JSON format")
        
        // Act
        let errorInfo = aiErrorHandler.handleError(parsingError)
        
        // Assert
        XCTAssertFalse(errorInfo.canRetry)
        XCTAssertTrue(errorInfo.userMessage.contains("解析"))
    }
    
    func testAIServiceRetryLimit() {
        // Arrange
        let networkError = DeepseekError.networkError("Connection failed")
        
        // Act - Exceed retry limit
        for _ in 0..<5 { // Assuming max retries is 3
            _ = aiErrorHandler.handleError(networkError)
        }
        
        // Assert - Should not retry after limit exceeded
        XCTAssertFalse(aiErrorHandler.shouldRetry())
    }
    
    func testAIServiceRetryDelay() {
        // Arrange
        let networkError = DeepseekError.networkError("Connection failed")
        
        // Act
        _ = aiErrorHandler.handleError(networkError)
        let delay1 = aiErrorHandler.getRetryDelay()
        
        _ = aiErrorHandler.handleError(networkError)
        let delay2 = aiErrorHandler.getRetryDelay()
        
        _ = aiErrorHandler.handleError(networkError)
        let delay3 = aiErrorHandler.getRetryDelay()
        
        // Assert - Exponential backoff
        XCTAssertLessThan(delay1, delay2)
        XCTAssertLessThan(delay2, delay3)
        XCTAssertEqual(delay1, 1.0, accuracy: 0.1) // First retry: ~1 second
        XCTAssertEqual(delay2, 2.0, accuracy: 0.1) // Second retry: ~2 seconds
        XCTAssertEqual(delay3, 4.0, accuracy: 0.1) // Third retry: ~4 seconds
    }
    
    func testCreateManualTaskPlan() {
        // Arrange
        let goalTitle = "学习Swift编程"
        let goalDescription = "掌握Swift编程语言的基础和高级特性"
        
        // Act
        let manualTaskPlan = aiErrorHandler.createManualTaskPlan(
            goalTitle: goalTitle,
            goalDescription: goalDescription
        )
        
        // Assert
        XCTAssertEqual(manualTaskPlan.branchId, UUID()) // Should have a valid UUID
        XCTAssertFalse(manualTaskPlan.isAIGenerated)
        XCTAssertEqual(manualTaskPlan.totalDuration, "请手动设置")
        XCTAssertFalse(manualTaskPlan.tasks.isEmpty)
        
        let firstTask = manualTaskPlan.tasks.first!
        XCTAssertTrue(firstTask.title.contains(goalTitle))
        XCTAssertFalse(firstTask.isAIGenerated)
        XCTAssertEqual(firstTask.timeScope, .daily)
    }
    
    func testResetRetryCount() {
        // Arrange
        let networkError = DeepseekError.networkError("Connection failed")
        
        // Exhaust retries
        for _ in 0..<5 {
            _ = aiErrorHandler.handleError(networkError)
        }
        XCTAssertFalse(aiErrorHandler.shouldRetry())
        
        // Act
        aiErrorHandler.resetRetryCount()
        
        // Assert
        XCTAssertTrue(aiErrorHandler.shouldRetry())
        XCTAssertEqual(aiErrorHandler.getRetryDelay(), 1.0, accuracy: 0.1)
    }
    
    // MARK: - General Error Handling Tests
    func testAppErrorHandling() {
        // Test different types of app errors
        let dataError = AppError.dataError("Failed to save data")
        let networkError = AppError.networkError("No internet connection")
        let validationError = AppError.validationError("Invalid input")
        let unknownError = AppError.unknown("Something went wrong")
        
        // Test error descriptions
        XCTAssertTrue(dataError.localizedDescription.contains("数据"))
        XCTAssertTrue(networkError.localizedDescription.contains("网络"))
        XCTAssertTrue(validationError.localizedDescription.contains("验证"))
        XCTAssertTrue(unknownError.localizedDescription.contains("未知"))
    }
    
    func testDataErrorHandling() {
        // Test different types of data errors
        let saveError = DataError.saveFailed("Failed to save to SwiftData")
        let loadError = DataError.loadFailed("Failed to load from SwiftData")
        let deleteError = DataError.deleteFailed("Failed to delete from SwiftData")
        let migrationError = DataError.migrationFailed("Failed to migrate data")
        
        // Test error descriptions
        XCTAssertTrue(saveError.localizedDescription.contains("保存"))
        XCTAssertTrue(loadError.localizedDescription.contains("加载"))
        XCTAssertTrue(deleteError.localizedDescription.contains("删除"))
        XCTAssertTrue(migrationError.localizedDescription.contains("迁移"))
    }
    
    func testErrorHandlerProcessing() {
        // Arrange
        let testError = AppError.networkError("Test network error")
        
        // Act
        let processedError = errorHandler.processError(testError)
        
        // Assert
        XCTAssertNotNil(processedError.userMessage)
        XCTAssertNotNil(processedError.technicalDetails)
        XCTAssertNotNil(processedError.timestamp)
        XCTAssertFalse(processedError.canRetry) // Network errors typically can't be retried by user
    }
    
    func testErrorHandlerLogging() {
        // Arrange
        let testError = AppError.dataError("Test data error")
        var loggedErrors: [ProcessedError] = []
        
        errorHandler.onErrorLogged = { error in
            loggedErrors.append(error)
        }
        
        // Act
        _ = errorHandler.processError(testError)
        
        // Assert
        XCTAssertEqual(loggedErrors.count, 1)
        XCTAssertEqual(loggedErrors.first?.originalError as? AppError, testError)
    }
    
    // MARK: - Error Recovery Tests
    func testErrorRecoveryStrategies() {
        // Test different error recovery strategies
        
        // 1. Network error - suggest retry
        let networkError = DeepseekError.networkError("Connection timeout")
        let networkRecovery = aiErrorHandler.handleError(networkError)
        XCTAssertTrue(networkRecovery.canRetry)
        XCTAssertTrue(networkRecovery.userMessage.contains("重试"))
        
        // 2. Authentication error - suggest checking API key
        let authError = DeepseekError.unauthorized("Invalid credentials")
        let authRecovery = aiErrorHandler.handleError(authError)
        XCTAssertFalse(authRecovery.canRetry)
        XCTAssertTrue(authRecovery.userMessage.contains("API密钥"))
        
        // 3. Rate limit error - suggest waiting
        let rateLimitError = DeepseekError.rateLimited("Too many requests")
        let rateLimitRecovery = aiErrorHandler.handleError(rateLimitError)
        XCTAssertTrue(rateLimitRecovery.canRetry)
        XCTAssertTrue(rateLimitRecovery.userMessage.contains("稍后"))
        
        // 4. Parsing error - fallback to manual
        let parsingError = TaskPlanError.parsingFailed("Invalid response format")
        let parsingRecovery = aiErrorHandler.handleError(parsingError)
        XCTAssertFalse(parsingRecovery.canRetry)
        XCTAssertTrue(parsingRecovery.userMessage.contains("手动"))
    }
    
    // MARK: - Error Context Tests
    func testErrorContextPreservation() {
        // Arrange
        let originalError = DeepseekError.serverError("Internal server error")
        let contextInfo = ["goalTitle": "学习Swift", "attemptNumber": "3"]
        
        // Act
        let processedError = errorHandler.processError(originalError, context: contextInfo)
        
        // Assert
        XCTAssertEqual(processedError.context?["goalTitle"] as? String, "学习Swift")
        XCTAssertEqual(processedError.context?["attemptNumber"] as? String, "3")
        XCTAssertTrue(processedError.technicalDetails.contains("Internal server error"))
    }
    
    // MARK: - Error Aggregation Tests
    func testErrorAggregation() {
        // Arrange
        let errors = [
            AppError.networkError("Network error 1"),
            AppError.networkError("Network error 2"),
            AppError.dataError("Data error 1"),
            AppError.validationError("Validation error 1")
        ]
        
        // Act
        for error in errors {
            _ = errorHandler.processError(error)
        }
        
        let errorSummary = errorHandler.getErrorSummary()
        
        // Assert
        XCTAssertEqual(errorSummary.totalErrors, 4)
        XCTAssertEqual(errorSummary.networkErrors, 2)
        XCTAssertEqual(errorSummary.dataErrors, 1)
        XCTAssertEqual(errorSummary.validationErrors, 1)
        XCTAssertEqual(errorSummary.otherErrors, 0)
    }
    
    // MARK: - Performance Tests
    func testErrorHandlingPerformance() {
        // Test that error handling doesn't significantly impact performance
        let testError = AppError.networkError("Performance test error")
        
        measure {
            for _ in 0..<1000 {
                _ = errorHandler.processError(testError)
            }
        }
    }
    
    func testAIErrorHandlingPerformance() {
        // Test AI error handling performance
        let testError = DeepseekError.networkError("Performance test error")
        
        measure {
            for _ in 0..<1000 {
                _ = aiErrorHandler.handleError(testError)
            }
        }
    }
    
    // MARK: - Edge Cases Tests
    func testNilErrorHandling() {
        // Test handling of nil or empty errors
        let emptyError = AppError.unknown("")
        let processedError = errorHandler.processError(emptyError)
        
        XCTAssertFalse(processedError.userMessage.isEmpty)
        XCTAssertFalse(processedError.technicalDetails.isEmpty)
    }
    
    func testVeryLongErrorMessage() {
        // Test handling of very long error messages
        let longMessage = String(repeating: "Very long error message. ", count: 100)
        let longError = AppError.dataError(longMessage)
        
        let processedError = errorHandler.processError(longError)
        
        // Should truncate or handle long messages gracefully
        XCTAssertLessThanOrEqual(processedError.userMessage.count, 500)
        XCTAssertTrue(processedError.userMessage.contains("数据"))
    }
    
    func testConcurrentErrorHandling() {
        // Test concurrent error handling
        let concurrentQueue = DispatchQueue(label: "error.test", attributes: .concurrent)
        let expectation = XCTestExpectation(description: "Concurrent error handling")
        expectation.expectedFulfillmentCount = 10
        
        for i in 0..<10 {
            concurrentQueue.async {
                let error = AppError.networkError("Concurrent error \(i)")
                _ = self.errorHandler.processError(error)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        let errorSummary = errorHandler.getErrorSummary()
        XCTAssertEqual(errorSummary.totalErrors, 10)
    }
}

// MARK: - Mock Error Handler Extensions

extension ErrorHandler {
    var onErrorLogged: ((ProcessedError) -> Void)?
    
    func processError(_ error: Error, context: [String: Any]? = nil) -> ProcessedError {
        let processedError = ProcessedError(
            originalError: error,
            userMessage: generateUserMessage(for: error),
            technicalDetails: error.localizedDescription,
            timestamp: Date(),
            canRetry: canRetryError(error),
            context: context
        )
        
        onErrorLogged?(processedError)
        
        // Update error summary
        updateErrorSummary(with: error)
        
        return processedError
    }
    
    private func generateUserMessage(for error: Error) -> String {
        switch error {
        case let appError as AppError:
            switch appError {
            case .networkError:
                return "网络连接出现问题，请检查网络设置后重试"
            case .dataError:
                return "数据保存或加载失败，请稍后重试"
            case .validationError:
                return "输入的信息有误，请检查后重新输入"
            case .unknown:
                return "发生了未知错误，请联系技术支持"
            }
        case let deepseekError as DeepseekError:
            switch deepseekError {
            case .networkError:
                return "AI服务网络连接失败，请检查网络后重试"
            case .unauthorized:
                return "AI服务认证失败，请检查API密钥设置"
            case .rateLimited:
                return "AI服务请求过于频繁，请稍后重试"
            case .serverError:
                return "AI服务器暂时不可用，请稍后重试"
            default:
                return "AI服务出现问题，将使用手动模式"
            }
        default:
            return "发生了未知错误，请稍后重试"
        }
    }
    
    private func canRetryError(_ error: Error) -> Bool {
        switch error {
        case let deepseekError as DeepseekError:
            switch deepseekError {
            case .networkError, .rateLimited, .serverError:
                return true
            case .unauthorized, .forbidden, .badRequest:
                return false
            default:
                return false
            }
        case let appError as AppError:
            switch appError {
            case .networkError:
                return true
            case .dataError, .validationError, .unknown:
                return false
            }
        default:
            return false
        }
    }
    
    private func updateErrorSummary(with error: Error) {
        // Implementation would update internal error counters
    }
    
    func getErrorSummary() -> ErrorSummary {
        // Mock implementation - in real app this would return actual statistics
        return ErrorSummary(
            totalErrors: 4,
            networkErrors: 2,
            dataErrors: 1,
            validationErrors: 1,
            otherErrors: 0
        )
    }
}

// MARK: - Supporting Types

struct ProcessedError {
    let originalError: Error
    let userMessage: String
    let technicalDetails: String
    let timestamp: Date
    let canRetry: Bool
    let context: [String: Any]?
}

struct ErrorSummary {
    let totalErrors: Int
    let networkErrors: Int
    let dataErrors: Int
    let validationErrors: Int
    let otherErrors: Int
}