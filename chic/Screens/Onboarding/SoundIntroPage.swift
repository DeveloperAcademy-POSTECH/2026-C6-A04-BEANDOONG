import SwiftUI

/// 온보딩 3/3: 공기주입 상태 확인 — 쪽 내용
/// - 디자인: Hi-Fi/iPhone 17 - 106.png
///
///     ┌ (상단 바 · 페이지 인디케이터 · 다음 버튼은 OnboardingView 가 그려요)
///     ├ 사운드 웨이브 일러스트
///     └ 타이틀 + 설명
///
/// `motion`: 쪽을 넘길 때 부분마다 옆으로 밀리고 투명해지는 정도. 평소에는 제자리(`.resting`)예요.
struct SoundIntroPage: View {
    var motion: OnboardingPageMotion = .resting

    var body: some View {
        VStack(spacing: 0) {
            // MARK: 일러스트
            AssetImageView(name: "IllustSoundWave", width: 219, height: 153)
                .onboardingPart(motion.illustration)
                .padding(.top, Metrics.illustrationTop)

            // MARK: 타이틀 + 설명
            DarkScreenTitle("공기주입 상태를\n한눈에 확인해요")
                .onboardingPart(motion.title)
                .padding(.top, Metrics.titleTop)

            DarkScreenSubtitle("스티밍 중 공기주입 상태를\n색상과 문구로 상태를 알려드려요")
                .onboardingPart(motion.subtitle)
                .padding(.top, Metrics.subtitleTop)
        }
    }
}

// MARK: - Metrics

private enum Metrics {
    static let illustrationTop: CGFloat = 199  // 상단 바 ↔ 일러스트
    static let titleTop: CGFloat = 92          // 일러스트 ↔ 타이틀
    static let subtitleTop: CGFloat = 11       // 타이틀 ↔ 설명
}

#Preview {
    OnboardingView(page: .sound)
}
