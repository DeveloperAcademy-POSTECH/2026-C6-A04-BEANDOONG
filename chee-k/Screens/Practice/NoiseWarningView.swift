import SwiftUI

/// 스티밍 연습 – 소리 구분 어려움 안내 화면
/// - 디자인: Hi-Fi/iPhone 17 - 103.png
///
///     ┌ 상단 바: 스티밍 연습  X
///     ├ 타이틀 + 설명
///     ├ 마이크 일러스트
///     └ 하단 중앙: 정지 버튼
struct NoiseWarningView: View {
    var onStop: () -> Void = {}
    var body: some View {
        VStack(spacing: 0) {
            // MARK: 상단 바
            SteamingPracticeTopBar(onClose: onStop)
                .padding(.top, Layout.topBarTop)

            // MARK: 타이틀 + 설명
            DarkScreenTitle("소리를 구분하기 어려워요")
                .padding(.top, Layout.titleTop)

            DarkScreenSubtitle("주변 소음과 마이크 위치를 확인해주세요", color: Color.white.opacity(0.85))
                .padding(.top, Layout.subtitleTop)

            // MARK: 일러스트
            AssetImageView(name: "IllustMic", width: 98, height: 170)
                .padding(.top, Layout.illustrationTop)

            Spacer(minLength: 0)

            // MARK: 정지 버튼
            SteamingStopButton(squareColor: AppColors.darkBackground, action: onStop)
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
    static let illustrationTop: CGFloat = 118  // 설명 ↔ 일러스트
    static let stopButtonBottom: CGFloat = 52  // 정지 버튼 ↔ 화면 하단(안전 영역)
}

struct NoiseWarningView_Previews: PreviewProvider {
    static var previews: some View {
        NoiseWarningView()
    }
}
