import SwiftUI

/// Apple Watch 연결 확인 중 화면
/// - 디자인: Hi-Fi/iPhone 17 - 111.png
///
///     ┌ 상단 네비게이션 바: 애플 워치 연결
///     ├ 워치 일러스트 (확인 중, 원형 점 로더 애니메이션)
///     └ 타이틀 + 설명   (하단 버튼 없음)
struct WatchConnectingView: View {
    @Environment(\.designScale) private var scale
    var body: some View {
        VStack(spacing: 0) {
            // MARK: 상단 네비게이션 바
            TopNavigationHeader(title: "애플 워치 연결", isDark: true)
                .padding(.top, Layout.headerTop.v(scale))

            // MARK: 일러스트
            WatchConnectingIllustration()
                .designScaled(width: 121, height: 207, scale)
                .padding(.top, Layout.illustrationTop.v(scale))

            // MARK: 타이틀 + 설명
            DarkScreenTitle("Apple Watch 연결을\n확인하고 있어요")
                .padding(.top, Layout.titleTop.v(scale))

            DarkScreenSubtitle("잠시만 기다려 주세요")
                .padding(.top, Layout.subtitleTop.v(scale))

            Spacer(minLength: 0)
        }
        .ignoresSafeArea()
        .darkScreenBackgroundWithTopGlow()
    }
}

// MARK: - Layout

private enum Layout {
    static let headerTop: CGFloat = 84  // 화면 위 ↔ 네비게이션 바 (Hi-Fi 글자 y0 86.5 − 2.5)
    static let illustrationTop: CGFloat = 130.5  // 네비게이션 바 ↔ 일러스트 (Hi-Fi 측정 후 보정)
    static let titleTop: CGFloat = 76  // 일러스트 ↔ 타이틀
    static let subtitleTop: CGFloat = 14  // 타이틀 ↔ 설명
}

struct WatchConnectingView_Previews: PreviewProvider {
    static var previews: some View {
        WatchConnectingView()
    }
}
