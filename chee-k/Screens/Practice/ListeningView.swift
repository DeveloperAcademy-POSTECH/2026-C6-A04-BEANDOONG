import SwiftUI

/// 스티밍 연습 – 소리 확인 중 화면
/// - 디자인: Hi-Fi/iPhone 17 - 102.png
///
///     ┌ 상단 바: 스티밍 연습  X
///     ├ 타이틀 + 설명
///     ├ 로딩 스피너 일러스트
///     └ 하단 중앙: 정지 버튼
struct ListeningView: View {
    var body: some View {
        VStack(spacing: 0) {
            // MARK: 상단 바
            SteamingPracticeTopBar()
                .padding(.top, Layout.topBarTop)

            // MARK: 타이틀 + 설명
            DarkScreenTitle("소리 확인 중")
                .padding(.top, Layout.titleTop)

            DarkScreenSubtitle("스티밍을 시작하면 소리를 확인해요.", color: Color.white.opacity(0.85))
                .padding(.top, Layout.subtitleTop)

            // MARK: 일러스트
            AssetImageView(name: "IllustSpinner", width: 108, height: 120)
                .padding(.top, Layout.illustrationTop)

            Spacer(minLength: 0)

            // MARK: 정지 버튼
            SteamingStopButton(squareColor: AppColors.darkBackground)
                .padding(.bottom, Layout.stopButtonBottom)
        }
        .darkScreenBackground()
    }
}

// MARK: - Layout

private enum Layout {
    static let topBarTop: CGFloat = 13         // 상태바 ↔ 상단 바
    static let titleTop: CGFloat = 80          // 상단 바 ↔ 타이틀
    static let subtitleTop: CGFloat = 18       // 타이틀 ↔ 설명
    static let illustrationTop: CGFloat = 142  // 설명 ↔ 일러스트
    static let stopButtonBottom: CGFloat = 52  // 정지 버튼 ↔ 화면 하단(안전 영역)
}

struct ListeningView_Previews: PreviewProvider {
    static var previews: some View {
        ListeningView()
    }
}
