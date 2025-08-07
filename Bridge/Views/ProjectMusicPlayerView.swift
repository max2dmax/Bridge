//
// ProjectMusicPlayerView.swift
// Bridge
//
// This file contains the ProjectMusicPlayerView for playing project audio and displaying lyrics.
// Always loads lyrics from .txt files using Persistence.swift functions.
// Uses AudioPlayerView.swift for audio playback.
//

import SwiftUI

struct ProjectMusicPlayerView: View {
    let project: Project

    private var bgColors: [Color] {
        if let art = project.artwork {
            return dominantColors(from: art)
        }
        return [Color.gray.opacity(0.2), Color.black.opacity(0.3)]
    }

    private var isArtLight: Bool {
        if let ui = project.artwork?.dominantColor() {
            var white: CGFloat = 0
            ui.getWhite(&white, alpha: nil)
            return white > 0.7
        }
        return false
    }

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: bgColors),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                // --- Squared artwork + stylized overlay ---
                if let art = project.artwork {
                    ZStack(alignment: .bottomLeading) {
                        Image(uiImage: art)
                            .resizable()
                            .aspectRatio(1, contentMode: .fill) // Crop to square
                            .frame(maxWidth: 200, maxHeight: 200)
                            .clipped()
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

                if let audioURL = project.files.first(where: {
                    ["mp3","m4a","wav","aac"].contains($0.pathExtension.lowercased())
                }) {
                    Text("Now Playing: \(audioURL.lastPathComponent)")
                    AudioPlayerView(url: audioURL)
                }

                // Always load lyrics from file using persistence function
                let lyrics = loadLyrics(from: project)
                if !lyrics.isEmpty {
                    ScrollView {
                        Text(lyrics)
                            .padding()
                            .foregroundColor(isArtLight ? .black : .white)
                    }
                    .frame(maxHeight: 200)
                } else {
                    Text("No lyrics available.")
                        .foregroundColor(isArtLight ? .black : .white)
                }
            }
            .padding()
        }
    }
}
//  ProjectMusicPlayerView.swift
//  Bridge
//
//  Created by Max stevenson on 8/5/25.
//
