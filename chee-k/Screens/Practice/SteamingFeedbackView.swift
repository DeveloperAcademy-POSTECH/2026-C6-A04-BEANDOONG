import SwiftUI

/// 스티밍 연습 – 모델 피드백 화면 (피드백 종류에 따라 색상·아이콘·텍스트만 변경)
/// - 디자인: Hi-Fi/iPhone 17 - 119, 101, 157, 158, 161.png
///
///     ┌ 배경: 피드백별 그라데이션 / 단색
///     ├ 상단 바: 스티밍 연습  X
///     ├ (상태 아이콘) + 타이틀 + 설명
///     ├ 피드백별 웨이브 일러스트
///     └ 하단 중앙: 정지 버튼
struct SteamingFeedbackView: View {
    let feedback: SteamingFeedback
    var onStop: () -> Void = {}

    var body: some View {
        ZStack {
            // MARK: 배경
            Rectangle()
                .fill(feedback.background)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: 상단 바
                SteamingPracticeTopBar(onClose: onStop)
                    .padding(.top, Layout.topBarTop)

                // MARK: 상태 아이콘 + 타이틀 + 설명
                if let statusIcon = feedback.statusIcon {
                    AssetImageView(name: statusIcon, width: 40, height: 38)
                        .padding(.top, Layout.iconTop)
                }

                DarkScreenTitle(feedback.title)
                    .padding(.top, hasIcon ? Layout.titleTopWithIcon : Layout.titleTop)

                DarkScreenSubtitle(feedback.subtitle, color: Color.white.opacity(0.92))
                    .padding(.top, Layout.subtitleTop)

                // MARK: 일러스트
                AssetImageView(name: feedback.waveImage, width: 262, height: 262)
                    .padding(.top, hasIcon ? Layout.illustrationTopWithIcon : Layout.illustrationTop)

                Spacer(minLength: 0)

                // MARK: 정지 버튼
                SteamingStopButton(squareColor: feedback.stopSquareColor, action: onStop)
                    .padding(.bottom, Layout.stopButtonBottom)
            }
        }
        .animation(.easeInOut, value: feedback)
        .preferredColorScheme(.dark)
    }

    private var hasIcon: Bool { feedback.statusIcon != nil }
}

// MARK: - 피드백 종류

enum SteamingFeedback: CaseIterable {
    /// 공기 주입 소리 감지 (파랑)
    case aeration
    /// 날카로운 소리 감지 (분홍)
    case sharpSound
    /// 큰 기포 주의 (주황)
    case bubble
    /// 공기 추가 주입 (보라)
    case moreAir
    /// 우유 흐름(롤링) 확인 (초록)
    case milkFlow

    var background: AnyShapeStyle {
        switch self {
        case .aeration:
            AnyShapeStyle(LinearGradient(colors: AppColors.aerationGradient, startPoint: .top, endPoint: .bottom))
        case .sharpSound:
            AnyShapeStyle(LinearGradient(colors: AppColors.sharpSoundGradient, startPoint: .top, endPoint: .bottom))
        case .bubble:
            AnyShapeStyle(AppColors.bubbleWarningOrange)
        case .moreAir:
            AnyShapeStyle(AppColors.moreAirPurple)
        case .milkFlow:
            AnyShapeStyle(AppColors.milkFlowGreen)
        }
    }

    var statusIcon: String? {
        switch self {
        case .aeration, .sharpSound: nil
        case .bubble: "IllustBubbleIcon"
        case .moreAir: "IllustPulseIcon"
        case .milkFlow: "IllustSwirlIcon"
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

    var waveImage: String {
        switch self {
        case .aeration: "IllustBlueWave"
        case .sharpSound: "IllustPinkWave"
        case .bubble: "IllustOrangeWave"
        case .moreAir: "IllustPurpleWave"
        case .milkFlow: "IllustGreenWave"
        }
    }

    var stopSquareColor: Color {
        switch self {
        case .aeration: AppColors.aerationStopSquare
        case .sharpSound: AppColors.sharpSoundStopSquare
        case .bubble: AppColors.bubbleWarningOrange
        case .moreAir: AppColors.moreAirPurple
        case .milkFlow: AppColors.milkFlowGreen
        }
    }
}

// MARK: - Layout

private enum Layout {
    static let topBarTop: CGFloat = 13                // 상태바 ↔ 상단 바
    static let iconTop: CGFloat = 44                  // 상단 바 ↔ 상태 아이콘
    static let titleTop: CGFloat = 80                 // 상단 바 ↔ 타이틀 (아이콘 없음)
    static let titleTopWithIcon: CGFloat = 22         // 상태 아이콘 ↔ 타이틀
    static let subtitleTop: CGFloat = 16              // 타이틀 ↔ 설명
    static let illustrationTop: CGFloat = 75          // 설명 ↔ 일러스트 (아이콘 없음)
    static let illustrationTopWithIcon: CGFloat = 68  // 설명 ↔ 일러스트 (아이콘 있음)
    static let stopButtonBottom: CGFloat = 52         // 정지 버튼 ↔ 화면 하단(안전 영역)
}

struct SteamingFeedbackView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(SteamingFeedback.allCases, id: \.self) { feedback in
            SteamingFeedbackView(feedback: feedback)
                .previewDisplayName("\(feedback)")
        }
    }
}
