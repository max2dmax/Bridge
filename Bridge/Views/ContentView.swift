//
// ContentView.swift
// Bridge
//
// This file contains the main ContentView for the Bridge app.
// Shows the list of projects with navigation to music player and project details.
// Now includes drag & drop reordering, username customization, and gradient picker.
// Uses Persistence.swift for all disk operations and UserPreferences for user settings.
//

import SwiftUI
import UIKit


struct ContentView: View {
    // Global app preferences injected via environment
    @EnvironmentObject var appPreferences: AppPreferences
    
    // Core state for projects
    @State private var projects: [Project] = loadProjectsFromDisk()
    
    // Sheet and navigation state
    @State private var showingCreateSheet = false
    @State private var showMusicPlayer = false
    @State private var selectedMP3Project: Project?
    @State private var selectedProject: Project?
    @State private var showingDetails = false
    @State private var isSplashActive = true
    @State private var showingSettings = false // New: settings modal via toolbar gear button

    // Compute gradient colors based on app preferences (All vs Selected mode)
    private var backgroundGradientColors: [Color] {
        return generateGradientColors(projects: projects, preferences: appPreferences)
    }

    // Determine if background is light for title contrast
    // Uses a simple heuristic based on whether we have projects with artworks
    private var isBackgroundLight: Bool {
        // If we have projects with artwork, assume darker background for better contrast
        let hasArtwork = projects.contains { $0.artwork != nil }
        return !hasArtwork // Light text on dark artwork-based backgrounds
    }

    // Floating Action Button uses primary gradient color
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
                        Text(appPreferences.homeTitle)
                            .font(.system(size: 26, weight: .heavy, design: .rounded))
                            .foregroundColor(isBackgroundLight ? .black : .white)
                    )
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                showingSettings = true
                            }) {
                                Image(systemName: "gearshape.fill")
                                    .foregroundColor(isBackgroundLight ? .black : .white)
                            }
                        }
                    }
                }
                .onAppear {
                    // Load projects from disk on appear
                    // This ensures backwards compatibility with existing projects
                    projects = loadProjectsFromDisk()
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
                .sheet(isPresented: $showingSettings) {
                    // Settings modal accessed via toolbar gear button
                    SettingsView(projects: projects)
                }
            }
        }
    }
    
    /// Handle drag & drop reordering of projects
    /// Immediately persists the new order to maintain consistency
    private func moveProjects(from source: IndexSet, to destination: Int) {
        projects.move(fromOffsets: source, toOffset: destination)
        // Persist the new order immediately to UserDefaults
        saveProjectsToDisk(projects)
    }
}

#Preview {
    ContentView()
}


