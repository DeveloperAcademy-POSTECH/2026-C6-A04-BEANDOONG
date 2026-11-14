import SwiftUI

/// 연습 준비 가이드 2쪽: 워치 화면 4종(정상 · 과다 · 부족 · 롤링)을 좌우로 넘겨 보는 캐러셀
/// - 디자인: 대화로 받은 시안 4장(파랑·주황·보라·초록), 움직임은 레퍼런스 영상(아이폰 동작 버튼 설정 화면)
///
///     ┌ 워치 (가운데 고정): 검정 테 + 상태색 화면 + [종료] 알약
///     │   └ 화면 안의 글자·원은 옆 칸에서 미끄러져 들어오고, 나간 칸은 회색으로 옅어짐 (이웃 칸이 양옆에 살짝 보임)
///     ├ 페이지 점 4개: 캡슐이 손가락을 따라 이어서 옮겨 감 (롤링 → 정상은 4번째가 줄어드는 동안 1번째가 늘어남)
///     ├ 타이틀: 상태 이름 (옆 칸으로 넘어가는 동안 짧게 흐려졌다 나타남)
///     └ 설명
///
/// 칸은 원형으로 이어져 있어요: 롤링 오른쪽에 정상, 정상 왼쪽에 롤링 (2026-11-13: 끝에서 처음으로 돌아갈 때도 같은 움직임).
/// `position`: 지금 가운데에 오는 칸 번호(소수 가능, 4칸마다 한 바퀴라 4 이상 · 0 미만도 그대로 써요). 손가락을 따라 움직일 때와 넘김 애니메이션이 같은 값을 쓰도록
/// 이 뷰가 `Animatable`이라서, `withAnimation { position = 2 }`처럼 바꾸면 중간값으로 매 프레임 다시 그려요.
struct PrepWatchCarousel: View, Animatable {
    var position: Double
    /// 쪽 넘김(온보딩과 같은 PageTurnStack) 중의 위치·투명도
    var motion: OnboardingPageMotion = .resting

    var animatableData: Double {
        get { position }
        set { position = newValue }
    }

    @Environment(\.designScale) private var scale

    var body: some View {
        VStack(spacing: 0) {
            stage
                .onboardingPart(motion.illustration)
                .padding(.top, Layout.stageTop.v(scale))

            PrepDots(position: position)
                .onboardingPart(motion.illustration)
                .padding(.top, Layout.dotsTop.v(scale))

            ZStack {
                ForEach(PrepWatchState.allCases, id: \.self) { state in
                    DarkScreenTitle(state.title)
                        .opacity(Self.titleOpacity(distance: Self.offset(of: state, position: position)))
                }
            }
            .onboardingPart(motion.title)
            .padding(.top, Layout.titleTop.v(scale))

            DarkScreenSubtitle(String(localized: "색상 변화로 공기 주입 상태를\n쉽게 확인 할 수 있어요."))
                    .onboardingPart(motion.subtitle)
                .padding(.top, Layout.subtitleTop.v(scale))
        }
    }

    // MARK: 워치 + 옆 칸들

    /// 시안 좌표(402 폭, 워치 위쪽 = 0)로 그린 뒤 화면에 맞춰 키운다
    private var stage: some View {
        ZStack(alignment: .topLeading) {
            watchBody
            ForEach(PrepWatchState.allCases, id: \.self) { state in
                item(state)
            }
            // 종료 알약: 가운데 워치에 고정
            Text(String(localized: "종료"))
                .font(.pretendard(.bold, size: Layout.pillFontSize))
                .foregroundStyle(Color.black)
                .frame(width: Layout.pillSize.width, height: Layout.pillSize.height)
                .background(Capsule().fill(Color.white))
                .position(x: Layout.watchCenterX, y: Layout.pillCenterY)
        }
        .frame(width: Layout.canvasWidth, height: Layout.watchHeight, alignment: .topLeading)
        .designScaled(width: Layout.canvasWidth, height: Layout.watchHeight, scale)
    }

    /// 검정 테 + 상태색 화면 (가운데 고정, 상태색은 칸이 넘어가는 비율대로 섞인다)
    private var watchBody: some View {
        ZStack(alignment: .topLeading) {
            // 용두
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Layout.crownColor)
                .frame(width: Layout.crownSize.width, height: Layout.crownSize.height)
                .offset(x: Layout.bodyX + Layout.bodySize.width - 1, y: Layout.crownY)

            // 본체: 검정 테 + 위쪽 가장자리의 금속 하이라이트 (시안: 위 호를 따라 흰 선)
            RoundedRectangle(cornerRadius: Layout.bodyRadius, style: .continuous)
                .fill(Layout.bodyColor)
                .overlay {
                    RoundedRectangle(cornerRadius: Layout.bodyRadius, style: .continuous)
                        .strokeBorder(
                            LinearGradient(stops: [.init(color: Color.white.opacity(0.7), location: 0),
                                                   .init(color: Color.white.opacity(0.05), location: 0.1),
                                                   .init(color: Color.clear, location: 0.2)],
                                           startPoint: .top, endPoint: .bottom),
                            lineWidth: 1.5)
                }
                .frame(width: Layout.bodySize.width, height: Layout.bodySize.height)
                .offset(x: Layout.bodyX)

            // 화면: 상태색 그라데이션을 가까운 두 칸의 비율대로 겹친다
            ZStack {
                ForEach(PrepWatchState.allCases, id: \.self) { state in
                    LinearGradient(gradient: state.gradient, startPoint: .top, endPoint: .bottom)
                        .opacity(Self.gradientWeight(distance: Self.offset(of: state, position: position)))
                }
            }
            .frame(width: Layout.screenSize.width, height: Layout.screenSize.height)
            .overlay {
                // 화면 가장자리의 은은한 빛 번짐 (워치 앱 피드백 화면과 같은 효과)
                RoundedRectangle(cornerRadius: Layout.screenRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 8)
                    .blur(radius: 6)
            }
            .clipShape(RoundedRectangle(cornerRadius: Layout.screenRadius, style: .continuous))
            .offset(x: Layout.screenX, y: Layout.screenY)
        }
    }

    /// 한 칸: 워치 문구 두 줄 + 우유 원. 가운데에서 멀어지면 옆으로 밀리며 옅어진다(30%)
    private func item(_ state: PrepWatchState) -> some View {
        let distance = Self.offset(of: state, position: position)
        return ZStack(alignment: .topLeading) {
            Text(state.watchText)
                .font(.pretendard(.bold, size: Layout.watchTextSize))
                .lineSpacing(Layout.watchTextLineSpacing)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.white)
                .fixedSize()
                .position(x: 0, y: Layout.textCenterY)
            AssetImageView(name: state.illustration, width: Layout.circleDiameter, height: Layout.circleDiameter)
                .position(x: 0, y: Layout.circleCenterY)
        }
        .frame(width: 0, height: 0, alignment: .topLeading)
        .offset(x: Layout.watchCenterX + distance * Layout.pitch, y: Layout.ghostDropY * min(1, abs(distance)))
        .opacity(Self.contentOpacity(distance: distance))
        .opacity(abs(distance) < Layout.visibleDistance ? 1 : 0)
    }

    // MARK: 칸 위치 계산

    /// 가운데 기준 칸의 위치 (0 = 가운데, ±1 = 양옆). 원형이라 가장 가까운 쪽으로 잰다 (−2 ~ +2)
    static func offset(of state: PrepWatchState, position: Double) -> Double {
        circularDistance(Double(state.rawValue) - position)
    }

    /// 칸 수(4)로 감싼 거리: −2 이상 +2 미만
    static func circularDistance(_ raw: Double) -> Double {
        let count = Double(PrepWatchState.allCases.count)
        let wrapped = (raw.truncatingRemainder(dividingBy: count) + count).truncatingRemainder(dividingBy: count)
        return wrapped >= count / 2 ? wrapped - count : wrapped
    }

    /// 상태색 화면의 보이는 정도: 가운데에 올수록 1, 한 칸 떨어지면 0
    static func gradientWeight(distance: Double) -> Double { max(0, 1 - abs(distance)) }

    /// 화면 안 글자·원의 진하기: 가운데 1 → 옆 칸 0.3 (어두운 배경 위에서 옅은 회색으로 보인다)
    static func contentOpacity(distance: Double) -> Double { 1 - (1 - Layout.sideOpacity) * min(1, abs(distance)) }

    /// 아래 타이틀의 진하기: 칸이 반쯤 넘어가면 사라지고 반쯤 넘어오면 나타난다
    static func titleOpacity(distance: Double) -> Double { min(1, max(0, 1 - 2 * abs(distance))) }
}

// MARK: - 페이지 점

/// 점 4개. 캡슐(38x11)은 `position`을 따라 연속으로 옮겨 가고, 나머지는 점(11x11).
/// 원형 거리로 재서 롤링 → 정상일 때는 끝 점이 줄어드는 동안 첫 점이 늘어난다
private struct PrepDots: View {
    let position: Double

    var body: some View {
        HStack(spacing: 7) {
            ForEach(0..<PrepWatchState.allCases.count, id: \.self) { index in
                let weight = max(0, 1 - abs(PrepWatchCarousel.circularDistance(Double(index) - position)))
                Capsule()
                    .fill(AppColors.pageIndicatorInactive)
                    .overlay { Capsule().fill(AppColors.pageIndicatorActive).opacity(weight) }
                    .frame(width: 11 + 27 * weight, height: 11)
            }
        }
    }
}

// MARK: - 워치 상태 4종

/// 가이드에 보여 줄 워치 화면 4종. 순서가 점·스와이프 순서다.
enum PrepWatchState: Int, CaseIterable {
    case normal    // 파랑 · 정상 공기 주입
    case over      // 주황 · 공기 과다
    case lack      // 보라 · 공기 주입 부족
    case rolling   // 초록 · 롤링

    /// 워치 화면 안의 안내 문구 (시안)
    var watchText: String {
        switch self {
        case .normal: String(localized: "지금 위치를\n유지해요")
        case .over: String(localized: "피처를\n내려 주세요")
        case .lack: String(localized: "피처를\n올려 주세요")
        case .rolling: String(localized: "우유가 도는지\n확인해요")
        }
    }

    /// 아래 타이틀: 상태 이름
    var title: String {
        switch self {
        case .normal: String(localized: "정상 공기 주입")
        case .over: String(localized: "공기 과다")
        case .lack: String(localized: "공기 주입 부족")
        case .rolling: String(localized: "롤링")
        }
    }

    /// 워치 화면 속 우유 원 (스티밍 피드백 화면과 같은 에셋)
    var illustration: String {
        switch self {
        case .normal: "IllustFeedbackAeration"
        case .over: "IllustFeedbackBubble"
        case .lack: "IllustFeedbackMoreAir"
        case .rolling: "IllustFeedbackMilkFlow"
        }
    }

    /// 워치 화면 배경 그라데이션 (위 → 아래). 색과 위치는 워치 앱 `SteamingFeedback.backgroundGradient`와 같다
    var gradient: Gradient {
        let colors: [UInt32] = switch self {
        case .normal: [0x052FA9, 0x1D4FCD, 0x2E66E4, 0x3A6EE7, 0x86A6EF]
        case .over: [0xFF6A11, 0xFE7E1D, 0xE4A727, 0xE9C353, 0xF0DC8B]
        case .lack: [0x5904A5, 0x6101A7, 0x7C1BC7, 0x913EDA, 0xC194EF]
        case .rolling: [0x1F9A0A, 0x258302, 0x25B539, 0x36D25D, 0x86EFA5]
        }
        let locations: [CGFloat] = [0, 0.5, 0.81, 0.89, 1]
        return Gradient(stops: zip(colors, locations).map { Gradient.Stop(color: Color(hex: $0), location: $1) })
    }
}

// MARK: - Layout (iPhone 17 시안 측정값, pt · 워치 본체 위쪽 = 0 / 화면 왼쪽 = 0)

private enum Layout {
    // 쪽 안 세로 간격 (상단 바 아래 y 104 기준)
    static let stageTop: CGFloat = 100          // 상단 바 아래 ↔ 워치 위 (시안 y 204)
    static let dotsTop: CGFloat = 35            // 워치 아래(417.5) ↔ 점 위 (시안 y 452.5)
    static let titleTop: CGFloat = 66           // 점 아래(463.5) ↔ 타이틀 (시안 글자 y0 533.5, 글자 위 여백 4 보정)
    static let subtitleTop: CGFloat = 11.5      // 타이틀 ↔ 설명 (시안: 설명 첫 줄 글자 y0 575)

    // 워치 (시안 y 204 ~ 417.5)
    static let canvasWidth: CGFloat = 402
    static let watchHeight: CGFloat = 213.5
    static let watchCenterX: CGFloat = 201
    static let bodyX: CGFloat = 108.5           // 본체 x 108.5 ~ 293.5
    static let bodySize = CGSize(width: 185, height: 213.5)
    static let bodyRadius: CGFloat = 50
    static let bodyColor = Color(hex: 0x070709)
    static let crownSize = CGSize(width: 10, height: 36)
    static let crownY: CGFloat = 51             // 시안 y 255
    static let crownColor = Color(hex: 0x1C1D22)
    static let screenX: CGFloat = 122           // 화면 x 122 ~ 279.5, y 218 ~ 406
    static let screenY: CGFloat = 14
    static let screenSize = CGSize(width: 157.5, height: 188)
    static let screenRadius: CGFloat = 40

    // 화면 안 (시안 측정)
    static let pitch: CGFloat = 196             // 이웃 칸 사이 거리 (시안 4장 중 3장). 양옆 칸이 반쯤 잘려 보인다
    static let visibleDistance: Double = 1.45   // 이보다 멀리 있는 칸은 화면 밖이라 그리지 않는다
    static let sideOpacity: Double = 0.3        // 옆 칸 글자·원의 진하기
    static let ghostDropY: CGFloat = 16         // 옆 칸은 워치 안의 칸보다 16pt 아래에 있다 (시안: 옆 칸 글자 y 266·원 y 338, 워치 안 250·322)
    static let watchTextSize: CGFloat = 14.5
    static let watchTextLineSpacing: CGFloat = 3
    static let textCenterY: CGFloat = 56        // 문구 두 줄의 가운데 (시안 y 260)
    static let circleDiameter: CGFloat = 55.5
    static let circleCenterY: CGFloat = 117.5   // 시안 y 321.5
    static let pillSize = CGSize(width: 37, height: 18.5)
    static let pillCenterY: CGFloat = 173.8     // 시안 y 377.8
    static let pillFontSize: CGFloat = 9
}
