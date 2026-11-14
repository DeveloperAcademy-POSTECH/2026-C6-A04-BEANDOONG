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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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

    /// 동작 줄이기·Hi-Fi 대조(`-uiTestStill`)에서는 수위를 따라가는 지연과 잔물결 없이 바로 그려요.
    private var isStill: Bool {
        #if DEBUG
        return reduceMotion || ProcessInfo.processInfo.arguments.contains("-uiTestStill")
        #else
        return reduceMotion
        #endif
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
                    Image(symbol.name)
                        .resizable()
                        .designScaled(width: symbol.size.width, height: symbol.size.height, scale)
                        .position(x: symbol.center.x.h(scale), y: symbol.center.y.v(scale))
                        .id(feedback)
                        .transition(.opacity)
                }

                // 공기 주입 중에는 매 프레임, 그 밖에는 수위가 마저 멈추고 잔물결이 잦아들 때까지 초당 30번 그려요.
                TimelineView(.animation(minimumInterval: aerationClock.isRunning ? nil : 1.0 / 30, paused: isStill && !aerationClock.isRunning)) { context in
                    let frame = pitcherMotion.advance(
                        to: context.date,
                        targetTop: MilkLevel.top(forAeration: aerationClock.seconds(at: context.date)),
                        rippling: aerationClock.isRunning,
                        still: isStill
                    )
                    SteamingPitcher(feedback: feedback, milkTop: frame.top,
                                    rippleAmplitude: frame.rippleAmplitude, ripplePhase: frame.ripplePhase)
                }
                .designScaled(width: SteamingPitcher.size.width, height: SteamingPitcher.size.height, scale)
                .position(x: Layout.pitcherCenter.x.h(scale), y: Layout.pitcherCenter.y.v(scale))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
            .accessibilityHidden(true)

            VStack(spacing: 0) {
                // MARK: 상단 바
                SteamingPracticeTopBar()
                    .padding(.top, Layout.topBarTop.v(scale))

                // MARK: 타이틀 + 설명
                // 색이 바뀌면 이전 문구가 먼저 사라지고 새 문구가 나타나요. (글자끼리 겹쳐 보이지 않게)
                ZStack(alignment: .top) {
                    VStack(spacing: 0) {
                        DarkScreenTitle(feedback.title, lineSpacing: Layout.titleLineSpacing)
                            .padding(.top, Layout.titleTop.v(scale))

                        if let subtitle = feedback.subtitle {
                            DarkScreenSubtitle(subtitle, color: Color.white)
                                .padding(.top, Layout.subtitleTop.v(scale))
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
}

/// 비커의 수위·잔물결을 프레임 사이에 이어 가요.
/// - 수위: 계산한 목표 수위를 0.35초 정도 늦게 따라가 출발·정지가 부드러워요.
/// - 잔물결: 공기 주입 중에만 세지고, 다른 상태에서는 0.6초에 걸쳐 잦아들어요.
private final class PitcherMotion {
    private var level = SmoothFollower(smoothTime: 0.35)
    private var ripple = SmoothFollower(smoothTime: 0.6)
    private var lastDate: Date?
    private var phase: Double = 0

    struct Frame {
        let top: CGFloat
        let rippleAmplitude: CGFloat
        let ripplePhase: Double
    }

    /// 잔물결 높이 (pt)와 1초에 지나가는 물결 수
    private static let rippleHeight: CGFloat = 1.6
    private static let rippleSpeed: Double = 1.1

    func advance(to date: Date, targetTop: CGFloat, rippling: Bool, still: Bool) -> Frame {
        let dt = lastDate.map { date.timeIntervalSince($0) } ?? 0
        lastDate = date
        if still {
            return Frame(top: targetTop, rippleAmplitude: 0, ripplePhase: 0)
        }
        let top = level.step(toward: Double(targetTop), dt: dt)
        let strength = ripple.step(toward: rippling ? 1 : 0, dt: dt)
        phase = (phase + max(0, min(dt, 0.1)) * Self.rippleSpeed * 2 * .pi).truncatingRemainder(dividingBy: 2 * .pi * 100)
        return Frame(top: CGFloat(top), rippleAmplitude: Self.rippleHeight * CGFloat(strength), ripplePhase: phase)
    }
}

// MARK: - 비커

/// 비커 그림 위에 우유·적정 구간·점선을 그려요. 좌표는 비커 그림(322×294pt) 기준, Hi-Fi 3x 에셋에서 잰 값이에요.
///
///     ┌ 비커 + 스팀 노즐 (`IllustSteamingPitcher`, 반투명 흰색)
///     ├ 우유 (윗면 = `milkTop`, 비커 안쪽 벽을 따라 사다리꼴)
///     ├ 적정 구간 (두 점선 사이를 상태 색으로 옅게 칠함)
///     ├ 점선 2줄 (위 = 4초, 아래 = 2초)
///     └ 상태별 장식 (보라: 물방울 · 주황: 기포)
private struct SteamingPitcher: View {
    static let size = CGSize(width: 322, height: 294)
    let feedback: SteamingFeedback
    /// 우유 윗면 y (`MilkLevel` 값을 부드럽게 따라간 값)
    let milkTop: CGFloat
    /// 우유 윗면 잔물결 높이 (pt, 0이면 잔잔함)와 위상
    var rippleAmplitude: CGFloat = 0
    var ripplePhase: Double = 0

    var body: some View {
        ZStack(alignment: .topLeading) {
            Image("IllustSteamingPitcher")
                .resizable()
                .frame(width: Self.size.width, height: Self.size.height)

            MilkSurface(vessel: .steamingPitcher, top: milkTop, amplitude: rippleAmplitude, phase: ripplePhase)
                .fill(AppColors.steamingMilk)

            Band()
                .fill(feedback.bandColor)

            DashLine(y: MilkLevel.upperLine, from: Line.upperStart, to: Line.upperEnd)
                .stroke(feedback.lineColor, style: Line.style)
            DashLine(y: MilkLevel.lowerLine, from: Line.lowerStart, to: Line.lowerEnd)
                .stroke(feedback.lineColor, style: Line.style)

            if let decoration = feedback.decoration {
                Image(decoration.name)
                    .resizable()
                    .frame(width: decoration.size.width, height: decoration.size.height)
                    .offset(x: decoration.origin.x, y: decoration.origin.y)
                    .id(feedback)
                    .transition(.opacity)
            }
        }
        .frame(width: Self.size.width, height: Self.size.height, alignment: .topLeading)
    }

    /// 점선 (Hi-Fi: 두께 8px, 선 26px · 틈 10px, 끝이 둥근 점선)
    private enum Line {
        static let style = StrokeStyle(lineWidth: 8.0 / 3, lineCap: .round, dash: [6, 6], dashPhase: 3)
        static let upperStart: CGFloat = 21, upperEnd: CGFloat = 227
        static let lowerStart: CGFloat = 18, lowerEnd: CGFloat = 230
    }
}

/// 비커 안쪽 (우유가 닿는 면). Hi-Fi 3x 에셋에서 잰 직선: 왼쪽 x = 47.33 − 0.15y, 오른쪽 x = 204.51 + 0.1227y
/// 모서리 반지름 (Hi-Fi: 윗면 5pt, 바닥 12pt), 잔물결 한 주기 64pt
private extension MilkVessel {
    static let steamingPitcher = MilkVessel(
        left: Wall(intercept: 47.33, slope: -0.15),
        right: Wall(intercept: 204.51, slope: 0.1227),
        bottom: MilkLevel.bottom,
        topRadius: 5,
        bottomRadius: 12,
        wavelength: 64
    )
}

private enum PitcherWall {
    /// 비커 바깥 테두리 (적정 구간 칠하기용): 왼쪽 x = 42.33 − 0.15y, 오른쪽 x = 209.81 + 0.1247y
    static func outerLeft(_ y: CGFloat) -> CGFloat { 42.33 - 0.15 * y }
    static func outerRight(_ y: CGFloat) -> CGFloat { 209.81 + 0.1247 * y }
}

/// 적정 구간: 두 점선 가운데 사이를 비커 폭만큼 칠해요. (점선이 위에 덮여 경계가 가려져요)
private struct Band: Shape {
    func path(in rect: CGRect) -> Path {
        let top = MilkLevel.upperLine
        let bottom = MilkLevel.lowerLine
        var path = Path()
        path.move(to: CGPoint(x: PitcherWall.outerLeft(top), y: top))
        path.addLine(to: CGPoint(x: PitcherWall.outerRight(top), y: top))
        path.addLine(to: CGPoint(x: PitcherWall.outerRight(bottom), y: bottom))
        path.addLine(to: CGPoint(x: PitcherWall.outerLeft(bottom), y: bottom))
        path.closeSubpath()
        return path
    }
}

private struct DashLine: Shape {
    let y: CGFloat
    let from: CGFloat
    let to: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: from, y: y))
        path.addLine(to: CGPoint(x: to, y: y))
        return path
    }
}

// MARK: - 피드백 종류

/// case 이름은 `PracticePhase`(워치와 공유)와 맞춰 두고, 화면 문구만 Hi-Fi에 맞춥니다.
enum SteamingFeedback: CaseIterable {
    /// 공기가 고르게 들어가는 중 (파랑)
    case aeration
    /// 노즐이 높아 큰 기포가 생길 수 있음 (주황)
    case bubble
    /// 공기 주입이 부족함 (보라)
    case moreAir
    /// 롤링이 안정적으로 진행되는 중 (초록)
    case milkFlow

    var gradientColors: [Color] {
        switch self {
        case .aeration: AppColors.aerationGradient
        case .bubble: AppColors.bubbleGradient
        case .moreAir: AppColors.moreAirGradient
        case .milkFlow: AppColors.milkFlowGradient
        }
    }

    /// 보라·주황은 해야 할 동작이 타이틀, 상태가 설명이에요.
    var title: String {
        switch self {
        case .aeration: String(localized: "공기가 고르게\n들어가고 있어요")
        case .bubble: String(localized: "피처를 살짝 올려\n노즐을 더 담가 주세요")
        case .moreAir: String(localized: "피처를 살짝\n내려 주세요")
        case .milkFlow: String(localized: "롤링이 안정적으로\n진행되고 있어요")
        }
    }

    /// 파랑·초록은 설명이 없어요.
    var subtitle: String? {
        switch self {
        case .aeration, .milkFlow: nil
        case .bubble: String(localized: "큰 기포가 생길 수 있어요")
        case .moreAir: String(localized: "공기 주입이 부족해요")
        }
    }

    /// 타이틀 뒤 반투명 큰 기호. 크기는 3x 에셋 그대로, 가운데 점은 Hi-Fi에서 잰 위치 (pt)
    fileprivate var symbol: (name: String, size: CGSize, center: CGPoint) {
        switch self {
        case .moreAir: ("IllustFeedbackArrowDown", CGSize(width: 340, height: 236), CGPoint(x: 201.2, y: 220))
        case .bubble: ("IllustFeedbackArrowUp", CGSize(width: 340, height: 236), CGPoint(x: 199.3, y: 237))
        case .aeration: ("IllustFeedbackCheck", CGSize(width: 255, height: 188), CGPoint(x: 206.5, y: 246))
        case .milkFlow: ("IllustFeedbackSwirl", CGSize(width: 248, height: 212), CGPoint(x: 198, y: 263))
        }
    }

    /// 비커 위 장식 (보라: 물방울, 주황: 기포). 위치는 비커 그림 왼쪽 위 기준 (pt)
    fileprivate var decoration: (name: String, size: CGSize, origin: CGPoint)? {
        switch self {
        case .moreAir: ("IllustFeedbackDrops", CGSize(width: 79, height: 69), CGPoint(x: 73.5, y: 22.3))
        case .bubble: ("IllustFeedbackBubbleRings", CGSize(width: 104, height: 78), CGPoint(x: 36, y: 1))
        case .aeration, .milkFlow: nil
        }
    }

    /// 점선 색 (Hi-Fi 에셋에서 잰 값)
    fileprivate var lineColor: Color {
        switch self {
        case .aeration: AppColors.steamingLineAeration
        case .bubble: AppColors.steamingLineBubble
        case .moreAir: AppColors.steamingLineMoreAir
        case .milkFlow: AppColors.steamingLineMilkFlow
        }
    }

    /// 두 점선 사이 적정 구간 색 (Hi-Fi 에셋의 겹친 색에서 거꾸로 계산한 색·불투명도)
    fileprivate var bandColor: Color {
        switch self {
        case .aeration: AppColors.steamingBandAeration
        case .bubble: AppColors.steamingBandBubble
        case .moreAir: AppColors.steamingBandMoreAir
        case .milkFlow: AppColors.steamingBandMilkFlow
        }
    }

    /// 종료하기 버튼 사각형 색 = 상태 팔레트 색 (배경 그라데이션의 아래쪽 색)
    var stopSquareColor: Color {
        switch self {
        case .aeration: AppColors.soundNormalAeration
        case .bubble: AppColors.soundOverAeration
        case .moreAir: AppColors.soundLackOfAir
        case .milkFlow: AppColors.soundRolling
        }
    }
}

// MARK: - Layout (iPhone 17 시안 측정값, pt)

private enum Layout {
    static let topBarTop: CGFloat = 72           // 화면 위 ↔ 상단 바 (Hi-Fi 160: 글자 y0 75 − 3)
    /// 상단 바 ↔ 타이틀. 4종 모두 같은 자리 (새 Hi-Fi 파랑: 글자 윗선 168.5)
    static let titleTop: CGFloat = 72.3
    static let titleLineSpacing: CGFloat = 4.7   // Hi-Fi 160: 타이틀 줄 높이 36 (171 → 207)
    static let subtitleTop: CGFloat = 14         // 타이틀 ↔ 설명
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

// MARK: - 화면 전용 색 (새 연습 중 Hi-Fi 3x 에셋에서 잰 값)

private extension AppColors {
    /// 우유 (에셋 245,250,255 → #F5FAFF)
    static let steamingMilk = Color(hex: 0xF5FAFF)

    static let steamingLineAeration = Color(hex: 0x80A5FE)
    static let steamingLineBubble = Color(hex: 0xFFC17A)
    static let steamingLineMoreAir = Color(hex: 0xD799FF)
    static let steamingLineMilkFlow = Color(hex: 0x5FF46B)

    static let steamingBandAeration = Color(hex: 0x6184E0).opacity(0.39)
    static let steamingBandBubble = Color(hex: 0xFF9726).opacity(0.152)
    static let steamingBandMoreAir = Color(hex: 0x7F07D1).opacity(0.152)
    static let steamingBandMilkFlow = Color(hex: 0x209D2C).opacity(0.408)
}

#Preview("aeration") { SteamingFeedbackView(feedback: .aeration, aerationClock: AerationClock(accumulated: 3)) }
#Preview("bubble") { SteamingFeedbackView(feedback: .bubble, aerationClock: AerationClock(accumulated: 3)) }
#Preview("moreAir") { SteamingFeedbackView(feedback: .moreAir, aerationClock: AerationClock(accumulated: 3)) }
#Preview("milkFlow") { SteamingFeedbackView(feedback: .milkFlow, aerationClock: AerationClock(accumulated: 3)) }
#Preview("시작 (0초)") { SteamingFeedbackView(feedback: .aeration) }
#Preview("소리 끊김") { SteamingFeedbackView(feedback: .aeration, showsEndDialog: true) }
