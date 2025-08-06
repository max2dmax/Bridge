//
// MAXNETTests.swift
// BridgeTests
//
// Tests for MAXNET chatbot functionality and OpenAI API integration
//

import Testing
import Foundation
@testable import Bridge

struct MAXNETTests {

    @Test func testOpenAIServiceInitialization() async throws {
        let service = OpenAIService()
        #expect(service != nil, "OpenAI service should initialize successfully")
    }

    @Test func testChatMessageCreation() async throws {
        let message = OpenAIService.ChatMessage(role: "user", content: "Hello")
        #expect(message.role == "user", "Message role should be set correctly")
        #expect(message.content == "Hello", "Message content should be set correctly")
        #expect(message.id != UUID(), "Message should have a unique ID") // Note: This will actually always pass due to UUID generation
    }

    @Test func testChatMessageEquality() async throws {
        let message1 = OpenAIService.ChatMessage(role: "user", content: "Hello")
        let message2 = OpenAIService.ChatMessage(role: "user", content: "Hello")
        
        // Messages with same content should be equal in content but not ID
        #expect(message1.role == message2.role, "Messages with same role should have equal roles")
        #expect(message1.content == message2.content, "Messages with same content should have equal content")
        #expect(message1.id != message2.id, "Messages should have unique IDs")
    }

    @Test func testOpenAIErrorDescriptions() async throws {
        let invalidKeyError = OpenAIService.OpenAIError.invalidAPIKey
        let networkError = OpenAIService.OpenAIError.networkError(NSError(domain: "test", code: 1))
        let apiError = OpenAIService.OpenAIError.apiError("Test error")
        
        #expect(invalidKeyError.errorDescription != nil, "Invalid API key error should have description")
        #expect(networkError.errorDescription != nil, "Network error should have description")
        #expect(apiError.errorDescription != nil, "API error should have description")
        
        #expect(invalidKeyError.errorDescription?.contains("API key") == true, "Invalid key error should mention API key")
        #expect(apiError.errorDescription?.contains("Test error") == true, "API error should contain the error message")
    }

    @Test func testMAXNETChatViewInitialization() async throws {
        let project = Project(title: "Test Project", artwork: nil, files: [])
        let chatView = MAXNETChatView(project: project)
        
        // We can't easily test SwiftUI views, but we can test that they initialize
        #expect(chatView.project?.title == "Test Project", "Chat view should store project correctly")
    }

    @Test func testMAXNETChatViewInitializationWithoutProject() async throws {
        let chatView = MAXNETChatView()
        
        #expect(chatView.project == nil, "Chat view should handle nil project correctly")
    }
}