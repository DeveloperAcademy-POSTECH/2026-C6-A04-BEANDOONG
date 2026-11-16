import SwiftUI

/// 온보딩 1/5 → 5/5 를 담는 화면 (ONB-TR 페이지 전환)
/// - 디자인: Hi-Fi/iPhone 17 - 108.png · 109.png · 106.png · 302.png · 237.png (2026-11-13: 302 추가로 5쪽)
///
///     ┌ 상단 바: 건너뛰기                 ← 고정
///     ├ 쪽 내용: 일러스트 + 타이틀 + 설명    ← 쪽마다 바뀜 (옆으로 밀리며 넘어감)
///     ├ 페이지 인디케이터                  ← 고정 (캡슐이 다음 자리로 옮겨 감)
///     └ 하단 버튼: 다음 (마지막 쪽은 "홈으로 가기") ← 고정
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
    /// 쪽 넘김이 다 끝나 한 쪽에 멈췄을 때
    var onPageSettled: (OnboardingPage) -> Void = { _ in }

    @Environment(\.designScale) private var scale
    /// 스플래시나 연습 화면이 덮고 있어서 반복 애니메이션이 멈춰 있는지 (앱을 켠 직후에는 스플래시가 덮고 있어요)
    @Environment(\.loopAnimationsPaused) private var loopsPaused
    @MotionStill private var isStill: Bool
    /// 페이지 인디케이터가 가리키는 쪽 (내용보다 조금 늦게 옮겨 가요)
    @State private var indicatorIndex: Int
    /// 지금 쪽 말고 나머지 쪽도 미리 만들어 두는지. 스플래시가 걷힌 뒤에 켜고, 한 번 켜면 다시 끄지 않아요.
    @State private var preloadsAllPages = false

    init(page: OnboardingPage, onNext: @escaping () -> Void = {}, onSkip: @escaping () -> Void = {}, onSwipe: @escaping (Int) -> Void = { _ in },
         onPageSettled: @escaping (OnboardingPage) -> Void = { _ in }) {
        self.page = page
        self.onNext = onNext
        self.onSkip = onSkip
        self.onSwipe = onSwipe
        self.onPageSettled = onPageSettled
        _indicatorIndex = State(initialValue: page.rawValue)
    }

    var body: some View {
        VStack(spacing: 0) {
            // MARK: 상단 바
            OnboardingSkipTopBar(action: onSkip)
                .padding(.top, ScreenMetrics.topBarTop.v(scale))

            // MARK: 쪽 내용 (넘김 애니메이션은 PageTurnStack 이 해요. 연습 준비 가이드와 같은 것)
            PageTurnStack(
                page: page, indicatorIndex: $indicatorIndex, indexOf: \.rawValue,
                // 다섯 쪽을 모두 만들어 둬요 (넘김 중에는 만들지 않게). 앞뒤 쪽만 두면 넘김이 끝날 때마다
                // 새 이웃 쪽을 만드는 일(이미지 디코딩 · 캔버스 준비)이 막 시작된 새 쪽의 애니메이션과 겹쳐 버벅였어요.
                // 미리 만든 쪽은 투명하고 반복 애니메이션도 멈춰 있어서 매 프레임 드는 일이 거의 없어요.
                // 다만 앱을 켠 직후 스플래시가 덮고 있는 동안에는 지금 쪽만 만들어요. 스플래시의 로고 애니메이션과 같은 시간에
                // 다섯 쪽을 한꺼번에 만들면 메인 스레드가 몰려 버벅일 수 있어서, 스플래시가 걷힌 뒤에 나머지 쪽을 만들어요
                // (사용자가 첫 쪽을 넘기기 전에 끝나요).
                preloadedPages: { _ in preloadsAllPages ? OnboardingPage.allCases : [] },
                onSettled: onPageSettled
            ) { visiblePage, motion in
                pageContent(visiblePage, motion: motion)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .contentShape(Rectangle())
            .gesture(swipe)

            // MARK: 페이지 인디케이터 + 하단 버튼
            OnboardingPageIndicator(activeIndex: indicatorIndex, pageCount: OnboardingPage.allCases.count)
                .padding(.bottom, Layout.indicatorBottom.v(scale))

            BottomPrimaryButton(title: page == OnboardingPage.allCases.last ? String(localized: "홈으로 가기") : String(localized: "다음"), action: onNext)
        }
        .ignoresSafeArea()
        .darkScreenBackgroundWithTopGlow()
        .onChange(of: loopsPaused, initial: true) { _, paused in
            // 스플래시가 걷히면(반복 애니메이션이 움직이기 시작하면) 나머지 쪽을 미리 만들어요.
            // 처음부터 멈춰 있지 않은 곳(미리보기 · 캡처)에서는 나타나자마자 만들어요.
            if !paused { preloadsAllPages = true }
        }
        .task {
            // 4/5 쪽의 우유 수위 표(`MilkLevelLoop.shared`, 240Hz × 3바퀴 스프링 계산)를 스플래시가 덮고 있는 동안 백그라운드에서 미리 계산해 둬요.
            // 처음 접근하는 순간(쪽을 미리 만들 때)에 메인 스레드에서 계산하면 그 프레임이 늦어져요.
            // `MilkLevelLoop` 는 `nonisolated` 이고 `shared` 는 값이 바뀌지 않는 `static let` 이라 어느 스레드에서 처음 접근해도 안전해요
            // (Swift 가 첫 접근을 한 번만 실행하고, 그동안 다른 스레드는 끝나길 기다려요). 움직임이 없는 화면(동작 줄이기)에서는 표를 안 써요.
            guard !isStill else { return }
            Task.detached(priority: .utility) { _ = MilkLevelLoop.shared }
        }
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
        case .milkLevel: MilkLevelIntroPage(motion: motion)
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
    case milkLevel
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

// MARK: - Layout

private enum Layout {
    static let indicatorBottom: CGFloat = 28   // 인디케이터 ↔ 버튼 (Hi-Fi 108: 인디케이터 y1 700 → 버튼 y0 728)
}

#Preview {
    @Previewable @State var page = OnboardingPage.watch

    OnboardingView(page: page, onNext: {
        let next = OnboardingPage(rawValue: page.rawValue + 1) ?? .watch
        page = next
    })
}
