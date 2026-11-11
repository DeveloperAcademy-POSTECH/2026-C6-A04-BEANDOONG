import SwiftUI

/// 연결 확인 중 일러스트 (WCH-02 원형 점 로더)
///
/// 워치 화면 가운데 점 6개 중 가장 진한 점이 시계 방향으로 한 칸씩 끊어서 넘어가고,
/// 지나간 점들은 Hi-Fi의 진하기 단계대로 옅어져요. 1초에 한 바퀴예요.
///
///          ②                ● 가장 진한 점(머리)이 ① → ② → ③ → ④ → ⑤ → ⑥ 순서로 시계 방향 이동
///      ①       ⑤
///      ②       ④
///          ③
///
///     ┌ 베이스: 워치 (점만 지우고 화면 그라데이션으로 채운 이미지, IllustWatchCheckingBase)
///     └ 점 6개: 코드로 그려서 진하기만 바꿈
///
/// - 첫 프레임은 Hi-Fi 정지 화면과 같아요.
/// - 동작 줄이기(Reduce Motion)가 켜져 있으면 Hi-Fi 정지 화면으로 멈춰 있어요.
struct WatchConnectingIllustration: View {
    var body: some View {
        ZStack {
            AssetImageView(name: "IllustWatchCheckingBase", width: Spec.frameSize.width, height: Spec.frameSize.height)

            LoopTimeline(period: Spec.period) { progress in
                IllustrationCanvas(pixelSize: Spec.frameSize, frameSize: Spec.frameSize) { context in
                    drawDots(in: &context, headStep: Int(progress * Double(Spec.dotCenters.count)))
                }
            }
        }
        .accessibilityHidden(true)
    }

    /// 머리가 `headStep`칸 넘어간 상태로 점을 그려요.
    private func drawDots(in context: inout GraphicsContext, headStep: Int) {
        let count = Spec.dotCenters.count
        for (index, center) in Spec.dotCenters.enumerated() {
            // 이 점이 머리에서 몇 칸 뒤에 있는지 (0 = 머리)
            let behind = ((headStep - index) % count + count) % count
            let dot = Path(ellipseIn: CGRect(
                x: center.x - Spec.dotRadius,
                y: center.y - Spec.dotRadius,
                width: Spec.dotRadius * 2,
                height: Spec.dotRadius * 2
            ))
            context.fill(dot, with: .color(Spec.dotColor.opacity(Spec.opacityBehindHead[behind])))
        }
    }
}

// MARK: - 사양 (애니메이션 벤치 WCH-02, 일러스트 왼쪽 위 기준 pt)

private enum Spec {
    /// 머리가 한 바퀴 도는 시간(초): iOS 기본 스피너처럼 1초에 한 바퀴
    static let period: TimeInterval = 1.0

    /// 화면에 놓이는 크기(pt) — 기존 일러스트와 같아요
    static let frameSize = CGSize(width: 121, height: 207)

    /// 점 중심: 머리가 지나가는 순서(시계 방향)대로. 0번이 Hi-Fi에서 가장 진한 점(왼쪽 위)이에요.
    /// 시안에서 잰 화면 좌표를 일러스트 영역(왼쪽 위 = 화면 140.5, 234.6)에 맞춰 옮긴 값이에요.
    /// 점 6개의 가운데는 워치 화면의 가운데라서, 워치 몸통 가운데(영역 가로 가운데)보다 4.6pt 왼쪽이에요 (시안 그대로).
    static let dotCenters: [CGPoint] = [
        CGPoint(x: 189.66 - 140.5, y: 333.89 - 234.6), // 왼쪽 위
        CGPoint(x: 196.37 - 140.5, y: 329.97 - 234.6), // 위
        CGPoint(x: 203.07 - 140.5, y: 333.93 - 234.6), // 오른쪽 위
        CGPoint(x: 203.07 - 140.5, y: 341.53 - 234.6), // 오른쪽 아래
        CGPoint(x: 196.37 - 140.5, y: 345.50 - 234.6), // 아래
        CGPoint(x: 189.66 - 140.5, y: 341.59 - 234.6), // 왼쪽 아래
    ]
    /// 점 반지름
    static let dotRadius: CGFloat = 3.2
    static let dotColor = Color(hex: 0x01040B)
    /// 머리에서 0 ~ 5칸 뒤 점의 진하기 (Hi-Fi에서 잰 단계)
    static let opacityBehindHead: [Double] = [1.0, 0.692, 0.493, 0.3, 0.204, 0.18]
}

#Preview {
    WatchConnectingIllustration()
        .padding(40)
        .background(AppColors.darkBackground)
}
