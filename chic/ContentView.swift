//
//  ContentView.swift
//  beandoong
//
//  Created by 최서진 on 10/9/26.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var step: OnboardingPage = .watch

    var body: some View {
        if hasCompletedOnboarding {
            HomeView()
        } else {
            onboarding
        }
    }

    /// 온보딩 1/3 → 2/3 → 3/3. 쪽이 바뀔 때의 넘김 애니메이션은 OnboardingView 가 해요.
    private var onboarding: some View {
        OnboardingView(page: step, onNext: showNextStep, onSkip: completeOnboarding)
    }

    /// 다음: 1/3 → 2/3 → 3/3, 마지막 쪽에서는 온보딩 완료
    private func showNextStep() {
        switch step {
        case .watch: step = .placement
        case .placement: step = .sound
        case .sound: completeOnboarding()
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
