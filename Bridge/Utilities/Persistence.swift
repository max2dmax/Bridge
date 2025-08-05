//
// Persistence.swift
// Bridge
//
// This file contains all disk persistence operations for Projects.
// Handles saving/loading project metadata (file paths, not content) to/from UserDefaults.
// Lyrics content is always stored in separate .txt files referenced by Project.files.
//

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
func ensureLyricsFile(for project: inout Project) {
    // Check if project already has a .txt file
    if project.files.contains(where: { $0.pathExtension.lowercased() == "txt" }) {
        return
    }
    
    // Create a new lyrics file
    guard let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
        return
    }
    
    let lyricsFileName = "Lyrics_\(project.title.replacingOccurrences(of: " ", with: "_"))_\(UUID().uuidString.prefix(6)).txt"
    let lyricsURL = documentsDir.appendingPathComponent(lyricsFileName)
    
    // Create empty lyrics file
    do {
        try "".write(to: lyricsURL, atomically: true, encoding: .utf8)
        project.files.append(lyricsURL)
    } catch {
        print("Failed to create lyrics file: \(error)")
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