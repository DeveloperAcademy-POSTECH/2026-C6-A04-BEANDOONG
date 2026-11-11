import SwiftUI

/// 애플 워치 연결 안내 화면
/// - 디자인: Hi-Fi/iPhone 17 - 93.png
///
///     ┌ 상단 네비게이션 바: 애플 워치 연결
///     ├ 아이폰 + 워치 일러스트 (전파 점등 애니메이션)
///     ├ 타이틀 + 설명
///     └ 하단 버튼: [연결 확인하기]
struct WatchSetupView: View {
    @Environment(\.designScale) private var scale
    var onCheck: () -> Void = {}
    var onContinue: (() -> Void)? = nil
    @State private var showsChecklist = false

    var body: some View {
        VStack(spacing: 0) {
            // MARK: 상단 네비게이션 바
            TopNavigationHeader(title: "애플 워치 연결", isDark: true)
                .padding(.top, Layout.headerTop.v(scale))

            // MARK: 일러스트
            PhoneWatchIllustration()
                .designScaled(width: 230, height: 193, scale)
                .padding(.top, Layout.illustrationTop.v(scale))

            // MARK: 타이틀 + 설명
            DarkScreenTitle("워치에서도 실시간 상태를\n확인할 수 있어요")
                .padding(.top, Layout.titleTop.v(scale))

            DarkScreenSubtitle("Apple Watch에서 chic 앱을 열어주세요\n손목 진동으로 스팀 상태를 알려드려요")
                .padding(.top, Layout.subtitleTop.v(scale))

            Spacer(minLength: 0)

            // MARK: 하단 버튼
            // 보조 버튼은 새 시안(Hi-Fi 93·94·112·113)에서 빠졌다. onContinue 등 연결 코드는 그대로 두고 화면에서만 숨긴다.
            DarkPrimaryButton(title: "연결 확인하기", width: Layout.buttonWidth.h(scale), height: BottomButton.height, action: onCheck)
                .padding(.bottom, BottomButton.bottomGap.v(scale) + scale.fixedHeightAdjustment(BottomButton.height))
        }
        .ignoresSafeArea()
        .darkScreenBackgroundWithTopGlow()
        .navigationDestination(isPresented: $showsChecklist) {
            PracticePrepGuideView(usesWatch: false)
                .toolbar(.hidden, for: .navigationBar)
        }
    }
}

// MARK: - Layout

private enum Layout {
    static let headerTop: CGFloat = 84  // 화면 위 ↔ 네비게이션 바 (Hi-Fi 글자 y0 86.5 − 2.5)
    static let illustrationTop: CGFloat = 143.5  // 네비게이션 바 ↔ 일러스트 (Hi-Fi 측정 후 보정)
    static let titleTop: CGFloat = 68  // 일러스트 ↔ 타이틀
    static let subtitleTop: CGFloat = 11 // 타이틀 ↔ 설명
    static let buttonWidth: CGFloat = 363       // Hi-Fi 버튼 폭
}

struct WatchSetupView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            WatchSetupView()
                .toolbar(.hidden, for: .navigationBar)
        }
    }
}
