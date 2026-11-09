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
        try? await Task.sleep(for: .seconds(SplashTiming.displayDuration))
        withAnimation(.easeOut(duration: SplashTiming.fadeOutDuration)) {
            showsSplash = false
        }
    }
}
