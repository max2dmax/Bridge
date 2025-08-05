//// ProjectDetailView.swift

import SwiftUI
import Foundation
import UniformTypeIdentifiers
import Compression
import PhotosUI
import AVFoundation
import ZIPFoundation

struct ProjectDetailView: View {
    @State var project: Project
    var onUpdate: ((Project) -> Void)?

    @State private var showingImagePicker = false
    @State private var showingFilePicker = false
    @State private var updatedArtwork: UIImage?
    @State private var additionalFiles: [URL] = []
    @State private var showLyricsEditor = false
    @State private var newLyricsText = ""
    @State private var showEditTitleAlert = false
    @State private var editedTitle = ""
    @State private var useBold = false
    @State private var useItalic = false
    @State private var selectedFontName: String = "System"
    private let fonts = ["System","Helvetica Neue","Courier","Georgia","Avenir Next"]

    private var dominantColor: Color {
        if let ui = (updatedArtwork ?? project.artwork)?.dominantColor() {
            return Color(ui)
        }
        return Color(.systemBackground)
    }

    private var isArtLight: Bool {
        if let ui = (updatedArtwork ?? project.artwork)?.dominantColor() {
            var white: CGFloat = 0
            ui.getWhite(&white, alpha: nil)
            return white > 0.7
        }
        return false
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(project.title)
                    .font(.largeTitle)
                    .bold()

                Divider()

                if let art = updatedArtwork ?? project.artwork {
                    ZStack {
                        Image(uiImage: art)
                            .resizable()
                            .aspectRatio(1, contentMode: .fit)
                            .frame(maxWidth: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 16))

                        Text(editedTitle.isEmpty ? project.title : editedTitle)
                            .font(editedTitle.isEmpty
                                  ? .system(size: 28)
                                  : Font.custom(editedTitle, size: 28))
                            .fontWeight(useBold ? .bold : .regular)
                            .italic(useItalic)
                            .foregroundColor(isArtLight ? .black : .white)
                            .padding(8)
                    }
                }

                Button("Change Artwork") {
                    showingImagePicker = true
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(dominantColor.opacity(0.8))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                Button("Edit Working Title") {
                    editedTitle = project.title
                    showEditTitleAlert = true
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(dominantColor.opacity(0.6))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                Divider()

                // Current Recording
                let mp3s = project.files.filter { $0.pathExtension.lowercased() == "mp3" }
                if let current = mp3s.first {
                    Text("Recording: \(current.lastPathComponent)")
                    AudioPlayerView(url: current)
                } else {
                    Text("No audio recording uploaded.").foregroundColor(.gray)
                }

                Divider()

                Button("Set Current Recording") {
                    showingFilePicker = true
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(dominantColor.opacity(0.8))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                Divider()

                // Lyrics edit
                if project.files.contains(where: { $0.pathExtension.lowercased() == "txt" }) {
                    Button("Edit Lyrics") {
                        if let url = project.files.first(where: { $0.pathExtension.lowercased() == "txt" }),
                           let text = try? String(contentsOf: url, encoding: .utf8) {
                            newLyricsText = text
                        }
                        showLyricsEditor = true
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(dominantColor.opacity(0.8))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    Button("Create Lyrics Document") {
                        newLyricsText = ""
                        showLyricsEditor = true
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(dominantColor.opacity(0.8))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                if let url = project.files.first(where: { $0.pathExtension.lowercased() == "txt" }),
                   let text = try? String(contentsOf: url, encoding: .utf8) {
                    ScrollView {
                        Text(text).padding(.vertical, 8)
                    }
                    .frame(maxHeight: 200)
                }

                Divider()

                Button("Ask MAXNET for Help") {
                    // hook in later…
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(dominantColor)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                DisclosureGroup("Archived Material") {
                    // …you know the drill
                }
                .padding(.vertical)

                Button("Download Project Files") {
                    // …zip & share logic
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding()
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [dominantColor.opacity(0.2), .white]),
                startPoint: .top, endPoint: .bottom
            )
        )
        .sheet(isPresented: $showLyricsEditor) {
            NavigationStack {
                VStack {
                    Text("Edit Lyrics")
                        .font(.headline)
                    TextEditor(text: $newLyricsText)
                        .multilineTextAlignment(.center)
                        .frame(height: 200)
                        .border(Color.gray)
                        .padding()
                    HStack {
                        Button("Save Lyrics") {
                            // Get existing lyrics file or create a new one
                            let existingLyricsURL = project.files.first(where: { $0.pathExtension.lowercased() == "txt" })
                            
                            if let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                                let lyricsURL: URL
                                var updatedProject = project
                                
                                if let existingURL = existingLyricsURL {
                                    // Use existing file and archive old content
                                    lyricsURL = existingURL
                                    if let oldContent = try? String(contentsOf: existingURL, encoding: .utf8) {
                                        let archiveURL = documentsDir.appendingPathComponent("Archived_Lyrics_\(UUID().uuidString.prefix(6)).txt")
                                        try? oldContent.write(to: archiveURL, atomically: true, encoding: .utf8)
                                    }
                                } else {
                                    // Create new lyrics file
                                    let sanitizedTitle = project.title.replacingOccurrences(of: "[^a-zA-Z0-9 ]", with: "", options: .regularExpression)
                                    let fileName = "\(sanitizedTitle)_lyrics.txt"
                                    lyricsURL = documentsDir.appendingPathComponent(fileName)
                                    
                                    // Add new file to project files
                                    updatedProject.files.append(lyricsURL)
                                }
                                
                                // Write the new lyrics content
                                if (try? newLyricsText.write(to: lyricsURL, atomically: true, encoding: .utf8)) != nil {
                                    // Update the project state only if write succeeded
                                    project = updatedProject
                                    onUpdate?(updatedProject)
                                } else {
                                    // Handle write failure - for now just print, could show alert later
                                    print("Error: Failed to save lyrics to file")
                                }
                            } else {
                                print("Error: Could not access documents directory")
                            }
                            
                            showLyricsEditor = false
                        }
                        .padding()
                        Button("Cancel", role: .cancel) {
                            showLyricsEditor = false
                        }
                        .padding()
                    }
                }
                .padding()
            }
        }
        .sheet(isPresented: $showEditTitleAlert) {
            NavigationStack {
                Form {
                    Section(header: Text("Working Title")) {
                        TextField("Title", text: $editedTitle)
                    }
                    Section(header: Text("Preview")) {
                        ForEach(fonts, id: \.self) { fontName in
                            Text(editedTitle.isEmpty ? "Your Title Here" : editedTitle)
                                .font(fontName == "System"
                                    ? .system(size: 20)
                                    : Font.custom(fontName, size: 20))
                                .fontWeight(useBold ? .bold : .regular)
                                .italic(useItalic)
                                .padding(5)
                                .onTapGesture {
                                    selectedFontName = fontName
                                }
                                .background(fontName == selectedFontName ? Color.gray.opacity(0.2) : Color.clear)
                                .cornerRadius(6)
                        }
                    }
                    Section {
                        Toggle("Bold", isOn: $useBold)
                        Toggle("Italic", isOn: $useItalic)
                    }
                }
                .navigationTitle("Edit Working Title")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            project.title = editedTitle
                            onUpdate?(project)
                            showEditTitleAlert = false
                        }
                    }
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", role: .cancel) {
                            showEditTitleAlert = false
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $updatedArtwork)
        }
        .sheet(isPresented: $showingFilePicker) {
            DocumentPicker(selectedFiles: $additionalFiles)
        }
        .onDisappear {
            // your archive-on-exit logic
        }
        .onChange(of: project) { updatedProject in
            // Persist updated project back to disk
            onUpdate?(updatedProject)
            var allProjects = loadProjectsFromDisk()
            if let index = allProjects.firstIndex(where: { $0.id == updatedProject.id }) {
                allProjects[index] = updatedProject
            } else {
                allProjects.append(updatedProject)
            }
            saveProjectsToDisk(allProjects)
        }
    }
}
//  ProjectDetailView.swift
//  Bridge
//
//  Created by Max stevenson on 8/5/25.
//

