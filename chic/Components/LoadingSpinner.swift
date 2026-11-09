import SwiftUI

/// 로딩 스피너 (STM-01) — 소리 확인 중 화면과 연습 결과 로딩 화면이 같이 써요
///
/// 원 위 12칸에 놓인 점은 제자리에 있고, 크기 배치(가장 큰 점 → 양쪽으로 작아짐 → 빈 칸)만
/// 시계 방향으로 부드럽게 흘러서 빈 칸이 한 바퀴 돌아요.
///
///         ∘ ○ ◯                    ∘ ○ ◯
///       ○       ∘                ○       ∘
///      ◯    →         (빈 칸이 시계 방향으로 이동)
///       ○       ∘
///         ∘ ○ ◯
///
/// - 점은 이미지가 아니라 벡터로 그려서 테두리가 깨지지 않아요.
/// - 점마다 위 → 아래 그라데이션이 들어 있고, 점이 돌지 않으니 그라데이션 방향도 항상 위 → 아래예요.
/// - 레이아웃 크기는 기존 일러스트(`IllustSpinner`, 62×70)와 같아서 화면 배치가 바뀌지 않아요.
struct LoadingSpinner: View {
    var body: some View {
        LoopTimeline(period: SpinnerMotion.period) { progress in
            Canvas { context, _ in
                drawDots(in: &context, progress: progress)
            }
            .frame(width: SpinnerGeometry.canvasSize, height: SpinnerGeometry.canvasSize)
        }
        // 캔버스는 점이 잘리지 않게 넉넉히 그리고, 레이아웃은 기존 일러스트 크기만 차지해요.
        .frame(width: SpinnerGeometry.layoutSize.width, height: SpinnerGeometry.layoutSize.height)
        .accessibilityHidden(true)
    }

    /// 크기 배치가 `progress`만큼 시계 방향으로 흐른 상태로 점 12개를 그려요.
    private func drawDots(in context: inout GraphicsContext, progress: Double) {
        let slotCount = SpinnerGeometry.slotCount
        // 가장 큰 점이 지금 있는 칸 (소수: 칸 사이를 부드럽게 지나감)
        let headSlot = Double(slotCount) * progress

        for slot in 0..<slotCount {
            let radius = SpinnerGeometry.dotRadius(atDistance: circularDistance(Double(slot), headSlot, count: slotCount))
            guard radius > SpinnerGeometry.hiddenRadius else { continue }

            let center = SpinnerGeometry.position(ofSlot: slot)
            let dotRect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
            context.fill(
                Path(ellipseIn: dotRect),
                with: .linearGradient(
                    SpinnerGeometry.dotGradient,
                    startPoint: CGPoint(x: dotRect.midX, y: dotRect.minY),
                    endPoint: CGPoint(x: dotRect.midX, y: dotRect.maxY)
                )
            )
        }
    }

    /// 원 위 두 칸 사이의 거리 (시계·반시계 중 가까운 쪽, 0 ... count/2)
    private func circularDistance(_ a: Double, _ b: Double, count: Int) -> Double {
        let n = Double(count)
        let forward = (a - b).truncatingRemainder(dividingBy: n)
        let wrapped = forward < 0 ? forward + n : forward
        return min(wrapped, n - wrapped)
    }
}

// MARK: - 타이밍

private enum SpinnerMotion {
    /// 빈 칸이 한 바퀴 도는 시간(초)
    static let period: TimeInterval = 1.4
}

// MARK: - 모양 (Hi-Fi 스피너 실측값, pt)

private enum SpinnerGeometry {
    /// 화면 레이아웃에서 차지하는 크기 (기존 일러스트와 같음)
    static let layoutSize = CGSize(width: 62, height: 70)
    /// 점이 레이아웃 밖으로 조금 나가도 잘리지 않도록 넉넉히 잡은 캔버스 크기
    static let canvasSize: CGFloat = 84

    /// 원 위에 점이 놓이는 칸 수
    static let slotCount = 12
    /// 점 중심이 놓이는 원의 반지름
    static let ringRadius: CGFloat = 29
    /// 레이아웃 영역 왼쪽 위 기준, 점이 놓인 원의 중심.
    /// 가장 큰 점이 왼쪽에 있어서 원의 중심이 영역 가운데보다 조금 오른쪽에 있어요.
    static let ringCenterInLayout = CGPoint(x: 37.6, y: 35)

    /// 가장 큰 점에서 몇 칸 떨어졌는지에 따른 점 반지름 (0칸 ... 6칸 = 빈 칸)
    static let radiusByDistance: [CGFloat] = [8.02, 6.72, 5.82, 5.12, 3.92, 2.91, 0]
    /// 이보다 작은 점은 그리지 않아요 (빈 칸 근처에서 아주 작은 점이 깜빡이지 않게)
    static let hiddenRadius: CGFloat = 0.2

    /// 점 하나의 위 → 아래 색
    static let dotGradient = Gradient(colors: [Color(hex: 0x78CBF2), Color(hex: 0xEEF7FE)])

    /// 칸 사이 거리(소수 가능)에 맞는 점 반지름: 이웃한 두 값 사이를 이어서 크기가 부드럽게 바뀌어요.
    static func dotRadius(atDistance distance: Double) -> CGFloat {
        let lastIndex = radiusByDistance.count - 1
        let clamped = min(max(distance, 0), Double(lastIndex))
        let lower = Int(clamped.rounded(.down))
        let upper = min(lower + 1, lastIndex)
        let fraction = CGFloat(clamped - Double(lower))
        return radiusByDistance[lower] + (radiusByDistance[upper] - radiusByDistance[lower]) * fraction
    }

    /// 캔버스 좌표에서 `slot`번째 칸의 점 중심. 0번 칸이 왼쪽(9시)이고, 번호가 커질수록 시계 방향이에요.
    static func position(ofSlot slot: Int) -> CGPoint {
        let angle = Double.pi + 2 * Double.pi * Double(slot) / Double(slotCount)
        // 캔버스가 레이아웃 영역보다 커서, 두 영역의 가운데를 맞춘 만큼 옮겨 줘요.
        let canvasOrigin = CGPoint(
            x: (layoutSize.width - canvasSize) / 2,
            y: (layoutSize.height - canvasSize) / 2
        )
        return CGPoint(
            x: ringCenterInLayout.x - canvasOrigin.x + ringRadius * cos(angle),
            y: ringCenterInLayout.y - canvasOrigin.y + ringRadius * sin(angle)
        )
    }
}

#Preview {
    LoadingSpinner()
        .padding(40)
        .background(AppColors.darkBackground)
}
