import SwiftUI

/// 히스토리 연습 내역 없음 화면 (빈 상자 일러스트 버전)
/// - 디자인: Hi-Fi/iPhone 17 - 166.png
///
///     ┌ 상단 네비게이션 바: 히스토리
///     ├ 빈 상자 일러스트
///     ├ 타이틀 + 설명
///     └ 하단 버튼: [첫 스티밍 시작하기]
struct EmptyHistoryView: View {
    @Environment(\.designScale) private var scale
    let onStartPractice: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // MARK: 상단 네비게이션 바
            // 안전 영역을 무시하고 화면 맨 위·아래 기준으로 잰다. iPhone 17 안전 영역(위 62·아래 34)을 더한 값이라 17에서는 예전과 같다.
            TopNavigationHeader(title: String(localized: "히스토리"), isDark: true)
                .padding(.top, ScreenMetrics.topBarTop.v(scale))

            // MARK: 일러스트
            AssetImageView(name: "IllustEmptyBox", size: Layout.illustrationSize)
                .designScaled(size: Layout.illustrationSize, scale)
                .padding(.top, Layout.illustrationTop.v(scale))

            // MARK: 타이틀 + 설명
            DarkScreenTitle(String(localized: "아직 기록이 없어요"))
                .padding(.top, Layout.titleTop.v(scale))

            DarkScreenSubtitle(String(localized: "첫 스티밍을 시작하고\n기록을 남겨볼까요?"))
                .padding(.top, Layout.subtitleTop.v(scale))

            Spacer(minLength: 0)

            // MARK: 하단 버튼
            BottomPrimaryButton(title: String(localized: "첫 스티밍 시작하기"), action: onStartPractice)
        }
        .ignoresSafeArea()
        .darkScreenBackgroundWithTopGlow()
    }
}

// MARK: - Layout

private enum Layout {
    static let illustrationSize = CGSize(width: 166, height: 122)
    static let illustrationTop: CGFloat = 240  // 네비게이션 바 ↔ 일러스트
    static let titleTop: CGFloat = 55          // 일러스트 ↔ 타이틀
    static let subtitleTop: CGFloat = 10       // 타이틀 ↔ 설명
}

#Preview {
    EmptyHistoryView(onStartPractice: {})
}
