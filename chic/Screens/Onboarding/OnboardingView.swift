import SwiftUI

/// 온보딩 1/3 → 2/3 → 3/3 을 담는 화면 (ONB-TR 페이지 전환)
/// - 디자인: Hi-Fi/iPhone 17 - 108.png · 109.png · 106.png
///
///     ┌ 상단 바: 건너뛰기                 ← 고정
///     ├ 쪽 내용: 일러스트 + 타이틀 + 설명    ← 쪽마다 바뀜 (옆으로 밀리며 넘어감)
///     ├ 페이지 인디케이터                  ← 고정 (캡슐이 다음 자리로 옮겨 감)
///     └ 하단 버튼: 다음                    ← 고정
///
/// 어느 쪽을 보여 줄지(`page`)와 버튼 동작은 바깥(`ContentView`)에서 정해요.
/// 이 화면은 `page`가 바뀌면 넘김 애니메이션만 해요.
struct OnboardingView: View {
    let page: OnboardingPage
    var onNext: () -> Void = {}
    var onSkip: () -> Void = {}

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.designScale) private var scale
    /// 지금 화면에 올라와 있는 쪽 (넘기는 중에는 나가는 쪽과 들어오는 쪽 두 개)
    @State private var visiblePages: [OnboardingPage]
    /// 쪽마다 일러스트 · 타이틀 · 설명이 지금 어디에 얼마나 보이는지
    @State private var motions: [OnboardingPage: OnboardingPageMotion] = [:]
    /// 페이지 인디케이터가 가리키는 쪽 (내용보다 조금 늦게 옮겨 가요)
    @State private var indicatorIndex: Int

    init(page: OnboardingPage, onNext: @escaping () -> Void = {}, onSkip: @escaping () -> Void = {}) {
        self.page = page
        self.onNext = onNext
        self.onSkip = onSkip
        _visiblePages = State(initialValue: [page])
        _indicatorIndex = State(initialValue: page.rawValue)
    }

    var body: some View {
        VStack(spacing: 0) {
            // MARK: 상단 바
            OnboardingSkipTopBar(action: onSkip)
                .padding(.top, Metrics.topBarTop.v(scale))

            // MARK: 쪽 내용 (넘기는 동안에는 두 쪽이 겹쳐 있어요)
            ZStack(alignment: .top) {
                ForEach(visiblePages, id: \.self) { visiblePage in
                    pageContent(visiblePage, motion: motions[visiblePage] ?? .resting)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            // MARK: 페이지 인디케이터 + 하단 버튼
            OnboardingPageIndicator(activeIndex: indicatorIndex)
                .padding(.bottom, Metrics.indicatorBottom.v(scale))

            DarkPrimaryButton(title: "다음", width: Metrics.buttonWidth.h(scale), height: BottomButton.height, action: onNext)
                .padding(.bottom, BottomButton.bottomGap.v(scale) + scale.fixedHeightAdjustment(BottomButton.height))
        }
        .ignoresSafeArea()
        .darkScreenBackgroundWithTopGlow()
        .onChange(of: page) { oldPage, newPage in
            turnPage(from: oldPage, to: newPage)
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

    /// 쪽 넘김: 나가는 쪽은 왼쪽으로 밀리며 사라지고, 들어오는 쪽은 조금 겹쳐서 오른쪽에서 들어와요.
    /// 일러스트 → 타이틀 → 설명 순서로 조금씩 늦게 움직여요.
    private func turnPage(from oldPage: OnboardingPage, to newPage: OnboardingPage) {
        // 동작 줄이기: 옆으로 밀지 않고 투명도로만 바꿔요.
        let slide: CGFloat = reduceMotion ? 0 : PageTurnMotion.slideDistance

        // 들어올 쪽을 오른쪽에 투명하게 올려 두기 (애니메이션 없이)
        var placement = Transaction()
        placement.disablesAnimations = true
        withTransaction(placement) {
            motions[newPage] = .waiting(offsetX: slide)
            // 넘기는 도중에 또 넘기면, 그 전에 나가던 쪽은 바로 내리고 지금 쪽부터 다시 넘겨요.
            visiblePages = [oldPage, newPage]
        }

        for (order, part) in OnboardingPagePart.allCases.enumerated() {
            withAnimation(PageTurnMotion.leave(order: order)) {
                motions[oldPage, default: .resting][part] = OnboardingPartMotion(offsetX: -slide, opacity: 0)
            }

            let isLastPart = order == OnboardingPagePart.allCases.count - 1
            withAnimation(PageTurnMotion.enter(order: order)) {
                motions[newPage, default: .resting][part] = .resting
            } completion: {
                // 마지막 부분까지 들어오면 나간 쪽을 화면에서 내려요.
                // (그사이 다음 쪽으로 또 넘어갔다면 그 넘김이 정리하도록 그냥 둬요)
                guard isLastPart, visiblePages.last == newPage else { return }
                visiblePages = [newPage]
                motions = [newPage: .resting]
            }
        }

        withAnimation(PageTurnMotion.indicator) {
            indicatorIndex = newPage.rawValue
        }
    }
}

// MARK: - 온보딩 쪽

/// 온보딩 쪽 순서 (0부터 시작하는 번호 = 페이지 인디케이터 위치)
enum OnboardingPage: Int, CaseIterable {
    case watch
    case placement
    case sound
    case review
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

    OnboardingView(page: page) {
        let next = OnboardingPage(rawValue: page.rawValue + 1) ?? .watch
        page = next
    }
}
