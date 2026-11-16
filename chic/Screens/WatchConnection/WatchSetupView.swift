import SwiftUI

/// 애플 워치 연결 안내 화면
/// - 디자인: Hi-Fi/iPhone 17 - 93.png
///
///     ┌ 상단 네비게이션 바: 애플 워치 연결
///     ├ 아이폰 + 워치 일러스트 (전파 점등 애니메이션)
///     ├ 타이틀 + 설명
///     └ 하단 버튼: [연결 확인하기]
struct WatchSetupView: View {
    var onCheck: () -> Void = {}
    // 보조 버튼은 새 시안(Hi-Fi 93·94·112·113)에서 빠졌다. onContinue 등 연결 코드(`WatchConnectionFlow`)는 그대로 두고 화면에서만 숨긴다.
    var onContinue: (() -> Void)? = nil

    var body: some View {
        // 일러스트가 아이폰 + 워치(230×193)라서 다른 워치 상태 화면과 위치 값이 달라요.
        WatchStatusScreen(
            illustrationSize: PhoneWatchIllustration.size,
            illustrationTop: Layout.illustrationTop,
            titleTop: Layout.titleTop,
            subtitleTop: ScreenMetrics.compactSubtitleTop,
            title: String(localized: "워치에서도 실시간 상태를\n확인할 수 있어요"),
            subtitle: String(localized: "Apple Watch에서 chic 앱을 열어주세요\n손목 진동으로 스팀 상태를 알려드려요")
        ) {
            PhoneWatchIllustration()
        } footer: {
            BottomPrimaryButton(title: String(localized: "연결 확인하기"), action: onCheck)
        }
    }
}

// MARK: - Layout

private enum Layout {
    static let illustrationTop: CGFloat = 143.5  // 네비게이션 바 ↔ 일러스트 (Hi-Fi 측정 후 보정)
    static let titleTop: CGFloat = 68  // 일러스트 ↔ 타이틀
}

#Preview {
    NavigationStack {
        WatchSetupView()
            .toolbar(.hidden, for: .navigationBar)
    }
}
