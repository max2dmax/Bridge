//
// UserPreferences.swift
// Bridge
//
// This file contains the UserPreferences model for storing user customization settings.
// Handles persistent storage of username, gradient mode, selected projects, and project ordering.
//

import Foundation

/// User customization preferences that persist between app launches
struct UserPreferences: Codable {
    var username: String = "Home"
    var gradientMode: GradientMode = .all
    var selectedProjectIds: [UUID] = []
    var projectOrder: [UUID] = [] // Order of project IDs for drag & drop persistence
    
    enum GradientMode: String, Codable, CaseIterable {
        case all = "all"        // Use all dominant colors from all project artworks
        case selected = "selected"  // Use only colors from user-selected projects
        
        var displayName: String {
            switch self {
            case .all: return "All"
            case .selected: return "Selected"
            }
        }
    }
}

/// Extension to provide default UserPreferences
extension UserPreferences {
    static let `default` = UserPreferences()
}