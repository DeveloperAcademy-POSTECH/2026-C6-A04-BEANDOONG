import SwiftUI

/// 온보딩 3/3: 휴대폰을 스팀 머신 가까이에 놓기
/// - 디자인: Hi-Fi/iPhone 17 - 109.png
///
///     ┌ 상단 바: 건너뛰기
///     ├ 스팀 머신 + 소리 감지 일러스트
///     ├ 타이틀 + 설명
///     ├ 페이지 인디케이터 (● 세 번째)
///     └ 하단 버튼: 다음
struct PlacementIntroView: View {
    var onNext: () -> Void = {}
    var onSkip: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            // MARK: 상단 바
            OnboardingSkipTopBar(action: onSkip)
                .padding(.top, Layout.topBarTop)

            // MARK: 일러스트
            AssetImageView(name: "IllustMachineSound", width: 251, height: 199)
                .padding(.top, Layout.illustrationTop)

            // MARK: 타이틀 + 설명
            DarkScreenTitle("휴대폰을 스팀 머신\n가까이에 놓아주세요")
                .padding(.top, Layout.titleTop)

            DarkScreenSubtitle("공기주입 소리가 잘 감지되도록\n물과 열기를 피해 안전한 위치에 놓아주세요")
                .padding(.top, Layout.subtitleTop)

            Spacer(minLength: 0)

            // MARK: 페이지 인디케이터 + 하단 버튼
            OnboardingPageIndicator(activeIndex: 2)
                .padding(.bottom, Layout.indicatorBottom)

            DarkPrimaryButton(title: "다음", action: onNext)
                .padding(.bottom, Layout.buttonBottom)
        }
        .darkScreenBackgroundWithTopGlow()
    }
}

// MARK: - Layout

private enum Layout {
    static let topBarTop: CGFloat = 22         // 상태바 ↔ 상단 바
    static let illustrationTop: CGFloat = 162  // 상단 바 ↔ 일러스트
    static let titleTop: CGFloat = 82          // 일러스트 ↔ 타이틀
    static let subtitleTop: CGFloat = 11       // 타이틀 ↔ 설명
    static let indicatorBottom: CGFloat = 28   // 인디케이터 ↔ 버튼
    static let buttonBottom: CGFloat = 10      // 버튼 ↔ 화면 하단(안전 영역)
}

struct PlacementIntroView_Previews: PreviewProvider {
    static var previews: some View {
        PlacementIntroView()
    }
}
