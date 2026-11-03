//
//  ContentView.swift
//  beandoong
//
//  Created by 최서진 on 10/9/26.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var step: OnboardingStep = .sound

    private enum OnboardingStep {
        case sound
        case watch
        case placement
    }

    var body: some View {
        if hasCompletedOnboarding {
            HomeView()
        } else {
            onboarding
        }
    }

    @ViewBuilder
    private var onboarding: some View {
        switch step {
        case .sound:
            SoundIntroView(onNext: { step = .watch }, onSkip: completeOnboarding)
        case .watch:
            WatchIntroView(onNext: { step = .placement }, onSkip: completeOnboarding)
        case .placement:
            PlacementIntroView(onNext: completeOnboarding, onSkip: completeOnboarding)
        }
    }

    private func completeOnboarding() {
        hasCompletedOnboarding = true
    }
}

#Preview {
    let connection = WatchConnection()
    ContentView()
        .environmentObject(PracticeSession(connection: connection))
        .environmentObject(connection)
}
