import Foundation
@testable import LifeGit

/// Mock implementation of DeepseekR1Client for testing
class MockDeepseekR1Client: DeepseekR1Client {
    
    // MARK: - Mock Configuration
    var shouldSucceed = true
    var responseDelay: TimeInterval = 0.1
    var mockResponse: ChatCompletionResponse?
    var mockError: DeepseekError?
    var callCount = 0
    var lastRequest: ChatCompletionRequest?
    
    // MARK: - Mock Responses
    static let successfulTaskPlanResponse = """
    {
      "totalDuration": "4周",
      "tasks": [
        {
          "title": "学习Swift基础语法",
          "description": "掌握变量、常量、数据类型和控制流",
          "timeScope": "daily",
          "estimatedDuration": 60,
          "orderIndex": 1,
          "executionTips": "建议每天早上学习1小时"
        },
        {
          "title": "练习面向对象编程",
          "description": "学习类、结构体、协议和继承",
          "timeScope": "weekly",
          "estimatedDuration": 120,
          "orderIndex": 2,
          "executionTips": "通过实际项目练习OOP概念"
        },
        {
          "title": "构建完整应用",
          "description": "使用所学知识构建一个完整的iOS应用",
          "timeScope": "monthly",
          "estimatedDuration": 480,
          "orderIndex": 3,
          "executionTips": "选择一个感兴趣的项目主题"
        }
      ]
    }
    """
    
    static let emptyTaskPlanResponse = """
    {
      "totalDuration": "未知",
      "tasks": []
    }
    """
    
    static let invalidJsonResponse = """
    {
      "totalDuration": "4周",
      "tasks": [
        {
          "title": "学习Swift基础语法",
          "description": "掌握变量、常量、数据类型和控制流"
          // Missing comma and other fields
        }
      ]
    """
    
    // MARK: - Initialization
    override init(apiKey: String, maxRetries: Int = 3, timeoutInterval: TimeInterval = 30) {
        super.init(apiKey: apiKey, maxRetries: maxRetries, timeoutInterval: timeoutInterval)
    }
    
    // MARK: - Mock Implementation
    override func chatCompletion(_ request: ChatCompletionRequest) async throws -> ChatCompletionResponse {
        callCount += 1
        lastRequest = request
        
        // Simulate network delay
        if responseDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(responseDelay * 1_000_000_000))
        }
        
        // Return mock error if configured
        if let error = mockError {
            throw error
        }
        
        // Return failure if configured
        if !shouldSucceed {
            throw DeepseekError.serverError("Mock server error")
        }
        
        // Return custom mock response if provided
        if let response = mockResponse {
            return response
        }
        
        // Return default successful response
        return createMockResponse(content: Self.successfulTaskPlanResponse)
    }
    
    // MARK: - Helper Methods
    func reset() {
        shouldSucceed = true
        responseDelay = 0.1
        mockResponse = nil
        mockError = nil
        callCount = 0
        lastRequest = nil
    }
    
    func configureMockResponse(content: String) {
        mockResponse = createMockResponse(content: content)
    }
    
    func configureMockError(_ error: DeepseekError) {
        mockError = error
        shouldSucceed = false
    }
    
    private func createMockResponse(content: String) -> ChatCompletionResponse {
        return ChatCompletionResponse(
            id: "mock-response-\(UUID().uuidString)",
            object: "chat.completion",
            created: Int(Date().timeIntervalSince1970),
            model: "deepseek-r1",
            choices: [
                Choice(
                    index: 0,
                    message: ChatMessage(role: .assistant, content: content),
                    finishReason: "stop"
                )
            ],
            usage: Usage(
                promptTokens: 100,
                completionTokens: 200,
                totalTokens: 300
            )
        )
    }
}

// MARK: - Mock Scenarios

extension MockDeepseekR1Client {
    
    /// Configure for successful task plan generation
    func configureForSuccess() {
        reset()
        shouldSucceed = true
        configureMockResponse(content: Self.successfulTaskPlanResponse)
    }
    
    /// Configure for empty task plan response
    func configureForEmptyResponse() {
        reset()
        shouldSucceed = true
        configureMockResponse(content: Self.emptyTaskPlanResponse)
    }
    
    /// Configure for invalid JSON response
    func configureForInvalidJson() {
        reset()
        shouldSucceed = true
        configureMockResponse(content: Self.invalidJsonResponse)
    }
    
    /// Configure for network error
    func configureForNetworkError() {
        reset()
        configureMockError(.networkError("Mock network error"))
    }
    
    /// Configure for rate limiting
    func configureForRateLimit() {
        reset()
        configureMockError(.rateLimited("Mock rate limit exceeded"))
    }
    
    /// Configure for unauthorized error
    func configureForUnauthorized() {
        reset()
        configureMockError(.unauthorized("Mock invalid API key"))
    }
    
    /// Configure for server error
    func configureForServerError() {
        reset()
        configureMockError(.serverError("Mock server error"))
    }
    
    /// Configure for slow response
    func configureForSlowResponse(delay: TimeInterval = 5.0) {
        reset()
        responseDelay = delay
        shouldSucceed = true
        configureMockResponse(content: Self.successfulTaskPlanResponse)
    }
    
    /// Configure for timeout
    func configureForTimeout() {
        reset()
        responseDelay = 35.0 // Longer than default timeout
        shouldSucceed = true
    }
}

// MARK: - Verification Helpers

extension MockDeepseekR1Client {
    
    /// Verify that the client was called with expected parameters
    func verifyLastRequest(
        expectedModel: String = "deepseek-r1",
        expectedMaxTokens: Int = 2000,
        expectedTemperature: Double = 0.7,
        expectedMessageCount: Int? = nil
    ) -> Bool {
        guard let request = lastRequest else { return false }
        
        if request.model != expectedModel { return false }
        if request.maxTokens != expectedMaxTokens { return false }
        if abs(request.temperature - expectedTemperature) > 0.01 { return false }
        
        if let expectedCount = expectedMessageCount {
            if request.messages.count != expectedCount { return false }
        }
        
        return true
    }
    
    /// Verify that the client was called the expected number of times
    func verifyCallCount(_ expectedCount: Int) -> Bool {
        return callCount == expectedCount
    }
    
    /// Verify that the last request contained expected content
    func verifyLastRequestContains(_ content: String) -> Bool {
        guard let request = lastRequest else { return false }
        
        return request.messages.contains { message in
            message.content.contains(content)
        }
    }
    
    /// Get the user message from the last request
    func getLastUserMessage() -> String? {
        guard let request = lastRequest else { return nil }
        
        return request.messages.first { $0.role == MessageRole.user.rawValue }?.content
    }
    
    /// Get the system message from the last request
    func getLastSystemMessage() -> String? {
        guard let request = lastRequest else { return nil }
        
        return request.messages.first { $0.role == MessageRole.system.rawValue }?.content
    }
}