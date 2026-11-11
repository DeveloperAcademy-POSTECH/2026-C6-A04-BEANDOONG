import SwiftUI

/// 연습 준비 가이드 (2쪽) — 연습을 시작하기 전에 휴대폰 위치와 워치 화면 색 의미를 안내한다
/// - 1쪽: Hi-Fi iPhone 17 - 249(1/2) 기반, 새 시안(대화로 받은 이미지)에서 페이지 점이 빠지고 타이틀이 y 533.5로 내려옴
/// - 2쪽: 새 시안 4장 — 워치 화면 4종(정상·과다·부족·롤링)을 좌우로 넘겨 보는 캐러셀 (`PrepWatchCarousel`)
///
///     ┌ 상단 바: < 연습 준비  건너뛰기
///     ├ 일러스트 (1쪽 머신+휴대폰 / 2쪽 워치 캐러셀 + 점 4개)
///     ├ 타이틀 + 설명
///     └ 버튼 (1쪽 "다음", 2쪽 "다음" → 마지막 칸 "스팀 연습 시작하기" = 가이드를 나가 연습 시작)
///
/// 쪽 이동: 1쪽 ↔ 2쪽은 온보딩과 같은 쪽 넘김(`PageTurnStack`), 2쪽 안의 4칸은 손가락을 따라 움직이는 캐러셀.
/// 좌우 스와이프 · "다음" · "건너뛰기"(바로 연습 시작). 2쪽에 들어온 뒤에는 스와이프로 1쪽에 돌아오지 못한다(첫 칸에서 오른쪽으로 밀어도 제자리).
/// 1쪽에서 오른쪽으로 밀면 메인으로 돌아간다. (왼쪽 가장자리에서 밀면 어느 쪽에서든 시스템 스와이프로 메인으로 돌아간다)
struct PracticePrepGuideView: View {
    @Environment(\.designScale) private var scale
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var practice: PracticeSession
    /// 진입 경로에서 정한 워치 사용 여부
    var usesWatch = true
    /// 0: 머신 + 휴대폰, 1: 워치 화면 캐러셀
    @State private var page: Int
    /// 캐러셀이 가운데에 보여 주는 칸 (0 ~ 3, 손가락을 따라 소수로 움직인다)
    @State private var position: Double
    /// 쪽 넘김 컴포넌트가 요구하는 인디케이터 값 (이 화면은 페이지 점을 캐러셀 안에서 직접 그린다)
    @State private var unusedIndicator = 0
    /// 드래그를 시작할 때의 캐러셀 위치
    @State private var dragStart: Double?

    /// `page`: 0 = 1쪽, 1...4 = 2쪽의 첫 칸부터 넷째 칸 (UI 테스트용 시작 위치)
    init(usesWatch: Bool = true, page: Int = 0) {
        self.usesWatch = usesWatch
        _page = State(initialValue: page == 0 ? 0 : 1)
        _position = State(initialValue: Double(min(max(page - 1, 0), PrepWatchState.allCases.count - 1)))
    }

    private static let lastState = PrepWatchState.allCases.count - 1

    var body: some View {
        VStack(spacing: 0) {
            // MARK: 상단 바
            TopNavigationHeader(
                title: "연습 준비", isDark: true,
                trailingTitle: "건너뛰기",
                onTrailing: skip
            )
            .padding(.top, Layout.topBarTop.v(scale))

            // MARK: 쪽 내용 (쪽 넘김 애니메이션은 온보딩과 같은 `PageTurnStack`)
            PageTurnStack(
                page: page, indicatorIndex: $unusedIndicator, indexOf: { $0 },
                // 2쪽(워치 캐러셀)을 미리 만들어 두어, 넘기기 시작할 때 버벅이지 않게 해요. (2쪽에서는 1쪽으로 돌아가지 않아요)
                preloadedPages: { $0 == 0 ? [1] : [] }
            ) { visiblePage, motion in
                content(for: visiblePage, motion: motion)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            // 왼쪽 가장자리는 시스템의 "밀어서 뒤로가기"가 쓰도록 쪽 넘김 제스처 영역에서 뺀다
            .contentShape(LeftEdgeExcludedShape(edgeWidth: Layout.systemBackEdgeWidth))
            .gesture(swipe)

            // MARK: 버튼
            DarkPrimaryButton(
                title: page == 1 && nearestState == Self.lastState ? "스팀 연습 시작하기" : "다음",
                width: Layout.buttonWidth.h(scale),
                height: BottomButton.height,
                action: advance
            )
            .padding(.bottom, BottomButton.bottomGap.v(scale) + scale.fixedHeightAdjustment(BottomButton.height))
        }
        .ignoresSafeArea()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // 배경: 1쪽은 위쪽이 은은하게 밝고(시안 y 20: #323D50), 2쪽(워치 캐러셀)은 평평한 어두운 색(#01030C).
        // 쪽 넘김 때 점이 옮겨 가는 타이밍에 맞춰 서서히 바뀐다.
        .background {
            ZStack {
                AppColors.darkBackground
                RadialGradient(colors: [AppColors.darkTopGlow, AppColors.darkBackground],
                               center: .top, startRadius: 0, endRadius: Layout.glowRadius)
                    .opacity(page == 0 ? 1 : 0)
                    .animation(PageTurnMotion.indicator, value: page)
            }
            .ignoresSafeArea()
        }
        .preferredColorScheme(.dark)
        .toolbar(.hidden, for: .navigationBar)
    }

    @ViewBuilder
    private func content(for index: Int, motion: OnboardingPageMotion) -> some View {
        if index == 0 {
            machinePage(motion: motion)
        } else {
            PrepWatchCarousel(position: position, motion: motion)
        }
    }

    /// 1쪽: 머신 + 휴대폰
    private func machinePage(motion: OnboardingPageMotion) -> some View {
        // 새 시안(이미지 20)은 일러스트·글자·버튼 가로 중심이 모두 201.2 — 예전 Hi-Fi 249의 가로 보정(+2·+1.6·−1.1)은 뺐다
        VStack(spacing: 0) {
            MachinePhoneIllustration()
                .designScaled(width: 304, height: 199, scale)
                .onboardingPart(motion.illustration)
                .padding(.top, Layout.page0IllustrationTop.v(scale))
            DarkScreenTitle("휴대폰은\n머신 가까이")
                .onboardingPart(motion.title)
                .padding(.top, Layout.page0TitleTop.v(scale))
            DarkScreenSubtitle("물과 열이 닿지 않는\n안정적인 곳에 두고 연습해주세요")
                .onboardingPart(motion.subtitle)
                .padding(.top, Layout.subtitleTop.v(scale))
        }
    }

    // MARK: 동작

    private var nearestState: Int {
        min(max(Int(position.rounded()), 0), Self.lastState)
    }

    /// 손가락을 떼면 캐러셀이 자리를 찾아가는 움직임 (ease-out-quint)
    private static let settle = Animation.timingCurve(MotionCurve.easeOutQuint, duration: 0.4)

    private func moveCarousel(to state: Int) {
        withAnimation(Self.settle) { position = Double(state) }
    }

    /// "건너뛰기": 어느 쪽에서든 안내를 건너뛰고 바로 소리 인식(연습)을 시작한다
    private func skip() {
        Task { await practice.start(usingWatch: usesWatch) }
    }

    private func advance() {
        if page == 0 {
            page = 1
        } else if nearestState < Self.lastState {
            moveCarousel(to: nearestState + 1)
        } else {
            Task { await practice.start(usingWatch: usesWatch) }
        }
    }

    /// 좌우 스와이프. 1쪽에서는 왼쪽으로 밀면 2쪽, 2쪽에서는 손가락을 따라 캐러셀이 움직이고
    /// 놓으면 한 칸 넘어간다 (양끝 밖으로는 저항이 생기고 놓으면 제자리로 돌아온다. 2쪽에서 1쪽으로는 돌아오지 못한다)
    private var swipe: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                guard page == 1 else { return }
                let start = dragStart ?? position
                if dragStart == nil { dragStart = start }
                // 세로로 더 움직인 제스처는 캐러셀을 움직이지 않는다
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                let raw = start - Double(value.translation.width) / Layout.carouselPitch
                var noAnimation = Transaction()
                noAnimation.disablesAnimations = true
                withTransaction(noAnimation) { position = Self.withResistance(raw) }
            }
            .onEnded { value in
                defer { dragStart = nil }
                let dx = Double(value.translation.width)
                guard abs(dx) > abs(Double(value.translation.height)) else {
                    if page == 1 { moveCarousel(to: nearestState) }
                    return
                }
                let predicted = Double(value.predictedEndTranslation.width)
                let threshold = Layout.carouselPitch * 0.18
                let step = (dx < -threshold || predicted < -Layout.carouselPitch * 0.5) ? 1
                    : (dx > threshold || predicted > Layout.carouselPitch * 0.5) ? -1 : 0
                if page == 0 {
                    if step == 1 { page = 1 }
                    // 1쪽은 처음 화면이라 오른쪽으로 밀면 메인(이전 화면)으로 돌아간다
                    else if step == -1 { dismiss() }
                    return
                }
                let start = Int((dragStart ?? position).rounded())
                // 2쪽에 들어온 뒤에는 스와이프로 1쪽에 돌아오지 못한다 (양끝 밖으로 밀면 제자리로 돌아간다)
                moveCarousel(to: min(max(start + step, 0), Self.lastState))
            }
    }

    /// 양끝(0 · 마지막 칸)을 넘어서 끌면 손가락 움직임의 30%만 따라온다
    private static func withResistance(_ raw: Double) -> Double {
        let last = Double(lastState)
        if raw < 0 { return raw * 0.3 }
        if raw > last { return last + (raw - last) * 0.3 }
        return raw
    }
}

// MARK: - Layout (iPhone 17 시안 측정값, pt)

private enum Layout {
    static let topBarTop: CGFloat = 84              // 화면 위 ↔ 상단 바 (Hi-Fi 249: 글자 y0 86.5 − 2.5)
    static let page0IllustrationTop: CGFloat = 109  // 상단 바 아래(104) ↔ 일러스트 (Hi-Fi 249: y0 213)
    static let page0TitleTop: CGFloat = 117.5       // 일러스트 ↔ 타이틀 (새 시안: 일러스트 아래 412.5 → 타이틀 글자 y0 533.5, 글자 위 여백 4 보정)
    static let subtitleTop: CGFloat = 12.5          // 타이틀 ↔ 설명
    static let glowRadius: CGFloat = 400            // 1쪽 위쪽 글로우가 배경색으로 사라지는 거리 (다른 다크 화면과 같음)
    static let carouselPitch: Double = 196          // 캐러셀 한 칸 이동에 필요한 손가락 거리 (칸 사이 거리와 같다)
    static let buttonWidth: CGFloat = 363
    static let systemBackEdgeWidth: CGFloat = 24    // 시스템 스와이프 뒤로가기가 시작되는 왼쪽 가장자리 폭
}

/// 화면 전체에서 왼쪽 가장자리 `edgeWidth`만 뺀 터치 영역
private struct LeftEdgeExcludedShape: Shape {
    let edgeWidth: CGFloat

    func path(in rect: CGRect) -> Path {
        Path(CGRect(x: rect.minX + edgeWidth, y: rect.minY, width: max(0, rect.width - edgeWidth), height: rect.height))
    }
}

#Preview {
    let connection = WatchConnection()
    PracticePrepGuideView()
        .environmentObject(PracticeSession(connection: connection))
}
