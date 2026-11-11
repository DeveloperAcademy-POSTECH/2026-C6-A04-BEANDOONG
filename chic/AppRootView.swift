//
//  AppRootView.swift
//
//  연습 상태를 관찰하며 기본 화면 위에 연습·결과 화면을 표시하는 앱의 루트 뷰입니다.
//  객체 생성은 cheekApp이 담당하고, 화면 갱신과 오류 안내는 이 View가 담당합니다.
//  .finished에서도 결과 화면을 유지하고, '다시 연습'으로 .idle이 되어야 기본 화면을 표시합니다.
//  앱을 켜면 맨 위에 스플래시(LaunchView)를 잠깐 보여 준 뒤 부드럽게 걷어 냅니다.
//

import SwiftUI

/// 연습 결과 화면에서 뒤로가기로 메인에 돌아갈 때의 움직임 (시스템 화면 뒤로가기와 같은 느낌)
enum ScreenPopMotion {
    /// 결과 화면이 오른쪽으로 밀려 나가고 홈이 제자리로 오는 시간·곡선
    static let animation = Animation.timingCurve(MotionCurve.easeOutQuint, duration: 0.42)
    /// 홈이 밀려 들어오기 전에 왼쪽으로 물러나 있는 거리(pt)
    static let homeParallax: CGFloat = 90
    /// 결과 화면 뒤에서 홈을 덮고 있다가 걷히는 검정 (0이면 안 덮음)
    static let homeDim: Double = 0.35
}

struct AppRootView: View {
    @EnvironmentObject private var practice: PracticeSession
    /// 앱을 켠 직후 스플래시를 보여 주는 중인지
    @State private var showsSplash = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.designScale) private var scale
    /// 결과 화면을 닫는 중인지 (연습은 이미 끝나 `.idle`이지만, 결과 화면이 밀려 나가는 동안은 계속 보여요)
    @State private var isClosingSession = false
    /// 닫히는 동안 결과 화면이 화면 밖으로 나갔는지 (이 값이 바뀔 때 애니메이션이 돌아요)
    @State private var sessionSlidOut = false

    /// 연습·결과 화면을 보여야 하는지
    private var showsSession: Bool { practice.state.phase != .idle || isClosingSession }
    /// 결과 화면이 홈을 덮고 있는지 (홈이 뒤로 물러나 어두워 있는 상태)
    private var homeIsCovered: Bool { showsSession && !sessionSlidOut }

    var body: some View {
        ZStack {
            ContentView()
                .opacity(practice.state.phase == .idle ? 1 : 0)
                // 투명도는 바로 바꾸고(결과 화면이 밀려 나가는 동안 뒤에 홈이 이미 보이게), 아래 위치·어두움만 움직여요.
                .animation(nil, value: practice.state.phase == .idle)
                // 결과 화면을 닫을 때: 홈이 왼쪽에서 살짝 밀려 들어오며 제자리로 와요 (시스템 뒤로가기의 시차 효과)
                .offset(x: homeIsCovered && !reduceMotion ? -ScreenPopMotion.homeParallax : 0)
                .overlay { Color.black.opacity(homeIsCovered ? ScreenPopMotion.homeDim : 0).allowsHitTesting(false) }
                .allowsHitTesting(practice.state.phase == .idle)
                .accessibilityHidden(practice.state.phase != .idle)

            // 이전 화면이 연결 완료인지 준비 화면인지와 관계없이 결과 화면을 유지합니다.
            if showsSession {
                PracticeSessionView(onResultClose: closeSession)
                    // 결과 화면을 닫을 때만 움직여요: 오른쪽으로 밀려 나가요 (연습 시작은 예전처럼 바로 나타나요)
                    .offset(x: sessionSlidOut && !reduceMotion ? Self.designWidth * scale.x : 0)
                    .opacity(sessionSlidOut && reduceMotion ? 0 : 1)
                    .allowsHitTesting(!isClosingSession)
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

    private static let designWidth = DesignScale.baseSize.width

    /// 결과 화면의 뒤로가기: 연습 상태를 `.idle`로 돌리고, 결과 화면을 오른쪽으로 밀어내며 메인을 보여 줘요.
    private func closeSession() {
        isClosingSession = true
        practice.finishReview()
        withAnimation(ScreenPopMotion.animation, completionCriteria: .logicallyComplete) {
            sessionSlidOut = true
        } completion: {
            isClosingSession = false
            sessionSlidOut = false
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
