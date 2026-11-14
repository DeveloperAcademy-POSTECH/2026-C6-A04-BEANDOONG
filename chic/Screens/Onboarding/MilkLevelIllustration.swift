import SwiftUI

/// 온보딩 4/5 우유 피처 일러스트 (ONB-04, 3.4초 반복)
///
/// 공기 주입 소리가 나는 동안 우유가 잔물결을 일으키며 위 점선까지 차오르고, 화살표도 함께 올라가요.
/// 잠깐 머문 뒤 원래 높이로 내려가 반복해요. 움직임은 `MilkLevelLoop` 표에서 꺼내 써요.
///
///     ┌ 비커 테두리 + 손잡이 (IllustMilkLevelBase)
///     ├ 우유: 코드로 그림 (MilkSurface, 세로 그라데이션)
///     ├ 점선 2줄 (IllustMilkLevelDashes): 우유 위에 얹혀요
///     └ 위 화살표 (IllustMilkLevelArrow): 수위를 따라 최대 6pt 올라가요
///
/// - 세 장의 에셋은 원본 `IllustMilkLevelPitcher`(@3x 557×454)를 층별로 나눈 것이라 캔버스 크기가 같아 겹쳐 놓기만 해요.
/// - 첫 프레임은 연습 화면처럼 잔잔한 윗면이라, 물결이 그려진 Hi-Fi 정지 화면과 윗면 모양이 조금 달라요.
/// - 동작 줄이기(Reduce Motion)·`-uiTestStill`에서는 원본 `IllustMilkLevelPitcher`를 그대로 보여 줘서 Hi-Fi와 같아요.
struct MilkLevelIllustration: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isStill: Bool {
        #if DEBUG
        return reduceMotion || ProcessInfo.processInfo.arguments.contains("-uiTestStill")
        #else
        return reduceMotion
        #endif
    }

    var body: some View {
        Group {
            if isStill {
                AssetImageView(name: "IllustMilkLevelPitcher", width: Spec.frameSize.width, height: Spec.frameSize.height)
            } else {
                ZStack {
                    AssetImageView(name: "IllustMilkLevelBase", width: Spec.frameSize.width, height: Spec.frameSize.height)

                    LoopTimeline(period: MilkLevelLoop.period) { progress in
                        let frame = MilkLevelLoop.shared.frame(at: progress)
                        ZStack {
                            IllustrationCanvas(pixelSize: Spec.frameSize, frameSize: Spec.frameSize, rendersAsynchronously: true) { context in
                                let milk = MilkSurface(
                                    vessel: Spec.vessel,
                                    top: frame.top,
                                    amplitude: MilkLevelLoop.rippleHeight * CGFloat(frame.rippleStrength),
                                    phase: MilkLevelLoop.ripplePhase(at: progress)
                                )
                                context.fill(milk.path(in: .zero),
                                             with: .linearGradient(Spec.milkGradient, startPoint: Spec.milkGradientStart, endPoint: Spec.milkGradientEnd))
                            }

                            AssetImageView(name: "IllustMilkLevelDashes", width: Spec.frameSize.width, height: Spec.frameSize.height)

                            AssetImageView(name: "IllustMilkLevelArrow", width: Spec.frameSize.width, height: Spec.frameSize.height)
                                .offset(y: MilkLevelLoop.arrowOffset(forTop: frame.top))
                        }
                    }
                }
            }
        }
        .frame(width: Spec.frameSize.width, height: Spec.frameSize.height)
        .accessibilityHidden(true)
    }
}

// MARK: - 사양 (애니메이션 벤치 ONB-04, 일러스트 왼쪽 위 기준 pt)

private enum Spec {
    /// 화면에 놓이는 크기: 에셋 @3x 557×454
    static let frameSize = CGSize(width: 557.0 / 3, height: 454.0 / 3)

    /// 우유가 닿는 비커 안쪽. 원본 @3x 에셋의 우유 가장자리에서 잰 직선이에요.
    /// - 벽: 왼쪽 x = 27.84 − 0.1462y, 오른쪽 x = 129.94 + 0.1235y (연습 화면 비커와 기울기가 같아요)
    /// - 바닥 y 146.1. 모서리는 연습 화면 값 × 0.604 (윗면 5 → 3pt, 바닥 12 → 7.25pt, 원본 바닥 모서리 약 7pt와 맞음)
    /// - 잔물결 한 주기: 64 × 0.604 = 38.6pt. 물결이 짧아서 2pt 간격으로 이어 그려요.
    static let vessel = MilkVessel(
        left: .init(intercept: 27.84, slope: -0.1462),
        right: .init(intercept: 129.94, slope: 0.1235),
        bottom: 146.1,
        topRadius: 5 * MilkLevelLoop.scale,
        bottomRadius: 12 * MilkLevelLoop.scale,
        wavelength: 64 * Double(MilkLevelLoop.scale),
        sampleStep: 2
    )

    /// 우유 색: 원본 에셋의 위 → 아래 세로 그라데이션 (y 84 #E1F2FD → y 146.5 #C5E8FA)
    static let milkGradient = Gradient(colors: [Color(hex: 0xE1F2FD), Color(hex: 0xC5E8FA)])
    static let milkGradientStart = CGPoint(x: 0, y: 84)
    static let milkGradientEnd = CGPoint(x: 0, y: 146.5)
}

#Preview {
    MilkLevelIllustration()
        .padding(40)
        .background(AppColors.darkBackground)
}
