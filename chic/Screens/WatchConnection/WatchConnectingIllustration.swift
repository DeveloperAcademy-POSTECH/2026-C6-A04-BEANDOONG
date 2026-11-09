import SwiftUI

/// 연결 확인 중 일러스트 (WCH-02 원형 점 로더)
///
/// 워치 화면 가운데 점 6개 중 가장 진한 점이 시계 방향으로 한 칸씩 끊어서 넘어가고,
/// 지나간 점들은 Hi-Fi의 진하기 단계대로 옅어져요. 1초에 한 바퀴예요.
///
///          ⑥                ● 가장 진한 점(머리)이 ① → ⑥ → ⑤ → ④ → ③ → ② 순서로 이동
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
                IllustrationCanvas(pixelSize: Spec.pixelSize, frameSize: Spec.frameSize) { context in
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

// MARK: - 사양 (Hi-Fi 일러스트 실측값, 일러스트 픽셀 단위)

private enum Spec {
    /// 머리가 한 바퀴 도는 시간(초)
    static let period: TimeInterval = 1.0

    /// 화면에 놓이는 크기(pt) — 기존 일러스트와 같아요
    static let frameSize = CGSize(width: 121, height: 207)
    /// 일러스트 PNG 크기(px, 3배)
    static let pixelSize = CGSize(width: 363, height: 620)

    /// 점 중심: 머리가 지나가는 순서(시계 방향)대로. 0번이 Hi-Fi에서 가장 진한 점(왼쪽 위)이에요.
    static let dotCenters: [CGPoint] = [
        CGPoint(x: 147.3, y: 296.8), // 왼쪽 위
        CGPoint(x: 167.3, y: 285.3), // 위
        CGPoint(x: 187.3, y: 296.3), // 오른쪽 위
        CGPoint(x: 187.6, y: 320.1), // 오른쪽 아래
        CGPoint(x: 167.5, y: 331.8), // 아래
        CGPoint(x: 147.4, y: 320.1), // 왼쪽 아래
    ]
    /// 점 반지름 (약 3.3pt)
    static let dotRadius: CGFloat = 10
    static let dotColor = Color(hex: 0x01030C)
    /// 머리에서 0 ~ 5칸 뒤 점의 진하기 (Hi-Fi 점 에셋의 알파값 255 · 178 · 128 · 77 · 51 · 45)
    static let opacityBehindHead: [Double] = [1.0, 0.698, 0.502, 0.302, 0.2, 0.176]
}

#Preview {
    WatchConnectingIllustration()
        .padding(40)
        .background(AppColors.darkBackground)
}
