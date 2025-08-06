//
// ProjectDetailView.swift
// Bridge
//
// This file contains the ProjectDetailView for editing project details.
// All lyrics editing reads/writes from .txt files using Persistence.swift functions.
// Uses ImagePicker.swift and DocumentPicker.swift for file selection.
//

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
    @State private var currentLyrics: String = "" // Track displayed lyrics
    @State private var showingMAXNETChat = false // MAXNET chat presentation state

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

                        Text(project.title)
                            .font(project.fontName == "System"
                                ? .system(size: 28)
                                : Font.custom(project.fontName, size: 28))
                            .fontWeight(project.useBold ? .bold : .regular)
                            .italic(project.useItalic)
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
                    selectedFontName = project.fontName
                    useBold = project.useBold
                    useItalic = project.useItalic
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
                        let lyrics = loadLyrics(from: project)
                        newLyricsText = lyrics // Load current lyrics for editing
                        currentLyrics = lyrics // Display current lyrics
                        showLyricsEditor = true
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(dominantColor.opacity(0.8))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    Button("Create Lyrics Document") {
                        ensureLyricsFile(for: &project)
                        newLyricsText = "" // Start with blank for new file
                        currentLyrics = ""
                        showLyricsEditor = true
                        onUpdate?(project)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(dominantColor.opacity(0.8))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                // Display current lyrics
                if !currentLyrics.isEmpty {
                    ScrollView {
                        Text(currentLyrics).padding(.vertical, 8)
                    }
                    .frame(maxHeight: 200)
                }

                Divider()

                Button(action: {
                    showingMAXNETChat = true
                }) {
                    HStack {
                        Image(systemName: "message")
                            .font(.title2)
                        Text("Ask MAXNET for Help")
                            .fontWeight(.medium)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.blue)
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
        .onAppear {
            currentLyrics = loadLyrics(from: project)
        }
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
                            // Ensure the project has a lyrics file first
                            if !project.files.contains(where: { $0.pathExtension.lowercased() == "txt" }) {
                                ensureLyricsFile(for: &project)
                            }

                            // Archive old lyrics if they exist
                            let oldLyrics = loadLyrics(from: project)
                            if !oldLyrics.isEmpty {
                                if let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                                    let archiveURL = documentsDir.appendingPathComponent("Archived_Lyrics_\(UUID().uuidString.prefix(6)).txt")
                                    try? oldLyrics.write(to: archiveURL, atomically: true, encoding: .utf8)
                                }
                            }

                            // Save new lyrics
                            saveLyrics(newLyricsText, to: project)
                            currentLyrics = newLyricsText // Update displayed lyrics immediately
                            onUpdate?(project)
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
                            project.fontName = selectedFontName
                            project.useBold = useBold
                            project.useItalic = useItalic
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
        .sheet(isPresented: $showingMAXNETChat) {
            MAXNETChatView(project: project)
        }
        .onDisappear {
            // your archive-on-exit logic
        }
        .onChange(of: project) { updatedProject in
            // Persist updated project back to disk
            onUpdate?(updatedProject)
            currentLyrics = loadLyrics(from: updatedProject)
        }
    }
}
