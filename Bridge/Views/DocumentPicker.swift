//
// DocumentPicker.swift
// Bridge
//
// This file contains the DocumentPicker UIViewControllerRepresentable for selecting documents.
// Used for selecting audio files, text files, and other project files across the app.
//

import SwiftUI
import UniformTypeIdentifiers

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var selectedFiles: [URL]

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: [.audio, .plainText, .image],
            asCopy: true
        )
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ vc: UIDocumentPickerViewController, context: Context) {}

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        init(_ parent: DocumentPicker) { self.parent = parent }
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.selectedFiles.append(contentsOf: urls)
        }
    }
}
//  DocumentPicker.swift
//  Bridge
//
//  Created by Max stevenson on 8/5/25.
//

