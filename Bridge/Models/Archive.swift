//
// Archive.swift
// Bridge
//
// Archive models for storing timestamped versions of project components.
// Supports archiving lyrics, audio files, artwork, and MAXNET conversations.
// All archive data persists locally using file system storage.
//

import Foundation
import UIKit

/// Represents a single archived item with timestamp and metadata
struct ArchiveEntry: Codable, Identifiable {
    let id = UUID()
    let timestamp: Date
    let entryType: ArchiveEntryType
    let label: String
    let filePath: String  // Path to the archived file
    
    enum ArchiveEntryType: String, Codable, CaseIterable {
        case lyrics = "lyrics"
        case audio = "audio" 
        case artwork = "artwork"
        case maxnetConversation = "maxnet_conversation"
        
        var displayName: String {
            switch self {
            case .lyrics: return "Lyrics"
            case .audio: return "Audio"
            case .artwork: return "Artwork"
            case .maxnetConversation: return "MAXNET Chat"
            }
        }
        
        var fileExtension: String {
            switch self {
            case .lyrics, .maxnetConversation: return "txt"
            case .audio: return "mp3"
            case .artwork: return "png"
            }
        }
    }
    
    /// Create a new archive entry with auto-generated label
    init(type: ArchiveEntryType, filePath: String, customLabel: String? = nil) {
        self.timestamp = Date()
        self.entryType = type
        self.filePath = filePath
        
        // Auto-generate descriptive label if none provided
        if let customLabel = customLabel {
            self.label = customLabel
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            
            switch type {
            case .lyrics:
                self.label = "Lyrics updated \(formatter.string(from: timestamp))"
            case .audio:
                self.label = "Audio swapped \(formatter.string(from: timestamp))"
            case .artwork:
                self.label = "Artwork changed \(formatter.string(from: timestamp))"
            case .maxnetConversation:
                self.label = "MAXNET chat \(formatter.string(from: timestamp))"
            }
        }
    }
    
    /// Get the full URL for this archive entry's file
    var fileURL: URL? {
        return URL(fileURLWithPath: filePath)
    }
    
    /// Check if the archived file still exists on disk
    var fileExists: Bool {
        return FileManager.default.fileExists(atPath: filePath)
    }
}

/// Container for all archive entries belonging to a project
struct ProjectArchive: Codable {
    var entries: [ArchiveEntry] = []
    
    /// Add a new archive entry
    mutating func addEntry(_ entry: ArchiveEntry) {
        entries.append(entry)
        // Sort by timestamp, newest first
        entries.sort { $0.timestamp > $1.timestamp }
    }
    
    /// Remove an archive entry and optionally delete its file
    mutating func removeEntry(withId id: UUID, deleteFile: Bool = false) {
        if deleteFile,
           let entry = entries.first(where: { $0.id == id }),
           let fileURL = entry.fileURL {
            try? FileManager.default.removeItem(at: fileURL)
        }
        entries.removeAll { $0.id == id }
    }
    
    /// Get entries filtered by type
    func entries(ofType type: ArchiveEntry.ArchiveEntryType) -> [ArchiveEntry] {
        return entries.filter { $0.entryType == type }
    }
    
    /// Get the archive directory for a specific project
    static func archiveDirectory(for projectId: UUID) -> URL? {
        guard let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let archiveDir = documentsDir.appendingPathComponent("Archives").appendingPathComponent(projectId.uuidString)
        
        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: archiveDir, withIntermediateDirectories: true)
        
        return archiveDir
    }
    
    /// Clean up any orphaned archive files (files that exist but aren't referenced)
    func cleanupOrphanedFiles(in directory: URL) {
        let referencedPaths = Set(entries.map { $0.filePath })
        
        guard let fileEnumerator = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: nil) else {
            return
        }
        
        for case let fileURL as URL in fileEnumerator {
            if !referencedPaths.contains(fileURL.path) {
                try? FileManager.default.removeItem(at: fileURL)
            }
        }
    }
    
    /// Remove entries older than the specified number of days (optional cleanup)
    mutating func removeEntriesOlderThan(days: Int, deleteFiles: Bool = true) {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date.distantPast
        let entriesToRemove = entries.filter { $0.timestamp < cutoffDate }
        
        for entry in entriesToRemove {
            if deleteFiles, let fileURL = entry.fileURL {
                try? FileManager.default.removeItem(at: fileURL)
            }
        }
        
        entries.removeAll { $0.timestamp < cutoffDate }
    }
    
    /// Get total file size of all archive entries
    var totalArchiveSize: Int64 {
        var totalSize: Int64 = 0
        for entry in entries {
            if let fileURL = entry.fileURL,
               let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
               let fileSize = attributes[.size] as? Int64 {
                totalSize += fileSize
            }
        }
        return totalSize
    }
    
    /// Get formatted string representation of archive size
    var formattedArchiveSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalArchiveSize)
    }
}