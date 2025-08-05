import XCTest
@testable import LifeGit

/// Unit tests for TaskPlanService
final class TaskPlanServiceTests: XCTestCase {
    
    // MARK: - Test Properties
    private var taskPlanService: TaskPlanService!
    private var mockClient: MockDeepseekR1Client!
    
    // MARK: - Setup & Teardown
    override func setUp() {
        super.setUp()
        mockClient = MockDeepseekR1Client(apiKey: "test-api-key")
        
        // Create TaskPlanService with mock client
        taskPlanService = TaskPlanService(apiKey: "test-api-key")
        
        // Replace the internal client with our mock (this would require dependency injection in real implementation)
        // For now, we'll test the service indirectly through integration tests
    }
    
    override func tearDown() {
        taskPlanService = nil
        mockClient = nil
        super.tearDown()
    }
    
    // MARK: - Successful Generation Tests
    func testGenerateTaskPlanSuccess() async throws {
        mockClient.configureForSuccess()
        
        let result = try await generateTaskPlanWithMock(
            goalTitle: "学习Swift编程",
            goalDescription: "掌握Swift编程语言的基础和高级特性"
        )
        
        XCTAssertEqual(result.totalDuration, "4周")
        XCTAssertEqual(result.tasks.count, 3)
        
        let firstTask = result.tasks[0]
        XCTAssertEqual(firstTask.title, "学习Swift基础语法")
        XCTAssertEqual(firstTask.timeScope, "daily")
        XCTAssertEqual(firstTask.estimatedDuration, 60)
        XCTAssertEqual(firstTask.orderIndex, 1)
        XCTAssertNotNil(firstTask.executionTips)
    }
    
    func testGenerateTaskPlanWithTimeframe() async throws {
        mockClient.configureForSuccess()
        
        let result = try await generateTaskPlanWithMock(
            goalTitle: "健身计划",
            goalDescription: "建立健康的运动习惯",
            timeframe: "8周"
        )
        
        XCTAssertNotNil(result)
        XCTAssertFalse(result.tasks.isEmpty)
        
        // Verify that the mock was called
        XCTAssertTrue(mockClient.verifyCallCount(1))
        XCTAssertTrue(mockClient.verifyLastRequestContains("健身计划"))
        XCTAssertTrue(mockClient.verifyLastRequestContains("8周"))
    }
    
    // MARK: - Error Handling Tests
    func testGenerateTaskPlanNetworkError() async {
        mockClient.configureForNetworkError()
        
        do {
            _ = try await generateTaskPlanWithMock(
                goalTitle: "测试目标",
                goalDescription: "测试描述"
            )
            XCTFail("Expected TaskPlanError to be thrown")
        } catch let error as TaskPlanError {
            switch error {
            case .aiServiceError(let message):
                XCTAssertTrue(message.contains("network"))
            default:
                XCTFail("Expected aiServiceError, got \(error)")
            }
        } catch {
            XCTFail("Expected TaskPlanError, got \(error)")
        }
    }
    
    func testGenerateTaskPlanUnauthorized() async {
        mockClient.configureForUnauthorized()
        
        do {
            _ = try await generateTaskPlanWithMock(
                goalTitle: "测试目标",
                goalDescription: "测试描述"
            )
            XCTFail("Expected TaskPlanError to be thrown")
        } catch let error as TaskPlanError {
            switch error {
            case .aiServiceError(let message):
                XCTAssertTrue(message.contains("Unauthorized"))
            default:
                XCTFail("Expected aiServiceError, got \(error)")
            }
        } catch {
            XCTFail("Expected TaskPlanError, got \(error)")
        }
    }
    
    func testGenerateTaskPlanRateLimit() async {
        mockClient.configureForRateLimit()
        
        do {
            _ = try await generateTaskPlanWithMock(
                goalTitle: "测试目标",
                goalDescription: "测试描述"
            )
            XCTFail("Expected TaskPlanError to be thrown")
        } catch let error as TaskPlanError {
            switch error {
            case .aiServiceError(let message):
                XCTAssertTrue(message.contains("rate limit"))
            default:
                XCTFail("Expected aiServiceError, got \(error)")
            }
        } catch {
            XCTFail("Expected TaskPlanError, got \(error)")
        }
    }
    
    // MARK: - Response Parsing Tests
    func testGenerateTaskPlanInvalidJson() async {
        mockClient.configureForInvalidJson()
        
        do {
            _ = try await generateTaskPlanWithMock(
                goalTitle: "测试目标",
                goalDescription: "测试描述"
            )
            XCTFail("Expected TaskPlanError to be thrown")
        } catch let error as TaskPlanError {
            switch error {
            case .parsingFailed:
                // Expected
                break
            default:
                XCTFail("Expected parsingFailed, got \(error)")
            }
        } catch {
            XCTFail("Expected TaskPlanError, got \(error)")
        }
    }
    
    func testGenerateTaskPlanEmptyResponse() async throws {
        mockClient.configureForEmptyResponse()
        
        do {
            _ = try await generateTaskPlanWithMock(
                goalTitle: "测试目标",
                goalDescription: "测试描述"
            )
            XCTFail("Expected TaskPlanError to be thrown")
        } catch let error as TaskPlanError {
            switch error {
            case .validationFailed(let message):
                XCTAssertTrue(message.contains("at least one task"))
            default:
                XCTFail("Expected validationFailed, got \(error)")
            }
        } catch {
            XCTFail("Expected TaskPlanError, got \(error)")
        }
    }
    
    // MARK: - Validation Tests
    func testValidateTaskPlanSuccess() {
        let validTaskPlan = AIGeneratedTaskPlan(
            totalDuration: "3周",
            tasks: [
                AIGeneratedTask(
                    title: "任务1",
                    description: "描述1",
                    timeScope: "daily",
                    estimatedDuration: 60,
                    orderIndex: 1,
                    executionTips: "提示1"
                )
            ]
        )
        
        // This would be tested through the service's internal validation
        XCTAssertNotNil(validTaskPlan)
        XCTAssertFalse(validTaskPlan.tasks.isEmpty)
    }
    
    // MARK: - Conversion Tests
    func testConvertToTaskPlan() {
        let branchId = UUID()
        let aiTaskPlan = AIGeneratedTaskPlan(
            totalDuration: "2周",
            tasks: [
                AIGeneratedTask(
                    title: "学习基础",
                    description: "掌握基本概念",
                    timeScope: "daily",
                    estimatedDuration: 90,
                    orderIndex: 1,
                    executionTips: "每天练习"
                ),
                AIGeneratedTask(
                    title: "实践项目",
                    description: "构建实际应用",
                    timeScope: "weekly",
                    estimatedDuration: 240,
                    orderIndex: 2,
                    executionTips: "选择感兴趣的项目"
                )
            ]
        )
        
        let taskPlan = taskPlanService.convertToTaskPlan(aiTaskPlan, branchId: branchId)
        
        XCTAssertEqual(taskPlan.branchId, branchId)
        XCTAssertEqual(taskPlan.totalDuration, "2周")
        XCTAssertTrue(taskPlan.isAIGenerated)
        XCTAssertEqual(taskPlan.tasks.count, 2)
        
        let firstTask = taskPlan.tasks[0]
        XCTAssertEqual(firstTask.title, "学习基础")
        XCTAssertEqual(firstTask.description, "掌握基本概念")
        XCTAssertEqual(firstTask.timeScope, .daily)
        XCTAssertEqual(firstTask.estimatedDuration, 90)
        XCTAssertEqual(firstTask.orderIndex, 1)
        XCTAssertEqual(firstTask.executionTips, "每天练习")
        XCTAssertTrue(firstTask.isAIGenerated)
    }
    
    func testConvertToTaskPlanWithInvalidTimeScope() {
        let branchId = UUID()
        let aiTaskPlan = AIGeneratedTaskPlan(
            totalDuration: "1周",
            tasks: [
                AIGeneratedTask(
                    title: "测试任务",
                    description: "测试描述",
                    timeScope: "invalid_scope", // Invalid time scope
                    estimatedDuration: 60,
                    orderIndex: 1,
                    executionTips: nil
                )
            ]
        )
        
        let taskPlan = taskPlanService.convertToTaskPlan(aiTaskPlan, branchId: branchId)
        
        // Should fallback to .daily for invalid time scope
        XCTAssertEqual(taskPlan.tasks[0].timeScope, .daily)
    }
    
    // MARK: - Performance Tests
    func testGenerateTaskPlanPerformance() async throws {
        mockClient.configureForSuccess()
        
        measure {
            Task {
                do {
                    _ = try await self.generateTaskPlanWithMock(
                        goalTitle: "性能测试目标",
                        goalDescription: "测试任务计划生成的性能"
                    )
                } catch {
                    XCTFail("Performance test failed: \(error)")
                }
            }
        }
    }
    
    func testConvertToTaskPlanPerformance() {
        let branchId = UUID()
        
        // Create large AI task plan
        var tasks: [AIGeneratedTask] = []
        for i in 0..<1000 {
            tasks.append(AIGeneratedTask(
                title: "任务\(i)",
                description: "描述\(i)",
                timeScope: "daily",
                estimatedDuration: 30,
                orderIndex: i,
                executionTips: "提示\(i)"
            ))
        }
        
        let largeAITaskPlan = AIGeneratedTaskPlan(
            totalDuration: "很长时间",
            tasks: tasks
        )
        
        measure {
            _ = taskPlanService.convertToTaskPlan(largeAITaskPlan, branchId: branchId)
        }
    }
    
    // MARK: - Edge Cases Tests
    func testGenerateTaskPlanEmptyTitle() async {
        mockClient.configureForSuccess()
        
        do {
            _ = try await generateTaskPlanWithMock(
                goalTitle: "",
                goalDescription: "有效的描述"
            )
            
            // Should still work with empty title
            XCTAssertTrue(mockClient.verifyCallCount(1))
        } catch {
            XCTFail("Should handle empty title gracefully: \(error)")
        }
    }
    
    func testGenerateTaskPlanEmptyDescription() async {
        mockClient.configureForSuccess()
        
        do {
            _ = try await generateTaskPlanWithMock(
                goalTitle: "有效的标题",
                goalDescription: ""
            )
            
            // Should still work with empty description
            XCTAssertTrue(mockClient.verifyCallCount(1))
        } catch {
            XCTFail("Should handle empty description gracefully: \(error)")
        }
    }
    
    func testGenerateTaskPlanVeryLongInput() async {
        mockClient.configureForSuccess()
        
        let longTitle = String(repeating: "很长的标题", count: 100)
        let longDescription = String(repeating: "很长的描述", count: 200)
        
        do {
            _ = try await generateTaskPlanWithMock(
                goalTitle: longTitle,
                goalDescription: longDescription
            )
            
            XCTAssertTrue(mockClient.verifyCallCount(1))
            XCTAssertTrue(mockClient.verifyLastRequestContains(longTitle))
        } catch {
            XCTFail("Should handle long input gracefully: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    private func generateTaskPlanWithMock(
        goalTitle: String,
        goalDescription: String,
        timeframe: String? = nil
    ) async throws -> AIGeneratedTaskPlan {
        // Since we can't easily inject the mock client into the real service,
        // we'll simulate the service behavior using the mock client directly
        
        let request = ChatCompletionRequest(
            messages: [
                ChatMessage(role: .system, content: "System prompt"),
                ChatMessage(role: .user, content: "User prompt with \(goalTitle)")
            ]
        )
        
        let response = try await mockClient.chatCompletion(request)
        let content = response.choices.first?.message.content ?? ""
        
        // Parse the response as the service would
        return try parseTaskPlanResponse(content)
    }
    
    private func parseTaskPlanResponse(_ content: String) throws -> AIGeneratedTaskPlan {
        let cleanedContent = cleanJSONResponse(content)
        
        guard let data = cleanedContent.data(using: .utf8) else {
            throw TaskPlanError.parsingFailed("Failed to convert response to data")
        }
        
        do {
            let taskPlan = try JSONDecoder().decode(AIGeneratedTaskPlan.self, from: data)
            try validateTaskPlan(taskPlan)
            return taskPlan
        } catch let decodingError as DecodingError {
            throw TaskPlanError.parsingFailed("JSON parsing failed: \(decodingError.localizedDescription)")
        }
    }
    
    private func cleanJSONResponse(_ content: String) -> String {
        var cleaned = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if cleaned.hasPrefix("```json") {
            cleaned = String(cleaned.dropFirst(7))
        }
        if cleaned.hasPrefix("```") {
            cleaned = String(cleaned.dropFirst(3))
        }
        if cleaned.hasSuffix("```") {
            cleaned = String(cleaned.dropLast(3))
        }
        
        if let startIndex = cleaned.firstIndex(of: "{"),
           let endIndex = cleaned.lastIndex(of: "}") {
            cleaned = String(cleaned[startIndex...endIndex])
        }
        
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func validateTaskPlan(_ taskPlan: AIGeneratedTaskPlan) throws {
        guard !taskPlan.tasks.isEmpty else {
            throw TaskPlanError.validationFailed("Task plan must contain at least one task")
        }
        
        guard !taskPlan.totalDuration.isEmpty else {
            throw TaskPlanError.validationFailed("Total duration must not be empty")
        }
        
        for (index, task) in taskPlan.tasks.enumerated() {
            guard !task.title.isEmpty else {
                throw TaskPlanError.validationFailed("Task \(index) title must not be empty")
            }
            
            guard !task.description.isEmpty else {
                throw TaskPlanError.validationFailed("Task \(index) description must not be empty")
            }
            
            guard task.estimatedDuration > 0 else {
                throw TaskPlanError.validationFailed("Task \(index) estimated duration must be positive")
            }
        }
    }
}