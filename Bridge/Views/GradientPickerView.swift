//
// GradientPickerView.swift
// Bridge
//
// This file contains the gradient picker modal that allows users to customize
// background gradients by choosing between "All" mode (all projects) and "Selected" mode.
// Also provides username editing functionality.
//

import SwiftUI

struct GradientPickerView: View {
    @Binding var preferences: UserPreferences
    let projects: [Project]
    let onSave: () -> Void
    @Environment(\.presentationMode) var presentationMode
    
    @State private var tempUsername: String = ""
    @State private var tempMode: UserPreferences.GradientMode = .all
    @State private var tempSelectedIds: Set<UUID> = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Username editing section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Display Name")
                            .font(.headline)
                        Spacer()
                    }
                    
                    TextField("Enter display name", text: $tempUsername)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal)
                
                Divider()
                
                // Gradient mode selection
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Background Gradient")
                            .font(.headline)
                        Spacer()
                    }
                    
                    Picker("Gradient Mode", selection: $tempMode) {
                        ForEach(UserPreferences.GradientMode.allCases, id: \.self) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    // Mode descriptions
                    VStack(alignment: .leading, spacing: 8) {
                        Text(modeDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                
                // Project selection grid (only visible in Selected mode)
                if tempMode == .selected {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Select Projects for Gradient")
                                .font(.headline)
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        ScrollView {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                                ForEach(projects) { project in
                                    ProjectSelectionCard(
                                        project: project,
                                        isSelected: tempSelectedIds.contains(project.id)
                                    ) {
                                        toggleProjectSelection(project.id)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Customize Home")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveChanges()
                }
            )
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
        tempUsername = preferences.username
        tempMode = preferences.gradientMode
        tempSelectedIds = Set(preferences.selectedProjectIds)
    }
    
    private func toggleProjectSelection(_ projectId: UUID) {
        if tempSelectedIds.contains(projectId) {
            tempSelectedIds.remove(projectId)
        } else {
            tempSelectedIds.insert(projectId)
        }
    }
    
    private func saveChanges() {
        preferences.username = tempUsername.isEmpty ? "Home" : tempUsername
        preferences.gradientMode = tempMode
        preferences.selectedProjectIds = Array(tempSelectedIds)
        
        onSave()
        presentationMode.wrappedValue.dismiss()
    }
}

/// Individual project card for selection in the grid
struct ProjectSelectionCard: View {
    let project: Project
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 80)
                    .cornerRadius(12)
                
                if let artwork = project.artwork {
                    Image(uiImage: artwork)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 80)
                        .cornerRadius(12)
                        .clipped()
                }
                
                // Selection overlay
                if isSelected {
                    Rectangle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(height: 80)
                        .cornerRadius(12)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }
            
            Text(project.title)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .onTapGesture {
            onTap()
        }
    }
}

#Preview {
    GradientPickerView(
        preferences: .constant(UserPreferences.default),
        projects: [],
        onSave: {}
    )
}