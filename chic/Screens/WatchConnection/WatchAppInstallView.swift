import SwiftUI

/// Apple Watch에 chic 설치 안내 화면
/// - 디자인: Hi-Fi/iPhone 17 - 113.png
///
///     ┌ 상단 네비게이션 바: 애플 워치 연결
///     ├ 워치 앱 설치 일러스트 (진행 링 회전 애니메이션)
///     ├ 타이틀 + 설명
///     └ 하단 버튼: [다시 연결 확인하기]
struct WatchAppInstallView: View {
    var onCheck: () -> Void = {}
    // 보조 버튼은 새 시안(Hi-Fi 93·94·112·113)에서 빠졌다. onContinue 등 연결 코드(`WatchConnectionFlow`)는 그대로 두고 화면에서만 숨긴다.
    var onContinue: (() -> Void)? = nil

    var body: some View {
        WatchStatusScreen(
            headerTitleWeight: .semibold,  // Hi-Fi 113: 이 화면만 제목이 굵다
            title: String(localized: "Apple Watch 에\nchic을 설치해주세요"),
            subtitle: String(localized: "iPhone의 Watch 앱에서\nchic을 찾아 설치해주세요.")
        ) {
            WatchInstallIllustration()
        } footer: {
            BottomPrimaryButton(title: String(localized: "다시 연결 확인하기"), action: onCheck)
        }
    }
}

#Preview {
    NavigationStack {
        WatchAppInstallView()
            .toolbar(.hidden, for: .navigationBar)
    }
}
