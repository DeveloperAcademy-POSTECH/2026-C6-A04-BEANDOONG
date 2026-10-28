import SwiftUI

/// Apple Watch 찾지 못함 화면
/// - 디자인: Hi-Fi/iPhone 17 - 112.png
///
///     ┌ 상단 네비게이션 바: 애플 워치 연결
///     ├ 워치 일러스트 (연결 끊김)
///     ├ 타이틀 + 설명
///     └ 하단 버튼: [다시 연결 확인하기] [휴대폰만 사용하기]
struct WatchNotFoundView: View {
    var body: some View {
        VStack(spacing: 0) {
            // MARK: 상단 네비게이션 바
            TopNavigationHeader(title: "애플 워치 연결", isDark: true)
                .padding(.top, Layout.headerTop)

            // MARK: 일러스트
            AssetImageView(name: "IllustWatchDisconnect", width: 126, height: 210)
                .padding(.top, Layout.illustrationTop)

            // MARK: 타이틀 + 설명
            DarkScreenTitle("Apple Watch 를\n찾지 못했어요")
                .padding(.top, Layout.titleTop)

            DarkScreenSubtitle("iPhone의 Watch 앱에서\nApple Watch의 페어링 상태를 확인해주세요")
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
    static let headerTop: CGFloat = 22         // 상태바 ↔ 네비게이션 바
    static let illustrationTop: CGFloat = 129  // 네비게이션 바 ↔ 일러스트
    static let titleTop: CGFloat = 76          // 일러스트 ↔ 타이틀
    static let subtitleTop: CGFloat = 18       // 타이틀 ↔ 설명
    static let buttonsBottom: CGFloat = 13     // 버튼 ↔ 화면 하단(안전 영역)
}

struct WatchNotFoundView_Previews: PreviewProvider {
    static var previews: some View {
        WatchNotFoundView()
    }
}
