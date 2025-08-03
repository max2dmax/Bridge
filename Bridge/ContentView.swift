private let savedProjectsKey = "savedProjects"

func saveProjectsToDisk(_ projects: [Project]) {
    let encoder = JSONEncoder()
    if let encoded = try? encoder.encode(projects.map { project in
        CodableProject(title: project.title, files: project.files.map { $0.path }, artworkData: project.artwork?.pngData())
    }) {
        UserDefaults.standard.set(encoded, forKey: savedProjectsKey)
    }
}

func loadProjectsFromDisk() -> [Project] {
    guard let data = UserDefaults.standard.data(forKey: savedProjectsKey) else { return [] }
    let decoder = JSONDecoder()
    guard let codableProjects = try? decoder.decode([CodableProject].self, from: data) else { return [] }
    return codableProjects.map { codable in
        Project(title: codable.title,
                artwork: codable.artworkData.flatMap { UIImage(data: $0) },
                files: codable.files.map { URL(fileURLWithPath: $0) })
    }
}

struct CodableProject: Codable {
    let title: String
    let files: [String]
    let artworkData: Data?
}
struct ProjectMusicPlayerView: View {
    let project: Project

    var body: some View {
        VStack(spacing: 20) {
            if let artwork = project.artwork {
                Image(uiImage: artwork)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            if let audioURL = project.files.first(where: { ["mp3", "m4a", "wav", "aac"].contains($0.pathExtension.lowercased()) }) {
                Text("Now Playing: \(audioURL.lastPathComponent)")
                AudioPlayerView(url: audioURL)
            }

            if let lyricsURL = project.files.first(where: { $0.pathExtension == "txt" }),
               let lyrics = try? String(contentsOf: lyricsURL) {
                ScrollView {
                    Text(lyrics)
                        .padding()
                }
                .frame(maxHeight: 200)
            } else {
                Text("No lyrics available.")
            }
        }
        .padding()
    }
}

import Foundation
import SwiftUI
import UniformTypeIdentifiers
import PhotosUI
import AVFoundation

struct Project: Identifiable, Equatable, Hashable {
    let id = UUID()
    var title: String
    var artwork: UIImage?
    var files: [URL]
}

struct ContentView: View {
    @State private var projects: [Project] = loadProjectsFromDisk()
    @State private var showingCreateSheet = false
    @State private var showMusicPlayer = false
    @State private var selectedMP3Project: Project?
    @State private var selectedProject: Project?
    @State private var showingDetails = false

    var body: some View {
        NavigationStack {
            VStack {
                Button(action: {
                    showingCreateSheet = true
                }) {
                    Text("Create New Song Project")
                        .fontWeight(.semibold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()

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
                                    .overlay(Text("Music"))
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
                }
                .listStyle(.plain)
            }
            .navigationTitle(Text("BRIDGE")
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundColor(.purple))
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
            if let project = selectedProject {
                NavigationStack {
                    ProjectDetailView(project: project, onUpdate: { updated in
                        if let index = projects.firstIndex(where: { $0.id == updated.id }) {
                            projects[index] = updated
                            saveProjectsToDisk(projects)
                        }
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
        // Removed .sheet for music player; now navigation is handled by NavigationLink
    }
}

struct CreateProjectView: View {
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var selectedImage: UIImage?
    @State private var selectedFiles: [URL] = []
    @State private var showingImagePicker = false
    @State private var showingFilePicker = false

    var onSave: (Project) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Song Title")) {
                    TextField("Enter title", text: $title)
                }

                Section(header: Text("Artwork")) {
                    if let selectedImage = selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 150)
                    } else {
                        Button("Upload Artwork") {
                            showingImagePicker = true
                        }
                    }
                }

                Section(header: Text("Files")) {
                    ForEach(selectedFiles, id: \.self) { file in
                        Text(file.lastPathComponent)
                    }

                    Button("Upload Files") {
                        showingFilePicker = true
                    }
                }
            }
            .navigationTitle("New Song Project")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let project = Project(title: title, artwork: selectedImage, files: selectedFiles)
                        onSave(project)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            NotificationCenter.default.post(name: Notification.Name("ProjectListShouldRefresh"), object: nil)
                            UIAccessibility.post(notification: .layoutChanged, argument: nil)
                        }
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .sheet(isPresented: $showingFilePicker) {
                DocumentPicker(selectedFiles: $selectedFiles)
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

struct ProjectDetailView: View {
    @State var project: Project
    var onUpdate: ((Project) -> Void)?

    @State private var showingImagePicker = false
    @State private var showingFilePicker = false
    @State private var updatedArtwork: UIImage?
    @State private var additionalFiles: [URL] = []
    @State private var audioPlayer: AVAudioPlayer?
    @State private var showProjectDetails = false
    // Async lyrics loading state
    @State private var lyrics: String?
    @State private var isLoadingLyrics = false
    // Async audio player loading state
    @State private var isPreparingAudioPlayer = false
    // For lyrics document creation
    @State private var newLyricsText: String = ""
    @State private var showLyricsEditor = false

    var body: some View {
        projectDetailsView
            .navigationTitle("Project Details")
            .sheet(isPresented: $showingImagePicker, onDismiss: {
                if let updatedArtwork = updatedArtwork {
                    // Update project artwork here if project was mutable
                }
            }) {
                ImagePicker(image: $updatedArtwork)
            }
            .sheet(isPresented: $showingFilePicker) {
                DocumentPicker(selectedFiles: $additionalFiles)
            }
            .onDisappear {
                if !additionalFiles.isEmpty {
                    project.files.append(contentsOf: additionalFiles)
                    onUpdate?(project)
                    additionalFiles.removeAll()
                }
            }
    }

    private var projectDetailsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(project.title)
                    .font(.largeTitle)
                    .bold()

                if let artwork = updatedArtwork ?? project.artwork {
                    Image(uiImage: artwork)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button("Change Artwork") {
                    showingImagePicker = true
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)

                if !project.files.isEmpty {
                    Text("Uploaded Files:")
                        .font(.headline)

                    ForEach(project.files, id: \.self) { file in
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• \(file.lastPathComponent)")
                                .font(.headline)

                            if file.pathExtension == "txt" {
                                // Synchronous lyrics loading is fine for detail list, but could be refactored similarly if needed
                                if let lyricsText = try? String(contentsOf: file, encoding: .utf8) {
                                    Text(lyricsText)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                        .padding(.bottom, 8)
                                } else {
                                    Text("Unable to load lyrics.")
                                        .foregroundColor(.red)
                                }
                            }

                            if file.pathExtension == "mp3" {
                                AudioPlayerView(url: file)
                                    .padding(.bottom, 8)
                            }

                            if ["png", "jpg", "jpeg"].contains(file.pathExtension.lowercased()) {
                                if let data = try? Data(contentsOf: file),
                                   let image = UIImage(data: data) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 150)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .padding(.bottom, 8)
                                } else {
                                    Text("Unable to load image.")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                } else {
                    Text("No files uploaded.")
                        .foregroundColor(.gray)
                }
                Button("Upload More Files") {
                    showingFilePicker = true
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)

                // Lyrics document creation and display
                if let lyricsURL = project.files.first(where: { $0.pathExtension == "txt" }) {
                    Text("Lyrics File: \(lyricsURL.lastPathComponent)")
                        .foregroundColor(.blue)
                } else {
                    Button(action: {
                        showLyricsEditor = true
                    }) {
                        Label("Create Lyrics Document", systemImage: "doc.text")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.8))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .sheet(isPresented: $showLyricsEditor) {
                        NavigationStack {
                            VStack {
                                Text("Write your lyrics")
                                    .font(.headline)
                                TextEditor(text: $newLyricsText)
                                    .frame(height: 200)
                                    .border(Color.gray)
                                    .padding()

                                Button("Save Lyrics") {
                                    let fileName = "Lyrics_\(UUID().uuidString.prefix(6)).txt"
                                    if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                                        let fileURL = dir.appendingPathComponent(fileName)
                                        do {
                                            try newLyricsText.write(to: fileURL, atomically: true, encoding: .utf8)
                                            project.files.append(fileURL)
                                            onUpdate?(project)
                                        } catch {
                                            print("Failed to save lyrics: \(error)")
                                        }
                                    }
                                    showLyricsEditor = false
                                }
                                .padding()
                                .disabled(newLyricsText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                                Button("Cancel", role: .cancel) {
                                    showLyricsEditor = false
                                }
                                .padding(.bottom)
                            }
                            .padding()
                        }
                    }
                }

                Button(action: {
                    // Add MAXNET helper logic here
                }) {
                    Label("Ask MAXNET for Help", systemImage: "lightbulb")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.top)
            }
            .padding()
            .onChange(of: updatedArtwork, initial: false) { oldValue, newValue in
                if let newArtwork = newValue {
                    project.artwork = newArtwork
                    onUpdate?(project)
                }
            }
        }
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var selectedFiles: [URL]

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.audio, .plainText, .image], asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: DocumentPicker

        init(_ parent: DocumentPicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.selectedFiles.append(contentsOf: urls)
        }
    }
}

struct AudioPlayerView: View {
    let url: URL
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var currentTime: TimeInterval = 0
    @State private var duration: TimeInterval = 1
    @State private var timer: Timer?

    var body: some View {
        VStack {
            HStack(spacing: 40) {
                Button(action: {
                    togglePlayback()
                }) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundColor(isPlaying ? .blue : .green)
                }
            }

            Slider(value: Binding(
                get: {
                    currentTime
                },
                set: { newValue in
                    currentTime = newValue
                    audioPlayer?.currentTime = newValue
                }
            ), in: 0...duration)
        }
        .onAppear {
            prepareAudioPlayer()
        }
        .onDisappear {
            timer?.invalidate()
            audioPlayer?.stop()
            audioPlayer = nil
        }
    }

    private func prepareAudioPlayer() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            duration = audioPlayer?.duration ?? 1
            startTimer()
        } catch {
            print("Error preparing audio player: \(error)")
        }
    }

    private func togglePlayback() {
        guard let player = audioPlayer else {
            prepareAudioPlayer()
            audioPlayer?.play()
            isPlaying = true
            return
        }

        if player.isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            if let player = audioPlayer {
                currentTime = player.currentTime
                duration = player.duration
            }
        }
    }
}

#Preview {
    ContentView()
}
