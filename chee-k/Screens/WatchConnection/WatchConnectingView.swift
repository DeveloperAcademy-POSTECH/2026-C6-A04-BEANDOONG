import SwiftUI

/// Apple Watch 연결 확인 중 화면
/// - 디자인: Hi-Fi/iPhone 17 - 111.png
///
///     ┌ 상단 네비게이션 바: 애플 워치 연결
///     ├ 워치 일러스트 (확인 중)
///     └ 타이틀 + 설명   (하단 버튼 없음)
struct WatchConnectingView: View {
    var body: some View {
        VStack(spacing: 0) {
            // MARK: 상단 네비게이션 바
            TopNavigationHeader(title: "애플 워치 연결", isDark: true)
                .padding(.top, Layout.headerTop)

            // MARK: 일러스트
            AssetImageView(name: "IllustWatchChecking", width: 126, height: 210)
                .padding(.top, Layout.illustrationTop)

            // MARK: 타이틀 + 설명
            DarkScreenTitle("Apple Watch 연결을\n확인하고 있어요")
                .padding(.top, Layout.titleTop)

            DarkScreenSubtitle("잠시만 기다려 주세요")
                .padding(.top, Layout.subtitleTop)

            Spacer(minLength: 0)
        }
        .darkScreenBackground()
    }
}

// MARK: - Layout

private enum Layout {
    static let headerTop: CGFloat = 22         // 상태바 ↔ 네비게이션 바
    static let illustrationTop: CGFloat = 129  // 네비게이션 바 ↔ 일러스트
    static let titleTop: CGFloat = 76          // 일러스트 ↔ 타이틀
    static let subtitleTop: CGFloat = 18       // 타이틀 ↔ 설명
}

struct WatchConnectingView_Previews: PreviewProvider {
    static var previews: some View {
        WatchConnectingView()
    }
}
