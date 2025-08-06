//
// GradientPickerView.swift
// Bridge
//
// DEPRECATED: This view is maintained for backwards compatibility.
// Use SettingsView instead for new implementations.
// This file redirects to the new SettingsView.
//

import SwiftUI

/// Legacy gradient picker view - redirects to SettingsView
/// Maintained for backwards compatibility
@available(*, deprecated, message: "Use SettingsView instead")
struct GradientPickerView: View {
    @Binding var preferences: UserPreferences
    let projects: [Project]
    let onSave: () -> Void
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        SettingsView(projects: projects)
            .onDisappear {
                onSave()
            }
    }
}