//
// ContentView.swift
// Bridge
//
// This file contains the main ContentView for the Bridge app.
// Shows the list of projects with navigation to music player and project details.
// Uses Persistence.swift for all disk operations and ImagePicker.swift for image selection.
//

import SwiftUI
import UIKit


struct ContentView: View {
    @State private var projects: [Project] = loadProjectsFromDisk()
    @State private var userPreferences: UserPreferences = loadUserPreferences()
    @State private var showingCreateSheet = false
    @State private var showMusicPlayer = false
    @State private var selectedMP3Project: Project?
    @State private var selectedProject: Project?
    @State private var showingDetails = false
    @State private var isSplashActive = true
    @State private var showingGradientPicker = false

    // Compute gradient colors based on user preferences
    private var backgroundGradientColors: [Color] {
        return generateGradientColors(projects: projects, preferences: userPreferences)
    }

    // Determine if background is light for title contrast
    private var isBackgroundLight: Bool {
        // Use first color from gradient to determine contrast
        let firstColor = backgroundGradientColors.first ?? Color.gray
        if let uiColor = UIColor(firstColor) {
            var white: CGFloat = 0
            uiColor.getWhite(&white, alpha: nil)
            return white > 0.7
        }
        return false
    }

    // Floating Action Button dominant color
    private var dominantFABColor: Color {
        // Use the primary gradient color for FAB
        return backgroundGradientColors.first ?? .blue
    }

    var body: some View {
        Group {
            if isSplashActive {
                SplashScreenView(isActive: $isSplashActive, gradientColors: backgroundGradientColors)
            } else {
                NavigationStack {
                    ZStack {
                        // Gradient background based on first project's artwork
                        LinearGradient(
                            gradient: Gradient(colors: backgroundGradientColors),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .ignoresSafeArea()

                        VStack {
                            List {
                                ForEach(projects) { project in
                                    NavigationLink(destination: ProjectMusicPlayerView(project: project)) {
                                        HStack {
                                            if let artwork = project.artwork {
                                                Image(uiImage: artwork)
                                                    .resizable()
                                                    .frame(width: 50, height: 50)
                                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                            } else {
                                                Rectangle()
                                                    .fill(Color.gray.opacity(0.2))
                                                    .frame(width: 50, height: 50)
                                            }
                                            Text(project.title)
                                        }
                                    }
                                    .contentShape(Rectangle())
                                    .swipeActions(edge: .trailing) {
                                        Button("Project Contents") {
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                selectedProject = project
                                                showingDetails = true
                                            }
                                        }
                                        .tint(.blue)
                                    }
                                    .swipeActions(edge: .leading) {
                                        Button(role: .destructive) {
                                            if let index = projects.firstIndex(of: project) {
                                                projects.remove(at: index)
                                                saveProjectsToDisk(projects)
                                            }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                    .listRowBackground(Color.clear)
                                }
                                .onMove(perform: moveProjects) // Enable drag & drop reordering
                            }
                            .listStyle(.plain)
                            .background(Color.clear)
                            Spacer()
                        }
                        // Floating Action Button (FAB)
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Button(action: {
                                    showingCreateSheet = true
                                }) {
                                    Image(systemName: "plus")
                                        .resizable()
                                        .frame(width: 24, height: 24)
                                        .padding()
                                        .background(dominantFABColor)
                                        .foregroundColor(.white)
                                        .clipShape(Circle())
                                        .shadow(radius: 4)
                                }
                                .padding()
                            }
                        }
                    }
                    .navigationTitle(
                        Text(userPreferences.username)
                            .font(.system(size: 26, weight: .heavy, design: .rounded))
                            .foregroundColor(isBackgroundLight ? .black : .white)
                            .onLongPressGesture {
                                // Long press on title opens gradient picker
                                showingGradientPicker = true
                            }
                    )
                }
                .onAppear {
                    // Load from disk on appear and refresh user preferences
                    projects = loadProjectsFromDisk()
                    userPreferences = loadUserPreferences()
                    NotificationCenter.default.addObserver(forName: Notification.Name("ProjectListShouldRefresh"), object: nil, queue: .main) { _ in
                        projects = projects
                    }
                }
                .sheet(isPresented: $showingCreateSheet) {
                    CreateProjectView { newProject in
                        projects.append(newProject)
                        saveProjectsToDisk(projects)
                        projects = projects // Trigger view update
                    }
                }
                .sheet(isPresented: $showingDetails, onDismiss: {
                    selectedProject = nil
                }) {
                    Group {
                        if let project = selectedProject {
                            NavigationStack {
                                ProjectDetailView(project: project, onUpdate: { updated in
                                    if let index = projects.firstIndex(where: { $0.id == updated.id }) {
                                        projects[index] = updated
                                    } else {
                                        projects.append(updated)
                                    }
                                    saveProjectsToDisk(projects)
                                })
                            }
                        } else {
                            NavigationStack {
                                Text("Failed to load project.")
                                    .font(.title)
                                    .padding()
                            }
                        }
                    }
                }
                .sheet(isPresented: $showingGradientPicker) {
                    GradientPickerView(
                        preferences: $userPreferences,
                        projects: projects,
                        onSave: {
                            // Save preferences and refresh view
                            saveUserPreferences(userPreferences)
                        }
                    )
                }
            }
        }
    }
    
    /// Handle drag & drop reordering of projects
    private func moveProjects(from source: IndexSet, to destination: Int) {
        projects.move(fromOffsets: source, toOffset: destination)
        // Persist the new order immediately
        saveProjectsToDisk(projects)
    }
}

#Preview {
    ContentView()
}


