import SwiftUI

/// 온보딩 2/3: 휴대폰을 스팀 머신 가까이에 놓기 — 쪽 내용
/// - 디자인: Hi-Fi/iPhone 17 - 109.png
///
///     ┌ (상단 바 · 페이지 인디케이터 · 다음 버튼은 OnboardingView 가 그려요)
///     ├ 스팀 머신 + 소리 감지 일러스트
///     └ 타이틀 + 설명
struct PlacementIntroPage: View {
    var body: some View {
        VStack(spacing: 0) {
            // MARK: 일러스트
            AssetImageView(name: "IllustMachineSound", width: 251, height: 199)
                .padding(.top, Metrics.illustrationTop)

            // MARK: 타이틀 + 설명
            DarkScreenTitle("휴대폰을 스팀 머신\n가까이에 놓아주세요")
                .padding(.top, Metrics.titleTop)

            DarkScreenSubtitle("공기주입 소리가 잘 감지되도록\n물과 열기를 피해 안전한 위치에 놓아주세요")
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
