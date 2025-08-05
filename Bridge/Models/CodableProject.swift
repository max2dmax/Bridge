//
// CodableProject.swift
// Bridge
//
// This file contains the CodableProject model for disk persistence of Projects.
// Only stores file paths and metadata, never lyrics content directly.
// Lyrics content is always stored in separate .txt files referenced by file paths.
//

import Foundation
import UIKit

/// A Codable representation of Project for disk persistence.
struct CodableProject: Codable {
    let title: String
    let files: [String]          // file paths
    let artworkData: Data?       // PNG data
    let fontName: String?
    let useBold: Bool?
    let useItalic: Bool?
}

extension CodableProject {
    /// Convert from CodableProject back to Project
    func toProject() -> Project {
        let artImage = artworkData.flatMap { UIImage(data: $0) }
        let fileURLs = files.map { URL(fileURLWithPath: $0) }
        return Project(
            title: title,
            artwork: artImage,
            files: fileURLs,
            fontName: fontName ?? "System",
            useBold: useBold ?? false,
            useItalic: useItalic ?? false
        )
    }
}

extension Project {
    /// Convert Project into its CodableProject form
    func toCodable() -> CodableProject {
        let artData = artwork?.pngData()
        let paths = files.map { $0.path }
        return CodableProject(
            title: title,
            files: paths,
            artworkData: artData,
            fontName: fontName,
            useBold: useBold,
            useItalic: useItalic
        )
    }
}//
//  CodableProject.swift
//  Bridge
//
//  Created by Max stevenson on 8/5/25.
//

