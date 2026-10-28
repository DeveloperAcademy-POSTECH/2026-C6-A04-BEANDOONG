import SwiftUI

/// 온보딩 1/3: 공기주입 상태 확인
/// - 디자인: Hi-Fi/iPhone 17 - 106.png
///
///     ┌ 상단 바: 건너뛰기
///     ├ 사운드 웨이브 일러스트
///     ├ 타이틀 + 설명
///     ├ 페이지 인디케이터 (● 첫 번째)
///     └ 하단 버튼: 다음
struct SoundIntroView: View {
    var body: some View {
        VStack(spacing: 0) {
            // MARK: 상단 바
            OnboardingSkipTopBar()
                .padding(.top, Layout.topBarTop)

            // MARK: 일러스트
            AssetImageView(name: "IllustSoundWave", width: 224, height: 156)
                .padding(.top, Layout.illustrationTop)

            // MARK: 타이틀 + 설명
            DarkScreenTitle("공기주입 상태를\n한눈에 확인해요")
                .padding(.top, Layout.titleTop)

            DarkScreenSubtitle("스티밍 중 공기주입 상태를\n색상과 문구로 상태를 알려드려요")
                .padding(.top, Layout.subtitleTop)

            Spacer(minLength: 0)

            // MARK: 페이지 인디케이터 + 하단 버튼
            OnboardingPageIndicator(activeIndex: 0)
                .padding(.bottom, Layout.indicatorBottom)

            DarkPrimaryButton(title: "다음")
                .padding(.bottom, Layout.buttonBottom)
        }
        .darkScreenBackground()
    }
}

// MARK: - Layout

private enum Layout {
    static let topBarTop: CGFloat = 22         // 상태바 ↔ 상단 바
    static let illustrationTop: CGFloat = 196  // 상단 바 ↔ 일러스트
    static let titleTop: CGFloat = 92          // 일러스트 ↔ 타이틀
    static let subtitleTop: CGFloat = 16       // 타이틀 ↔ 설명
    static let indicatorBottom: CGFloat = 28   // 인디케이터 ↔ 버튼
    static let buttonBottom: CGFloat = 13      // 버튼 ↔ 화면 하단(안전 영역)
}

struct SoundIntroView_Previews: PreviewProvider {
    static var previews: some View {
        SoundIntroView()
    }
}
