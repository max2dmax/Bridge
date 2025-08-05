import SwiftUI
import UIKit

// MARK: - Extracted View Components
// SplashScreenView moved to SplashScreenView.swift
// CreateProjectView moved to CreateProjectView.swift
// ProjectMusicPlayerView moved to ProjectMusicPlayerView.swift
// ProjectDetailView moved to ProjectDetailView.swift
// AudioPlayerView moved to AudioPlayerView.swift
// DocumentPicker moved to DocumentPicker.swift
// Dominant color utilities moved to ColorUtils.swift
private let savedProjectsKey = "savedProjects"

func saveProjectsToDisk(_ projects: [Project]) {
    let encoder = JSONEncoder()
    if let encoded = try? encoder.encode(projects.map { project in
        CodableProject(
            title: project.title,
            files: project.files.map { $0.path },
            artworkData: project.artwork?.pngData(),
            fontName: project.fontName,
            useBold: project.useBold,
            useItalic: project.useItalic,
            lyrics: project.lyrics
        )
    }) {
        UserDefaults.standard.set(encoded, forKey: savedProjectsKey)
    }
}

func loadProjectsFromDisk() -> [Project] {
    guard let data = UserDefaults.standard.data(forKey: savedProjectsKey) else { return [] }
    let decoder = JSONDecoder()
    guard let codableProjects = try? decoder.decode([CodableProject].self, from: data) else { return [] }
    return codableProjects.map { codable in
        var project = Project(
            title: codable.title,
            artwork: codable.artworkData.flatMap { UIImage(data: $0) },
            files: codable.files.map { URL(fileURLWithPath: $0) },
            fontName: codable.fontName ?? "System",
            useBold: codable.useBold ?? false,
            useItalic: codable.useItalic ?? false,
            lyrics: codable.lyrics
        )
        
        // Backward compatibility: if lyrics is nil, try to load from .txt file
        if project.lyrics == nil {
            if let txtURL = project.files.first(where: { $0.pathExtension.lowercased() == "txt" }),
               let lyricsContent = try? String(contentsOf: txtURL, encoding: .utf8) {
                project.lyrics = lyricsContent
            }
        }
        
        return project
    }
}


struct ContentView: View {
    @State private var projects: [Project] = loadProjectsFromDisk()
    @State private var showingCreateSheet = false
    @State private var showMusicPlayer = false
    @State private var selectedMP3Project: Project?
    @State private var selectedProject: Project?
    @State private var showingDetails = false
    @State private var isSplashActive = true

    // Compute gradient colors from the first project's artwork, fallback to default
    private var backgroundGradientColors: [Color] {
        if let artwork = projects.first?.artwork {
            return dominantColors(from: artwork)
        }
        return [Color.gray.opacity(0.2), Color.black.opacity(0.3)]
    }

    // Determine if background is light for title contrast
    private var isBackgroundLight: Bool {
        if let uiColor = projects.first?.artwork?.dominantColor() {
            var white: CGFloat = 0
            uiColor.getWhite(&white, alpha: nil)
            return white > 0.7
        }
        return false
    }

    // Floating Action Button dominant color
    private var dominantFABColor: Color {
        if let uiColor = projects.first?.artwork?.dominantColor() {
            return Color(uiColor)
        }
        return .blue
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
                            List(projects) { project in
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
                    .navigationTitle(Text("Home")
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundColor(isBackgroundLight ? .black : .white))
                }
                .onAppear {
                    // Load from disk on appear
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
            }
        }
    }
}



struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            picker.dismiss(animated: true)
        }
    }
}




#Preview {
    ContentView()
}


