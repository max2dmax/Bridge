//
// OpenAIService.swift
// Bridge
//
// OpenAI API integration service for MAXNET chatbot functionality.
// Handles chat/completions API calls with proper error handling and loading states.
//
// TODO: SECURITY IMPROVEMENT NEEDED
// Currently uses a placeholder API key embedded in code. For production deployment:
// 1. Store API key in iOS Keychain using Security framework
// 2. Or use app-specific secure storage (Core Data with encryption)
// 3. Or implement server-side proxy to avoid client-side API key exposure
// 4. Consider using environment-specific configuration files
//

import Foundation

/// OpenAI API service for chat completions
class OpenAIService: ObservableObject {
    
    // MARK: - Security Notice
    // TODO: REPLACE WITH SECURE STORAGE - DO NOT COMMIT REAL API KEYS
    // This is a placeholder for development. In production, store securely in Keychain
    private let apiKey = "YOUR_OPENAI_API_KEY_HERE" // Replace with actual API key
    
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    /// Chat message structure for OpenAI API
    struct ChatMessage: Codable, Identifiable, Equatable {
        let id = UUID()
        let role: String // "system", "user", or "assistant" 
        let content: String
        
        // Custom init for easy creation
        init(role: String, content: String) {
            self.role = role
            self.content = content
        }
    }
    
    /// OpenAI API request structure
    private struct ChatCompletionRequest: Codable {
        let model: String
        let messages: [ChatMessage]
        let max_tokens: Int?
        let temperature: Double?
    }
    
    /// OpenAI API response structure 
    private struct ChatCompletionResponse: Codable {
        let choices: [Choice]
        
        struct Choice: Codable {
            let message: ChatMessage
        }
    }
    
    /// Custom error types for better error handling
    enum OpenAIError: LocalizedError {
        case invalidAPIKey
        case networkError(Error)
        case decodingError(Error)
        case apiError(String)
        case invalidResponse
        
        var errorDescription: String? {
            switch self {
            case .invalidAPIKey:
                return "Invalid API key. Please check your OpenAI API key configuration."
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .decodingError(let error):
                return "Failed to parse response: \(error.localizedDescription)"
            case .apiError(let message):
                return "API error: \(message)"
            case .invalidResponse:
                return "Invalid response from OpenAI API"
            }
        }
    }
    
    /// Send chat completion request to OpenAI API
    /// - Parameters:
    ///   - messages: Array of chat messages including system, user, and assistant messages
    ///   - completion: Completion handler with Result containing response message or error
    func sendChatCompletion(messages: [ChatMessage], completion: @escaping (Result<String, OpenAIError>) -> Void) {
        
        // Validate API key is not placeholder
        guard apiKey != "YOUR_OPENAI_API_KEY_HERE" && !apiKey.isEmpty else {
            completion(.failure(.invalidAPIKey))
            return
        }
        
        guard let url = URL(string: baseURL) else {
            completion(.failure(.invalidResponse))
            return
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create request body
        let requestBody = ChatCompletionRequest(
            model: "gpt-3.5-turbo",
            messages: messages,
            max_tokens: 500, // Reasonable limit for chat responses
            temperature: 0.7 // Balanced creativity vs consistency
        )
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            completion(.failure(.decodingError(error)))
            return
        }
        
        // Send request
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(.networkError(error)))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(.invalidResponse))
                }
                return
            }
            
            // Check for HTTP errors
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = errorData["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    DispatchQueue.main.async {
                        completion(.failure(.apiError(message)))
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(.apiError("HTTP \(httpResponse.statusCode)")))
                    }
                }
                return
            }
            
            // Parse response
            do {
                let response = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
                if let assistantMessage = response.choices.first?.message.content {
                    DispatchQueue.main.async {
                        completion(.success(assistantMessage))
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(.invalidResponse))
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(.decodingError(error)))
                }
            }
        }.resume()
    }
}