import SwiftUI

/// 온보딩 2/3: 아이폰과 워치로 함께 확인
/// - 디자인: Hi-Fi/iPhone 17 - 108.png
///
///     ┌ 상단 바: 건너뛰기
///     ├ 아이폰 + 워치 일러스트
///     ├ 타이틀 + 설명
///     ├ 페이지 인디케이터 (● 두 번째)
///     └ 하단 버튼: 다음
struct WatchIntroView: View {
    var onNext: () -> Void = {}
    var onSkip: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            // MARK: 상단 바
            OnboardingSkipTopBar(action: onSkip)
                .padding(.top, Layout.topBarTop)

            // MARK: 일러스트
            AssetImageView(name: "IllustPhoneWatch", width: 234, height: 198)
                .padding(.top, Layout.illustrationTop)

            // MARK: 타이틀 + 설명
            DarkScreenTitle("아이폰과 워치로\n함께 확인해요")
                .padding(.top, Layout.titleTop)

            DarkScreenSubtitle("Apple Watch를 함께 사용하면\n상태 변화를 진동으로도 안내받을 수 있어요")
                .padding(.top, Layout.subtitleTop)

            Spacer(minLength: 0)

            // MARK: 페이지 인디케이터 + 하단 버튼
            OnboardingPageIndicator(activeIndex: 1)
                .padding(.bottom, Layout.indicatorBottom)

            DarkPrimaryButton(title: "다음", action: onNext)
                .padding(.bottom, Layout.buttonBottom)
        }
        .darkScreenBackground()
    }
}

// MARK: - Layout

private enum Layout {
    static let topBarTop: CGFloat = 22         // 상태바 ↔ 상단 바
    static let illustrationTop: CGFloat = 173  // 상단 바 ↔ 일러스트
    static let titleTop: CGFloat = 74          // 일러스트 ↔ 타이틀
    static let subtitleTop: CGFloat = 16       // 타이틀 ↔ 설명
    static let indicatorBottom: CGFloat = 28   // 인디케이터 ↔ 버튼
    static let buttonBottom: CGFloat = 13      // 버튼 ↔ 화면 하단(안전 영역)
}

struct WatchIntroView_Previews: PreviewProvider {
    static var previews: some View {
        WatchIntroView()
    }
}
