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

    // MARK: - Equatable
    static func == (lhs: Project, rhs: Project) -> Bool {
        // Don't compare artwork (UIImage) as it's not Equatable
        return lhs.id == rhs.id &&
            lhs.title == rhs.title &&
            lhs.files == rhs.files &&
            lhs.fontName == rhs.fontName &&
            lhs.useBold == rhs.useBold &&
            lhs.useItalic == rhs.useItalic
            // Don't compare .archive unless ProjectArchive is Equatable
    }

    // MARK: - Hashable
    func hash(into hasher: inout Hasher) {
        // Don't include artwork or archive in hash as UIImage and ProjectArchive may not be Hashable
        hasher.combine(id)
        hasher.combine(title)
        hasher.combine(files)
        hasher.combine(fontName)
        hasher.combine(useBold)
        hasher.combine(useItalic)
    }
}
