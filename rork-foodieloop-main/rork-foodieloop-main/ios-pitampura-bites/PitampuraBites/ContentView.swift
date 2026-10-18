//
//  ContentView.swift
//  PitampuraBites
//
//  Root switch between the simulated onboarding flow and the main app.
//

import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            if appState.hasOnboarded {
                MainTabView()
                    .transition(.opacity)
            } else {
                OnboardingFlow()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.hasOnboarded)
        .background(Color.appBackground)
    }
}

#Preview {
    ContentView()
        .environment(AppState())
}
