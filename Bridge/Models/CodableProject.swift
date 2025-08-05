// CodableProject.swift

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
    let lyrics: String?
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
            useItalic: useItalic ?? false,
            lyrics: lyrics
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
            useItalic: useItalic,
            lyrics: lyrics
        )
    }
}//
//  CodableProject.swift
//  Bridge
//
//  Created by Max stevenson on 8/5/25.
//

