//
//  ContentView.swift
//  beandoong
//
//  Created by 최서진 on 10/9/26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var practice: PracticeSession
    @EnvironmentObject private var connection: WatchConnection
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    /// 지금 홈을 보여 주는지. 저장값(`hasCompletedOnboarding`)으로 시작하고, 온보딩을 마칠 때 애니메이션과 함께 바꿔요.
    /// (@AppStorage 값 변경은 withAnimation 의 전환 애니메이션이 전달되지 않아서 화면 전환은 이 값으로 해요)
    @State private var showsHome = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var step: OnboardingPage = .watch
    /// 온보딩을 방금 마치고 홈으로 넘어왔는지 (이때만 홈 요소가 차례로 나타나요)
    @State private var arrivesFromOnboarding = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    /// 온보딩 화면이 올라와 있는지. 걷히는 애니메이션이 끝난 뒤에 내려요.
    @State private var mountsOnboarding = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    /// 온보딩 마지막 쪽에 멈춰 있어서 홈을 미리 만들어 두는지. 앱을 켤 때(스플래시 중) 일을 늘리지 않으려고
    /// 마지막 쪽에 도착해 넘김이 끝난 뒤에 만들어요.
    @State private var preparesHome = false

    var body: some View {
        // 온보딩 → 홈: 온보딩은 살짝 작아지며 사라지고, 홈 요소가 차례로 떠오르며 나타나요.
        //
        // 두 화면을 if/else 전환(transition)으로 바꿔 끼우면, 사라지는 온보딩이 전환 도중 안전 영역 안으로 다시 배치되어
        // 위·아래가 검게 비고 내용이 눌려 보였어요. 그래서 두 화면을 처음부터 같이 올려 두고 투명도·크기만 바꿔요.
        // - 홈은 온보딩 아래에 미리 만들어 둬서(처음 그리는 무거운 일을 미리), 넘어가는 순간 버벅이지 않아요.
        //   보이기 전에는 등장 애니메이션을 멈춰 두고, 보이기 시작할 때 출발해요.
        // - 움직임(0.25초 ease-in, 온보딩 98% · 투명도, 홈 투명도)은 전과 같아요.
        ZStack {
            if showsHome || preparesHome {
                HomeView(animatesEntrance: arrivesFromOnboarding, isEntranceActive: showsHome)
                    .opacity(showsHome ? 1 : Self.hiddenOpacity)
                    .allowsHitTesting(showsHome)
                    .accessibilityHidden(!showsHome)
                    // 미리 만들지 못하고(건너뛰기 등) 넘어가는 순간 올라올 때는 전처럼 투명도로 나타나요
                    .transition(.opacity)
            }

            if mountsOnboarding {
                onboarding
                    .opacity(showsHome ? 0 : 1)
                    .scaleEffect(showsHome && !reduceMotion ? OnboardingExit.scale : 1)
                    // 크기 변환(scaleEffect)이 걸리면 안쪽으로 안전 영역 정보가 전달되지 않아, 온보딩 안의 ignoresSafeArea 가
                    // 듣지 않고 안전 영역 안으로 다시 배치돼요(위·아래가 검게 비고 내용이 눌림). 바깥에서 먼저 화면 전체 크기를
                    // 주면 안쪽은 안전 영역 정보가 없어도 평소와 같은 크기로 배치돼요.
                    .ignoresSafeArea()
                    .allowsHitTesting(!showsHome)
                    .accessibilityHidden(showsHome)
            }
        }
    }

    /// 보이기 전 홈의 투명도. 0이면 그리지 않아서 넘어가는 순간 처음 그리느라 버벅여요.
    /// 위에 불투명한 온보딩이 덮고 있어서 화면에는 보이지 않아요.
    private static let hiddenOpacity = 0.001

    /// 온보딩 1/4 → 2/4 → 3/4 → 4/4. 쪽이 바뀔 때의 넘김 애니메이션은 OnboardingView 가 해요.
    private var onboarding: some View {
        OnboardingView(page: step, onNext: showNextStep, onSkip: skipToPractice, onSwipe: swipeStep,
                       onPageSettled: { page in if page == .review { preparesHome = true } })
    }

    /// 좌우 스와이프: 첫·마지막 쪽 밖으로는 가지 않는다 (마지막 쪽에서 나가는 것은 "다음" 버튼으로만)
    private func swipeStep(_ delta: Int) {
        guard let target = OnboardingPage(rawValue: step.rawValue + delta) else { return }
        step = target
    }

    /// 다음: 1/4 → 2/4 → 3/4 → 4/4, 마지막 쪽에서는 온보딩 완료
    private func showNextStep() {
        switch step {
        case .watch: step = .placement
        case .placement: step = .sound
        case .sound: step = .review
        case .review: completeOnboarding()
        }
    }

    /// 건너뛰기: 온보딩을 마치고 바로 소리 인식(연습)을 시작한다
    private func skipToPractice() {
        completeOnboarding()
        Task { await practice.start(usingWatch: connection.isReachable) }
    }

    private func completeOnboarding() {
        hasCompletedOnboarding = true
        withAnimation(.easeIn(duration: OnboardingExit.duration)) {
            showsHome = true
        } completion: {
            // 다 걷힌 온보딩은 내려요 (보이지 않으니 애니메이션 없이)
            mountsOnboarding = false
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
