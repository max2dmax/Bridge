# Bridge App File Structure

This document describes the organization of the Bridge app codebase after refactoring for robust lyrics persistence and home page customization features.

## Models/
- **Project.swift** - Core Project model with id, title, artwork, files array, and font settings
- **CodableProject.swift** - Serializable version of Project for UserDefaults persistence (stores file paths only)
- **UserPreferences.swift** - User customization settings (username, gradient mode, project order, selected projects)

## Views/
- **ContentView.swift** - Main app view showing project list with navigation, drag & drop reordering, and gradient customization
- **CreateProjectView.swift** - Project creation form, ensures lyrics file creation  
- **ProjectDetailView.swift** - Project editing view with lyrics editor
- **ProjectMusicPlayerView.swift** - Audio playback view with lyrics display
- **GradientPickerView.swift** - Modal for customizing background gradients and username
- **ImagePicker.swift** - Reusable image picker component
- **DocumentPicker.swift** - Reusable document picker component  
- **AudioPlayerView.swift** - Audio playback controls component
- **BridgeApp.swift** - SwiftUI app entry point
- **SplashScreenView.swift** - App splash screen

## Utilities/
- **Persistence.swift** - All disk persistence functions (projects and user preferences with backwards compatibility)
- **ColorUtils.swift** - Functions for extracting dominant colors and generating gradient combinations
- **UIImage+DominantColor.swift** - UIImage extension for color analysis

## Key Features

### Home Page Customization
1. **Drag & Drop Project Reordering**: Users can reorder projects via drag-and-drop with persistent storage
2. **Username Customization**: Editable username displayed in navigation title (defaults to "Home")  
3. **Gradient Background Picker**: Long-press on username opens modal with two modes:
   - **All Mode**: Uses dominant colors from all project artworks (default)
   - **Selected Mode**: User selects specific projects to determine gradient colors
4. **Persistent Settings**: All customizations saved to UserDefaults with safe migration

### Key Principles

1. **Lyrics Persistence**: All lyrics are stored as .txt files referenced in Project.files array, never in UserDefaults
2. **Single Responsibility**: Each file has a clear, documented purpose  
3. **No Duplication**: Helper functions and components are defined exactly once
4. **Consistent Interface**: All views use centralized persistence functions from Persistence.swift
5. **Backwards Compatibility**: Safe migration ensures existing projects work seamlessly with new features

### Data Flow

#### Lyrics Management
1. **Project Creation**: `ensureLyricsFile()` automatically creates empty .txt file
2. **Lyrics Display**: `loadLyrics()` reads from .txt file in Project.files  
3. **Lyrics Editing**: `saveLyrics()` writes to .txt file, archives previous version
4. **Project Persistence**: Only file paths stored in UserDefaults, not content

#### User Preferences
1. **Settings Load**: `loadUserPreferences()` with safe migration from UserDefaults
2. **Gradient Generation**: `generateGradientColors()` based on selected mode and projects  
3. **Project Ordering**: Maintained through UserPreferences.projectOrder array
4. **Settings Save**: `saveUserPreferences()` persists all customizations