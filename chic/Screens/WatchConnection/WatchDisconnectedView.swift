import SwiftUI

/// 스티밍 연습 중 Apple Watch 연결 끊김 화면
/// - 디자인: Hi-Fi/iPhone 17 - 94.png
///
///     ┌ 상단 네비게이션 바: 스티밍 연습
///     ├ 워치 일러스트 (연결 끊김)
///     ├ 타이틀 + 설명
///     └ 하단 버튼: [워치 연결 다시 확인]
struct WatchDisconnectedView: View {
    @Environment(\.designScale) private var scale
    var onCheck: () -> Void = {}
    var onContinue: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            // MARK: 상단 네비게이션 바
            TopNavigationHeader(title: "스티밍 연습", isDark: true)
                .padding(.top, Layout.headerTop.v(scale))

            // MARK: 일러스트
            AssetImageView(name: "IllustWatchDisconnect", width: 121, height: 207)
                .designScaled(width: 121, height: 207, scale)
                .padding(.top, Layout.illustrationTop.v(scale))

            // MARK: 타이틀 + 설명
            DarkScreenTitle("Apple Watch\n연결이 끊겼어요")
                .padding(.top, Layout.titleTop.v(scale))

            DarkScreenSubtitle("휴대폰의 상태 표시는 계속 확인할 수 있어요\n진동 피드백은 연결 후 다시 사용할 수 있어요")
                .padding(.top, Layout.subtitleTop.v(scale))

            Spacer(minLength: 0)

            // MARK: 하단 버튼
            // 보조 버튼은 새 시안(Hi-Fi 93·94·112·113)에서 빠졌다. onContinue 등 연결 코드는 그대로 두고 화면에서만 숨긴다.
            DarkPrimaryButton(title: "워치 연결 다시 확인", width: Layout.buttonWidth.h(scale), height: BottomButton.height, action: onCheck)
                .padding(.bottom, BottomButton.bottomGap.v(scale) + scale.fixedHeightAdjustment(BottomButton.height))
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
    static let buttonWidth: CGFloat = 363       // Hi-Fi 버튼 폭
}

struct WatchDisconnectedView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            WatchDisconnectedView()
                .toolbar(.hidden, for: .navigationBar)
        }
    }
}
