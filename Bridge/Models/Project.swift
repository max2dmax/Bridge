//// Project.swift

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
}
//  Project.swift
//  Bridge
//
//  Created by Max stevenson on 8/5/25.
//

