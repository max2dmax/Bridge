//
//  Bridge1App.swift
//  Bridge1
//
//  Created by Max stevenson on 8/3/25.
//

import SwiftUI

@main
struct Bridge1App: App {
    // Global app preferences - injected as environment object
    @StateObject private var appPreferences = loadAppPreferences()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appPreferences)
        }
    }
}
