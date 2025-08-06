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

    @Test func testAppPreferencesBackwardsCompatibility() async throws {
        // Test that AppPreferences can decode old UserPreferences JSON format
        let oldUserPreferencesJSON = """
        {
            "username": "My Custom Home Title",
            "gradientMode": "selected", 
            "selectedProjectIds": ["12345678-1234-1234-1234-123456789012"],
            "projectOrder": ["12345678-1234-1234-1234-123456789012"]
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let appPreferences = try decoder.decode(AppPreferences.self, from: oldUserPreferencesJSON)
        
        #expect(appPreferences.homeTitle == "My Custom Home Title", "Home title should be decoded from old 'username' field")
        #expect(appPreferences.gradientMode == .selected, "Gradient mode should be preserved")
        #expect(appPreferences.selectedProjectIds.count == 1, "Selected project IDs should be preserved")
        #expect(appPreferences.projectOrder.count == 1, "Project order should be preserved")
    }
    
    @Test func testAppPreferencesEncodingUsesOldKeys() async throws {
        // Test that AppPreferences encodes using old keys for backwards compatibility
        let appPreferences = AppPreferences(
            homeTitle: "Test Title",
            gradientMode: .all,
            selectedProjectIds: [],
            projectOrder: []
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(appPreferences)
        let jsonString = String(data: data, encoding: .utf8)!
        
        #expect(jsonString.contains("\"username\""), "Should encode homeTitle as 'username' for backwards compatibility")
        #expect(jsonString.contains("Test Title"), "Should contain the home title value")
    }

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

}
