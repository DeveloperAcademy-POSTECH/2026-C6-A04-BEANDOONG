import SwiftUI

/// 쪽 넘김 애니메이션 (온보딩 · 연습 준비 가이드 공용, 애니메이션 벤치 ONB-TR)
///
/// `page`가 바뀌면 나가는 쪽은 왼쪽(뒤로 넘길 때는 오른쪽)으로 밀리며 사라지고, 들어오는 쪽은 반대편에서 들어와요.
/// 일러스트 → 타이틀 → 설명 순서로 조금씩 늦게 움직이고, 페이지 인디케이터는 `indicatorIndex`로 조금 늦게 옮겨 가요.
///
/// 쪽 안의 각 부분(일러스트·타이틀·설명)에 `onboardingPart(motion.illustration)` 등을 붙여야 따로 움직여요.
///
/// - 쪽 번호를 바꾸는 쪽(버튼·스와이프)은 `withAnimation` 없이 `page`만 바꾸면 돼요. 애니메이션은 이 뷰가 해요.
/// - 상태·움직임은 모두 이 뷰 안에 있어서 쪽 하나(`content`)는 모양만 그리면 돼요.
struct PageTurnStack<Page: Hashable & Comparable, Content: View>: View {
    /// 지금 보여 줄 쪽
    let page: Page
    /// 페이지 인디케이터가 가리키는 쪽 번호 (바깥 인디케이터가 읽어요. 내용보다 조금 늦게 옮겨 가요)
    @Binding var indicatorIndex: Int
    /// 쪽 → 인디케이터 위치 (0부터)
    let indexOf: (Page) -> Int
    /// 지금 쪽에서 넘어갈 수 있는 이웃 쪽. 이 쪽들은 보이지 않게 미리 만들어 둬요 (기본: 없음)
    ///
    /// 넘기기 시작하는 순간에 들어올 쪽을 처음 만들면(일러스트 이미지 · 캔버스 준비) 그 프레임이 늦게 그려져
    /// 넘김 앞부분이 버벅여요. 미리 만들어 둔 쪽은 투명하고, 누를 수 없고, 반복 애니메이션도 멈춰 있어서
    /// 보이는 모습과 움직임은 그대로예요. 들어올 때 반복 애니메이션이 0부터 시작하는 것도 전과 같아요.
    let preloadedPages: (Page) -> [Page]
    /// 넘김이 다 끝나 한 쪽에 멈췄을 때 (기본: 아무것도 안 함)
    let onSettled: (Page) -> Void
    @ViewBuilder let content: (Page, OnboardingPageMotion) -> Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.loopAnimationsPaused) private var parentLoopsPaused
    @Environment(\.designScale) private var scale
    /// 지금 화면에 올라와 있는 쪽 (넘기는 중에는 나가는 쪽과 들어오는 쪽 두 개)
    @State private var visiblePages: [Page]
    /// 쪽마다 일러스트 · 타이틀 · 설명이 지금 어디에 얼마나 보이는지
    @State private var motions: [Page: OnboardingPageMotion] = [:]
    /// 이웃 쪽을 미리 만들어 둘 기준 쪽. 넘김이 다 끝난 뒤에만 바꿔서, 새 이웃 쪽을 처음 그리는 무거운 일이
    /// 넘기는 도중(애니메이션 중)에 겹치지 않고 쪽이 멈춰 있을 때 일어나요.
    @State private var preloadAnchor: Page

    init(
        page: Page,
        indicatorIndex: Binding<Int>,
        indexOf: @escaping (Page) -> Int,
        preloadedPages: @escaping (Page) -> [Page] = { _ in [] },
        onSettled: @escaping (Page) -> Void = { _ in },
        @ViewBuilder content: @escaping (Page, OnboardingPageMotion) -> Content
    ) {
        self.page = page
        _indicatorIndex = indicatorIndex
        self.indexOf = indexOf
        self.preloadedPages = preloadedPages
        self.onSettled = onSettled
        self.content = content
        _visiblePages = State(initialValue: [page])
        _preloadAnchor = State(initialValue: page)
    }

    var body: some View {
        // 넘기는 동안에는 두 쪽이 겹쳐 있어요
        // 보이는 쪽은 나중에 올라온 쪽이 위에 그려져요 (zIndex = visiblePages 안의 순서). 미리 만든 쪽은 맨 아래에 투명하게 있어요.
        ZStack(alignment: .top) {
            ForEach(mountedPages, id: \.self) { mountedPage in
                let order = visiblePages.firstIndex(of: mountedPage)
                content(mountedPage, motions[mountedPage] ?? .resting)
                    // 미리 만든 쪽은 거의 투명하게(0.001) 둬요. 0이면 화면에 그리지 않아서, 처음 보이는 순간
                    // (캔버스 일러스트 등) 처음 그리는 일이 몰려 버벅여요. 보이는 쪽 뒤에 깔려 있어 화면에는 드러나지 않아요.
                    .opacity(order == nil ? Self.preloadedOpacity : 1)
                    .allowsHitTesting(order != nil)
                    .accessibilityHidden(order == nil)
                    .environment(\.loopAnimationsPaused, parentLoopsPaused || order == nil)
                    .zIndex(Double(order ?? -1))
            }
        }
        .onChange(of: page) { oldPage, newPage in
            turnPage(from: oldPage, to: newPage)
        }
    }

    /// 미리 만든(아직 안 보이는) 쪽의 투명도
    private static var preloadedOpacity: Double { 0.001 }

    /// 화면에 올려 둔 쪽: 보이는 쪽 + 지금 쪽의 이웃 쪽(미리 만들어 둠)
    private var mountedPages: [Page] {
        var pages = visiblePages
        for neighbor in preloadedPages(preloadAnchor) where !pages.contains(neighbor) {
            pages.append(neighbor)
        }
        return pages
    }

    /// 쪽 넘김: 나가는 쪽은 밀리며 사라지고, 들어오는 쪽은 조금 겹쳐서 반대편에서 들어와요.
    /// 일러스트 → 타이틀 → 설명 순서로 조금씩 늦게 움직여요.
    private func turnPage(from oldPage: Page, to newPage: Page) {
        // 앞으로 넘길 때는 왼쪽으로 나가고 오른쪽에서 들어오고, 뒤로 넘길 때(스와이프)는 반대로 움직여요.
        // 동작 줄이기: 옆으로 밀지 않고 투명도로만 바꿔요.
        // 미는 거리는 화면 폭에 비례해요 (벤치는 화면 폭 대비 %로 움직여요).
        let direction: CGFloat = newPage >= oldPage ? 1 : -1
        let slide: CGFloat = (reduceMotion ? 0 : PageTurnMotion.slideDistance.h(scale)) * direction

        // 들어올 쪽을 옆에 투명하게 올려 두기 (애니메이션 없이)
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
                preloadAnchor = newPage
                onSettled(newPage)
            }
        }

        withAnimation(PageTurnMotion.indicator) {
            indicatorIndex = indexOf(newPage)
        }
    }
}

// MARK: - 넘김 타이밍

/// 쪽 넘김 사양 (애니메이션 벤치 ONB-TR)
enum PageTurnMotion {
    /// 내용이 옆으로 밀리는 거리(pt, iPhone 17 기준 — 다른 기기는 폭 비율로 변환)
    static let slideDistance: CGFloat = 36

    // 나가는 쪽: 0.28초 동안 점점 빨라지며 왼쪽으로, 부분마다 0.04초씩 늦게
    static let leaveDuration: TimeInterval = 0.28
    static let leaveStagger: TimeInterval = 0.04

    // 들어오는 쪽: 나가는 글자와 겹치는 시간을 줄이려고 0.24초 뒤에 출발, 0.45초 동안 부드럽게 멈춤, 부분마다 0.05초씩 늦게
    static let enterDelay: TimeInterval = 0.24
    static let enterDuration: TimeInterval = 0.45
    static let enterStagger: TimeInterval = 0.05

    // 페이지 인디케이터: 0.12초 뒤에 0.38초 동안 다음 자리로
    static let indicatorDelay: TimeInterval = 0.12
    static let indicatorDuration: TimeInterval = 0.38

    static func leave(order: Int) -> Animation {
        Animation.timingCurve(MotionCurve.easeIn, duration: leaveDuration)
            .delay(leaveStagger * Double(order))
    }

    static func enter(order: Int) -> Animation {
        Animation.timingCurve(MotionCurve.easeOutExpo, duration: enterDuration)
            .delay(enterDelay + enterStagger * Double(order))
    }

    static let indicator = Animation.timingCurve(MotionCurve.easeInOut, duration: indicatorDuration)
        .delay(indicatorDelay)
}
