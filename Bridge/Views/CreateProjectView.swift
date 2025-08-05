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

    var onSave: (Project) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Song Title")) {
                    TextField("Enter title", text: $title)
                }

                Section(header: Text("Artwork")) {
                    if let img = selectedImage {
                        Image(uiImage: img)
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
                        // Create the project first
                        var proj = Project(title: title, artwork: selectedImage, files: selectedFiles)
                        
                        // Ensure the project has a lyrics file
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
//  CreateProjectView.swift
//  Bridge
//
//  Created by Max stevenson on 8/5/25.
//

