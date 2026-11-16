import SwiftUI

/// 온보딩 3/5: 공기주입 상태 확인 — 쪽 내용
/// - 디자인: Hi-Fi/iPhone 17 - 106.png
///
///     ┌ (상단 바 · 페이지 인디케이터 · 다음 버튼은 OnboardingView 가 그려요)
///     ├ 사운드 웨이브 일러스트 (원형 파동 애니메이션)
///     └ 타이틀 + 설명
///
/// `motion`: 쪽을 넘길 때 부분마다 옆으로 밀리고 투명해지는 정도. 평소에는 제자리(`.resting`)예요.
struct SoundIntroPage: View {
    var motion: OnboardingPageMotion = .resting

    var body: some View {
        OnboardingPageLayout(
            motion: motion,
            illustrationSize: SoundRippleIllustration.size,
            illustrationTop: Layout.illustrationTop,
            titleTop: Layout.titleTop,
            subtitleTop: ScreenMetrics.compactSubtitleTop,
            title: String(localized: "공기주입 상태를\n한눈에 확인해요"),
            subtitle: String(localized: "스티밍 중 공기주입 상태를\n색상과 문구로 상태를 알려드려요")
        ) {
            SoundRippleIllustration()
        }
    }
}

// MARK: - Layout

private enum Layout {
    static let illustrationTop: CGFloat = 119  // 상단 바 ↔ 일러스트 (Hi-Fi 106: 일러스트 y0 223 − 104)
    static let titleTop: CGFloat = 91          // 일러스트 ↔ 타이틀 (Hi-Fi 106: 376.5 → 471)
}

#Preview {
    OnboardingView(page: .sound)
}
