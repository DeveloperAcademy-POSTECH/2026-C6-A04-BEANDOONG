import SwiftUI

/// 온보딩 소개 쪽 5개가 같이 쓰는 틀: 일러스트 + 타이틀 + 설명 (위에서 아래로, 가운데 정렬)
///
/// 상단 바 · 페이지 인디케이터 · 하단 버튼은 `OnboardingView` 가 그려요. 쪽마다 다른 것(일러스트 · 문구 · 간격 숫자)만 넘겨요.
///
/// 쪽을 넘길 때 일러스트 · 타이틀 · 설명이 따로 움직이도록, 각 부분에 `onboardingPart(motion.…)` 를 붙여요.
/// 붙이는 자리는 "그리는 내용 바로 뒤, 위 간격(`padding`) 앞"이에요. 그래서 옆으로 밀리는 것은 내용뿐이고 레이아웃 자리는 그대로예요.
///
///     OnboardingPageLayout(
///         motion: motion,
///         illustrationSize: PhoneWatchIllustration.size,
///         illustrationTop: Layout.illustrationTop, titleTop: Layout.titleTop, subtitleTop: Layout.subtitleTop,
///         title: String(localized: "…"), subtitle: String(localized: "…")
///     ) {
///         PhoneWatchIllustration()
///     }
struct OnboardingPageLayout<Illustration: View>: View {
    /// 쪽을 넘길 때 부분마다 옆으로 밀리고 투명해지는 정도
    let motion: OnboardingPageMotion
    /// 일러스트가 화면에 놓이는 크기 (iPhone 17 기준 pt, 다른 기기는 `designScaled` 가 키워요)
    let illustrationSize: CGSize
    /// 상단 바 ↔ 일러스트
    let illustrationTop: CGFloat
    /// 일러스트 ↔ 타이틀
    let titleTop: CGFloat
    /// 타이틀 ↔ 설명
    let subtitleTop: CGFloat
    let title: String
    let subtitle: String
    @ViewBuilder let illustration: () -> Illustration

    @Environment(\.designScale) private var scale

    var body: some View {
        VStack(spacing: 0) {
            // MARK: 일러스트
            illustration()
                .designScaled(size: illustrationSize, scale)
                .onboardingPart(motion.illustration)
                .padding(.top, illustrationTop.v(scale))

            // MARK: 타이틀 + 설명
            DarkScreenTitle(title)
                .onboardingPart(motion.title)
                .padding(.top, titleTop.v(scale))

            DarkScreenSubtitle(subtitle)
                .onboardingPart(motion.subtitle)
                .padding(.top, subtitleTop.v(scale))
        }
    }
}
