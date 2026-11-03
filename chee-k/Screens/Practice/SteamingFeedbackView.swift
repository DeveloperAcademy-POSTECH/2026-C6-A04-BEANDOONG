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

/// case 이름은 `PracticePhase`(워치와 공유)와 맞춰 두고, 화면 문구만 Hi-Fi에 맞춥니다.
enum SteamingFeedback: CaseIterable {
    /// 공기가 고르게 들어가는 중 (파랑)
    case aeration
    /// 금속성 소리 — 우유가 오래 가열되는 중 (빨강)
    case sharpSound
    /// 노즐이 높아 큰 기포가 생길 수 있음 (주황)
    case bubble
    /// 공기 주입이 부족함 (보라)
    case moreAir
    /// 롤링이 안정적으로 진행되는 중 (초록)
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
        case .aeration: "공기가 고르게\n들어가고 있어요"
        case .sharpSound: "우유가 오래\n가열되고 있어요"
        case .bubble: "큰 기포가\n생길 수 있어요"
        case .moreAir: "공기 주입이\n부족해요"
        case .milkFlow: "롤링이 안정적으로\n진행되고 있어요"
        }
    }

    var subtitle: String {
        switch self {
        case .aeration: "지금 상태를 유지해 주세요"
        case .sharpSound: "온도를 확인해 주세요"
        case .bubble: "피처를 살짝 올려 노즐을 더 담가 주세요"
        case .moreAir: "피처를 살짝 내려 주세요"
        case .milkFlow: "우유가 한 방향으로 돌도록 유지해 주세요"
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
