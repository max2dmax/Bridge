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
                if let art = project.artwork {
                    Image(uiImage: art)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
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

