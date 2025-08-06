//
// ProjectExporter.swift
// Bridge
//
// Utility functions for exporting and downloading project files.
// Creates zip files containing all project data including archives.
// Ensures iOS Files app compatibility with proper file naming and structure.
//

import Foundation
import UIKit
import ZIPFoundation
import UniformTypeIdentifiers

/// Handles project file export and download functionality
struct ProjectExporter {
    
    /// Export all project files as a zip archive
    /// - Parameter project: The project to export
    /// - Returns: URL of the created zip file, or nil if export failed
    static func exportProject(_ project: Project) -> URL? {
        guard let tempDir = createTempExportDirectory(for: project) else {
            print("Failed to create temporary export directory")
            return nil
        }
        
        do {
            // Create project structure
            try createProjectStructure(for: project, in: tempDir)
            
            // Create zip file
            let zipURL = try createZipFile(from: tempDir, for: project)
            
            // Clean up temp directory
            try? FileManager.default.removeItem(at: tempDir)
            
            print("Successfully exported project to: \(zipURL.path)")
            return zipURL
            
        } catch {
            print("Failed to export project: \(error)")
            // Clean up on failure
            try? FileManager.default.removeItem(at: tempDir)
            return nil
        }
    }
    
    /// Create temporary directory for export preparation
    private static func createTempExportDirectory(for project: Project) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ProjectExport_\(project.id.uuidString)")
        
        do {
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            return tempDir
        } catch {
            print("Failed to create temp export directory: \(error)")
            return nil
        }
    }
    
    /// Create the project folder structure in the export directory
    private static func createProjectStructure(for project: Project, in exportDir: URL) throws {
        let safeTitle = sanitizeFileName(project.title)
        let projectDir = exportDir.appendingPathComponent(safeTitle)
        
        try FileManager.default.createDirectory(at: projectDir, withIntermediateDirectories: true)
        
        // Export current files
        try exportCurrentFiles(from: project, to: projectDir)
        
        // Export artwork variations
        try exportArtworkVariations(from: project, to: projectDir)
        
        // Export archive files
        try exportArchiveFiles(from: project, to: projectDir)
        
        // Create project info file
        try createProjectInfoFile(for: project, in: projectDir)
    }
    
    /// Export current project files (lyrics, audio)
    private static func exportCurrentFiles(from project: Project, to projectDir: URL) throws {
        // Export lyrics
        let lyrics = loadLyrics(from: project)
        if !lyrics.isEmpty {
            let lyricsURL = projectDir.appendingPathComponent("Current_Lyrics.txt")
            try lyrics.write(to: lyricsURL, atomically: true, encoding: .utf8)
        }
        
        // Export audio files
        let audioFiles = project.files.filter { $0.pathExtension.lowercased() == "mp3" }
        for audioFile in audioFiles {
            let destinationURL = projectDir.appendingPathComponent("Current_\(audioFile.lastPathComponent)")
            try FileManager.default.copyItem(at: audioFile, to: destinationURL)
        }
    }
    
    /// Export artwork with and without title overlay
    private static func exportArtworkVariations(from project: Project, to projectDir: URL) throws {
        guard let artwork = project.artwork else { return }
        
        // Original artwork
        if let originalData = artwork.pngData() {
            let originalURL = projectDir.appendingPathComponent("Current_Artwork_Original.png")
            try originalData.write(to: originalURL)
        }
        
        // Artwork with title overlay
        if let overlaidArtwork = createArtworkWithTitleOverlay(artwork: artwork, project: project),
           let overlaidData = overlaidArtwork.pngData() {
            let overlaidURL = projectDir.appendingPathComponent("Current_Artwork_With_Title.png")
            try overlaidData.write(to: overlaidURL)
        }
    }
    
    /// Create artwork with title overlay matching the ProjectDetailView style
    private static func createArtworkWithTitleOverlay(artwork: UIImage, project: Project) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: artwork.size)
        
        return renderer.image { context in
            // Draw original artwork
            artwork.draw(in: CGRect(origin: .zero, size: artwork.size))
            
            // Determine text color based on artwork brightness
            let isArtLight = artwork.dominantColor()?.cgColor.components?.first ?? 0.5 > 0.7
            let textColor = isArtLight ? UIColor.black : UIColor.white
            
            // Set up text attributes
            let fontSize = min(artwork.size.width, artwork.size.height) * 0.1 // Scale font to image size
            var font = UIFont.systemFont(ofSize: fontSize)
            
            // Apply custom font if not system
            if project.fontName != "System" {
                font = UIFont(name: project.fontName, size: fontSize) ?? font
            }
            
            // Apply bold/italic
            if project.useBold || project.useItalic {
                var traits: UIFontDescriptor.SymbolicTraits = []
                if project.useBold { traits.insert(.traitBold) }
                if project.useItalic { traits.insert(.traitItalic) }
                
                if let descriptor = font.fontDescriptor.withSymbolicTraits(traits) {
                    font = UIFont(descriptor: descriptor, size: fontSize)
                }
            }
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: textColor
            ]
            
            // Calculate text position (centered)
            let text = project.title as NSString
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (artwork.size.width - textSize.width) / 2,
                y: (artwork.size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            
            // Draw text
            text.draw(in: textRect, withAttributes: attributes)
        }
    }
    
    /// Export archived files to a subfolder
    private static func exportArchiveFiles(from project: Project, to projectDir: URL) throws {
        guard !project.archive.entries.isEmpty else { return }
        
        let archiveDir = projectDir.appendingPathComponent("Archive")
        try FileManager.default.createDirectory(at: archiveDir, withIntermediateDirectories: true)
        
        for entry in project.archive.entries {
            guard let sourceURL = entry.fileURL, FileManager.default.fileExists(atPath: sourceURL.path) else {
                continue
            }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
            let timestamp = formatter.string(from: entry.timestamp)
            
            let fileName = "\(entry.entryType.displayName)_\(timestamp).\(entry.entryType.fileExtension)"
            let destinationURL = archiveDir.appendingPathComponent(fileName)
            
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
        }
    }
    
    /// Create a project info file with metadata
    private static func createProjectInfoFile(for project: Project, in projectDir: URL) throws {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        
        var info = "Project Export Information\n"
        info += "========================\n\n"
        info += "Project Title: \(project.title)\n"
        info += "Export Date: \(formatter.string(from: Date()))\n"
        info += "Files Included: \(project.files.count)\n"
        info += "Archive Entries: \(project.archive.entries.count)\n\n"
        
        info += "Font Settings:\n"
        info += "- Font: \(project.fontName)\n"
        info += "- Bold: \(project.useBold ? "Yes" : "No")\n"
        info += "- Italic: \(project.useItalic ? "Yes" : "No")\n\n"
        
        if !project.archive.entries.isEmpty {
            info += "Archive Contents:\n"
            for entry in project.archive.entries {
                info += "- \(entry.label) (\(entry.entryType.displayName))\n"
            }
        }
        
        let infoURL = projectDir.appendingPathComponent("Project_Info.txt")
        try info.write(to: infoURL, atomically: true, encoding: .utf8)
    }
    
    /// Create zip file from the prepared project directory
    private static func createZipFile(from tempDir: URL, for project: Project) throws -> URL {
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let safeTitle = sanitizeFileName(project.title)
        let zipFileName = "\(safeTitle)_Export.zip"
        let zipURL = documentsDir.appendingPathComponent(zipFileName)
        
        // Remove existing zip if it exists
        if FileManager.default.fileExists(atPath: zipURL.path) {
            try FileManager.default.removeItem(at: zipURL)
        }
        
        // Create zip archive
        try FileManager.default.zipItem(at: tempDir, to: zipURL)
        
        return zipURL
    }
    
    /// Sanitize filename for cross-platform compatibility
    private static func sanitizeFileName(_ fileName: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "/<>:\"|?*")
        return fileName.components(separatedBy: invalidCharacters).joined(separator: "_")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}