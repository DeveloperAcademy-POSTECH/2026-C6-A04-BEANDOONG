import SwiftUI

/// 온보딩 1/3: 아이폰과 워치로 함께 확인 — 쪽 내용
/// - 디자인: Hi-Fi/iPhone 17 - 108.png
///
///     ┌ (상단 바 · 페이지 인디케이터 · 다음 버튼은 OnboardingView 가 그려요)
///     ├ 아이폰 + 워치 일러스트
///     └ 타이틀 + 설명
struct WatchIntroPage: View {
    var body: some View {
        VStack(spacing: 0) {
            // MARK: 일러스트
            AssetImageView(name: "IllustPhoneWatch", width: 230, height: 193)
                .padding(.top, Metrics.illustrationTop)

            // MARK: 타이틀 + 설명
            DarkScreenTitle("아이폰과 워치로\n함께 확인해요")
                .padding(.top, Metrics.titleTop)

            DarkScreenSubtitle("Apple Watch를 함께 사용하면\n상태 변화를 진동으로도 안내받을 수 있어요")
                .padding(.top, Metrics.subtitleTop)
        }
    }
}

// MARK: - Metrics

private enum Metrics {
    static let illustrationTop: CGFloat = 177  // 상단 바 ↔ 일러스트
    static let titleTop: CGFloat = 74          // 일러스트 ↔ 타이틀
    static let subtitleTop: CGFloat = 11       // 타이틀 ↔ 설명
}

#Preview {
    OnboardingView(page: .watch)
}
