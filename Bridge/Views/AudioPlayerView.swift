//
// AudioPlayerView.swift
// Bridge
//
// This file contains the AudioPlayerView for playing audio files in projects.
// Provides play/pause controls and a seek slider for audio playback.
//

import SwiftUI
import AVFoundation

struct AudioPlayerView: View {
    let url: URL
    @State private var player: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var currentTime: TimeInterval = 0
    @State private var duration: TimeInterval = 1
    @State private var timer: Timer?

    var body: some View {
        VStack {
            Button(action: togglePlayback) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
            }
            Slider(value: Binding(
                get: { currentTime },
                set: {
                    currentTime = $0
                    player?.currentTime = $0
                }
            ), in: 0...duration)
        }
        .onAppear(perform: preparePlayer)
        .onDisappear {
            timer?.invalidate()
            player?.stop()
        }
    }

    private func preparePlayer() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            duration = player?.duration ?? 1
            timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                currentTime = player?.currentTime ?? 0
            }
        } catch {
            print("Audio prep error:", error)
        }
    }

    private func togglePlayback() {
        guard let p = player else { preparePlayer(); player?.play(); isPlaying = true; return }
        if p.isPlaying {
            p.pause(); isPlaying = false
        } else {
            p.play(); isPlaying = true
        }
    }
}
//  AudioPlayerView.swift
//  Bridge
//
//  Created by Max stevenson on 8/5/25.
//

