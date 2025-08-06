import Foundation

/// HTTP client for Deepseek-R1 API integration
class DeepseekR1Client {
    private let baseURL = "https://api.deepseek.com/v1"
    private let apiKey: String
    private let session: URLSession
    private let maxRetries: Int
    private let timeoutInterval: TimeInterval
    
    /// Initialize the Deepseek-R1 client
    /// - Parameters:
    ///   - apiKey: API key for authentication
    ///   - maxRetries: Maximum number of retry attempts (default: 3)
    ///   - timeoutInterval: Request timeout in seconds (default: 30)
    init(apiKey: String, maxRetries: Int = 3, timeoutInterval: TimeInterval = 30) {
        self.apiKey = apiKey
        self.maxRetries = maxRetries
        self.timeoutInterval = timeoutInterval
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeoutInterval
        config.timeoutIntervalForResource = timeoutInterval * 2
        self.session = URLSession(configuration: config)
    }
    
    /// Send a chat completion request to Deepseek-R1
    /// - Parameter request: The chat completion request
    /// - Returns: The chat completion response
    /// - Throws: DeepseekClientError for various failure scenarios
    func chatCompletion(_ request: ChatCompletionRequest) async throws -> ChatCompletionResponse {
        let url = URL(string: "\(baseURL)/chat/completions")!
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            throw DeepseekClientError.encodingFailed("Failed to encode request: \(error.localizedDescription)")
        }
        
        return try await performRequestWithRetry(urlRequest)
    }
    
    /// Perform HTTP request with retry mechanism
    private func performRequestWithRetry(_ request: URLRequest) async throws -> ChatCompletionResponse {
        var lastError: Error?
        
        for attempt in 0..<maxRetries {
            do {
                let (data, response) = try await session.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw DeepseekClientError.invalidResponse("Invalid response type")
                }
                
                // Handle HTTP status codes
                switch httpResponse.statusCode {
                case 200...299:
                    return try decodeResponse(data)
                case 400:
                    throw DeepseekClientError.badRequest(try decodeErrorResponse(data))
                case 401:
                    throw DeepseekClientError.unauthorized("Invalid API key")
                case 403:
                    throw DeepseekClientError.forbidden("Access forbidden")
                case 429:
                    // Rate limit - wait before retry
                    if attempt < maxRetries - 1 {
                        let delay = calculateRetryDelay(attempt: attempt)
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        continue
                    }
                    throw DeepseekClientError.rateLimited("Rate limit exceeded")
                case 500...599:
                    // Server error - retry
                    if attempt < maxRetries - 1 {
                        let delay = calculateRetryDelay(attempt: attempt)
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        continue
                    }
                    throw DeepseekClientError.serverError("Server error: \(httpResponse.statusCode)")
                default:
                    throw DeepseekClientError.httpError("HTTP error: \(httpResponse.statusCode)")
                }
                
            } catch let error as DeepseekClientError {
                throw error
            } catch {
                lastError = error
                if attempt < maxRetries - 1 {
                    let delay = calculateRetryDelay(attempt: attempt)
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                }
            }
        }
        
        throw DeepseekClientError.networkError(lastError?.localizedDescription ?? "Network request failed after \(maxRetries) attempts")
    }
    
    /// Decode successful response
    private func decodeResponse(_ data: Data) throws -> ChatCompletionResponse {
        do {
            return try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        } catch {
            throw DeepseekClientError.decodingFailed("Failed to decode response: \(error.localizedDescription)")
        }
    }
    
    /// Decode error response
    private func decodeErrorResponse(_ data: Data) -> String {
        if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
            return errorResponse.error.message
        }
        return "Unknown error"
    }
    
    /// Calculate exponential backoff delay
    private func calculateRetryDelay(attempt: Int) -> Double {
        let baseDelay = 1.0
        let maxDelay = 16.0
        let delay = baseDelay * pow(2.0, Double(attempt))
        return min(delay, maxDelay)
    }
}

// MARK: - AI Review Generation Extension

extension DeepseekR1Client {
    
    /// Generate branch review report using AI
    /// - Parameters:
    ///   - branch: The branch to generate review for
    ///   - reviewType: Type of review (completion or abandonment)
    /// - Returns: Structured review data
    /// - Throws: DeepseekClientError for various failure scenarios
    func generateBranchReview(for branch: Branch, reviewType: ReviewType) async throws -> BranchReviewData {
        let prompt = createReviewPrompt(for: branch, reviewType: reviewType)
        
        let request = ChatCompletionRequest(
            messages: [
                ChatMessage(role: .system, content: "你是一个专业的人生目标管理顾问，擅长分析用户的目标执行情况并提供深入的复盘分析和建议。请以JSON格式返回结构化的复盘报告。"),
                ChatMessage(role: .user, content: prompt)
            ],
            maxTokens: 3000,
            temperature: 0.7
        )
        
        let response = try await chatCompletion(request)
        
        guard let content = response.choices.first?.message.content else {
            throw DeepseekClientError.decodingFailed("No content in AI response")
        }
        
        return try parseReviewResponse(content, reviewType: reviewType)
    }
    
    /// Create review prompt based on branch data and review type
    private func createReviewPrompt(for branch: Branch, reviewType: ReviewType) -> String {
        let commits = branch.commits.sorted { $0.timestamp < $1.timestamp }
        let taskPlan = branch.taskPlan
        let totalDays = Calendar.current.dateComponents([.day], from: branch.createdAt, to: Date()).day ?? 0
        let completedTasks = taskPlan?.tasks.filter { $0.isCompleted }.count ?? 0
        let totalTasks = taskPlan?.tasks.count ?? 0
        let completionRate = totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) : 0.0
        
        let baseInfo = """
        目标分支信息：
        - 分支名称：\(branch.name)
        - 目标描述：\(branch.branchDescription)
        - 创建时间：\(formatDate(branch.createdAt))
        - 状态：\(reviewType == .completion ? "已完成" : "已废弃")
        - 执行天数：\(totalDays)天
        - 总提交数：\(commits.count)次
        - 任务完成情况：\(completedTasks)/\(totalTasks) (\(String(format: "%.1f", completionRate * 100))%)
        - 平均每日提交：\(totalDays > 0 ? String(format: "%.1f", Double(commits.count) / Double(totalDays)) : "0.0")次
        """
        
        let commitHistory = commits.isEmpty ? "无提交记录" : commits.map { commit in
            "- \(formatDate(commit.timestamp)) [\(commit.type.rawValue)] \(commit.message)"
        }.joined(separator: "\n")
        
        let taskDetails = taskPlan?.tasks.isEmpty == false ? taskPlan!.tasks.map { task in
            "- \(task.isCompleted ? "✅" : "❌") \(task.title) (\(task.timeScope.rawValue), \(task.estimatedDuration)分钟)"
        }.joined(separator: "\n") : "无任务计划"
        
        let specificPrompt: String
        if reviewType == .completion {
            specificPrompt = """
            
            这是一个成功完成的目标分支，请生成完成复盘报告。重点分析：
            1. 目标达成的关键成功因素
            2. 执行过程中的亮点和优势
            3. 时间管理和效率表现
            4. 可以复制到其他目标的经验
            5. 未来类似目标的优化建议
            """
        } else {
            specificPrompt = """
            
            这是一个被废弃的目标分支，请生成废弃复盘报告。重点分析：
            1. 导致废弃的主要原因（时间冲突、难度过高、优先级变化、外部因素等）
            2. 执行过程中遇到的具体挑战和困难
            3. 从这次失败中可以学到的宝贵经验教训
            4. 目标设定、任务规划或执行方式存在的问题
            5. 如何在未来避免类似问题再次发生
            6. 这次经历中仍然有价值的部分（技能、知识、认知等）
            7. 如何将学到的经验应用到新的目标中
            
            请以积极的态度分析失败，强调学习和成长的价值，避免过度自责。
            """
        }
        
        return """
        \(baseInfo)
        
        提交历史：
        \(commitHistory)
        
        任务详情：
        \(taskDetails)
        \(specificPrompt)
        
        请以以下JSON格式返回复盘报告：
        {
          "summary": "复盘总结（100-200字）",
          "achievements": "成就分析（具体列举取得的成果）",
          "challenges": "挑战分析（遇到的困难和障碍）",
          "lessonsLearned": "经验教训（从中学到的重要经验）",
          "recommendations": "改进建议（具体的优化建议）",
          "nextSteps": "下一步建议（后续行动建议）",
          "timeEfficiencyScore": 8.5,
          "goalAchievementScore": 9.0,
          "overallScore": 8.7
        }
        
        评分标准（0-10分）：
        - timeEfficiencyScore: 时间效率评分，考虑执行速度和时间利用率
        - goalAchievementScore: 目标达成评分，考虑完成度和质量
        - overallScore: 综合评分，综合考虑各方面表现
        """
    }
    
    /// Parse AI response into structured review data
    private func parseReviewResponse(_ content: String, reviewType: ReviewType) throws -> BranchReviewData {
        // Extract JSON from response (AI might include additional text)
        guard let jsonStart = content.range(of: "{"),
              let jsonEnd = content.range(of: "}", options: .backwards) else {
            throw DeepseekClientError.decodingFailed("No JSON found in AI response")
        }
        
        let jsonString = String(content[jsonStart.lowerBound...jsonEnd.upperBound])
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw DeepseekClientError.decodingFailed("Failed to convert JSON string to data")
        }
        
        do {
            var reviewData = try JSONDecoder().decode(BranchReviewData.self, from: jsonData)
            reviewData.reviewType = reviewType
            return reviewData
        } catch {
            throw DeepseekClientError.decodingFailed("Failed to parse review JSON: \(error.localizedDescription)")
        }
    }
    
    /// Format date for display in prompts
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

// MARK: - Abandonment Analysis Extension

extension DeepseekR1Client {
    
    /// Generate detailed abandonment analysis
    /// - Parameter branch: The abandoned branch to analyze
    /// - Returns: Comprehensive abandonment analysis data
    /// - Throws: DeepseekClientError for various failure scenarios
    func generateAbandonmentAnalysis(for branch: Branch) async throws -> AbandonmentAnalysisData {
        let prompt = createAbandonmentAnalysisPrompt(for: branch)
        
        let request = ChatCompletionRequest(
            messages: [
                ChatMessage(role: .system, content: "你是一个专业的心理学家和目标管理专家，擅长从失败中提取价值和学习机会。请以积极、建设性的态度分析失败，帮助用户从挫折中成长。"),
                ChatMessage(role: .user, content: prompt)
            ],
            maxTokens: 4000,
            temperature: 0.8
        )
        
        let response = try await chatCompletion(request)
        
        guard let content = response.choices.first?.message.content else {
            throw DeepseekClientError.decodingFailed("No content in AI response")
        }
        
        return try parseAbandonmentAnalysisResponse(content)
    }
    
    /// Generate failure pattern analysis across multiple branches
    /// - Parameter branches: List of abandoned branches to analyze
    /// - Returns: Pattern analysis data
    /// - Throws: DeepseekClientError for various failure scenarios
    func generateFailurePatternAnalysis(for branches: [Branch]) async throws -> FailurePatternAnalysisData {
        let prompt = createFailurePatternAnalysisPrompt(for: branches)
        
        let request = ChatCompletionRequest(
            messages: [
                ChatMessage(role: .system, content: "你是一个数据分析专家和行为心理学家，擅长识别行为模式和系统性问题。请客观分析用户的失败模式，并提供建设性的改进建议。"),
                ChatMessage(role: .user, content: prompt)
            ],
            maxTokens: 4000,
            temperature: 0.7
        )
        
        let response = try await chatCompletion(request)
        
        guard let content = response.choices.first?.message.content else {
            throw DeepseekClientError.decodingFailed("No content in AI response")
        }
        
        return try parseFailurePatternAnalysisResponse(content)
    }
    
    /// Create detailed abandonment analysis prompt
    private func createAbandonmentAnalysisPrompt(for branch: Branch) -> String {
        let commits = branch.commits.sorted { $0.timestamp < $1.timestamp }
        let taskPlan = branch.taskPlan
        let totalDays = Calendar.current.dateComponents([.day], from: branch.createdAt, to: Date()).day ?? 0
        let completedTasks = taskPlan?.tasks.filter { $0.isCompleted }.count ?? 0
        let totalTasks = taskPlan?.tasks.count ?? 0
        
        let branchInfo = """
        废弃分支详细信息：
        - 分支名称：\(branch.name)
        - 目标描述：\(branch.branchDescription)
        - 创建时间：\(formatDate(branch.createdAt))
        - 废弃时间：\(formatDate(Date()))
        - 执行天数：\(totalDays)天
        - 总提交数：\(commits.count)次
        - 任务完成情况：\(completedTasks)/\(totalTasks)
        - 完成率：\(totalTasks > 0 ? String(format: "%.1f", Double(completedTasks) / Double(totalTasks) * 100) : "0")%
        """
        
        let commitHistory = commits.isEmpty ? "无提交记录" : commits.map { commit in
            "- \(formatDate(commit.timestamp)) [\(commit.type.rawValue)] \(commit.message)"
        }.joined(separator: "\n")
        
        let taskDetails = taskPlan?.tasks.isEmpty == false ? taskPlan!.tasks.map { task in
            "- \(task.isCompleted ? "✅" : "❌") \(task.title) (\(task.timeScope.rawValue))"
        }.joined(separator: "\n") : "无任务计划"
        
        return """
        \(branchInfo)
        
        提交历史：
        \(commitHistory)
        
        任务详情：
        \(taskDetails)
        
        请对这个废弃的目标进行深度分析，以JSON格式返回：
        
        {
          "failureReasons": ["具体的失败原因1", "具体的失败原因2"],
          "challengesFaced": ["遇到的挑战1", "遇到的挑战2"],
          "lessonsLearned": ["学到的教训1", "学到的教训2"],
          "valueExtracted": ["提取的价值1", "提取的价值2"],
          "preventionStrategies": ["预防策略1", "预防策略2"],
          "futureApplications": ["未来应用1", "未来应用2"],
          "emotionalImpact": "对情感和心理状态的影响分析",
          "recoveryRecommendations": "恢复和重新开始的具体建议",
          "resilienceScore": 7.5,
          "learningScore": 8.0,
          "adaptabilityScore": 6.5
        }
        
        分析要求：
        1. 客观分析失败原因，避免过度自责
        2. 识别过程中的积极因素和学习价值
        3. 提供具体可行的改进建议
        4. 评分标准（0-10分）：
           - resilienceScore: 面对挫折的韧性表现
           - learningScore: 从失败中学习的能力
           - adaptabilityScore: 调整策略的适应能力
        """
    }
    
    /// Create failure pattern analysis prompt
    private func createFailurePatternAnalysisPrompt(for branches: [Branch]) -> String {
        let branchSummaries = branches.map { branch in
            let totalDays = Calendar.current.dateComponents([.day], from: branch.createdAt, to: Date()).day ?? 0
            let completedTasks = branch.taskPlan?.tasks.filter { $0.isCompleted }.count ?? 0
            let totalTasks = branch.taskPlan?.tasks.count ?? 0
            
            return """
            分支：\(branch.name)
            - 描述：\(branch.branchDescription)
            - 执行天数：\(totalDays)天
            - 提交数：\(branch.commits.count)次
            - 完成率：\(totalTasks > 0 ? String(format: "%.1f", Double(completedTasks) / Double(totalTasks) * 100) : "0")%
            """
        }.joined(separator: "\n\n")
        
        return """
        用户的废弃分支历史：
        
        \(branchSummaries)
        
        请分析这些废弃分支的共同模式，以JSON格式返回：
        
        {
          "commonFailureReasons": ["常见失败原因1", "常见失败原因2"],
          "recurringChallenges": ["重复挑战1", "重复挑战2"],
          "behavioralPatterns": ["行为模式1", "行为模式2"],
          "systemicIssues": ["系统性问题1", "系统性问题2"],
          "improvementRecommendations": ["改进建议1", "改进建议2"],
          "strengthsIdentified": ["识别的优势1", "识别的优势2"],
          "riskFactors": ["风险因素1", "风险因素2"],
          "successPredictors": ["成功预测因子1", "成功预测因子2"]
        }
        
        分析重点：
        1. 识别重复出现的失败模式
        2. 发现潜在的系统性问题
        3. 提取可复制的成功因素
        4. 提供个性化的改进策略
        """
    }
    
    /// Parse abandonment analysis response
    private func parseAbandonmentAnalysisResponse(_ content: String) throws -> AbandonmentAnalysisData {
        guard let jsonStart = content.range(of: "{"),
              let jsonEnd = content.range(of: "}", options: .backwards) else {
            throw DeepseekClientError.decodingFailed("No JSON found in abandonment analysis response")
        }
        
        let jsonString = String(content[jsonStart.lowerBound...jsonEnd.upperBound])
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw DeepseekClientError.decodingFailed("Failed to convert JSON string to data")
        }
        
        do {
            return try JSONDecoder().decode(AbandonmentAnalysisData.self, from: jsonData)
        } catch {
            throw DeepseekClientError.decodingFailed("Failed to parse abandonment analysis JSON: \(error.localizedDescription)")
        }
    }
    
    /// Parse failure pattern analysis response
    private func parseFailurePatternAnalysisResponse(_ content: String) throws -> FailurePatternAnalysisData {
        guard let jsonStart = content.range(of: "{"),
              let jsonEnd = content.range(of: "}", options: .backwards) else {
            throw DeepseekClientError.decodingFailed("No JSON found in pattern analysis response")
        }
        
        let jsonString = String(content[jsonStart.lowerBound...jsonEnd.upperBound])
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw DeepseekClientError.decodingFailed("Failed to convert JSON string to data")
        }
        
        do {
            return try JSONDecoder().decode(FailurePatternAnalysisData.self, from: jsonData)
        } catch {
            throw DeepseekClientError.decodingFailed("Failed to parse pattern analysis JSON: \(error.localizedDescription)")
        }
    }
}

// MARK: - Review Data Models

/// Structured data from AI review generation
struct BranchReviewData: Codable {
    let summary: String
    let achievements: String
    let challenges: String
    let lessonsLearned: String
    let recommendations: String
    let nextSteps: String
    let timeEfficiencyScore: Double
    let goalAchievementScore: Double
    let overallScore: Double
    var reviewType: ReviewType = .completion
}

/// Structured data from AI abandonment analysis
struct AbandonmentAnalysisData: Codable {
    let failureReasons: [String]
    let challengesFaced: [String]
    let lessonsLearned: [String]
    let valueExtracted: [String]
    let preventionStrategies: [String]
    let futureApplications: [String]
    let emotionalImpact: String
    let recoveryRecommendations: String
    let resilienceScore: Double
    let learningScore: Double
    let adaptabilityScore: Double
}

/// Structured data from AI failure pattern analysis
struct FailurePatternAnalysisData: Codable {
    let commonFailureReasons: [String]
    let recurringChallenges: [String]
    let behavioralPatterns: [String]
    let systemicIssues: [String]
    let improvementRecommendations: [String]
    let strengthsIdentified: [String]
    let riskFactors: [String]
    let successPredictors: [String]
}

// MARK: - Request/Response Models

/// Chat completion request model
struct ChatCompletionRequest: Codable {
    let model: String
    let messages: [ChatMessage]
    let maxTokens: Int
    let temperature: Double
    let stream: Bool
    
    enum CodingKeys: String, CodingKey {
        case model, messages, temperature, stream
        case maxTokens = "max_tokens"
    }
    
    init(model: String = "deepseek-r1", 
         messages: [ChatMessage], 
         maxTokens: Int = 2000, 
         temperature: Double = 0.7, 
         stream: Bool = false) {
        self.model = model
        self.messages = messages
        self.maxTokens = maxTokens
        self.temperature = temperature
        self.stream = stream
    }
}

/// Chat message model
struct ChatMessage: Codable {
    let role: String
    let content: String
    
    init(role: MessageRole, content: String) {
        self.role = role.rawValue
        self.content = content
    }
}

/// Message role enumeration
enum MessageRole: String, CaseIterable {
    case system = "system"
    case user = "user"
    case assistant = "assistant"
}

/// Chat completion response model
struct ChatCompletionResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [Choice]
    let usage: Usage
}

/// Choice model in response
struct Choice: Codable {
    let index: Int
    let message: ChatMessage
    let finishReason: String?
    
    enum CodingKeys: String, CodingKey {
        case index, message
        case finishReason = "finish_reason"
    }
}

/// Usage statistics model
struct Usage: Codable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

/// Error response model
struct ErrorResponse: Codable {
    let error: APIError
}

/// API error model
struct APIError: Codable {
    let message: String
    let type: String?
    let code: String?
}

// MARK: - Error Types

/// Deepseek API specific errors
enum DeepseekClientError: Error, LocalizedError {
    case encodingFailed(String)
    case decodingFailed(String)
    case networkError(String)
    case invalidResponse(String)
    case badRequest(String)
    case unauthorized(String)
    case forbidden(String)
    case rateLimited(String)
    case serverError(String)
    case httpError(String)
    
    var errorDescription: String? {
        switch self {
        case .encodingFailed(let message):
            return "Encoding failed: \(message)"
        case .decodingFailed(let message):
            return "Decoding failed: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .invalidResponse(let message):
            return "Invalid response: \(message)"
        case .badRequest(let message):
            return "Bad request: \(message)"
        case .unauthorized(let message):
            return "Unauthorized: \(message)"
        case .forbidden(let message):
            return "Forbidden: \(message)"
        case .rateLimited(let message):
            return "Rate limited: \(message)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .httpError(let message):
            return "HTTP error: \(message)"
        }
    }
}