import SwiftUI

/// 스티밍 연습 중 Apple Watch 연결 끊김 화면
/// - 디자인: Hi-Fi/iPhone 17 - 94.png
///
///     ┌ 상단 네비게이션 바: 스티밍 연습
///     ├ 워치 일러스트 (연결 끊김)
///     ├ 타이틀 + 설명
///     └ 하단 버튼: [워치 연결 다시 확인] [워치 없이 연습하기]
struct WatchDisconnectedView: View {
    var body: some View {
        VStack(spacing: 0) {
            // MARK: 상단 네비게이션 바
            TopNavigationHeader(title: "스티밍 연습", isDark: true)
                .padding(.top, Layout.headerTop)

            // MARK: 일러스트
            AssetImageView(name: "IllustWatchDisconnect", width: 126, height: 210)
                .padding(.top, Layout.illustrationTop)

            // MARK: 타이틀 + 설명
            DarkScreenTitle("Apple Watch\n연결이 끊겼어요")
                .padding(.top, Layout.titleTop)

            DarkScreenSubtitle("휴대폰의 상태 표시는 계속 확인할 수 있어요\n진동 피드백은 연결 후 다시 사용할 수 있어요")
                .padding(.top, Layout.subtitleTop)

            Spacer(minLength: 0)

            // MARK: 하단 버튼
            DarkButtonPair(primaryTitle: "워치 연결 다시 확인", secondaryTitle: "워치 없이 연습하기")
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

struct WatchDisconnectedView_Previews: PreviewProvider {
    static var previews: some View {
        WatchDisconnectedView()
    }
}
