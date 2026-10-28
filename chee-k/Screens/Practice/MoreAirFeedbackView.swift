import SwiftUI

/// 스티밍 연습 – 공기 추가 주입 피드백 화면 (보라 배경)
/// - 디자인: Hi-Fi/iPhone 17 - 158.png
///
///     ┌ 배경: 보라 단색
///     ├ 상단 바: 스티밍 연습  X
///     ├ 상단 파형 아이콘 + 타이틀 + 설명
///     ├ 보라 웨이브 일러스트
///     └ 하단 중앙: 정지 버튼
struct MoreAirFeedbackView: View {
    var body: some View {
        ZStack {
            // MARK: 배경
            AppColors.moreAirPurple
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: 상단 바
                SteamingPracticeTopBar()
                    .padding(.top, Layout.topBarTop)

                // MARK: 상태 아이콘 + 타이틀 + 설명
                AssetImageView(name: "IllustPulseIcon", width: 40, height: 38)
                    .padding(.top, Layout.iconTop)

                DarkScreenTitle("공기를 조금 더\n넣어 주세요")
                    .padding(.top, Layout.titleTop)

                DarkScreenSubtitle("피처를 살짝 내려 주세요.", color: Color.white.opacity(0.92))
                    .padding(.top, Layout.subtitleTop)

                // MARK: 일러스트
                AssetImageView(name: "IllustPurpleWave", width: 262, height: 262)
                    .padding(.top, Layout.illustrationTop)

                Spacer(minLength: 0)

                // MARK: 정지 버튼
                SteamingStopButton(squareColor: AppColors.moreAirPurple)
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
    static let moreAirPurple = Color(hex: 0x784AD6)
}

struct MoreAirFeedbackView_Previews: PreviewProvider {
    static var previews: some View {
        MoreAirFeedbackView()
    }
}
