//
// UserPreferences.swift
// Bridge
//
// This file contains the AppPreferences model for storing user customization settings.
// Implements ObservableObject for reactive UI updates and handles persistent storage
// of home page title, gradient mode, selected projects, and project ordering.
//

import Foundation
import SwiftUI

/// Global app preferences that persist between app launches
/// Implements ObservableObject for reactive UI updates across the app
class AppPreferences: ObservableObject, Codable {
    @Published var homeTitle: String = "Home"
    @Published var gradientMode: GradientMode = .all
    @Published var selectedProjectIds: [UUID] = []
    @Published var projectOrder: [UUID] = [] // Order of project IDs for drag & drop persistence
    
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
    
    // MARK: - Initializers
    
    init() {
        // Default initializer with default values
    }
    
    init(homeTitle: String = "Home", gradientMode: GradientMode = .all, selectedProjectIds: [UUID] = [], projectOrder: [UUID] = []) {
        self.homeTitle = homeTitle
        self.gradientMode = gradientMode
        self.selectedProjectIds = selectedProjectIds
        self.projectOrder = projectOrder
    }
    
    // MARK: - Codable Implementation
    
    private enum CodingKeys: String, CodingKey {
        case username // Keep old key name for backwards compatibility
        case gradientMode
        case selectedProjectIds
        case projectOrder
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Use "username" key for backwards compatibility with existing UserDefaults
        homeTitle = try container.decodeIfPresent(String.self, forKey: .username) ?? "Home"
        gradientMode = try container.decodeIfPresent(GradientMode.self, forKey: .gradientMode) ?? .all
        selectedProjectIds = try container.decodeIfPresent([UUID].self, forKey: .selectedProjectIds) ?? []
        projectOrder = try container.decodeIfPresent([UUID].self, forKey: .projectOrder) ?? []
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Use "username" key for backwards compatibility with existing UserDefaults
        try container.encode(homeTitle, forKey: .username)
        try container.encode(gradientMode, forKey: .gradientMode)
        try container.encode(selectedProjectIds, forKey: .selectedProjectIds)
        try container.encode(projectOrder, forKey: .projectOrder)
    }
}

/// Extension to provide default AppPreferences
extension AppPreferences {
    static let `default` = AppPreferences()
}

// MARK: - Legacy Support

/// Legacy type alias for backwards compatibility
/// This ensures existing code continues to work during the transition
typealias UserPreferences = AppPreferences