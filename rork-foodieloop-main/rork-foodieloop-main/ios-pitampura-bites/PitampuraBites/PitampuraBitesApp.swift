//
//  PitampuraBitesApp.swift
//  PitampuraBites
//

import SwiftUI

@main
struct PitampuraBitesApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .preferredColorScheme(.dark)
        }
    }
}
