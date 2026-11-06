import SwiftUI

/// 온보딩 1/3 → 2/3 → 3/3 을 담는 화면
/// - 디자인: Hi-Fi/iPhone 17 - 108.png · 109.png · 106.png
///
///     ┌ 상단 바: 건너뛰기                 ← 고정
///     ├ 쪽 내용: 일러스트 + 타이틀 + 설명    ← 쪽마다 바뀜
///     ├ 페이지 인디케이터                  ← 고정
///     └ 하단 버튼: 다음                    ← 고정
///
/// 어느 쪽을 보여 줄지(`page`)와 버튼 동작은 바깥(`ContentView`)에서 정해요.
struct OnboardingView: View {
    let page: OnboardingPage
    var onNext: () -> Void = {}
    var onSkip: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            // MARK: 상단 바
            OnboardingSkipTopBar(action: onSkip)
                .padding(.top, Metrics.topBarTop)

            // MARK: 쪽 내용
            pageContent(page)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            // MARK: 페이지 인디케이터 + 하단 버튼
            OnboardingPageIndicator(activeIndex: page.rawValue)
                .padding(.bottom, Metrics.indicatorBottom)

            DarkPrimaryButton(title: "다음", action: onNext)
                .padding(.bottom, Metrics.buttonBottom)
        }
        .darkScreenBackgroundWithTopGlow()
    }

    @ViewBuilder
    private func pageContent(_ page: OnboardingPage) -> some View {
        switch page {
        case .watch: WatchIntroPage()
        case .placement: PlacementIntroPage()
        case .sound: SoundIntroPage()
        }
    }
}

// MARK: - 온보딩 쪽

/// 온보딩 쪽 순서 (0부터 시작하는 번호 = 페이지 인디케이터 위치)
enum OnboardingPage: Int, CaseIterable {
    case watch
    case placement
    case sound
}

// MARK: - Metrics

/// 세 쪽이 같이 쓰는 고정 영역 간격 (Hi-Fi 기준)
private enum Metrics {
    static let topBarTop: CGFloat = 22         // 상태바 ↔ 상단 바
    static let indicatorBottom: CGFloat = 28   // 인디케이터 ↔ 버튼
    static let buttonBottom: CGFloat = 10      // 버튼 ↔ 화면 하단(안전 영역)
}

#Preview {
    @Previewable @State var page = OnboardingPage.watch

    OnboardingView(page: page) {
        let next = OnboardingPage(rawValue: page.rawValue + 1) ?? .watch
        page = next
    }
}
