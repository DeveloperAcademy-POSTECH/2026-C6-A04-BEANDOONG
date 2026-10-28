import SwiftUI

/// Apple Watch에 chic 설치 안내 화면
/// - 디자인: Hi-Fi/iPhone 17 - 113.png
///
///     ┌ 상단 네비게이션 바: 애플 워치 연결
///     ├ 워치 앱 설치 일러스트 (오른쪽으로 15pt 치우침)
///     ├ 타이틀 + 설명
///     └ 하단 버튼: [다시 연결 확인하기] [휴대폰만 사용하기]
struct WatchAppInstallView: View {
    var body: some View {
        VStack(spacing: 0) {
            // MARK: 상단 네비게이션 바
            TopNavigationHeader(title: "애플 워치 연결", isDark: true)
                .padding(.top, Layout.headerTop)

            // MARK: 일러스트
            AssetImageView(name: "IllustWatchInstall", width: 252, height: 264)
                .offset(x: Layout.illustrationOffsetX)
                .padding(.top, Layout.illustrationTop)

            // MARK: 타이틀 + 설명
            DarkScreenTitle("Apple Watch 에\nchic을 설치해주세요")
                .padding(.top, Layout.titleTop)

            DarkScreenSubtitle("iPhone의 Watch 앱에서\nchic을 찾아 설치해주세요.")
                .padding(.top, Layout.subtitleTop)

            Spacer(minLength: 0)

            // MARK: 하단 버튼
            DarkButtonPair(primaryTitle: "다시 연결 확인하기", secondaryTitle: "휴대폰만 사용하기")
                .padding(.bottom, Layout.buttonsBottom)
        }
        .darkScreenBackground()
    }
}

// MARK: - Layout

private enum Layout {
    static let headerTop: CGFloat = 22           // 상태바 ↔ 네비게이션 바
    static let illustrationTop: CGFloat = 102    // 네비게이션 바 ↔ 일러스트
    static let illustrationOffsetX: CGFloat = 15 // 일러스트 가로 보정 (오른쪽으로)
    static let titleTop: CGFloat = 49            // 일러스트 ↔ 타이틀
    static let subtitleTop: CGFloat = 18         // 타이틀 ↔ 설명
    static let buttonsBottom: CGFloat = 12       // 버튼 ↔ 화면 하단(안전 영역)
}

struct WatchAppInstallView_Previews: PreviewProvider {
    static var previews: some View {
        WatchAppInstallView()
    }
}
