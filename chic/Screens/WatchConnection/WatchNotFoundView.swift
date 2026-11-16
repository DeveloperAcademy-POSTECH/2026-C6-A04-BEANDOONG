import SwiftUI

/// Apple Watch 찾지 못함 화면
/// - 디자인: Hi-Fi/iPhone 17 - 112.png
///
///     ┌ 상단 네비게이션 바: 애플 워치 연결
///     ├ 워치 일러스트 (연결 끊김)
///     ├ 타이틀 + 설명
///     └ 하단 버튼: [다시 연결 확인하기]
struct WatchNotFoundView: View {
    var onCheck: () -> Void = {}
    // 보조 버튼은 새 시안(Hi-Fi 93·94·112·113)에서 빠졌다. onContinue 등 연결 코드(`WatchConnectionFlow`)는 그대로 두고 화면에서만 숨긴다.
    var onContinue: (() -> Void)? = nil

    var body: some View {
        WatchStatusScreen(
            title: String(localized: "Apple Watch 를\n찾지 못했어요"),
            subtitle: String(localized: "iPhone의 Watch 앱에서\nApple Watch의 페어링 상태를 확인해주세요")
        ) {
            AssetImageView(name: "IllustWatchDisconnect", size: ScreenMetrics.WatchStatus.illustrationSize)
        } footer: {
            BottomPrimaryButton(title: String(localized: "다시 연결 확인하기"), action: onCheck)
        }
    }
}

#Preview {
    NavigationStack {
        WatchNotFoundView()
            .toolbar(.hidden, for: .navigationBar)
    }
}
