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

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }
    
    @Test func testProjectLyricsFileSaving() async throws {
        // Test case for lyrics file creation and saving with new logic
        let project = Project(
            title: "Test Project",
            artwork: nil,
            files: [] // No existing lyrics file
        )
        
        // Verify project starts without lyrics file
        let txtFiles = project.files.filter { $0.pathExtension.lowercased() == "txt" }
        #expect(txtFiles.isEmpty, "Project should start without lyrics file")
        
        // Test creating a lyrics file using the updated logic
        if let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let sanitizedTitle = project.title.replacingOccurrences(of: "[^a-zA-Z0-9 ]", with: "", options: .regularExpression)
            let fileName = "\(sanitizedTitle)_lyrics.txt"
            let lyricsURL = documentsDir.appendingPathComponent(fileName)
            
            let testLyrics = "Test lyrics content\nLine 2"
            
            // Test the write operation
            let writeSuccess = (try? testLyrics.write(to: lyricsURL, atomically: true, encoding: .utf8)) != nil
            #expect(writeSuccess, "Should be able to write lyrics to file")
            
            // Verify file was created
            #expect(FileManager.default.fileExists(atPath: lyricsURL.path), "Lyrics file should be created")
            
            // Verify file content
            let savedContent = try String(contentsOf: lyricsURL, encoding: .utf8)
            #expect(savedContent == testLyrics, "Saved lyrics content should match")
            
            // Clean up
            try? FileManager.default.removeItem(at: lyricsURL)
        } else {
            #expect(Bool(false), "Should be able to access documents directory")
        }
    }

}
