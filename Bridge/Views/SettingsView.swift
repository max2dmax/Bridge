//
// SettingsView.swift
// Bridge
//
// This file contains the main settings view that allows users to customize
// app preferences including home title, background gradients by choosing between
// "All" mode (all projects) and "Selected" mode (specific projects).
// Uses @EnvironmentObject to access and modify global AppPreferences.
//

import SwiftUI

/// Main settings view for customizing app preferences
/// Accessible via the toolbar gear button in ContentView
struct SettingsView: View {
    @EnvironmentObject var appPreferences: AppPreferences
    let projects: [Project]
    @Environment(\.presentationMode) var presentationMode
    
    @State private var tempHomeTitle: String = ""
    @State private var tempMode: AppPreferences.GradientMode = .all
    @State private var tempSelectedIds: Set<UUID> = []
    
    var body: some View {
        NavigationView {
            Form {
                // Home page title section
                Section(header: Text("Home Page")) {
                    HStack {
                        Text("Title")
                        Spacer()
                        TextField("Home title", text: $tempHomeTitle)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    Text("This appears as the main navigation title.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Gradient options section
                Section(header: Text("Background Gradient")) {
                    Picker("Gradient Mode", selection: $tempMode) {
                        ForEach(AppPreferences.GradientMode.allCases, id: \.self) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    Text(modeDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Project selection section (only visible in Selected mode)
                if tempMode == .selected {
                    Section(header: Text("Selected Projects")) {
                        if projects.isEmpty {
                            Text("No projects available")
                                .foregroundColor(.secondary)
                                .italic()
                        } else {
                            ForEach(projects) { project in
                                ProjectSelectionRow(
                                    project: project,
                                    isSelected: tempSelectedIds.contains(project.id)
                                ) {
                                    toggleProjectSelection(project.id)
                                }
                            }
                        }
                        
                        if !tempSelectedIds.isEmpty {
                            Text("\(tempSelectedIds.count) project\(tempSelectedIds.count == 1 ? "" : "s") selected")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Future settings can be added here as new sections
                // Example placeholder for extensibility:
                Section(header: Text("More Settings")) {
                    Text("Additional preferences will appear here in future updates.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            setupTempValues()
        }
    }
    
    private var modeDescription: String {
        switch tempMode {
        case .all:
            return "Uses colors from all project artworks to create the background gradient."
        case .selected:
            return "Uses colors only from the projects you select below."
        }
    }
    
    private func setupTempValues() {
        tempHomeTitle = appPreferences.homeTitle
        tempMode = appPreferences.gradientMode
        tempSelectedIds = Set(appPreferences.selectedProjectIds)
    }
    
    private func toggleProjectSelection(_ projectId: UUID) {
        if tempSelectedIds.contains(projectId) {
            tempSelectedIds.remove(projectId)
        } else {
            tempSelectedIds.insert(projectId)
        }
    }
    
    private func saveChanges() {
        // Update app preferences (will automatically notify observers due to @Published)
        appPreferences.homeTitle = tempHomeTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Home" : tempHomeTitle
        appPreferences.gradientMode = tempMode
        appPreferences.selectedProjectIds = Array(tempSelectedIds)
        
        // Persist changes to UserDefaults
        saveAppPreferences(appPreferences)
        
        presentationMode.wrappedValue.dismiss()
    }
}

/// Individual project row for selection in the settings form
struct ProjectSelectionRow: View {
    let project: Project
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Project artwork thumbnail
                if let artwork = project.artwork {
                    Image(uiImage: artwork)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "music.note")
                                .foregroundColor(.gray)
                                .font(.caption)
                        )
                }
                
                // Project title
                VStack(alignment: .leading, spacing: 2) {
                    Text(project.title)
                        .foregroundColor(.primary)
                    Text("Project")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SettingsView(projects: [])
        .environmentObject(AppPreferences())
}