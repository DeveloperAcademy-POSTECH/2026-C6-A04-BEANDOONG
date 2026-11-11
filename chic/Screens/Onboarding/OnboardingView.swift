import SwiftUI

/// 온보딩 1/3 → 2/3 → 3/3 을 담는 화면 (ONB-TR 페이지 전환)
/// - 디자인: Hi-Fi/iPhone 17 - 108.png · 109.png · 106.png
///
///     ┌ 상단 바: 건너뛰기                 ← 고정
///     ├ 쪽 내용: 일러스트 + 타이틀 + 설명    ← 쪽마다 바뀜 (옆으로 밀리며 넘어감)
///     ├ 페이지 인디케이터                  ← 고정 (캡슐이 다음 자리로 옮겨 감)
///     └ 하단 버튼: 다음                    ← 고정
///
/// 쪽 이동: 좌우 스와이프 · "다음" 버튼 (마지막 쪽 버튼은 온보딩을 마치고 나가요)
/// 어느 쪽을 보여 줄지(`page`)와 버튼·스와이프 동작은 바깥(`ContentView`)에서 정해요.
/// 이 화면은 `page`가 바뀌면 넘김 애니메이션만 해요 (`PageTurnStack`).
struct OnboardingView: View {
    let page: OnboardingPage
    var onNext: () -> Void = {}
    var onSkip: () -> Void = {}
    /// 좌우로 밀었을 때 (+1: 다음 쪽, -1: 이전 쪽). 첫·마지막 쪽 범위 처리는 바깥에서 한다
    var onSwipe: (Int) -> Void = { _ in }

    @Environment(\.designScale) private var scale
    /// 페이지 인디케이터가 가리키는 쪽 (내용보다 조금 늦게 옮겨 가요)
    @State private var indicatorIndex: Int

    init(page: OnboardingPage, onNext: @escaping () -> Void = {}, onSkip: @escaping () -> Void = {}, onSwipe: @escaping (Int) -> Void = { _ in }) {
        self.page = page
        self.onNext = onNext
        self.onSkip = onSkip
        self.onSwipe = onSwipe
        _indicatorIndex = State(initialValue: page.rawValue)
    }

    var body: some View {
        VStack(spacing: 0) {
            // MARK: 상단 바
            OnboardingSkipTopBar(action: onSkip)
                .padding(.top, Metrics.topBarTop.v(scale))

            // MARK: 쪽 내용 (넘김 애니메이션은 PageTurnStack 이 해요. 연습 준비 가이드와 같은 것)
            PageTurnStack(
                page: page, indicatorIndex: $indicatorIndex, indexOf: \.rawValue
            ) { visiblePage, motion in
                pageContent(visiblePage, motion: motion)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .contentShape(Rectangle())
            .gesture(swipe)

            // MARK: 페이지 인디케이터 + 하단 버튼
            OnboardingPageIndicator(activeIndex: indicatorIndex)
                .padding(.bottom, Metrics.indicatorBottom.v(scale))

            DarkPrimaryButton(title: "다음", width: Metrics.buttonWidth.h(scale), height: BottomButton.height, action: onNext)
                .padding(.bottom, BottomButton.bottomGap.v(scale) + scale.fixedHeightAdjustment(BottomButton.height))
        }
        .ignoresSafeArea()
        .darkScreenBackgroundWithTopGlow()
    }

    /// 좌우 스와이프: 왼쪽으로 밀면 다음 쪽(+1), 오른쪽으로 밀면 이전 쪽(-1). 세로로 더 많이 움직인 제스처는 무시한다.
    /// 쪽을 바꾸는 일은 바깥에서 정하고, 바뀌면 `PageTurnStack`이 넘김 애니메이션을 한다.
    private var swipe: some Gesture {
        DragGesture(minimumDistance: 24)
            .onEnded { value in
                let dx = value.translation.width
                guard abs(dx) > abs(value.translation.height), abs(dx) > 50 else { return }
                onSwipe(dx < 0 ? 1 : -1)
            }
    }

    @ViewBuilder
    private func pageContent(_ page: OnboardingPage, motion: OnboardingPageMotion) -> some View {
        switch page {
        case .watch: WatchIntroPage(motion: motion)
        case .placement: PlacementIntroPage(motion: motion)
        case .sound: SoundIntroPage(motion: motion)
        case .review: ReviewIntroPage(motion: motion)
        }
    }
}

// MARK: - 온보딩 쪽

/// 온보딩 쪽 순서 (0부터 시작하는 번호 = 페이지 인디케이터 위치)
enum OnboardingPage: Int, CaseIterable, Comparable {
    case watch
    case placement
    case sound
    case review

    static func < (lhs: OnboardingPage, rhs: OnboardingPage) -> Bool { lhs.rawValue < rhs.rawValue }
}

/// 쪽 안에서 따로 움직이는 부분 (움직이는 순서대로)
enum OnboardingPagePart: CaseIterable {
    case illustration
    case title
    case subtitle
}

/// 쪽 안 한 부분의 위치와 투명도
struct OnboardingPartMotion: Equatable {
    /// 제자리에서 옆으로 밀린 거리 (음수: 왼쪽)
    var offsetX: CGFloat = 0
    var opacity: Double = 1

    /// 제자리에 그대로 보이는 상태
    static let resting = OnboardingPartMotion()
}

/// 쪽 하나의 부분별 위치와 투명도
struct OnboardingPageMotion: Equatable {
    var illustration = OnboardingPartMotion.resting
    var title = OnboardingPartMotion.resting
    var subtitle = OnboardingPartMotion.resting

    /// 모든 부분이 제자리에 보이는 상태
    static let resting = OnboardingPageMotion()

    /// 모든 부분이 옆에 투명하게 대기하는 상태 (들어오기 직전)
    static func waiting(offsetX: CGFloat) -> OnboardingPageMotion {
        let hidden = OnboardingPartMotion(offsetX: offsetX, opacity: 0)
        return OnboardingPageMotion(illustration: hidden, title: hidden, subtitle: hidden)
    }

    subscript(part: OnboardingPagePart) -> OnboardingPartMotion {
        get {
            switch part {
            case .illustration: illustration
            case .title: title
            case .subtitle: subtitle
            }
        }
        set {
            switch part {
            case .illustration: illustration = newValue
            case .title: title = newValue
            case .subtitle: subtitle = newValue
            }
        }
    }
}

extension View {
    /// 온보딩 쪽 안 한 부분에 넘김 위치와 투명도를 적용해요. (레이아웃 자리는 그대로 두고 그림만 옮겨요)
    func onboardingPart(_ motion: OnboardingPartMotion) -> some View {
        self
            .offset(x: motion.offsetX)
            .opacity(motion.opacity)
    }
}

// MARK: - Metrics

/// 세 쪽이 같이 쓰는 고정 영역 간격 (Hi-Fi 기준)
private enum Metrics {
    static let topBarTop: CGFloat = 84         // 화면 위 ↔ 상단 바 (Hi-Fi 108: 글자 y0 86.5 − 2.5)
    static let indicatorBottom: CGFloat = 28   // 인디케이터 ↔ 버튼 (Hi-Fi 108: 인디케이터 y1 700 → 버튼 y0 728)
    static let buttonWidth: CGFloat = 363      // Hi-Fi 버튼 폭
}

#Preview {
    @Previewable @State var page = OnboardingPage.watch

    OnboardingView(page: page, onNext: {
        let next = OnboardingPage(rawValue: page.rawValue + 1) ?? .watch
        page = next
    })
}
