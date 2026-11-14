import SwiftUI

/// 온보딩 4/5: 공기 주입에 따라 우유가 차오름 — 쪽 내용
/// - 디자인: Hi-Fi/iPhone 17 - 302.png (2026-11-13 추가)
///
///     ┌ (상단 바 · 페이지 인디케이터 · 하단 버튼은 OnboardingView 가 그려요)
///     ├ 비커 일러스트 (`MilkLevelIllustration`, 185.7x151.3: 우유가 위 점선까지 차올랐다 내려가며 반복, 화살표도 따라 움직임)
///     └ 타이틀 + 설명
///
/// `motion`: 쪽을 넘길 때 부분마다 옆으로 밀리고 투명해지는 정도. 평소에는 제자리(`.resting`)예요.
struct MilkLevelIntroPage: View {
    var motion: OnboardingPageMotion = .resting
    @Environment(\.designScale) private var scale

    var body: some View {
        VStack(spacing: 0) {
            // MARK: 일러스트
            MilkLevelIllustration()
                .designScaled(width: Metrics.illustrationSize.width, height: Metrics.illustrationSize.height, scale)
                .onboardingPart(motion.illustration)
                .padding(.top, Metrics.illustrationTop.v(scale))
                .accessibilityHidden(true)

            // MARK: 타이틀 + 설명
            DarkScreenTitle(String(localized: "공기 주입에 따라\n우유가 차올라요"))
                .onboardingPart(motion.title)
                .padding(.top, Metrics.titleTop.v(scale))

            DarkScreenSubtitle(String(localized: "공기 주입 소리가 감지되는 동안\n 화면 속 우유가 서서히 차올라요")) // 2행 앞 공백: Hi-Fi 302 2행이 가운데에서 약 2pt 오른쪽
                .onboardingPart(motion.subtitle)
                .padding(.top, Metrics.subtitleTop.v(scale))
        }
    }
}

// MARK: - Metrics

private enum Metrics {
    static let illustrationSize = CGSize(width: 557.0 / 3, height: 454.0 / 3) // 에셋 @3x 557x454 (왼쪽 3pt 투명 여백). Hi-Fi 302: 그림 x 111.5 ~ 294.5, y 241 ~ 392.5
    static let illustrationTop: CGFloat = 137  // 상단 바 ↔ 일러스트 (Hi-Fi 302: 일러스트 y0 241 − 104)
    static let titleTop: CGFloat = 75          // 일러스트 ↔ 타이틀 (Hi-Fi 302: 392.5 → 글자 y0 471, 글자 상자 여백 3.5)
    static let subtitleTop: CGFloat = 11       // 타이틀 ↔ 설명
}

#Preview {
    OnboardingView(page: .milkLevel)
}
