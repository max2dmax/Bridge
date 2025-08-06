//
//  ArchiveTests.swift
//  BridgeTests
//
//  Test cases for the Archive functionality
//

import Testing
import Foundation
@testable import Bridge

struct ArchiveTests {

    @Test func testArchiveEntryCreation() async throws {
        let testFilePath = "/tmp/test_lyrics.txt"
        let entry = ArchiveEntry(type: .lyrics, filePath: testFilePath)
        
        #expect(entry.entryType == .lyrics, "Entry type should be lyrics")
        #expect(entry.filePath == testFilePath, "File path should match")
        #expect(entry.label.contains("Lyrics updated"), "Label should contain 'Lyrics updated'")
        #expect(entry.fileURL?.path == testFilePath, "File URL should match path")
    }

    @Test func testProjectArchiveAddEntry() async throws {
        var archive = ProjectArchive()
        let entry = ArchiveEntry(type: .lyrics, filePath: "/tmp/test.txt")
        
        archive.addEntry(entry)
        
        #expect(archive.entries.count == 1, "Archive should have one entry")
        #expect(archive.entries.first?.id == entry.id, "Entry should match")
    }

    @Test func testArchiveDirectoryCreation() async throws {
        let projectId = UUID()
        let archiveDir = ProjectArchive.archiveDirectory(for: projectId)
        
        #expect(archiveDir != nil, "Archive directory should be created")
        
        if let archiveDir = archiveDir {
            #expect(FileManager.default.fileExists(atPath: archiveDir.path), "Directory should exist on disk")
            #expect(archiveDir.lastPathComponent == projectId.uuidString, "Directory name should match project ID")
            
            // Clean up
            try? FileManager.default.removeItem(at: archiveDir.deletingLastPathComponent())
        }
    }

    @Test func testArchiveEntryTypes() async throws {
        let types: [ArchiveEntry.ArchiveEntryType] = [.lyrics, .audio, .artwork, .maxnetConversation]
        let expectedExtensions = ["txt", "mp3", "png", "txt"]
        let expectedNames = ["Lyrics", "Audio", "Artwork", "MAXNET Chat"]
        
        for (index, type) in types.enumerated() {
            #expect(type.fileExtension == expectedExtensions[index], "File extension should match for \(type)")
            #expect(type.displayName == expectedNames[index], "Display name should match for \(type)")
        }
    }
}