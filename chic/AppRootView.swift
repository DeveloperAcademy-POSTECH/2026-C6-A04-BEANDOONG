//
//  AppRootView.swift
//
//  연습 상태를 관찰하며 기본 화면 위에 연습·결과 화면을 표시하는 앱의 루트 뷰입니다.
//  객체 생성은 cheekApp이 담당하고, 화면 갱신과 오류 안내는 이 View가 담당합니다.
//  .finished에서도 결과 화면을 유지하고, '다시 연습'으로 .idle이 되어야 기본 화면을 표시합니다.
//  앱을 켜면 맨 위에 스플래시(LaunchView)를 잠깐 보여 준 뒤 부드럽게 걷어 냅니다.
//

import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var practice: PracticeSession
    /// 앱을 켠 직후 스플래시를 보여 주는 중인지
    @State private var showsSplash = true

    var body: some View {
        ZStack {
            ContentView()
                .opacity(practice.state.phase == .idle ? 1 : 0)
                .allowsHitTesting(practice.state.phase == .idle)
                .accessibilityHidden(practice.state.phase != .idle)
                // 스플래시나 연습 화면이 덮고 있는 동안에는 아래 화면의 반복 애니메이션을 멈춰 둬요.
                // (보이지 않는 화면이 매 프레임 그려지며 메인 스레드를 쓰지 않게) 다시 보일 때 0부터 시작해요.
                .environment(\.loopAnimationsPaused, showsSplash || practice.state.phase != .idle)

            // 이전 화면이 연결 완료인지 준비 화면인지와 관계없이 결과 화면을 유지합니다.
            if practice.state.phase != .idle {
                PracticeSessionView()
            }

            // 스플래시: 아래 화면은 미리 준비해 두고, 로고 애니메이션이 끝나면 걷어 내요.
            if showsSplash {
                LaunchView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        // 모든 화면이 다크라서 앱 전체를 다크로 고정해요. 화면을 바꿔 끼우는 순간(스플래시가 걷힐 때, 화면을 넣고 뺄 때)
        // 다크 지정이 잠깐 비어 시스템 라이트 배경이 한 프레임 비치는 일을 막아요. 각 화면의 지정은 그대로 둬요.
        .preferredColorScheme(.dark)
        .task { await hideSplashAfterDisplay() }
        .alert("연습 안내", isPresented: Binding(
            get: { practice.errorMessage != nil && practice.state.phase == .idle },
            set: { if !$0 { practice.errorMessage = nil } }
        )) {
            Button("확인") { practice.errorMessage = nil }
        } message: {
            Text(practice.errorMessage ?? "")
        }
    }

    /// 스플래시를 정해진 시간만큼 보여 준 뒤 서서히 걷어 내요.
    private func hideSplashAfterDisplay() async {
        // 로고 애니메이션과 같은 기준(첫 프레임이 그려진 뒤)에서 시간을 재요.
        await FrameClock.nextFrame()
        try? await Task.sleep(for: .seconds(SplashTiming.displayDuration))
        withAnimation(.easeOut(duration: SplashTiming.fadeOutDuration)) {
            showsSplash = false
        }
    }
}
