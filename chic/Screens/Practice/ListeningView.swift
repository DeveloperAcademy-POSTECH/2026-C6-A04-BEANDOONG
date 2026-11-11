import SwiftUI

/// 스티밍 연습 – 소리 확인 중 화면
/// - 디자인: Hi-Fi/iPhone 17 - 222.png
///
///     ┌ 상단 바: 스티밍 연습
///     ├ 타이틀 + 설명
///     ├ 소리 막대 일러스트 (`IllustSoundBars`, 90x136)
///     └ 하단 중앙: 정지 버튼
struct ListeningView: View {
    @Environment(\.designScale) private var scale
    var onStop: () -> Void = {}
    var body: some View {
        VStack(spacing: 0) {
            // MARK: 상단 바
            SteamingPracticeTopBar()
                .padding(.top, Layout.topBarTop.v(scale))

            // MARK: 타이틀 + 설명
            DarkScreenTitle("스티밍을 시작하면\n소리를 확인해요", lineSpacing: Layout.titleLineSpacing)
                .padding(.top, Layout.titleTop.v(scale))

            // MARK: 소리 막대 일러스트
            // 왼쪽 막대부터 번지듯 나타났다가 차례로 사라지기를 반복해요 (애니메이션 벤치 STM-02)
            SoundBarsIllustration()
                .designScaled(width: 90, height: 136, scale)
                .padding(.top, Layout.illustrationTop.v(scale))

            Spacer(minLength: 0)

            // MARK: 정지 버튼
            SteamingStopButton(squareColor: AppColors.darkBackground, action: onStop)
                .padding(.bottom, Layout.stopButtonBottom.v(scale))
        }
        .ignoresSafeArea()
        .darkScreenBackground()
    }
}

// MARK: - Layout

private enum Layout {
    static let topBarTop: CGFloat = 72          // 화면 위 ↔ 상단 바 (Hi-Fi 222: 글자 y0 75 − 3)
    static let titleTop: CGFloat = 75.5         // 상단 바 ↔ 타이틀 (Hi-Fi 222: 90 → 171)
    static let titleLineSpacing: CGFloat = 4.7  // Hi-Fi 222: 타이틀 줄 높이 36
    static let illustrationTop: CGFloat = 118.5 // 타이틀 ↔ 막대 (Hi-Fi 222: 231 → 353, 측정 보정)
    static let stopButtonBottom: CGFloat = 94.5 // 정지 버튼 ↔ 화면 하단 (Hi-Fi 222: 874 − 779.5)
}

struct ListeningView_Previews: PreviewProvider {
    static var previews: some View {
        ListeningView()
    }
}
