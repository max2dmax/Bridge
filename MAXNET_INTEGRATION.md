# MAXNET OpenAI Integration Guide

## Overview
The MAXNET chatbot integration provides an AI-powered assistant for musicians and creators within the Bridge app. It uses OpenAI's GPT-3.5-turbo model to offer help with songwriting, production tips, creative inspiration, and technical questions.

## Current Implementation
The integration consists of three main components:
1. **OpenAIService.swift** - Handles API communication with OpenAI
2. **MAXNETChatView.swift** - Provides the chat interface UI  
3. **ProjectDetailView.swift** - Integration point with MAXNET button

## Security Configuration (IMPORTANT)

### Current State - Development Only
The current implementation uses a placeholder API key embedded in the code for development purposes:
```swift
private let apiKey = "YOUR_OPENAI_API_KEY_HERE"
```

**⚠️ WARNING: This is NOT secure for production use.**

### Recommended Production Implementation

For production deployment, implement one of these secure approaches:

#### Option 1: iOS Keychain (Recommended)
```swift
import Security

class SecureStorage {
    private let service = "com.bridge.openai"
    private let account = "api-key"
    
    func storeAPIKey(_ key: String) -> Bool {
        let data = key.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary) // Remove existing
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    func retrieveAPIKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
}
```

#### Option 2: App Settings Integration
Allow users to enter their API key in the app settings:
```swift
// In SettingsView.swift
@State private var openAIAPIKey: String = ""

// Store in UserDefaults (less secure but user-controlled)
UserDefaults.standard.set(openAIAPIKey, forKey: "openai_api_key")
```

#### Option 3: Server-Side Proxy (Most Secure)
Implement a backend service that handles OpenAI API calls:
- Client sends requests to your backend
- Backend adds API key and forwards to OpenAI
- Client never has direct access to API key
- Allows usage monitoring and rate limiting

### Migration Steps

1. **Immediate Setup (Development)**:
   - Replace `"YOUR_OPENAI_API_KEY_HERE"` with your actual OpenAI API key
   - This is only for testing - DO NOT commit real keys to version control

2. **Production Preparation**:
   - Implement one of the secure storage options above
   - Update `OpenAIService.swift` to use secure storage
   - Add API key configuration UI to settings
   - Test thoroughly on device (not just simulator)

3. **Deployment**:
   - Ensure API key is never embedded in the binary
   - Consider implementing usage limits and monitoring
   - Add proper error handling for missing/invalid keys

## Usage

### Basic Integration
The MAXNET button is automatically added to the Project Contents (ProjectDetailView) page. Users can:
1. Tap the "Ask MAXNET for Help" button
2. Chat with the AI assistant about their music project
3. Get contextual help based on their project

### Extending with Project Context
The system is designed to be extensible. Current project context includes:
- Project title
- Number of associated files
- Future: lyrics content, project metadata, etc.

To add more context, modify the `setupInitialMessages()` function in `MAXNETChatView.swift`.

## API Usage and Costs

### Current Configuration
- Model: gpt-3.5-turbo
- Max tokens: 500 per response
- Temperature: 0.7 (balanced creativity)

### Cost Management
- Implement usage tracking
- Consider message limits per user/session
- Monitor API costs in OpenAI dashboard
- Consider caching common responses

## Error Handling

The system handles several error scenarios:
- Invalid/missing API key
- Network connectivity issues
- API rate limits
- Malformed responses
- Service unavailability

All errors are presented to users with clear, actionable messages.

## Future Enhancements

Potential improvements include:
- Project-specific context (lyrics, audio analysis)
- Voice input/output
- Conversation history persistence
- Integration with other AI services
- Collaborative features
- Template responses for common questions

## Testing

Run the included tests with:
```bash
swift test
```

Tests cover:
- Service initialization
- Message creation and handling
- Error scenarios
- UI component initialization

## Support

For issues with the OpenAI integration:
1. Check API key configuration
2. Verify network connectivity
3. Review OpenAI API status
4. Check usage limits and billing
5. Review error logs in Xcode console