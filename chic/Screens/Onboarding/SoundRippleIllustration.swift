import SwiftUI

/// 소리 파동 일러스트 (ONB-03 공기주입 일러스트)
///
/// 코어 구 뒤에서 원형 파동이 끊임없이 생겨 바깥으로 퍼지다가 Hi-Fi의 바깥 링을 지나면서 옅어져요.
/// 파동 선은 Hi-Fi 모양 그대로 고정이에요. 1초마다 파동이 하나씩 생겨 4초 동안 퍼지는 한 주기가 반복돼요.
///
///        ╭───╮
///      ╭─┼ ● ┼─╮      ← 원형 파동 4개가 1초 간격으로 계속 퍼짐
///     ~~~~ ● ~~~~     ← 파동 선: 고정 (Hi-Fi 모양)
///
///     캔버스: 원형 파동 + 파동 선 → 그 위에 코어 구 (모두 코드로 그림) — 파동이 코어 뒤로 지나가요
///
/// - 값은 애니메이션 벤치(ONB-03)와 같아요: 파동 반지름 25.5 → 91.5pt, 75pt부터 옅어짐, 선 두께 2.7pt, 파동 선 3pt.
/// - 파동 4개가 같은 간격으로 돌아서 첫 프레임은 Hi-Fi의 링 3개와 같아요 (나머지 하나는 코어 뒤에 숨어 있어요).
/// - 원본 시안은 코어 구가 링 중심보다 약 2pt 아래에 있어서, 코어 · 링 · 파동 선을 화면 가로 가운데의 한 중심에 맞춰 그려요.
/// - 링·선·코어 색은 시안처럼 일러스트 전체에 깔린 위 → 아래 세로 그라데이션을 써요.
/// - 동작 줄이기(Reduce Motion)가 켜져 있으면 Hi-Fi 정지 화면으로 멈춰 있어요.
struct SoundRippleIllustration: View {
    var body: some View {
        LoopTimeline(period: Spec.period) { progress in
            IllustrationCanvas(pixelSize: Spec.frameSize, frameSize: Spec.frameSize, overflow: Spec.overflow,
                               rendersAsynchronously: true) { context in
                let paint = Spec.gradientShading
                drawRings(in: &context, progress: progress, paint: paint)
                drawWave(in: &context, paint: paint)
                drawCore(in: &context, paint: paint)
            }
        }
        .accessibilityHidden(true)
    }

    // MARK: 원형 파동

    private func drawRings(in context: inout GraphicsContext, progress: Double, paint: GraphicsContext.Shading) {
        for index in 0..<Spec.ringCount {
            // 같은 간격으로 놓인 파동이 progress 만큼 바깥으로 퍼진 반지름
            let phase = (progress + Double(index) / Double(Spec.ringCount)).truncatingRemainder(dividingBy: 1)
            let radius = Spec.ringStartRadius + Spec.ringTravel * phase
            // Hi-Fi 바깥 링을 지나면서 옅어짐
            let fade = smoothstep((radius - Spec.ringFadeStartRadius) / (Spec.ringEndRadius - Spec.ringFadeStartRadius))
            let opacity = 1 - fade
            guard opacity > 0 else { continue }

            let ring = Path(ellipseIn: CGRect(
                x: Spec.center.x - radius, y: Spec.center.y - radius,
                width: radius * 2, height: radius * 2
            ))
            var ringContext = context
            ringContext.opacity = opacity
            ringContext.stroke(ring, with: paint, lineWidth: Spec.ringLineWidth)
        }
    }

    // MARK: 파동 선 (고정)

    private func drawWave(in context: inout GraphicsContext, paint: GraphicsContext.Shading) {
        context.stroke(Spec.wavePath, with: paint, style: StrokeStyle(lineWidth: Spec.waveLineWidth, lineCap: .round, lineJoin: .round))
    }

    // MARK: 코어 구

    /// 파동과 선을 덮는 코어 구. 파동과 같은 중심에 그려 동심원이 돼요.
    private func drawCore(in context: inout GraphicsContext, paint: GraphicsContext.Shading) {
        let radius = Spec.coreRadius
        let core = Path(ellipseIn: CGRect(
            x: Spec.center.x - radius, y: Spec.center.y - radius,
            width: radius * 2, height: radius * 2
        ))
        context.fill(core, with: paint)
    }

    private func smoothstep(_ value: CGFloat) -> CGFloat {
        let t = min(max(value, 0), 1)
        return t * t * (3 - 2 * t)
    }
}

// MARK: - 사양 (애니메이션 벤치 ONB-03, 일러스트 왼쪽 위 기준 pt)

private enum Spec {
    /// 화면에 놓이는 크기(pt) — 기존 일러스트와 같아요
    static let frameSize = CGSize(width: 219, height: 153)
    /// 파동이 일러스트 영역 밖으로 퍼져도 잘리지 않게 둘 여백(pt)
    static let overflow: CGFloat = 24

    /// 한 주기(초) = 파동 하나가 퍼지는 시간. 4개가 1초 간격으로 돌아요.
    static let period: TimeInterval = 4.0
    /// 동시에 퍼지는 원형 파동 수
    static let ringCount = 4

    /// 원형 파동 · 파동 선 · 코어 구의 중심.
    /// 시안에서 잰 중심(화면 가로 가운데 201, 세로 299.3)을 일러스트 영역(왼쪽 위 = 화면 91.5, 223) 기준으로 옮긴 값이에요.
    static let center = CGPoint(x: 201 - 91.5, y: 299.3 - 223)
    /// 코어 구 반지름
    static let coreRadius: CGFloat = 28.55

    /// 파동이 생기는 반지름 (코어 뒤) · 다 사라지는 반지름 · 옅어지기 시작하는 반지름 (= Hi-Fi 바깥 링)
    static let ringStartRadius: CGFloat = 25.5
    static let ringEndRadius: CGFloat = 91.5
    static let ringFadeStartRadius: CGFloat = 75
    /// 한 주기에 퍼지는 거리
    static var ringTravel: CGFloat { ringEndRadius - ringStartRadius }

    static let ringLineWidth: CGFloat = 2.7
    static let waveLineWidth: CGFloat = 3

    /// 일러스트 위 · 아래 색 (시안에 깔린 세로 그라데이션: 화면 y 224 → 374.5)
    static let topColor = Color(hex: 0xF6FAFF)
    static let bottomColor = Color(hex: 0xC6E8FA)
    static let gradientShading: GraphicsContext.Shading =
        .linearGradient(
            Gradient(colors: [topColor, bottomColor]),
            startPoint: CGPoint(x: 0, y: 224 - 223),
            endPoint: CGPoint(x: 0, y: 374.5 - 223)
        )

    /// 파동 선 경로 (고정이라 한 번만 만들어 둬요)
    static let wavePath: Path = {
        var wave = Path()
        for side in [waveLeft, waveRight] {
            for (index, offset) in side.enumerated() {
                let point = CGPoint(x: center.x + offset.x, y: center.y + offset.y)
                if index == 0 { wave.move(to: point) } else { wave.addLine(to: point) }
            }
        }
        return wave
    }()

    /// 파동 선: 중심에서 본 위치(pt). 시안의 선을 1pt 간격으로 따라 그린 점이에요 (왼쪽 · 오른쪽 선이 따로예요).
    static let waveLeft: [CGPoint] = points([
            (-107.40, 11.70), (-106.40, 11.54), (-105.40, 11.37), (-104.40, 11.18), (-103.40, 10.98), (-102.40, 10.60),
            (-101.40, 10.20), (-100.40, 9.73), (-99.40, 9.24), (-98.40, 8.70), (-97.40, 8.13), (-96.40, 7.51),
            (-95.40, 6.86), (-94.40, 6.21), (-93.40, 5.54), (-92.40, 4.86), (-91.40, 4.23), (-90.40, 3.63),
            (-89.40, 3.07), (-88.40, 2.57), (-87.40, 2.11), (-86.40, 1.73), (-85.40, 1.42), (-84.40, 1.16),
            (-83.40, 0.94), (-82.40, 0.80), (-81.40, 0.71), (-80.40, 0.71), (-79.40, 0.79), (-78.40, 0.94),
            (-77.40, 1.12), (-76.40, 1.38), (-75.40, 1.71), (-74.40, 2.09), (-73.40, 2.55), (-72.40, 3.07),
            (-71.40, 3.67), (-70.40, 4.33), (-69.40, 5.09), (-68.40, 5.94), (-67.40, 6.86), (-66.40, 7.83),
            (-65.40, 8.88), (-64.40, 9.98), (-63.40, 11.24), (-62.40, 12.51), (-61.40, 13.71), (-60.40, 14.82),
            (-59.40, 15.88), (-58.40, 16.89), (-57.40, 17.81), (-56.40, 18.64), (-55.40, 19.36), (-54.40, 20.01),
            (-53.40, 20.68), (-52.40, 21.32), (-51.40, 21.94), (-50.40, 22.49), (-49.40, 22.99), (-48.40, 23.42),
            (-47.40, 23.79), (-46.40, 24.02), (-45.40, 24.11), (-44.40, 24.11), (-43.40, 24.04), (-42.40, 24.01),
            (-41.40, 23.80), (-40.40, 23.36), (-39.40, 22.69), (-38.40, 21.94), (-37.40, 21.13), (-36.40, 20.14),
            (-35.40, 18.95), (-34.40, 17.48), (-33.40, 15.77), (-32.40, 14.30), (-31.40, 13.62), (-30.40, 12.95),
            (-29.40, 12.09), (-28.40, 11.12), (-24.40, 7.93)
    ])
    static let waveRight: [CGPoint] = points([
            (108.10, 11.48), (107.10, 11.29), (106.10, 11.08), (105.10, 10.87), (104.10, 10.64), (103.10, 10.19),
            (102.10, 9.71), (101.10, 9.23), (100.10, 8.70), (99.10, 8.14), (98.10, 7.55), (97.10, 6.96),
            (96.10, 6.35), (95.10, 5.73), (94.10, 5.13), (93.10, 4.54), (92.10, 3.96), (91.10, 3.42),
            (90.10, 2.91), (89.10, 2.45), (88.10, 2.04), (87.10, 1.69), (86.10, 1.39), (85.10, 1.16),
            (84.10, 0.98), (83.10, 0.85), (82.10, 0.83), (81.10, 0.87), (80.10, 0.99), (79.10, 1.17),
            (78.10, 1.39), (77.10, 1.66), (76.10, 1.97), (75.10, 2.41), (74.10, 2.94), (73.10, 3.52),
            (72.10, 4.19), (71.10, 4.94), (70.10, 5.80), (69.10, 6.74), (68.10, 7.79), (67.10, 8.89),
            (66.10, 9.99), (65.10, 11.14), (64.10, 12.32), (63.10, 13.57), (62.10, 14.95), (61.10, 16.27),
            (60.10, 17.48), (59.10, 18.57), (58.10, 19.58), (57.10, 20.47), (56.10, 21.25), (55.10, 21.92),
            (54.10, 22.44), (53.10, 22.88), (52.10, 23.31), (51.10, 23.71), (50.10, 24.07), (49.10, 24.38),
            (48.10, 24.62), (47.10, 24.79), (46.10, 24.85), (45.10, 24.71), (44.10, 24.45), (43.10, 24.21),
            (42.10, 23.80), (41.10, 23.12), (40.10, 22.20), (39.10, 21.24), (38.10, 20.26), (37.10, 19.11),
            (36.10, 17.77), (35.10, 16.20), (34.10, 14.62), (33.10, 13.83), (32.10, 13.16), (31.10, 12.56),
            (30.10, 11.70), (26.10, 8.78)
    ])

    private static func points(_ offsets: [(CGFloat, CGFloat)]) -> [CGPoint] {
        offsets.map { CGPoint(x: $0.0, y: $0.1) }
    }
}

#Preview("ONB-03") {
    SoundRippleIllustration()
        .padding(40)
        .background(AppColors.darkBackground)
}
