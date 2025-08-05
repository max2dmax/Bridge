# Bridge App File Structure

This document describes the organization of the Bridge app codebase after refactoring for robust lyrics persistence.

## Models/
- **Project.swift** - Core Project model with id, title, artwork, files array, and font settings
- **CodableProject.swift** - Serializable version of Project for UserDefaults persistence (stores file paths only)

## Views/
- **ContentView.swift** - Main app view showing project list with navigation
- **CreateProjectView.swift** - Project creation form, ensures lyrics file creation  
- **ProjectDetailView.swift** - Project editing view with lyrics editor
- **ProjectMusicPlayerView.swift** - Audio playback view with lyrics display
- **ImagePicker.swift** - Reusable image picker component
- **DocumentPicker.swift** - Reusable document picker component  
- **AudioPlayerView.swift** - Audio playback controls component
- **BridgeApp.swift** - SwiftUI app entry point
- **SplashScreenView.swift** - App splash screen

## Utilities/
- **Persistence.swift** - All disk persistence functions (saveProjectsToDisk, loadProjectsFromDisk, ensureLyricsFile, loadLyrics, saveLyrics)
- **ColorUtils.swift** - Functions for extracting dominant colors from images
- **UIImage+DominantColor.swift** - UIImage extension for color analysis

## Key Principles

1. **Lyrics Persistence**: All lyrics are stored as .txt files referenced in Project.files array, never in UserDefaults
2. **Single Responsibility**: Each file has a clear, documented purpose  
3. **No Duplication**: Helper functions and components are defined exactly once
4. **Consistent Interface**: All views use centralized persistence functions from Persistence.swift

## Lyrics Flow

1. **Project Creation**: `ensureLyricsFile()` automatically creates empty .txt file
2. **Lyrics Display**: `loadLyrics()` reads from .txt file in Project.files  
3. **Lyrics Editing**: `saveLyrics()` writes to .txt file, archives previous version
4. **Project Persistence**: Only file paths stored in UserDefaults, not content