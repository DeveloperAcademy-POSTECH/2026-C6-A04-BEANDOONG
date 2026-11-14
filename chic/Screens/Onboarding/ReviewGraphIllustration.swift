import SwiftUI

/// 온보딩 5/5 그래프 일러스트 (ONB-05, 3.6초 반복)
///
/// 그래프(선 · 아래 면)가 왼쪽부터 그려지고, 점은 드러나는 순간 톡 튀어요.
/// 마지막 큰 점은 조금 더 크게 튀고 둘레로 링이 퍼져요. 다 그려진 채 머물다 사라지고 반복해요.
///
///     0.00 ~ 1.50s  왼쪽 → 오른쪽으로 드러남 (경계 28pt 부드럽게, MotionCurve.easeInOutReveal)
///                   점마다 드러나는 순간 0.36초 동안 커졌다 돌아옴, 큰 점 둘레로 링이 0.75초 동안 퍼짐
///     2.80 ~ 3.20s  사라짐 (smoothstep)
///     3.20 ~ 3.60s  빈 채로 쉬고 반복
///
/// - 그래프는 한 장(`IllustReviewGraph`)을 마스크로 드러내고, 점은 같은 그림을 원으로 잘라 키워요. 새 레이어가 없어요.
/// - 첫 프레임은 빈 상태예요.
/// - 동작 줄이기(Reduce Motion)·`-uiTestStill`에서는 다 그려진 그림으로 멈춰 있어서 Hi-Fi와 같아요.
struct ReviewGraphIllustration: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// 그래프가 사라진 뒤 빈 채 쉬는 구간(3.2 ~ 3.6초)에 들어설 때 부를 동작 (온보딩이 홈을 이때 미리 만들어요)
    @Environment(\.loopRestAction) private var loopRestAction

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
                AssetImageView(name: Spec.imageName, width: Spec.frameSize.width, height: Spec.frameSize.height)
            } else {
                LoopTimeline(period: Spec.period) { progress in
                    let time = progress * Spec.period
                    frame(at: time)
                        .onChange(of: Spec.isResting(at: time)) { _, resting in
                            if resting { loopRestAction?() }
                        }
                }
            }
        }
        .frame(width: Spec.frameSize.width, height: Spec.frameSize.height)
        .accessibilityHidden(true)
    }

    /// 한 바퀴 안의 시간 `time`(초)의 그림
    ///
    /// Canvas 로 매 프레임 이미지를 다시 그리지 않고 이미지 · 마스크 · 원을 뷰로 두고 값만 바꿔요.
    /// - 이미지는 한 번 디코딩해 두고 GPU가 마스크 · 크기 · 투명도만 합성해서 프레임마다 가벼워요.
    /// - 첫 프레임(빈 그래프)도 이미지는 마스크에 가려 있을 뿐 화면에 올라가 있어서, 미리 만든 이웃 쪽일 때
    ///   이미지를 디코딩해 둬요. 처음 보이는 순간 디코딩이 몰려 버벅이던 문제를 막아요.
    /// - 완전히 0인 투명도는 그리기를 건너뛰어 다음에 보일 때 다시 준비하므로, 숨길 때도 `Spec.hidden`(0.001)으로 둬요.
    private func frame(at time: TimeInterval) -> some View {
        let reveal = Spec.revealCurve(time / Spec.drawDuration)
        let fade = 1 - Spec.smoothstep((time - Spec.fadeStart) / Spec.fadeDuration)
        let edge = Spec.edge(at: reveal)

        return ZStack(alignment: .topLeading) {
            // MARK: 그래프: 왼쪽부터 드러나고, 머문 뒤 사라짐
            AssetImageView(name: Spec.imageName, width: Spec.frameSize.width, height: Spec.frameSize.height)
                .mask {
                    LinearGradient(colors: [.black, .clear],
                                   startPoint: UnitPoint(x: (edge - Spec.feather) / Spec.frameSize.width, y: 0),
                                   endPoint: UnitPoint(x: edge / Spec.frameSize.width, y: 0))
                }
                .opacity(max(fade, Spec.hidden))

            // MARK: 점이 톡 튀기 (같은 그림을 원으로 잘라 키워요)
            // 점 크기만 한 상자에 그림을 옮겨 놓고 원으로 잘라요. 상자 전체를 채우는 원이라 GPU가 모서리 둥글리기로 바로 자르고,
            // 일러스트 전체 크기 마스크를 매 프레임 따로 합성하지 않아요.
            ForEach(Spec.nodes.indices, id: \.self) { index in
                let node = Spec.nodes[index]
                let b = (time - Spec.popStarts[index]) / Spec.popDuration
                let popping = b > 0 && b < 1
                let k = popping ? 1 + node.popScale * sin(.pi * b) * (1 - b * 0.3) : 1
                let clip = node.clipRect
                AssetImageView(name: Spec.imageName, width: Spec.frameSize.width, height: Spec.frameSize.height)
                    .offset(x: -clip.minX, y: -clip.minY)
                    .frame(width: clip.width, height: clip.height, alignment: .topLeading)
                    .clipShape(Circle())
                    .scaleEffect(k)
                    .position(node.center)
                    .opacity(popping ? 1 : Spec.hidden)
            }

            // MARK: 큰 점 둘레로 퍼지는 링
            // 링도 꺼진 동안 0 대신 0.001로 둬요. 0이면 미리 그려 두지 않아, 큰 점이 튀는 순간 링을 처음 만드느라 버벅였어요.
            if let last = Spec.nodes.last, let lastStart = Spec.popStarts.last {
                let rb = (time - lastStart) / Spec.Ring.duration
                let ringOn = rb > 0 && rb < 1
                // 벤치처럼 링 전체를 키워서 선 두께도 같은 비율로 굵어져요.
                let k = ringOn ? 1 + (Spec.Ring.grow / last.radius) * (1 - pow(1 - rb, 3)) : 1
                Circle()
                    .stroke(Spec.Ring.color, lineWidth: Spec.Ring.lineWidth)
                    .frame(width: last.radius * 2, height: last.radius * 2)
                    .scaleEffect(k)
                    .position(last.center)
                    .opacity(ringOn ? Spec.Ring.opacity * (1 - rb) : Spec.hidden)
            }
        }
        .frame(width: Spec.frameSize.width, height: Spec.frameSize.height, alignment: .topLeading)
        .allowsHitTesting(false)
    }
}

// MARK: - 사양 (애니메이션 벤치 ONB-05, 일러스트 왼쪽 위 기준 pt)

private enum Spec {
    static let imageName = "IllustReviewGraph"
    /// 화면에 놓이는 크기 (Hi-Fi 237)
    static let frameSize = CGSize(width: 303, height: 212)
    /// 숨긴 요소의 투명도: 0이면 그리기를 건너뛰어 다시 보일 때 준비가 몰려요. 0.001은 눈에 보이지 않아요.
    static let hidden: Double = 0.001

    /// 한 바퀴 길이 (초)
    static let period: TimeInterval = 3.6
    /// 왼쪽 → 오른쪽으로 그려지는 시간
    static let drawDuration: TimeInterval = 1.5
    /// 드러내는 경계의 부드러운 폭 (pt)
    static let feather: CGFloat = 28
    /// 다 그려진 채 머물다 사라지기 시작하는 시점 · 사라지는 시간. 끝 0.4초는 빈 채 쉬어요.
    static let fadeStart: TimeInterval = 2.8
    static let fadeDuration: TimeInterval = 0.4
    /// 점이 튀는 시간
    static let popDuration: TimeInterval = 0.36

    /// 큰 점 둘레로 퍼지는 링
    enum Ring {
        static let duration: TimeInterval = 0.75
        /// 퍼지는 거리 (pt)
        static let grow: CGFloat = 14
        static let lineWidth: CGFloat = 1.6
        static let color = Color(hex: 0xEAF5FE)
        static let opacity: Double = 0.55
    }

    struct Node {
        let center: CGPoint
        let radius: CGFloat
        /// 가장 크게 튈 때 커지는 비율
        let popScale: Double

        /// 점 안쪽만 잘라요. 반지름보다 0.4pt 안쪽을 잘라야 키울 때 가장자리에 어두운 테두리가 생기지 않아요.
        var clipRect: CGRect {
            let r = radius - 0.4
            return CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)
        }

        /// 드러내는 경계의 불투명한 쪽이 점 오른쪽 끝을 지나는 시각 (초): 이때 튀기 시작해요.
        var popStart: TimeInterval {
            let target = (center.x + radius + Spec.feather) / (Spec.frameSize.width + Spec.feather)
            var lo = 0.0
            var hi = 1.0
            for _ in 0..<30 {
                let mid = (lo + hi) / 2
                if Spec.revealCurve(mid) < target { lo = mid } else { hi = mid }
            }
            return hi * Spec.drawDuration
        }
    }

    /// 점 4개 (Hi-Fi 237에서 잰 중심 · 반지름). 마지막 큰 점은 조금 더 크게 튀어요.
    static let nodes = [
        Node(center: CGPoint(x: 76, y: 95), radius: 11, popScale: 0.2),
        Node(center: CGPoint(x: 142.5, y: 101.5), radius: 9.5, popScale: 0.2),
        Node(center: CGPoint(x: 192.75, y: 57.55), radius: 9.5, popScale: 0.2),
        Node(center: CGPoint(x: 282, y: 21), radius: 21, popScale: 0.26),
    ]

    /// 점마다 튀기 시작하는 시각 (초). 매 프레임 다시 찾지 않게 한 번만 계산해 둬요.
    static let popStarts: [TimeInterval] = nodes.map(\.popStart)

    /// 그려진 정도 (0 ~ 1). `t`는 그리는 시간 대비 진행률이에요.
    static func revealCurve(_ t: Double) -> Double {
        MotionCurve.easeInOutReveal.value(at: min(max(t, 0), 1))
    }

    /// 드러내는 경계(투명해지는 쪽)의 x
    static func edge(at reveal: Double) -> CGFloat {
        (frameSize.width + feather) * reveal
    }

    /// 다 사라지고 빈 채 쉬는 구간인지 (화면이 멈춰 있어요)
    static func isResting(at time: TimeInterval) -> Bool {
        time >= fadeStart + fadeDuration
    }

    static func smoothstep(_ t: Double) -> Double {
        let x = min(max(t, 0), 1)
        return x * x * (3 - 2 * x)
    }
}

#Preview {
    ReviewGraphIllustration()
        .padding(40)
        .background(AppColors.darkBackground)
}
