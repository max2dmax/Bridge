//
// ProjectDetailView.swift
// Bridge
//
// This file contains the ProjectDetailView for editing project details.
// All lyrics editing reads/writes from .txt files using Persistence.swift functions.
// Uses ImagePicker.swift and DocumentPicker.swift for file selection.
//
// NEW ARCHIVE & DOWNLOAD FEATURES:
// - Automatic archiving of lyrics, audio, and artwork when changed
// - MAXNET conversation archiving on chat completion
// - Archive viewing and sharing capabilities
// - Project export as zip files with iOS Files app compatibility
// - Archive management with size tracking and cleanup options
//
// Archive files are stored in Documents/Archives/{projectId}/
// Export files are temporarily created and then moved to Documents for sharing
//

import SwiftUI
import Foundation
import UniformTypeIdentifiers
import Compression
import PhotosUI
import AVFoundation
import ZIPFoundation
import UIKit

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
    
    // Archive and export state
    @State private var showingArchiveDetail = false
    @State private var selectedArchiveEntry: ArchiveEntry?
    @State private var isExporting = false
    @State private var exportError: String?
    @State private var showShareSheet = false
    @State private var shareURL: URL?
    @State private var showingArchiveSuccess = false
    @State private var archiveMessage = ""

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

                Divider()

                // Download Project Files Button
                Button(action: exportProject) {
                    HStack {
                        if isExporting {
                            ProgressView()
                                .scaleEffect(0.8)
                                .padding(.trailing, 4)
                        } else {
                            Image(systemName: "square.and.arrow.down")
                                .font(.title2)
                        }
                        Text(isExporting ? "Exporting..." : "Download Project Files")
                            .fontWeight(.medium)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .disabled(isExporting)

                // Archived Material - moved to bottom
                DisclosureGroup("Archived Material (\(project.archive.entries.count))") {
                    if project.archive.entries.isEmpty {
                        Text("No archived items yet")
                            .foregroundColor(.gray)
                            .padding(.vertical, 8)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            // Archive summary
                            HStack {
                                Text("Total: \(project.archive.formattedArchiveSize)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal)
                            
                            // Archive entries
                            ForEach(project.archive.entries) { entry in
                                ArchiveEntryRow(entry: entry) {
                                    selectedArchiveEntry = entry
                                    showingArchiveDetail = true
                                }
                            }
                        }
                    }
                }
                .padding(.vertical)
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

                            // Archive old lyrics using proper archiving function
                            if archiveLyrics(for: &project) {
                                archiveMessage = "Previous lyrics archived successfully"
                                showingArchiveSuccess = true
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
            MAXNETChatView(project: project) { messages in
                // Archive the MAXNET conversation
                if let archiveEntry = archiveMAXNETConversation(messages, for: project.id) {
                    project.archive.addEntry(archiveEntry)
                    onUpdate?(project)
                    archiveMessage = "MAXNET conversation archived successfully"
                    showingArchiveSuccess = true
                }
            }
        }
        .onChange(of: updatedArtwork) { newArtwork in
            if let newArtwork = newArtwork {
                // Archive old artwork before updating
                if archiveArtwork(for: &project) {
                    archiveMessage = "Previous artwork archived successfully"
                    showingArchiveSuccess = true
                }
                project.artwork = newArtwork
                onUpdate?(project)
            }
        }
        .onChange(of: additionalFiles) { newFiles in
            if !newFiles.isEmpty {
                let mp3Files = newFiles.filter { $0.pathExtension.lowercased() == "mp3" }
                if !mp3Files.isEmpty {
                    // Archive old audio before updating
                    if archiveAudio(for: &project) {
                        archiveMessage = "Previous audio archived successfully"
                        showingArchiveSuccess = true
                    }
                }
                project.files.append(contentsOf: newFiles)
                additionalFiles.removeAll() // Clear the array to avoid re-adding
                onUpdate?(project)
            }
        }
        .onChange(of: project) { updatedProject in
            // Persist updated project back to disk
            onUpdate?(updatedProject)
            currentLyrics = loadLyrics(from: updatedProject)
        }
        .alert("Export Error", isPresented: .constant(exportError != nil)) {
            Button("OK") {
                exportError = nil
            }
        } message: {
            Text(exportError ?? "")
        }
        .alert("Archive Success", isPresented: $showingArchiveSuccess) {
            Button("OK") {}
        } message: {
            Text(archiveMessage)
        }
        .sheet(isPresented: $showingArchiveDetail) {
            if let entry = selectedArchiveEntry {
                ArchiveDetailView(entry: entry)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let shareURL = shareURL {
                ActivityViewController(activityItems: [shareURL])
            }
        }
    }
    
    // MARK: - Helper Functions
    
    /// Export the project as a zip file and present share sheet
    private func exportProject() {
        isExporting = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            if let exportURL = ProjectExporter.exportProject(project) {
                DispatchQueue.main.async {
                    self.shareURL = exportURL
                    self.showShareSheet = true
                    self.isExporting = false
                }
            } else {
                DispatchQueue.main.async {
                    self.exportError = "Failed to export project files. Please try again."
                    self.isExporting = false
                }
            }
        }
    }
    }


// MARK: - Archive Entry Row

/// Row view for displaying a single archive entry
struct ArchiveEntryRow: View {
    let entry: ArchiveEntry
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Icon based on entry type
                Image(systemName: entryIcon)
                    .foregroundColor(entryColor)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.label)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    HStack {
                        Text(DateFormatter.archiveDateFormatter.string(from: entry.timestamp))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if !entry.fileExists {
                            Spacer()
                            Label("Missing", systemImage: "exclamationmark.triangle")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
    
    private var entryIcon: String {
        switch entry.entryType {
        case .lyrics: return "doc.text"
        case .audio: return "waveform"
        case .artwork: return "photo"
        case .maxnetConversation: return "message"
        }
    }
    
    private var entryColor: Color {
        switch entry.entryType {
        case .lyrics: return .blue
        case .audio: return .green
        case .artwork: return .purple
        case .maxnetConversation: return .orange
        }
    }
}

// MARK: - Archive Detail View

/// Detail view for viewing/downloading archive entries
struct ArchiveDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let entry: ArchiveEntry
    @State private var fileContent: String = ""
    @State private var isLoading = true
    @State private var showShareSheet = false
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                // Entry Info
                VStack(alignment: .leading, spacing: 8) {
                    Text(entry.label)
                        .font(.headline)
                    
                    Label(DateFormatter.archiveDateFormatter.string(from: entry.timestamp), systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Label(entry.entryType.displayName, systemImage: entry.entryType == .lyrics ? "doc.text" : 
                          entry.entryType == .audio ? "waveform" :
                          entry.entryType == .artwork ? "photo" : "message")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // Content
                if isLoading {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if entry.entryType == .lyrics || entry.entryType == .maxnetConversation {
                    ScrollView {
                        Text(fileContent)
                            .font(.system(.body, design: .monospaced))
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                } else if entry.entryType == .artwork, 
                          let imageData = try? Data(contentsOf: entry.fileURL!),
                          let image = UIImage(data: imageData) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else if entry.entryType == .audio, let audioURL = entry.fileURL {
                    AudioPlayerView(url: audioURL)
                } else {
                    Text("Unable to preview this file")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Archive Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(action: shareFile) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .disabled(!entry.fileExists)
                }
            }
        }
        .onAppear {
            loadFileContent()
        }
        .sheet(isPresented: $showShareSheet) {
            if let fileURL = entry.fileURL {
                ActivityViewController(activityItems: [fileURL])
            }
        }
    }
    
    private func loadFileContent() {
        guard let fileURL = entry.fileURL,
              entry.entryType == .lyrics || entry.entryType == .maxnetConversation else {
            isLoading = false
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let content = try String(contentsOf: fileURL, encoding: .utf8)
                DispatchQueue.main.async {
                    self.fileContent = content
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.fileContent = "Error loading file: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    private func shareFile() {
        showShareSheet = true
    }
}

// MARK: - Activity View Controller

/// UIActivityViewController wrapper for sharing files
struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        return UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - DateFormatter Extension

extension DateFormatter {
    static let archiveDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
