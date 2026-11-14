import SwiftUI

/// 온보딩 5/5: 연습을 돌아보고 부족했던 순간 채우기 — 쪽 내용
/// - 디자인: Hi-Fi/iPhone 17 - 237.png
///
///     ┌ (상단 바 · 페이지 인디케이터 · 다음 버튼은 OnboardingView 가 그려요)
///     ├ 그래프 일러스트 (`ReviewGraphIllustration`, 303x212: 왼쪽부터 그려지고 점이 톡 튀며 반복)
///     └ 타이틀 + 설명
///
/// `motion`: 쪽을 넘길 때 부분마다 옆으로 밀리고 투명해지는 정도. 평소에는 제자리(`.resting`)예요.
struct ReviewIntroPage: View {
    var motion: OnboardingPageMotion = .resting
    @Environment(\.designScale) private var scale

    var body: some View {
        VStack(spacing: 0) {
            // MARK: 일러스트
            ReviewGraphIllustration()
                .designScaled(width: 303, height: 212, scale)
                .onboardingPart(motion.illustration)
                .padding(.top, Metrics.illustrationTop.v(scale))

            // MARK: 타이틀 + 설명
            DarkScreenTitle("연습을 돌아보고\n부족했던 순간을 채워가요")
                .onboardingPart(motion.title)
                .padding(.top, Metrics.titleTop.v(scale))

            DarkScreenSubtitle("어떤 소리가 얼마나 감지됐는지 확인하고\n 다음 연습에 활용해 보세요") // 2행 앞 공백: Hi-Fi 237 2행이 가운데에서 약 2pt 오른쪽
                .onboardingPart(motion.subtitle)
                .padding(.top, Metrics.subtitleTop.v(scale))
        }
    }
}

// MARK: - Metrics

private enum Metrics {
    static let illustrationTop: CGFloat = 116  // 상단 바 ↔ 일러스트 (Hi-Fi 237: 일러스트 y0 220 − 104)
    static let titleTop: CGFloat = 36          // 일러스트 ↔ 타이틀 (Hi-Fi 237: 프레임 아래 432 → 471.5)
    static let subtitleTop: CGFloat = 11       // 타이틀 ↔ 설명
}

#Preview {
    OnboardingView(page: .review)
}
