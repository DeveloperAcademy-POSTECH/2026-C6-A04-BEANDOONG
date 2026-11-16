import SwiftUI

/// 스티밍 연습 – 모델 피드백 화면 (피드백 종류에 따라 색상·문구·배경 기호·비커 장식이 바뀜)
/// - 디자인: Hi-Fi 새 연습 중 화면 4종 (보라·주황·파랑·초록) · 265 (팝업)
///
///     ┌ 배경: 피드백별 위 → 아래 그라데이션 + 반투명 큰 기호 (↓ · ↑ · ✓ · 소용돌이)
///     ├ 상단 바: 스티밍 연습
///     ├ 타이틀 (+ 설명: 보라·주황만)
///     ├ 비커: 누적 공기 주입 시간만큼 우유 수위가 부드럽게 올라감 (2~4초면 두 점선 사이, 공기 주입 중 잔물결)
///     ※ 색이 바뀌면 배경·기호·문구·점선 색이 0.4초 동안 섞이며 바뀜
///     └ 하단 중앙: 종료하기 버튼 (누르면 바로 정지. "스티밍이 끝났나요?" 팝업은 끝난 것 같을 때만)
///     ※ 타이틀·종료하기 버튼 위치는 4종 모두 같음
struct SteamingFeedbackView: View {
    @Environment(\.designScale) private var scale
    @MotionStill private var isStill: Bool
    let feedback: SteamingFeedback
    /// 이번 연습의 누적 공기 주입 시간 (연습 관리자가 정해요). 비커 수위가 이 값을 따라가요.
    var aerationClock = AerationClock()
    /// 종료하기 버튼: 묻지 않고 바로 정지
    var onStop: () -> Void = {}
    /// 스팀 소리가 끊겨 "스티밍이 끝났나요?"를 묻는 중인지 (연습 관리자가 정해요)
    var showsEndDialog = false
    /// 팝업의 '계속 연습'
    var onContinue: () -> Void = {}
    /// 팝업의 '연습 종료' (소리가 끊긴 시각으로 종료)
    var onFinishAfterSilence: () -> Void = {}

    /// 수위·잔물결을 프레임마다 이어 가는 상태 (화면을 다시 그리게 하지 않는 참조 타입)
    @State private var pitcherMotion = PitcherMotion()
    /// 수위와 잔물결이 다 멈춰서 비커 그리기를 쉬는 중인 공기 주입 시계. 지금 시계와 같을 때만 쉬어요 (시계가 바뀌면 바로 다시 그려요).
    @State private var restingClock: AerationClock?

    var body: some View {
        ZStack {
            // MARK: 배경
            // 색이 바뀌면 그라데이션이 섞이며 바뀌어요.
            LinearGradient(colors: feedback.gradientColors, startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            // MARK: 배경 기호 · 비커 (시안 좌표 그대로 배치)
            ZStack {
                // 색이 바뀌면 이전 기호가 사라지며 새 기호가 겹쳐 나타나요.
                ZStack {
                    let symbol = feedback.symbol
                    Image.prepared(symbol.name)
                        .resizable()
                        .designScaled(size: symbol.size, scale)
                        .position(x: symbol.center.x.h(scale), y: symbol.center.y.v(scale))
                        .id(feedback)
                        .transition(.opacity)
                }

                // 공기 주입 중에는 매 프레임, 그 밖에는 수위가 마저 멈추고 잔물결이 잦아들 때까지 초당 30번 그리고, 다 멈추면 쉬어요.
                TimelineView(.animation(minimumInterval: aerationClock.isRunning ? nil : 1.0 / 30, paused: isPitcherPaused)) { context in
                    let frame = pitcherFrame(at: context.date)
                    SteamingPitcher(feedback: feedback, milkTop: frame.top,
                                    rippleAmplitude: frame.rippleAmplitude, ripplePhase: frame.ripplePhase)
                }
                .designScaled(size: SteamingPitcher.size, scale)
                .position(x: Layout.pitcherCenter.x.h(scale), y: Layout.pitcherCenter.y.v(scale))

                // 비커 위 장식은 비커와 같은 자리에 겹치되, 매 프레임 다시 계산하는 `TimelineView` 밖에 둬요.
                SteamingPitcherDecoration(feedback: feedback)
                    .designScaled(size: SteamingPitcher.size, scale)
                    .position(x: Layout.pitcherCenter.x.h(scale), y: Layout.pitcherCenter.y.v(scale))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
            .accessibilityHidden(true)

            VStack(spacing: 0) {
                // MARK: 상단 바
                SteamingPracticeTopBar()
                    .padding(.top, ScreenMetrics.practiceTopBarTop.v(scale))

                // MARK: 타이틀 + 설명
                // 색이 바뀌면 이전 문구가 먼저 사라지고 새 문구가 나타나요. (글자끼리 겹쳐 보이지 않게)
                ZStack(alignment: .top) {
                    VStack(spacing: 0) {
                        DarkScreenTitle(feedback.title, lineSpacing: Layout.titleLineSpacing)
                            .padding(.top, Layout.titleTop.v(scale))

                        if let subtitle = feedback.subtitle {
                            DarkScreenSubtitle(subtitle, color: Color.white)
                                .padding(.top, ScreenMetrics.subtitleTop.v(scale))
                        }
                    }
                    .id(feedback)
                    .transition(Layout.textChange)
                }
                .frame(maxWidth: .infinity)

                Spacer(minLength: 0)

                // MARK: 종료하기 버튼
                // 직접 누르면 묻지 않고 바로 정지해요. (팝업은 소리가 끊겼을 때만)
                SteamingEndButton(squareColor: feedback.stopSquareColor, width: Layout.endButtonWidth.h(scale),
                                  backgroundOpacity: Layout.endButtonOpacity, action: onStop)
                    .padding(.bottom, Layout.endButtonBottom.v(scale))
            }
            .ignoresSafeArea()
        }
        // 색이 바뀔 때 배경·기호·문구·점선 색·버튼 위치가 함께 부드럽게 바뀌어요.
        .animation(Layout.feedbackChange, value: feedback)
        .chicAlert(
            isPresented: showsEndDialog,
            title: String(localized: "스티밍이 끝났나요?"),
            message: String(localized: "스팀 소리가 감지되지 않아요\n연습을 마쳤다면 기록을 확인해 주세요"),
            cancelTitle: String(localized: "계속 연습"),
            confirmTitle: String(localized: "연습 종료"),
            onCancel: onContinue,
            onConfirm: onFinishAfterSilence
        )
        .preferredColorScheme(.dark)
    }

    // MARK: 비커 그리기 쉬기

    /// 비커 그리기를 멈출지.
    /// - 공기 주입 중에는 언제나 그려요 (수위가 매 프레임 올라가고 잔물결이 일어요).
    /// - 동작 줄이기 · Hi-Fi 대조(`-uiTestStill`)에서는 수위를 따라가는 지연도 잔물결도 없어서, 공기 주입이 아니면 바뀔 게 없으니 멈춰요.
    /// - 그 밖에는 수위와 잔물결이 다 멈췄을 때(`restingClock`) 멈추고, 공기 주입 시계가 바뀌면(주입 시작 · 수위 목표 변화) 같은 순간에 다시 그려요.
    private var isPitcherPaused: Bool {
        guard !aerationClock.isRunning else { return false }
        return isStill || restingClock == aerationClock
    }

    /// `date` 시점의 비커 수위 · 잔물결. 다 멈췄으면 쉬어도 된다고 상태에 알려요.
    private func pitcherFrame(at date: Date) -> PitcherMotion.Frame {
        let clock = aerationClock
        let frame = pitcherMotion.advance(
            to: date,
            targetTop: MilkLevel.top(forAeration: clock.seconds(at: date)),
            rippling: clock.isRunning,
            still: isStill
        )
        if frame.isResting, restingClock != clock {
            // 그리는 도중에는 상태를 바꿀 수 없어서 바로 다음에 알려요.
            Task { @MainActor in restingClock = clock }
        }
        return frame
    }
}

// MARK: - Layout (iPhone 17 시안 측정값, pt)

private enum Layout {
    /// 상단 바 ↔ 타이틀. 4종 모두 같은 자리 (새 Hi-Fi 파랑: 글자 윗선 168.5)
    static let titleTop: CGFloat = 72.3
    static let titleLineSpacing: CGFloat = 4.7   // Hi-Fi 160: 타이틀 줄 높이 36 (171 → 207)
    /// 비커 그림(322×294) 가운데 점: 왼쪽 79 · 위 382 (Hi-Fi: 노즐 위 383, 비커 바닥 675.5, 노즐이 화면 오른쪽 끝까지)
    static let pitcherCenter = CGPoint(x: 79 + 161, y: 382 + 147)
    static let endButtonWidth: CGFloat = 274     // Hi-Fi 160: 캡슐 폭 274.5
    /// 종료하기 버튼 ↔ 화면 하단. 4종 모두 같은 자리 (새 Hi-Fi: 874 − 809.5)
    static let endButtonBottom: CGFloat = 64.5
    static let endButtonOpacity: Double = 0.73   // 새 Hi-Fi: 버튼 색 = #F5FAFF 73% + 배경 (4종 모두 0.72~0.74)
    /// 색이 바뀔 때 배경·기호·문구·점선 색이 섞이며 바뀌는 시간
    static let feedbackChange = Animation.easeInOut(duration: 0.4)
    /// 문구: 이전 문구가 0.15초에 사라진 뒤 새 문구가 0.25초에 나타나요 (전체 0.4초)
    static let textChange = AnyTransition.asymmetric(
        insertion: .opacity.animation(.easeOut(duration: 0.25).delay(0.15)),
        removal: .opacity.animation(.easeIn(duration: 0.15))
    )
}

#Preview("aeration") { SteamingFeedbackView(feedback: .aeration, aerationClock: AerationClock(accumulated: 3)) }
#Preview("bubble") { SteamingFeedbackView(feedback: .bubble, aerationClock: AerationClock(accumulated: 3)) }
#Preview("moreAir") { SteamingFeedbackView(feedback: .moreAir, aerationClock: AerationClock(accumulated: 3)) }
#Preview("milkFlow") { SteamingFeedbackView(feedback: .milkFlow, aerationClock: AerationClock(accumulated: 3)) }
#Preview("시작 (0초)") { SteamingFeedbackView(feedback: .aeration) }
#Preview("소리 끊김") { SteamingFeedbackView(feedback: .aeration, showsEndDialog: true) }
