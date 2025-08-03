import Foundation

/// Service for generating task plans using Deepseek-R1 AI
class TaskPlanService {
    private let deepseekClient: DeepseekR1Client
    private let jsonDecoder = JSONDecoder()
    
    init(apiKey: String) {
        self.deepseekClient = DeepseekR1Client(apiKey: apiKey)
    }
    
    /// Generate a task plan for a given goal using AI
    /// - Parameters:
    ///   - goalTitle: The title of the goal
    ///   - goalDescription: Detailed description of the goal
    ///   - timeframe: Expected timeframe for completion (optional)
    /// - Returns: Generated task plan with structured tasks
    /// - Throws: TaskPlanError for various failure scenarios
    func generateTaskPlan(
        goalTitle: String,
        goalDescription: String,
        timeframe: String? = nil
    ) async throws -> AIGeneratedTaskPlan {
        
        let prompt = buildTaskPlanPrompt(
            goalTitle: goalTitle,
            goalDescription: goalDescription,
            timeframe: timeframe
        )
        
        let messages = [
            ChatMessage(role: .system, content: getSystemPrompt()),
            ChatMessage(role: .user, content: prompt)
        ]
        
        let request = ChatCompletionRequest(
            messages: messages,
            maxTokens: 2000,
            temperature: 0.7
        )
        
        do {
            let response = try await deepseekClient.chatCompletion(request)
            
            guard let choice = response.choices.first else {
                throw TaskPlanError.emptyResponse("No response choices received")
            }
            
            let content = choice.message.content
            return try parseTaskPlanResponse(content)
            
        } catch let error as DeepseekError {
            throw TaskPlanError.aiServiceError(error.localizedDescription)
        } catch {
            throw TaskPlanError.unknownError(error.localizedDescription)
        }
    }
    
    /// Build the user prompt for task plan generation
    private func buildTaskPlanPrompt(
        goalTitle: String,
        goalDescription: String,
        timeframe: String?
    ) -> String {
        var prompt = """
        请为以下目标生成详细的任务计划：
        
        目标标题：\(goalTitle)
        目标描述：\(goalDescription)
        """
        
        if let timeframe = timeframe, !timeframe.isEmpty {
            prompt += "\n预期完成时间：\(timeframe)"
        }
        
        prompt += """
        
        请生成一个结构化的任务计划，包含以下要求：
        1. 将目标拆解为具体的、可执行的任务
        2. 为每个任务分配合理的时间维度（日、周、月）
        3. 估算每个任务的预计时长（分钟）
        4. 提供任务的详细描述和执行建议
        5. 确保任务之间有逻辑顺序
        
        请严格按照JSON格式返回，不要包含任何其他文本。
        """
        
        return prompt
    }
    
    /// Get the system prompt for AI task planning
    private func getSystemPrompt() -> String {
        return """
        你是一个专业的目标管理和任务规划助手。你的任务是帮助用户将大的目标拆解成具体的、可执行的任务计划。
        
        请遵循以下原则：
        1. 任务要具体、可衡量、可执行
        2. 合理估算时间，避免过于乐观或悲观
        3. 考虑任务的难度递进，从简单到复杂
        4. 提供实用的执行建议
        5. 确保任务计划的完整性和可行性
        
        返回格式必须是有效的JSON，结构如下：
        {
          "totalDuration": "总预计时长描述",
          "tasks": [
            {
              "title": "任务标题",
              "description": "任务详细描述",
              "timeScope": "daily|weekly|monthly",
              "estimatedDuration": 预计时长分钟数,
              "orderIndex": 任务顺序索引,
              "executionTips": "执行建议"
            }
          ]
        }
        """
    }
    
    /// Parse the AI response into a structured task plan
    private func parseTaskPlanResponse(_ content: String) throws -> AIGeneratedTaskPlan {
        // Clean the response - remove any markdown formatting or extra text
        let cleanedContent = cleanJSONResponse(content)
        
        guard let data = cleanedContent.data(using: .utf8) else {
            throw TaskPlanError.parsingFailed("Failed to convert response to data")
        }
        
        do {
            let taskPlan = try jsonDecoder.decode(AIGeneratedTaskPlan.self, from: data)
            
            // Validate the parsed task plan
            try validateTaskPlan(taskPlan)
            
            return taskPlan
        } catch let decodingError as DecodingError {
            throw TaskPlanError.parsingFailed("JSON parsing failed: \(decodingError.localizedDescription)")
        } catch {
            throw error
        }
    }
    
    /// Clean the JSON response by removing markdown formatting and extra text
    private func cleanJSONResponse(_ content: String) -> String {
        var cleaned = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove markdown code blocks
        if cleaned.hasPrefix("```json") {
            cleaned = String(cleaned.dropFirst(7))
        }
        if cleaned.hasPrefix("```") {
            cleaned = String(cleaned.dropFirst(3))
        }
        if cleaned.hasSuffix("```") {
            cleaned = String(cleaned.dropLast(3))
        }
        
        // Find the JSON object boundaries
        if let startIndex = cleaned.firstIndex(of: "{"),
           let endIndex = cleaned.lastIndex(of: "}") {
            cleaned = String(cleaned[startIndex...endIndex])
        }
        
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Validate the generated task plan
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
            
            guard TaskTimeScope.allCases.map(\.rawValue).contains(task.timeScope) else {
                throw TaskPlanError.validationFailed("Task \(index) has invalid time scope: \(task.timeScope)")
            }
        }
    }
}

// MARK: - Data Models

/// AI-generated task plan structure
struct AIGeneratedTaskPlan: Codable {
    let totalDuration: String
    let tasks: [AIGeneratedTask]
}

/// AI-generated task structure
struct AIGeneratedTask: Codable {
    let title: String
    let description: String
    let timeScope: String
    let estimatedDuration: Int
    let orderIndex: Int
    let executionTips: String?
}

// MARK: - Error Types

/// Task plan service specific errors
enum TaskPlanError: Error, LocalizedError {
    case emptyResponse(String)
    case parsingFailed(String)
    case validationFailed(String)
    case aiServiceError(String)
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .emptyResponse(let message):
            return "Empty response: \(message)"
        case .parsingFailed(let message):
            return "Parsing failed: \(message)"
        case .validationFailed(let message):
            return "Validation failed: \(message)"
        case .aiServiceError(let message):
            return "AI service error: \(message)"
        case .unknownError(let message):
            return "Unknown error: \(message)"
        }
    }
}

// MARK: - Extensions

extension TaskPlanService {
    /// Convert AI-generated task plan to domain models
    func convertToTaskPlan(
        _ aiTaskPlan: AIGeneratedTaskPlan,
        branchId: UUID
    ) -> TaskPlan {
        let taskPlan = TaskPlan(
            branchId: branchId,
            totalDuration: aiTaskPlan.totalDuration,
            isAIGenerated: true
        )
        
        let taskItems = aiTaskPlan.tasks.map { aiTask in
            TaskItem(
                title: aiTask.title,
                description: aiTask.description,
                timeScope: TaskTimeScope(rawValue: aiTask.timeScope) ?? .daily,
                estimatedDuration: aiTask.estimatedDuration,
                orderIndex: aiTask.orderIndex,
                executionTips: aiTask.executionTips
            )
        }
        
        taskPlan.tasks = taskItems
        return taskPlan
    }
}