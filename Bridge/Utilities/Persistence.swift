import Foundation
import UIKit

private let savedProjectsKey = "savedProjects"

/// Save projects to UserDefaults. Only stores metadata and file paths, never lyrics content.
func saveProjectsToDisk(_ projects: [Project]) {
    let encoder = JSONEncoder()
    if let encoded = try? encoder.encode(projects.map { $0.toCodable() }) {
        UserDefaults.standard.set(encoded, forKey: savedProjectsKey)
    }
}

/// Load projects from UserDefaults. Lyrics content is loaded separately from .txt files.
func loadProjectsFromDisk() -> [Project] {
    guard let data = UserDefaults.standard.data(forKey: savedProjectsKey) else { return [] }
    let decoder = JSONDecoder()
    guard let codableProjects = try? decoder.decode([CodableProject].self, from: data) else { return [] }
    return codableProjects.map { $0.toProject() }
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
