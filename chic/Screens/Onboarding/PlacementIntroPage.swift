import SwiftUI

/// 온보딩 2/3: 휴대폰을 스팀 머신 가까이에 놓기 — 쪽 내용
/// - 디자인: Hi-Fi/iPhone 17 - 109.png
///
///     ┌ (상단 바 · 페이지 인디케이터 · 다음 버튼은 OnboardingView 가 그려요)
///     ├ 스팀 머신 + 소리 감지 일러스트 (원형 파동 애니메이션)
///     └ 타이틀 + 설명
///
/// `motion`: 쪽을 넘길 때 부분마다 옆으로 밀리고 투명해지는 정도. 평소에는 제자리(`.resting`)예요.
struct PlacementIntroPage: View {
    var motion: OnboardingPageMotion = .resting

    var body: some View {
        VStack(spacing: 0) {
            // MARK: 일러스트
            SoundRippleIllustration(spec: .machineSound)
                .onboardingPart(motion.illustration)
                .padding(.top, Metrics.illustrationTop)

            // MARK: 타이틀 + 설명
            DarkScreenTitle("휴대폰을 스팀 머신\n가까이에 놓아주세요")
                .onboardingPart(motion.title)
                .padding(.top, Metrics.titleTop)

            DarkScreenSubtitle("공기주입 소리가 잘 감지되도록\n물과 열기를 피해 안전한 위치에 놓아주세요")
                .onboardingPart(motion.subtitle)
                .padding(.top, Metrics.subtitleTop)
        }
    }
}

// MARK: - Metrics

private enum Metrics {
    static let illustrationTop: CGFloat = 162  // 상단 바 ↔ 일러스트
    static let titleTop: CGFloat = 82          // 일러스트 ↔ 타이틀
    static let subtitleTop: CGFloat = 11       // 타이틀 ↔ 설명
}

#Preview {
    OnboardingView(page: .placement)
}
