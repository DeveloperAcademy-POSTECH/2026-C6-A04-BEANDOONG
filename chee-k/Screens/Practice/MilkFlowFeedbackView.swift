import SwiftUI

/// 스티밍 연습 – 우유 흐름(롤링) 확인 피드백 화면 (초록 배경)
/// - 디자인: Hi-Fi/iPhone 17 - 161.png
///
///     ┌ 배경: 초록 단색
///     ├ 상단 바: 스티밍 연습  X
///     ├ 상단 회오리 아이콘 + 타이틀 + 설명
///     ├ 초록 흐름 웨이브 일러스트
///     └ 하단 중앙: 정지 버튼
struct MilkFlowFeedbackView: View {
    var body: some View {
        ZStack {
            // MARK: 배경
            AppColors.milkFlowGreen
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: 상단 바
                SteamingPracticeTopBar()
                    .padding(.top, Layout.topBarTop)

                // MARK: 상태 아이콘 + 타이틀 + 설명
                AssetImageView(name: "IllustSwirlIcon", width: 40, height: 38)
                    .padding(.top, Layout.iconTop)

                DarkScreenTitle("우유의 흐름을\n확인해요")
                    .padding(.top, Layout.titleTop)

                DarkScreenSubtitle("한 방향으로 돌면 그대로 유지해 주세요", color: Color.white.opacity(0.92))
                    .padding(.top, Layout.subtitleTop)

                // MARK: 일러스트
                AssetImageView(name: "IllustGreenWave", width: 262, height: 262)
                    .padding(.top, Layout.illustrationTop)

                Spacer(minLength: 0)

                // MARK: 정지 버튼
                SteamingStopButton(squareColor: AppColors.milkFlowGreen)
                    .padding(.bottom, Layout.stopButtonBottom)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Layout

private enum Layout {
    static let topBarTop: CGFloat = 13         // 상태바 ↔ 상단 바
    static let iconTop: CGFloat = 44           // 상단 바 ↔ 상태 아이콘
    static let titleTop: CGFloat = 22          // 상태 아이콘 ↔ 타이틀
    static let subtitleTop: CGFloat = 16       // 타이틀 ↔ 설명
    static let illustrationTop: CGFloat = 68   // 설명 ↔ 일러스트
    static let stopButtonBottom: CGFloat = 52  // 정지 버튼 ↔ 화면 하단(안전 영역)
}

// MARK: - 이 화면 전용 색상

private extension AppColors {
    static let milkFlowGreen = Color(hex: 0x1ABC6B)
}

struct MilkFlowFeedbackView_Previews: PreviewProvider {
    static var previews: some View {
        MilkFlowFeedbackView()
    }
}
