//
// Project.swift
// Bridge
//
// This file contains the Project model representing a music project.
// Projects always have a lyrics .txt file in their files array.
// Use Persistence.swift functions for creating/loading/saving projects.
//

import Foundation
import UIKit

struct Project: Identifiable, Equatable, Hashable {
    let id = UUID()
    var title: String
    var artwork: UIImage?
    var files: [URL]
    var fontName: String = "System"
    var useBold: Bool = false
    var useItalic: Bool = false
    var archive: ProjectArchive = ProjectArchive() // Archive for this project
}
//  Project.swift
//  Bridge
//
//  Created by Max stevenson on 8/5/25.
//

