//
//  BridgeTests.swift
//  BridgeTests
//
//  Created by Max Stevenson on 8/1/25.
//

import Testing
import Foundation
@testable import Bridge

struct BridgeTests {

    @Test func testEnsureLyricsFileCreation() async throws {
        // Create a temporary directory for test
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        // Create a project without lyrics file
        var project = Project(title: "Test Song", artwork: nil, files: [])
        
        // Ensure lyrics file is created
        ensureLyricsFile(for: &project)
        
        // Verify lyrics file was added to project
        let lyricsFiles = project.files.filter { $0.pathExtension.lowercased() == "txt" }
        #expect(lyricsFiles.count == 1, "Project should have exactly one lyrics file")
        
        // Verify the file actually exists
        let lyricsFile = lyricsFiles.first!
        #expect(FileManager.default.fileExists(atPath: lyricsFile.path), "Lyrics file should exist on disk")
        
        // Verify we can read empty lyrics
        let lyrics = loadLyrics(from: project)
        #expect(lyrics == "", "New lyrics file should be empty")
    }

    @Test func testLyricsLoadSave() async throws {
        // Create a project with a lyrics file
        var project = Project(title: "Test Song", artwork: nil, files: [])
        ensureLyricsFile(for: &project)
        
        let testLyrics = "This is a test song\nWith multiple lines\nOf lyrics"
        
        // Save lyrics
        saveLyrics(testLyrics, to: project)
        
        // Load lyrics and verify
        let loadedLyrics = loadLyrics(from: project)
        #expect(loadedLyrics == testLyrics, "Loaded lyrics should match saved lyrics")
        
        // Clean up
        if let lyricsFile = project.files.first(where: { $0.pathExtension.lowercased() == "txt" }) {
            try? FileManager.default.removeItem(at: lyricsFile)
        }
    }

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

}
