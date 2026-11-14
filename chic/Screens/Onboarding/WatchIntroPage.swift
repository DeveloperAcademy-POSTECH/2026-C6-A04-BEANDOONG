import SwiftUI

/// 온보딩 1/5: 아이폰과 워치로 함께 확인 — 쪽 내용
/// - 디자인: Hi-Fi/iPhone 17 - 108.png
///
///     ┌ (상단 바 · 페이지 인디케이터 · 다음 버튼은 OnboardingView 가 그려요)
///     ├ 아이폰 + 워치 일러스트 (전파 점등 애니메이션)
///     └ 타이틀 + 설명
///
/// `motion`: 쪽을 넘길 때 부분마다 옆으로 밀리고 투명해지는 정도. 평소에는 제자리(`.resting`)예요.
struct WatchIntroPage: View {
    var motion: OnboardingPageMotion = .resting
    @Environment(\.designScale) private var scale

    var body: some View {
        VStack(spacing: 0) {
            // MARK: 일러스트
            PhoneWatchIllustration()
                .designScaled(width: 230, height: 193, scale)
                .onboardingPart(motion.illustration)
                .padding(.top, Metrics.illustrationTop.v(scale))

            // MARK: 타이틀 + 설명
            DarkScreenTitle(String(localized: "아이폰과 워치로\n함께 확인해요"))
                .onboardingPart(motion.title)
                .padding(.top, Metrics.titleTop.v(scale))

            DarkScreenSubtitle(String(localized: "Apple Watch를 함께 사용하면\n상태 변화를 진동으로도 안내받을 수 있어요"))
                .onboardingPart(motion.subtitle)
                .padding(.top, Metrics.subtitleTop.v(scale))
        }
    }
}

// MARK: - Metrics

private enum Metrics {
    static let illustrationTop: CGFloat = 97   // 상단 바 ↔ 일러스트 (Hi-Fi 108: 일러스트 y0 201 − 상단 바 아래 104)
    static let titleTop: CGFloat = 74          // 일러스트 ↔ 타이틀 (Hi-Fi 108: 394 → 471.5)
    static let subtitleTop: CGFloat = 11       // 타이틀 ↔ 설명
}

#Preview {
    OnboardingView(page: .watch)
}
