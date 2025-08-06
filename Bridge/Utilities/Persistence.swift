import Foundation
import UIKit

private let savedProjectsKey = "savedProjects"
private let userPreferencesKey = "userPreferences"

/// Save projects to UserDefaults. Only stores metadata and file paths, never lyrics content.
/// Also maintains project order consistency with UserPreferences.
func saveProjectsToDisk(_ projects: [Project]) {
    let encoder = JSONEncoder()
    if let encoded = try? encoder.encode(projects.map { $0.toCodable() }) {
        UserDefaults.standard.set(encoded, forKey: savedProjectsKey)
        
        // Update project order in user preferences
        var preferences = loadUserPreferences()
        preferences.projectOrder = projects.map { $0.id }
        saveUserPreferences(preferences)
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
    let preferences = loadUserPreferences()
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

// MARK: - UserPreferences Persistence

/// Load user preferences from UserDefaults with safe migration support
func loadUserPreferences() -> UserPreferences {
    guard let data = UserDefaults.standard.data(forKey: userPreferencesKey) else {
        return UserPreferences.default
    }
    
    let decoder = JSONDecoder()
    do {
        return try decoder.decode(UserPreferences.self, from: data)
    } catch {
        print("Failed to decode user preferences, using defaults: \(error)")
        return UserPreferences.default
    }
}

/// Save user preferences to UserDefaults
func saveUserPreferences(_ preferences: UserPreferences) {
    let encoder = JSONEncoder()
    do {
        let data = try encoder.encode(preferences)
        UserDefaults.standard.set(data, forKey: userPreferencesKey)
    } catch {
        print("Failed to save user preferences: \(error)")
    }
}
