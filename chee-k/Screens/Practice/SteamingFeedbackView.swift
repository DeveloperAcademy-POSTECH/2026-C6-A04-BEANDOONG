import SwiftUI

/// 스티밍 연습 – 모델 피드백 화면 (피드백 종류에 따라 색상·텍스트·일러스트만 변경)
/// - 디자인: Hi-Fi 변경사항 07~11
///
///     ┌ 배경: 피드백별 위 → 아래 그라데이션
///     ├ 상단 바: 스티밍 연습
///     ├ 타이틀 + 설명
///     ├ 피드백별 우유 일러스트
///     └ 하단 중앙: 정지 버튼
struct SteamingFeedbackView: View {
    let feedback: SteamingFeedback
    var onStop: () -> Void = {}

    var body: some View {
        ZStack {
            // MARK: 배경
            LinearGradient(colors: feedback.gradientColors, startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: 상단 바
                SteamingPracticeTopBar()
                    .padding(.top, Layout.topBarTop)

                // MARK: 타이틀 + 설명
                DarkScreenTitle(feedback.title)
                    .padding(.top, Layout.titleTop)

                DarkScreenSubtitle(feedback.subtitle, color: Color.white)
                    .padding(.top, Layout.subtitleTop)

                // MARK: 일러스트
                AssetImageView(name: feedback.illustration, width: Layout.illustrationSize, height: Layout.illustrationSize)
                    .padding(.top, Layout.illustrationTop)

                Spacer(minLength: 0)

                // MARK: 정지 버튼
                SteamingStopButton(squareColor: feedback.stopSquareColor, action: onStop)
                    .padding(.bottom, Layout.stopButtonBottom)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - 피드백 종류

enum SteamingFeedback: CaseIterable {
    /// 공기 주입 소리 감지 (파랑)
    case aeration
    /// 날카로운 소리 감지 (빨강)
    case sharpSound
    /// 큰 기포 주의 (주황)
    case bubble
    /// 공기 추가 주입 (보라)
    case moreAir
    /// 우유 흐름(롤링) 확인 (초록)
    case milkFlow

    var gradientColors: [Color] {
        switch self {
        case .aeration: AppColors.aerationGradient
        case .sharpSound: AppColors.sharpSoundGradient
        case .bubble: AppColors.bubbleGradient
        case .moreAir: AppColors.moreAirGradient
        case .milkFlow: AppColors.milkFlowGradient
        }
    }

    var title: String {
        switch self {
        case .aeration: "공기 주입 소리가\n감지되고 있어요."
        case .sharpSound: "날카로운 소리가\n감지되고 있어요"
        case .bubble: "큰 기포가\n생길 수 있어요"
        case .moreAir: "공기를 조금 더\n넣어 주세요"
        case .milkFlow: "우유의 흐름을\n확인해요"
        }
    }

    var subtitle: String {
        switch self {
        case .aeration: "공기 주입 소리가 들리고 있어요"
        case .sharpSound: "우유의 상태를 확인해주세요"
        case .bubble: "피처를 살짝 올려 노즐을 더 담가 주세요"
        case .moreAir: "피처를 살짝 내려 주세요."
        case .milkFlow: "한 방향으로 돌면 그대로 유지해 주세요"
        }
    }

    var illustration: String {
        switch self {
        case .aeration: "IllustFeedbackAeration"
        case .sharpSound: "IllustFeedbackSharpSound"
        case .bubble: "IllustFeedbackBubble"
        case .moreAir: "IllustFeedbackMoreAir"
        case .milkFlow: "IllustFeedbackMilkFlow"
        }
    }

    /// 정지 버튼 가운데 사각형 색 = 배경 그라데이션의 위쪽 색
    var stopSquareColor: Color {
        switch self {
        case .aeration: AppColors.aerationTop
        case .sharpSound: AppColors.sharpSoundTop
        case .bubble: AppColors.bubbleTop
        case .moreAir: AppColors.moreAirTop
        case .milkFlow: AppColors.milkFlowTop
        }
    }
}

// MARK: - Layout

private enum Layout {
    static let topBarTop: CGFloat = 13          // 상태바 ↔ 상단 바
    static let titleTop: CGFloat = 79           // 상단 바 ↔ 타이틀
    static let subtitleTop: CGFloat = 16        // 타이틀 ↔ 설명
    static let illustrationTop: CGFloat = 75    // 설명 ↔ 일러스트
    static let illustrationSize: CGFloat = 258  // 일러스트 가로·세로
    static let stopButtonBottom: CGFloat = 74   // 정지 버튼 ↔ 화면 하단(안전 영역)
}

struct SteamingFeedbackView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(SteamingFeedback.allCases, id: \.self) { feedback in
            SteamingFeedbackView(feedback: feedback)
                .previewDisplayName("\(feedback)")
        }
    }
}
