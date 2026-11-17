import SwiftUI

/// 발표용 피드백 화면. 시퀀스가 끝나면 수위를 고정하고 잔물결을 유지합니다.
struct PresentationFeedbackView: View {
    @Environment(\.designScale) private var scale
    @MotionStill private var isStill: Bool
    let presentation: PresentationPractice
    let onStop: () -> Void
    @State private var pitcherMotion = PitcherMotion()

    private var aerationClock: AerationClock { presentation.aerationClock }

    private var feedback: SteamingFeedback {
        switch presentation.phase {
        case .bubble: .bubble
        case .moreAir: .moreAir
        case .milkFlow: .milkFlow
        default: .aeration
        }
    }

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

                // 공기 주입 중에는 매 프레임, 다른 구간과 마지막 잔물결은 초당 30번 그려요.
                TimelineView(.animation(minimumInterval: aerationClock.isRunning ? nil : 1.0 / 30, paused: isStill && !aerationClock.isRunning)) { context in
                    let frame = pitcherMotion.advance(
                        to: context.date,
                        targetTop: MilkLevel.top(forAeration: aerationClock.seconds(at: context.date), model: aerationClock.model),
                        rippling: aerationClock.isRunning || presentation.isComplete,
                        still: isStill
                    )
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
                // 발표용 종료 버튼은 바로 결과 화면으로 이어져요.
                SteamingEndButton(squareColor: feedback.stopSquareColor, width: Layout.endButtonWidth.h(scale),
                                  backgroundOpacity: Layout.endButtonOpacity, action: onStop)
                    .padding(.bottom, Layout.endButtonBottom.v(scale))
            }
            .ignoresSafeArea()
        }
        // 색이 바뀔 때 배경·기호·문구·점선 색·버튼 위치가 함께 부드럽게 바뀌어요.
        .animation(Layout.feedbackChange, value: feedback)
        .preferredColorScheme(.dark)
    }
}

// MARK: - Layout (iPhone 17 시안 측정값, pt)

private enum Layout {
    /// 화면 위 ↔ 타이틀. 기존 상단 제목을 제거해도 4종 모두 같은 자리 (72 + 20 + 72.3)
    static let titleTop: CGFloat = 164.3
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

