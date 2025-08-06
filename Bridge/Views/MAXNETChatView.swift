//
// MAXNETChatView.swift
// Bridge
//
// Chat interface view for MAXNET chatbot powered by OpenAI API.
// Provides a scrolling conversation interface with loading states and error handling.
// Designed to be presented modally from ProjectDetailView.
//

import SwiftUI

/// MAXNET chatbot interface view
struct MAXNETChatView: View {
    // MARK: - Environment and State
    @Environment(\.dismiss) private var dismiss
    @StateObject private var openAIService = OpenAIService()
    
    // MARK: - Chat State
    @State private var messages: [OpenAIService.ChatMessage] = []
    @State private var currentMessage = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // MARK: - Project Context (for future enhancement)
    let project: Project?
    
    // MARK: - System Prompt
    private let systemPrompt = "You are MAXNET, a friendly assistant helping musicians and creators with their projects. You're knowledgeable about music production, songwriting, creative processes, and technical aspects of music creation. Be helpful, encouraging, and concise in your responses."
    
    // MARK: - Initializer
    init(project: Project? = nil) {
        self.project = project
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Chat Messages Area
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            // Welcome message
                            if messages.isEmpty {
                                welcomeMessage
                            }
                            
                            // Chat messages
                            ForEach(messages.filter { $0.role != "system" }) { message in
                                ChatMessageView(message: message)
                                    .id(message.id)
                            }
                            
                            // Loading indicator
                            if isLoading {
                                loadingIndicator
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages) { _ in
                        // Auto-scroll to bottom when new messages arrive
                        if let lastMessage = messages.last {
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                Divider()
                
                // Message Input Area
                messageInputArea
            }
            .navigationTitle("MAXNET")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
        }
        .onAppear {
            setupInitialMessages()
        }
    }
    
    // MARK: - Subviews
    
    private var welcomeMessage: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "message.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                Text("MAXNET")
                    .font(.headline)
                    .foregroundColor(.blue)
            }
            
            Text("Hello! I'm MAXNET, your friendly assistant for music and creative projects. I'm here to help with songwriting, production tips, creative inspiration, and technical questions. How can I assist you today?")
                .font(.body)
                .foregroundColor(.secondary)
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.top)
    }
    
    private var loadingIndicator: some View {
        HStack {
            ProgressView()
                .scaleEffect(0.8)
            Text("MAXNET is thinking...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
    
    private var messageInputArea: some View {
        HStack(spacing: 12) {
            TextField("Ask MAXNET anything...", text: $currentMessage, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...4)
                .disabled(isLoading)
            
            Button(action: sendMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundColor(currentMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue)
            }
            .disabled(currentMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
        }
        .padding()
    }
    
    // MARK: - Helper Functions
    
    private func setupInitialMessages() {
        // Add system message (not displayed in UI)
        messages = [OpenAIService.ChatMessage(role: "system", content: systemPrompt)]
        
        // Add project context if available
        if let project = project {
            let contextMessage = "I'm working on a music project called '\(project.title)'. The project has \(project.files.count) files associated with it."
            let systemContext = OpenAIService.ChatMessage(role: "system", content: "User context: \(contextMessage)")
            messages.append(systemContext)
        }
    }
    
    private func sendMessage() {
        let messageText = currentMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !messageText.isEmpty else { return }
        
        // Add user message to conversation
        let userMessage = OpenAIService.ChatMessage(role: "user", content: messageText)
        messages.append(userMessage)
        
        // Clear input and start loading
        currentMessage = ""
        isLoading = true
        errorMessage = nil
        
        // Send to OpenAI API
        openAIService.sendChatCompletion(messages: messages) { result in
            isLoading = false
            
            switch result {
            case .success(let responseText):
                let assistantMessage = OpenAIService.ChatMessage(role: "assistant", content: responseText)
                messages.append(assistantMessage)
                
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Chat Message View

/// Individual chat message view
private struct ChatMessageView: View {
    let message: OpenAIService.ChatMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.role == "user" {
                Spacer()
                messageContent
                    .background(.blue)
                    .foregroundColor(.white)
                profileIcon
            } else {
                profileIcon
                messageContent
                    .background(.gray.opacity(0.1))
                    .foregroundColor(.primary)
                Spacer()
            }
        }
    }
    
    private var profileIcon: some View {
        Image(systemName: message.role == "user" ? "person.circle.fill" : "message.circle.fill")
            .font(.title3)
            .foregroundColor(message.role == "user" ? .blue : .green)
    }
    
    private var messageContent: some View {
        Text(message.content)
            .font(.body)
            .padding(12)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview

#Preview {
    MAXNETChatView(project: Project(title: "My Song", artwork: nil, files: []))
}