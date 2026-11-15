import SwiftUI

/// Apple Watch 연결 확인 중 화면
/// - 디자인: Hi-Fi/iPhone 17 - 111.png
///
///     ┌ 상단 네비게이션 바: 애플 워치 연결
///     ├ 워치 일러스트 (확인 중, 원형 점 로더 애니메이션)
///     └ 타이틀 + 설명   (하단 버튼 없음)
struct WatchConnectingView: View {
    var body: some View {
        WatchStatusScreen(
            title: String(localized: "Apple Watch 연결을\n확인하고 있어요"),
            subtitle: String(localized: "잠시만 기다려 주세요")
        ) {
            WatchConnectingIllustration()
        }
    }
}

#Preview {
    WatchConnectingView()
}
