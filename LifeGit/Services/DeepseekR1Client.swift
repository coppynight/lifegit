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
    /// - Throws: DeepseekError for various failure scenarios
    func chatCompletion(_ request: ChatCompletionRequest) async throws -> ChatCompletionResponse {
        let url = URL(string: "\(baseURL)/chat/completions")!
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            throw DeepseekError.encodingFailed("Failed to encode request: \(error.localizedDescription)")
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
                    throw DeepseekError.invalidResponse("Invalid response type")
                }
                
                // Handle HTTP status codes
                switch httpResponse.statusCode {
                case 200...299:
                    return try decodeResponse(data)
                case 400:
                    throw DeepseekError.badRequest(try decodeErrorResponse(data))
                case 401:
                    throw DeepseekError.unauthorized("Invalid API key")
                case 403:
                    throw DeepseekError.forbidden("Access forbidden")
                case 429:
                    // Rate limit - wait before retry
                    if attempt < maxRetries - 1 {
                        let delay = calculateRetryDelay(attempt: attempt)
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        continue
                    }
                    throw DeepseekError.rateLimited("Rate limit exceeded")
                case 500...599:
                    // Server error - retry
                    if attempt < maxRetries - 1 {
                        let delay = calculateRetryDelay(attempt: attempt)
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        continue
                    }
                    throw DeepseekError.serverError("Server error: \(httpResponse.statusCode)")
                default:
                    throw DeepseekError.httpError("HTTP error: \(httpResponse.statusCode)")
                }
                
            } catch let error as DeepseekError {
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
        
        throw DeepseekError.networkError(lastError?.localizedDescription ?? "Network request failed after \(maxRetries) attempts")
    }
    
    /// Decode successful response
    private func decodeResponse(_ data: Data) throws -> ChatCompletionResponse {
        do {
            return try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        } catch {
            throw DeepseekError.decodingFailed("Failed to decode response: \(error.localizedDescription)")
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
enum DeepseekError: Error, LocalizedError {
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