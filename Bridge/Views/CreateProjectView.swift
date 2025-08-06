//
// CreateProjectView.swift
// Bridge
//
// This file contains the CreateProjectView for creating new projects.
// Ensures every project has a lyrics .txt file upon creation.
// Uses ImagePicker.swift and DocumentPicker.swift for file selection.
//

import SwiftUI

struct CreateProjectView: View {
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var selectedImage: UIImage?
    @State private var selectedFiles: [URL] = []
    @State private var showingImagePicker = false
    @State private var showingFilePicker = false

    // Working title style defaults
    @State private var selectedFontName: String = "System"
    @State private var useBold: Bool = false
    @State private var useItalic: Bool = false

    var onSave: (Project) -> Void

    var body: some View {
        NavigationStack {
            Form {
                // Song title at the top
                Section(header: Text("Song Title")) {
                    TextField("Enter title", text: $title)
                }

                // Artwork section, overlayed preview after upload
                Section(header: Text("Artwork")) {
                    if selectedImage == nil {
                        Button("Upload Artwork") {
                            showingImagePicker = true
                        }
                    } else {
                        ZStack(alignment: .bottomLeading) {
                            Image(uiImage: selectedImage!)
                                .resizable()
                                .aspectRatio(1, contentMode: .fit)
                                .frame(maxWidth: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            if !title.isEmpty {
                                Text(title)
                                    .font(selectedFontName == "System"
                                        ? .system(size: 28)
                                        : Font.custom(selectedFontName, size: 28))
                                    .fontWeight(useBold ? .bold : .regular)
                                    .italic(useItalic)
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .shadow(radius: 6)
                            }
                        }
                        Button("Replace Artwork") {
                            showingImagePicker = true
                        }
                    }
                }

                // Style section appears ONLY after artwork is uploaded
                if selectedImage != nil {
                    Section(header: Text("Style")) {
                        Picker("Font", selection: $selectedFontName) {
                            Text("System").tag("System")
                            Text("Helvetica Neue").tag("Helvetica Neue")
                            Text("Arial").tag("Arial")
                            Text("Courier").tag("Courier")
                            Text("Georgia").tag("Georgia")
                            Text("Avenir Next").tag("Avenir Next")
                            // Add more fonts as needed
                        }
                        Toggle("Bold", isOn: $useBold)
                        Toggle("Italic", isOn: $useItalic)
                    }
                }

                // Upload files section, renamed to Upload Recording
                Section(header: Text("Upload Recording")) {
                    ForEach(selectedFiles, id: \.self) { file in
                        Text(file.lastPathComponent)
                    }
                    Button("Upload Recording") {
                        showingFilePicker = true
                    }
                }
            }
            .navigationTitle("New Song Project")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        // Create the project first, including style
                        var proj = Project(
                            title: title,
                            artwork: selectedImage,
                            files: selectedFiles,
                            fontName: selectedFontName,
                            useBold: useBold,
                            useItalic: useItalic
                        )
                        // Ensure the project has a lyrics file (and that it exists on disk!)
                        ensureLyricsFile(for: &proj)
                        onSave(proj)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            NotificationCenter.default
                                .post(name: .init("ProjectListShouldRefresh"), object: nil)
                            UIAccessibility.post(notification: .layoutChanged, argument: nil)
                        }
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { dismiss() }
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

// No local/private ensureLyricsFile(for:) in this file anymore!
// The function is now only in your persistence helper.
