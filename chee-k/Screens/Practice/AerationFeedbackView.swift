import SwiftUI

/// 스티밍 연습 – 공기 주입 소리 감지 화면 (파란 배경)
/// - 디자인: Hi-Fi/iPhone 17 - 119.png
///
///     ┌ 배경: 파란 세로 그라데이션
///     ├ 상단 바: 스티밍 연습  X
///     ├ 타이틀 + 설명
///     ├ 파란 웨이브 일러스트
///     └ 하단 중앙: 정지 버튼
struct AerationFeedbackView: View {
    var body: some View {
        ZStack {
            // MARK: 배경
            LinearGradient(
                colors: AppColors.aerationGradient,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: 상단 바
                SteamingPracticeTopBar()
                    .padding(.top, Layout.topBarTop)

                // MARK: 타이틀 + 설명
                DarkScreenTitle("공기 주입 소리가\n감지되고 있어요.")
                    .padding(.top, Layout.titleTop)

                DarkScreenSubtitle("공기 주입 소리가 들리고 있어요", color: Color.white.opacity(0.92))
                    .padding(.top, Layout.subtitleTop)

                // MARK: 일러스트
                AssetImageView(name: "IllustBlueWave", width: 262, height: 262)
                    .padding(.top, Layout.illustrationTop)

                Spacer(minLength: 0)

                // MARK: 정지 버튼
                SteamingStopButton(squareColor: AppColors.aerationStopSquare)
                    .padding(.bottom, Layout.stopButtonBottom)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Layout

private enum Layout {
    static let topBarTop: CGFloat = 13         // 상태바 ↔ 상단 바
    static let titleTop: CGFloat = 80          // 상단 바 ↔ 타이틀
    static let subtitleTop: CGFloat = 16       // 타이틀 ↔ 설명
    static let illustrationTop: CGFloat = 75   // 설명 ↔ 일러스트
    static let stopButtonBottom: CGFloat = 52  // 정지 버튼 ↔ 화면 하단(안전 영역)
}

struct AerationFeedbackView_Previews: PreviewProvider {
    static var previews: some View {
        AerationFeedbackView()
    }
}
