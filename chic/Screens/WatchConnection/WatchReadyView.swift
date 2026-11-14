import SwiftUI

/// Apple Watch 준비 완료 화면
/// - 디자인: Hi-Fi/iPhone 17 - 114.png
///
///     ┌ 상단 네비게이션 바: 애플 워치 연결
///     ├ 워치 일러스트 (준비 완료)
///     ├ 타이틀 + 설명
///     └ 하단 버튼: [완료]
struct WatchReadyView: View {
    @Environment(\.designScale) private var scale
    var onContinue: (() -> Void)? = nil
    @State private var showsChecklist = false

    var body: some View {
        VStack(spacing: 0) {
            // MARK: 상단 네비게이션 바
            TopNavigationHeader(title: String(localized: "애플 워치 연결"), isDark: true)
                .padding(.top, Layout.headerTop.v(scale))

            // MARK: 일러스트
            AssetImageView(name: "IllustWatchReady", width: 121, height: 207)
                .designScaled(width: 121, height: 207, scale)
                .padding(.top, Layout.illustrationTop.v(scale))

            // MARK: 타이틀 + 설명
            DarkScreenTitle(String(localized: "Apple Watch 가\n준비되었어요"))
                .padding(.top, Layout.titleTop.v(scale))

            DarkScreenSubtitle(String(localized: "이제 스팀 연습을 시작하면\n워치에서 진동 피드백을 받을 수 있어요"))
                .padding(.top, Layout.subtitleTop.v(scale))

            Spacer(minLength: 0)

            // MARK: 하단 버튼
            DarkPrimaryButton(title: String(localized: "완료"), width: Layout.buttonWidth.h(scale), height: BottomButton.height) {
                if let onContinue { onContinue() } else { showsChecklist = true }
            }
                .padding(.bottom, BottomButton.bottomGap.v(scale) + scale.fixedHeightAdjustment(BottomButton.height))
        }
        .ignoresSafeArea()
        .darkScreenBackgroundWithTopGlow()
        .navigationDestination(isPresented: $showsChecklist) {
            PracticePrepGuideView()
                .toolbar(.hidden, for: .navigationBar)
        }
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

struct WatchReadyView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            WatchReadyView()
                .toolbar(.hidden, for: .navigationBar)
        }
    }
}
