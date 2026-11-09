//
//  ContentView.swift
//  beandoong
//
//  Created by 최서진 on 10/9/26.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    /// 지금 홈을 보여 주는지. 저장값(`hasCompletedOnboarding`)으로 시작하고, 온보딩을 마칠 때 애니메이션과 함께 바꿔요.
    /// (@AppStorage 값 변경은 withAnimation 의 전환 애니메이션이 전달되지 않아서 화면 전환은 이 값으로 해요)
    @State private var showsHome = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var step: OnboardingPage = .watch
    /// 온보딩을 방금 마치고 홈으로 넘어왔는지 (이때만 홈 요소가 차례로 나타나요)
    @State private var arrivesFromOnboarding = false

    var body: some View {
        // 온보딩 → 홈: 온보딩은 살짝 작아지며 사라지고, 홈 요소가 차례로 떠오르며 나타나요.
        ZStack {
            if showsHome {
                HomeView(animatesEntrance: arrivesFromOnboarding)
                    .transition(.opacity)
            } else {
                onboarding
                    .transition(onboardingExit)
            }
        }
    }

    /// 온보딩이 걷히는 전환. 동작 줄이기가 켜져 있으면 크기 변화 없이 투명도만 바뀌어요.
    private var onboardingExit: AnyTransition {
        reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: OnboardingExit.scale))
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
        arrivesFromOnboarding = true
        withAnimation(.easeIn(duration: OnboardingExit.duration)) {
            showsHome = true
        }
    }
}

/// 온보딩이 걷히는 모양: 0.25초 동안 98% 크기로 살짝 작아지며 사라져요.
private enum OnboardingExit {
    static let duration: TimeInterval = 0.25
    static let scale: CGFloat = 0.98
}

#Preview {
    let connection = WatchConnection()
    ContentView()
        .environmentObject(PracticeSession(connection: connection))
        .environmentObject(connection)
}
