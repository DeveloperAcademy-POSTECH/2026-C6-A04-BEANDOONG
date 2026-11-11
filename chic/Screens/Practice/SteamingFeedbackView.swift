import SwiftUI

/// 스티밍 연습 – 모델 피드백 화면 (피드백 종류에 따라 색상·텍스트·일러스트만 변경)
/// - 디자인: Hi-Fi iPhone 17 - 160 · 188 · 189 · 190 · 265
///
///     ┌ 배경: 피드백별 위 → 아래 그라데이션
///     ├ 상단 바: 스티밍 연습
///     ├ 타이틀 + 설명
///     ├ 피드백별 우유 일러스트
///     └ 하단 중앙: 종료하기 버튼 (누르면 바로 정지. "스티밍이 끝났나요?" 팝업은 소리가 끊겼을 때만)
struct SteamingFeedbackView: View {
    @Environment(\.designScale) private var scale
    let feedback: SteamingFeedback
    /// 종료하기 버튼: 묻지 않고 바로 정지
    var onStop: () -> Void = {}
    /// 스팀 소리가 끊겨 "스티밍이 끝났나요?"를 묻는 중인지 (연습 관리자가 정해요)
    var showsEndDialog = false
    /// 팝업의 '계속 연습'
    var onContinue: () -> Void = {}
    /// 팝업의 '연습 종료' (소리가 끊긴 시각으로 종료)
    var onFinishAfterSilence: () -> Void = {}

    var body: some View {
        ZStack {
            // MARK: 배경
            LinearGradient(colors: feedback.gradientColors, startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: 상단 바
                SteamingPracticeTopBar()
                    .padding(.top, Layout.topBarTop.v(scale))

                // MARK: 타이틀 + 설명
                DarkScreenTitle(feedback.title, lineSpacing: Layout.titleLineSpacing)
                    .padding(.top, Layout.titleTop.v(scale))

                DarkScreenSubtitle(feedback.subtitle, color: Color.white)
                    .padding(.top, Layout.subtitleTop.v(scale))

                // MARK: 일러스트
                AssetImageView(name: feedback.illustration, width: Layout.illustrationSize, height: Layout.illustrationSize)
                    .designScaled(width: Layout.illustrationSize, height: Layout.illustrationSize, scale)
                    .offset(x: feedback.illustrationOffsetX.h(scale))
                    .padding(.top, Layout.illustrationTop.v(scale))

                Spacer(minLength: 0)

                // MARK: 종료하기 버튼
                // 직접 누르면 묻지 않고 바로 정지해요. (팝업은 소리가 끊겼을 때만)
                SteamingEndButton(squareColor: feedback.stopSquareColor, width: Layout.endButtonWidth.h(scale), action: onStop)
                .padding(.bottom, Layout.endButtonBottom.v(scale))
            }
            .ignoresSafeArea()
        }
        .chicAlert(
            isPresented: showsEndDialog,
            title: "스티밍이 끝났나요?",
            message: "스팀 소리가 감지되지 않아요\n연습을 마쳤다면 기록을 확인해 주세요",
            cancelTitle: "계속 연습",
            confirmTitle: "연습 종료",
            onCancel: onContinue,
            onConfirm: onFinishAfterSilence
        )
        .preferredColorScheme(.dark)
    }
}

// MARK: - 피드백 종류

/// case 이름은 `PracticePhase`(워치와 공유)와 맞춰 두고, 화면 문구만 Hi-Fi에 맞춥니다.
enum SteamingFeedback: CaseIterable {
    /// 공기가 고르게 들어가는 중 (파랑)
    case aeration
    /// 노즐이 높아 큰 기포가 생길 수 있음 (주황)
    case bubble
    /// 공기 주입이 부족함 (보라)
    case moreAir
    /// 롤링이 안정적으로 진행되는 중 (초록)
    case milkFlow

    var gradientColors: [Color] {
        switch self {
        case .aeration: AppColors.aerationGradient
        case .bubble: AppColors.bubbleGradient
        case .moreAir: AppColors.moreAirGradient
        case .milkFlow: AppColors.milkFlowGradient
        }
    }

    var title: String {
        switch self {
        case .aeration: "공기가 고르게\n들어가고 있어요"
        case .bubble: "큰 기포가\n생길 수 있어요"
        case .moreAir: "공기 주입이\n부족해요"
        case .milkFlow: "롤링이 안정적으로\n진행되고 있어요"
        }
    }

    var subtitle: String {
        switch self {
        case .aeration: "지금 상태를 유지해 주세요"
        case .bubble: "피처를 살짝 올려 노즐을 더 담가 주세요"
        case .moreAir: "피처를 살짝 내려 주세요"
        case .milkFlow: "우유가 한 방향으로 돌도록 유지해 주세요"
        }
    }

    var illustration: String {
        switch self {
        case .aeration: "IllustFeedbackAeration"
        case .bubble: "IllustFeedbackBubble"
        case .moreAir: "IllustFeedbackMoreAir"
        case .milkFlow: "IllustFeedbackMilkFlow"
        }
    }

    /// 일러스트 가로 위치 보정 (Hi-Fi 190: 공기 부족 일러스트만 가운데보다 8pt 왼쪽에 있음)
    var illustrationOffsetX: CGFloat {
        switch self {
        case .moreAir: -8
        default: 0
        }
    }

    /// 종료하기 버튼 사각형 색 = 상태 팔레트 색 (배경 그라데이션의 아래쪽 색)
    var stopSquareColor: Color {
        switch self {
        case .aeration: AppColors.soundNormalAeration
        case .bubble: AppColors.soundOverAeration
        case .moreAir: AppColors.soundLackOfAir
        case .milkFlow: AppColors.soundRolling
        }
    }
}

// MARK: - Layout (iPhone 17 시안 측정값, pt)

private enum Layout {
    static let topBarTop: CGFloat = 72           // 화면 위 ↔ 상단 바 (Hi-Fi 160: 글자 y0 75 − 3)
    static let titleTop: CGFloat = 75.5          // 상단 바 ↔ 타이틀 (Hi-Fi 160: 90 → 171)
    static let titleLineSpacing: CGFloat = 4.7   // Hi-Fi 160: 타이틀 줄 높이 36 (171 → 207)
    static let subtitleTop: CGFloat = 14         // 타이틀 ↔ 설명
    static let illustrationTop: CGFloat = 76     // 설명 ↔ 일러스트 (Hi-Fi 160 343 / 188·189·190 344의 중간)
    static let illustrationSize: CGFloat = 258   // 일러스트 가로·세로 (Hi-Fi 160: 258.5)
    static let endButtonWidth: CGFloat = 274     // Hi-Fi 160: 캡슐 폭 274.5
    static let endButtonBottom: CGFloat = 94     // 종료하기 버튼 ↔ 화면 하단 (Hi-Fi 160: 874 − 780)
}

#Preview("aeration") { SteamingFeedbackView(feedback: .aeration) }
#Preview("bubble") { SteamingFeedbackView(feedback: .bubble) }
#Preview("moreAir") { SteamingFeedbackView(feedback: .moreAir) }
#Preview("milkFlow") { SteamingFeedbackView(feedback: .milkFlow) }
#Preview("소리 끊김") { SteamingFeedbackView(feedback: .aeration, showsEndDialog: true) }
