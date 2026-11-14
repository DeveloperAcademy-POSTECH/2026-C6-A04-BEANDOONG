import SwiftUI

/// 마이크 권한 안내 화면 (권한이 꺼져 있을 때 설정으로 유도)
/// - 디자인: Hi-Fi/iPhone 17 - 115.png
///
///     ┌ 상단 네비게이션 바: 마이크 설정
///     ├ 마이크 일러스트
///     ├ 타이틀 + 설명
///     └ 하단 버튼: [설정 열기]
struct MicrophoneAccessView: View {
    @Environment(\.designScale) private var scale
    var onOpenSettings: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            // MARK: 상단 네비게이션 바
            TopNavigationHeader(title: String(localized: "마이크 설정"), isDark: true)
                .padding(.top, Layout.headerTop.v(scale))

            // MARK: 일러스트
            AssetImageView(name: "IllustMic", width: 93, height: 165)
                .designScaled(width: 93, height: 165, scale)
                .padding(.top, Layout.illustrationTop.v(scale))

            // MARK: 타이틀 + 설명
            DarkScreenTitle(String(localized: "공기주입 상태를 분석하려면\n마이크 권한이 필요해요"))
                .padding(.top, Layout.titleTop.v(scale))

            DarkScreenSubtitle(String(localized: "기기 설정에서 chic의 마이크 접근을\n허용한 뒤 돌아와 주세요"))
                .padding(.top, Layout.subtitleTop.v(scale))

            Spacer(minLength: 0)

            // MARK: 하단 버튼
            DarkPrimaryButton(title: String(localized: "설정 열기"), width: Layout.buttonWidth.h(scale), height: BottomButton.height, action: onOpenSettings)
                .padding(.bottom, BottomButton.bottomGap.v(scale) + scale.fixedHeightAdjustment(BottomButton.height))
        }
        .ignoresSafeArea()
        .darkScreenBackgroundWithTopGlow()
    }
}

// MARK: - Layout

private enum Layout {
    static let headerTop: CGFloat = 84  // 화면 위 ↔ 네비게이션 바 (Hi-Fi 글자 y0 86.5 − 2.5)
    static let illustrationTop: CGFloat = 131  // 네비게이션 바 ↔ 일러스트 (Hi-Fi 측정 후 보정)
    static let titleTop: CGFloat = 75.5  // 일러스트 ↔ 타이틀
    static let subtitleTop: CGFloat = 15  // 타이틀 ↔ 설명
    static let buttonWidth: CGFloat = 363       // Hi-Fi 버튼 폭
}

struct MicrophoneAccessView_Previews: PreviewProvider {
    static var previews: some View {
        MicrophoneAccessView()
    }
}
