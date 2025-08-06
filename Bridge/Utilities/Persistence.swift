import Foundation
import UIKit

private let savedProjectsKey = "savedProjects"
private let userPreferencesKey = "userPreferences"

/// Save projects to UserDefaults. Only stores metadata and file paths, never lyrics content.
/// Also maintains project order consistency with AppPreferences.
func saveProjectsToDisk(_ projects: [Project]) {
    let encoder = JSONEncoder()
    if let encoded = try? encoder.encode(projects.map { $0.toCodable() }) {
        UserDefaults.standard.set(encoded, forKey: savedProjectsKey)
        
        // Update project order in app preferences
        let preferences = loadAppPreferences()
        preferences.projectOrder = projects.map { $0.id }
        saveAppPreferences(preferences)
    }
}

/// Load projects from UserDefaults. Lyrics content is loaded separately from .txt files.
/// Applies user-defined project ordering if available.
func loadProjectsFromDisk() -> [Project] {
    guard let data = UserDefaults.standard.data(forKey: savedProjectsKey) else { return [] }
    let decoder = JSONDecoder()
    guard let codableProjects = try? decoder.decode([CodableProject].self, from: data) else { return [] }
    var projects = codableProjects.map { $0.toProject() }
    
    // Apply user-defined ordering if available
    let preferences = loadAppPreferences()
    if !preferences.projectOrder.isEmpty {
        projects = applyProjectOrdering(projects, order: preferences.projectOrder)
    }
    
    return projects
}

/// Apply user-defined project ordering to a projects array
private func applyProjectOrdering(_ projects: [Project], order: [UUID]) -> [Project] {
    var orderedProjects: [Project] = []
    var projectDict = Dictionary(uniqueKeysWithValues: projects.map { ($0.id, $0) })
    
    // Add projects in the specified order
    for id in order {
        if let project = projectDict.removeValue(forKey: id) {
            orderedProjects.append(project)
        }
    }
    
    // Add any remaining projects (new ones not in the order yet)
    orderedProjects.append(contentsOf: projectDict.values)
    
    return orderedProjects
}

/// Ensure a project has a lyrics file. Creates one if it doesn't exist.
/// If the file is missing on disk, recreate it.
func ensureLyricsFile(for project: inout Project) {
    // Check if a .txt file is listed and if it really exists
    if let lyricsURL = project.files.first(where: { $0.pathExtension.lowercased() == "txt" }) {
        // If file doesn't exist on disk, (re-)create it
        if !FileManager.default.fileExists(atPath: lyricsURL.path) {
            do {
                try "".write(to: lyricsURL, atomically: true, encoding: .utf8)
            } catch {
                print("Failed to (re)create missing lyrics file: \(error)")
            }
        }
        return
    }
    // No .txt file listed, so create one
    if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
        // Use a safe filename
        let safeTitle = project.title.replacingOccurrences(of: " ", with: "_").replacingOccurrences(of: "/", with: "-")
        let fileName = "Lyrics_\(safeTitle)_\(UUID().uuidString.prefix(6)).txt"
        let newLyricsURL = dir.appendingPathComponent(fileName)
        do {
            try "".write(to: newLyricsURL, atomically: true, encoding: .utf8)
            project.files.append(newLyricsURL)
        } catch {
            print("Failed to create lyrics file: \(error)")
        }
    }
}

/// Load lyrics content from a project's .txt file
func loadLyrics(from project: Project) -> String {
    guard let lyricsURL = project.files.first(where: { $0.pathExtension.lowercased() == "txt" }) else {
        return ""
    }
    do {
        return try String(contentsOf: lyricsURL, encoding: .utf8)
    } catch {
        print("Failed to load lyrics: \(error)")
        return ""
    }
}

/// Save lyrics content to a project's .txt file
func saveLyrics(_ lyrics: String, to project: Project) {
    guard let lyricsURL = project.files.first(where: { $0.pathExtension.lowercased() == "txt" }) else {
        print("No lyrics file found in project")
        return
    }
    do {
        try lyrics.write(to: lyricsURL, atomically: true, encoding: .utf8)
    } catch {
        print("Failed to save lyrics: \(error)")
    }
}

// MARK: - AppPreferences Persistence

/// Load app preferences from UserDefaults with safe migration support
/// Provides backwards compatibility - if no preferences exist, uses sensible defaults
func loadAppPreferences() -> AppPreferences {
    guard let data = UserDefaults.standard.data(forKey: userPreferencesKey) else {
        // First time user - return defaults which will provide backwards compatibility
        return AppPreferences.default
    }
    
    let decoder = JSONDecoder()
    do {
        let preferences = try decoder.decode(AppPreferences.self, from: data)
        // Migrate any existing projects into the project order if not already done
        return migrateAppPreferences(preferences)
    } catch {
        print("Failed to decode app preferences (likely version upgrade), using defaults: \(error)")
        return AppPreferences.default
    }
}

/// Migrate app preferences to ensure backwards compatibility
/// Ensures existing projects are included in project order
private func migrateAppPreferences(_ preferences: AppPreferences) -> AppPreferences {
    let migratedPreferences = preferences
    
    // If project order is empty but we haven't migrated yet, populate order
    // Avoid infinite recursion by only calling this during migration
    if migratedPreferences.projectOrder.isEmpty {
        // Get existing projects without triggering another migration
        guard let data = UserDefaults.standard.data(forKey: savedProjectsKey) else {
            return migratedPreferences
        }
        let decoder = JSONDecoder()
        guard let codableProjects = try? decoder.decode([CodableProject].self, from: data) else {
            return migratedPreferences
        }
        let projects = codableProjects.map { $0.toProject() }
        migratedPreferences.projectOrder = projects.map { $0.id }
    }
    
    return migratedPreferences
}

/// Save app preferences to UserDefaults
func saveAppPreferences(_ preferences: AppPreferences) {
    let encoder = JSONEncoder()
    do {
        let data = try encoder.encode(preferences)
        UserDefaults.standard.set(data, forKey: userPreferencesKey)
    } catch {
        print("Failed to save app preferences: \(error)")
    }
}

// MARK: - Legacy Functions for Backwards Compatibility

/// Legacy function for backwards compatibility - loads AppPreferences as UserPreferences
func loadUserPreferences() -> UserPreferences {
    return loadAppPreferences()
}

/// Legacy function for backwards compatibility - saves AppPreferences
func saveUserPreferences(_ preferences: UserPreferences) {
    saveAppPreferences(preferences)
}

// MARK: - Archive Functions

/// Archive the current lyrics content before updating
/// - Parameters:
///   - project: The project whose lyrics will be archived
/// - Returns: True if archiving was successful, false otherwise
func archiveLyrics(for project: inout Project) -> Bool {
    let currentLyrics = loadLyrics(from: project)
    
    // Don't archive empty lyrics
    guard !currentLyrics.isEmpty else { return true }
    
    guard let archiveDir = ProjectArchive.archiveDirectory(for: project.id) else {
        print("Failed to create archive directory for project")
        return false
    }
    
    // Create timestamped archive file
    let timestamp = Date()
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
    let fileName = "lyrics_\(formatter.string(from: timestamp)).txt"
    let archiveURL = archiveDir.appendingPathComponent(fileName)
    
    do {
        try currentLyrics.write(to: archiveURL, atomically: true, encoding: .utf8)
        
        // Create archive entry
        let entry = ArchiveEntry(type: .lyrics, filePath: archiveURL.path)
        project.archive.addEntry(entry)
        
        print("Successfully archived lyrics to: \(archiveURL.path)")
        return true
    } catch {
        print("Failed to archive lyrics: \(error)")
        return false
    }
}

/// Archive the current audio file before updating
/// - Parameters:
///   - project: The project whose audio will be archived
/// - Returns: True if archiving was successful, false otherwise
func archiveAudio(for project: inout Project) -> Bool {
    // Find current audio file
    guard let currentAudioURL = project.files.first(where: { $0.pathExtension.lowercased() == "mp3" }) else {
        return true // No audio to archive
    }
    
    guard let archiveDir = ProjectArchive.archiveDirectory(for: project.id) else {
        print("Failed to create archive directory for project")
        return false
    }
    
    // Create timestamped archive file
    let timestamp = Date()
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
    let fileName = "audio_\(formatter.string(from: timestamp)).mp3"
    let archiveURL = archiveDir.appendingPathComponent(fileName)
    
    do {
        try FileManager.default.copyItem(at: currentAudioURL, to: archiveURL)
        
        // Create archive entry
        let entry = ArchiveEntry(type: .audio, filePath: archiveURL.path)
        project.archive.addEntry(entry)
        
        print("Successfully archived audio to: \(archiveURL.path)")
        return true
    } catch {
        print("Failed to archive audio: \(error)")
        return false
    }
}

/// Archive the current artwork before updating
/// - Parameters:
///   - project: The project whose artwork will be archived
/// - Returns: True if archiving was successful, false otherwise
func archiveArtwork(for project: inout Project) -> Bool {
    guard let currentArtwork = project.artwork else {
        return true // No artwork to archive
    }
    
    guard let archiveDir = ProjectArchive.archiveDirectory(for: project.id) else {
        print("Failed to create archive directory for project")
        return false
    }
    
    // Create timestamped archive file
    let timestamp = Date()
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
    let fileName = "artwork_\(formatter.string(from: timestamp)).png"
    let archiveURL = archiveDir.appendingPathComponent(fileName)
    
    do {
        guard let pngData = currentArtwork.pngData() else {
            print("Failed to convert artwork to PNG data")
            return false
        }
        
        try pngData.write(to: archiveURL)
        
        // Create archive entry
        let entry = ArchiveEntry(type: .artwork, filePath: archiveURL.path)
        project.archive.addEntry(entry)
        
        print("Successfully archived artwork to: \(archiveURL.path)")
        return true
    } catch {
        print("Failed to archive artwork: \(error)")
        return false
    }
}

/// Archive a MAXNET conversation
/// - Parameters:
///   - conversation: The conversation messages to archive  
///   - projectId: The ID of the project this conversation belongs to
/// - Returns: Archive entry if successful, nil otherwise
func archiveMAXNETConversation<T: MAXNETMessage>(_ messages: [T], for projectId: UUID) -> ArchiveEntry? {
    guard let archiveDir = ProjectArchive.archiveDirectory(for: projectId) else {
        print("Failed to create archive directory for project")
        return nil
    }
    
    // Create timestamped archive file
    let timestamp = Date()
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
    let fileName = "maxnet_chat_\(formatter.string(from: timestamp)).txt"
    let archiveURL = archiveDir.appendingPathComponent(fileName)
    
    // Format conversation for text file
    let conversationText = formatConversationForArchive(messages)
    
    do {
        try conversationText.write(to: archiveURL, atomically: true, encoding: .utf8)
        
        // Create archive entry
        let entry = ArchiveEntry(type: .maxnetConversation, filePath: archiveURL.path)
        
        print("Successfully archived MAXNET conversation to: \(archiveURL.path)")
        return entry
    } catch {
        print("Failed to archive MAXNET conversation: \(error)")
        return nil
    }
}

/// Protocol for archivable chat messages
protocol MAXNETMessage {
    var role: String { get }
    var content: String { get }
}

/// Format chat messages into readable text format for archiving
private func formatConversationForArchive<T: MAXNETMessage>(_ messages: [T]) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    
    var conversationText = "MAXNET Conversation - \(formatter.string(from: Date()))\n"
    conversationText += "=" + String(repeating: "=", count: 50) + "\n\n"
    
    for message in messages.filter({ $0.role != "system" }) {
        let speaker = message.role == "user" ? "You" : "MAXNET"
        conversationText += "\(speaker):\n\(message.content)\n\n"
    }
    
    return conversationText
}
