import SwiftUI

/// 소리 파동 일러스트 (ONB-02 소리 감지 아이콘 · ONB-03 공기주입 일러스트)
///
/// 코어 구 뒤에서 원형 파동이 생겨 바깥으로 퍼지다가 Hi-Fi의 바깥 링을 지나면서 옅어지고,
/// 파동 선의 마루도 파동과 같은 속도로 바깥으로 흘러요. 한 주기 4초예요.
///
///        ╭───╮
///      ╭─┼ ● ┼─╮      ← 원형 파동 4개가 같은 간격으로 계속 퍼짐
///     ~~~~ ● ~~~~     ← 파동 선: 마루가 양옆으로 흘러감
///
///     ┌ 아래: 원형 파동 + 파동 선 (코드로 그림)
///     └ 위:   베이스 이미지 (코어 구, ONB-02는 스팀 머신까지) — 파동이 코어 뒤로 지나가요
///
/// - 파동 4개가 같은 간격으로 돌아서, 첫 프레임은 Hi-Fi의 링 3개와 같아요 (4번째는 코어 뒤에 숨어 있어요).
/// - 새 파동은 코어 뒤에서 나오는 동안 서서히 나타나요 (코어가 링 중심보다 조금 아래라 위쪽이 먼저 삐져나오지 않게).
/// - 파동 선의 파장 = 파동이 한 주기에 퍼지는 거리라서, 선의 마루가 파동과 같은 속도로 움직여요.
/// - 링·선 색은 원본 일러스트처럼 일러스트 전체에 깔린 위 → 아래 그라데이션을 써요.
/// - 동작 줄이기(Reduce Motion)가 켜져 있으면 Hi-Fi 정지 화면으로 멈춰 있어요.
struct SoundRippleIllustration: View {
    let spec: SoundRippleSpec

    var body: some View {
        ZStack {
            LoopTimeline(period: SoundRippleSpec.period) { progress in
                IllustrationCanvas(pixelSize: spec.pixelSize, frameSize: spec.frameSize, overflow: spec.overflow) { context in
                    let paint = spec.gradientShading
                    drawRings(in: &context, progress: progress, paint: paint)
                    drawWave(in: &context, progress: progress, paint: paint)
                }
            }

            AssetImageView(name: spec.baseImage, width: spec.frameSize.width, height: spec.frameSize.height)
        }
        .accessibilityHidden(true)
    }

    // MARK: 원형 파동

    private func drawRings(in context: inout GraphicsContext, progress: Double, paint: GraphicsContext.Shading) {
        let shape = spec.shape
        for index in 0..<SoundRippleSpec.ringCount {
            // 같은 간격으로 놓인 파동이 progress 만큼 바깥으로 퍼진 반지름
            let phase = (progress + Double(index) / Double(SoundRippleSpec.ringCount)).truncatingRemainder(dividingBy: 1)
            let radius = shape.ringStartRadius + shape.ringTravel * phase
            // 코어 뒤에서 나오는 동안 서서히 나타나고, Hi-Fi 바깥 링을 지나면서 옅어짐
            let appear = smoothstep((radius - shape.ringAppearStartRadius) / (shape.ringAppearEndRadius - shape.ringAppearStartRadius))
            let fade = smoothstep((radius - shape.ringFadeStartRadius) / (shape.ringEndRadius - shape.ringFadeStartRadius))
            let opacity = appear * (1 - fade)
            guard opacity > 0 else { continue }

            let ring = Path(ellipseIn: CGRect(
                x: spec.center.x - radius, y: spec.center.y - radius,
                width: radius * 2, height: radius * 2
            ))
            var ringContext = context
            ringContext.opacity = opacity
            ringContext.stroke(ring, with: paint, lineWidth: spec.ringLineWidth)
        }
    }

    // MARK: 파동 선

    /// 가운데에서 양옆으로 대칭인 물결. 마루가 `crestDistance`에 있고, 끝(`tailDistance`)으로 갈수록 일자로 잦아들어요.
    private func drawWave(in context: inout GraphicsContext, progress: Double, paint: GraphicsContext.Shading) {
        let shape = spec.shape
        let phase = 2 * Double.pi * progress
        var wave = Path()
        var x = spec.center.x - shape.tailDistance
        while x <= spec.center.x + shape.tailDistance {
            let distance = abs(x - spec.center.x)
            let envelope = distance <= shape.crestDistance
                ? 1
                : smoothstep((shape.tailDistance - distance) / (shape.tailDistance - shape.crestDistance))
            let wavePhase = 2 * Double.pi * Double(distance - shape.crestDistance) / Double(shape.ringTravel) - phase
            let y = spec.center.y + shape.amplitude - shape.amplitude * envelope * CGFloat(cos(wavePhase))
            if wave.isEmpty { wave.move(to: CGPoint(x: x, y: y)) } else { wave.addLine(to: CGPoint(x: x, y: y)) }
            x += SoundRippleSpec.waveSampleStep
        }
        context.stroke(wave, with: paint, style: StrokeStyle(lineWidth: spec.waveLineWidth, lineCap: .round, lineJoin: .round))
    }

    private func smoothstep(_ value: CGFloat) -> CGFloat {
        let t = min(max(value, 0), 1)
        return t * t * (3 - 2 * t)
    }
}

// MARK: - 사양

/// 소리 파동 일러스트 한 장의 사양 (Hi-Fi 일러스트 실측값, 일러스트 픽셀 단위)
struct SoundRippleSpec {
    /// 위에 덮는 베이스 이미지 (코어 구 포함)
    let baseImage: String
    /// 화면에 놓이는 크기(pt) — 기존 일러스트와 같아요
    let frameSize: CGSize
    /// 일러스트 PNG 크기(px, 3배)
    let pixelSize: CGSize
    /// 원형 파동과 파동 선의 중심
    let center: CGPoint
    /// ONB-03 일러스트 대비 크기 비율 (ONB-03 = 1)
    let scale: CGFloat
    let ringLineWidth: CGFloat
    let waveLineWidth: CGFloat
    /// 일러스트 맨 위 · 맨 아래 색 (원본 일러스트에 깔린 세로 그라데이션)
    let topColor: Color
    let bottomColor: Color
    /// 파동이 일러스트 영역 밖으로 퍼져도 잘리지 않게 둘 여백(pt)
    let overflow: CGFloat

    /// 한 주기(초)
    static let period: TimeInterval = 4.0
    /// 동시에 퍼지는 원형 파동 수
    static let ringCount = 4
    /// 파동 선을 그릴 때 가로 간격(px)
    static let waveSampleStep: CGFloat = 1.5

    /// ONB-03 기준 치수(px)에 `scale`을 곱한 값
    var shape: Dimensions { Dimensions(scale: scale) }

    struct Dimensions {
        let scale: CGFloat
        /// 파동이 생기는 반지름 (코어 뒤)
        var ringStartRadius: CGFloat { 76.5 * scale }
        /// 파동이 다 사라지는 반지름
        var ringEndRadius: CGFloat { 274.5 * scale }
        /// 코어 뒤에서 나오며 나타나기 시작하는 반지름 / 다 나타나는 반지름.
        /// 코어 구가 링 중심보다 조금 아래에 있어서, 링이 코어 위쪽으로 먼저 삐져나와 눈썹처럼 보이지 않게 이 구간에서 서서히 나타나요.
        /// 다 나타나는 반지름은 Hi-Fi 안쪽 링(126px)보다 작아서 첫 프레임은 Hi-Fi와 같아요.
        var ringAppearStartRadius: CGFloat { 90 * scale }
        var ringAppearEndRadius: CGFloat { 115 * scale }
        /// 옅어지기 시작하는 반지름 = Hi-Fi 바깥 링
        var ringFadeStartRadius: CGFloat { 225 * scale }
        /// 한 주기에 퍼지는 거리 = 파동 선의 파장
        var ringTravel: CGFloat { ringEndRadius - ringStartRadius }
        /// 파동 선 마루(첫 프레임)가 있는 중심 거리
        var crestDistance: CGFloat { 243 * scale }
        /// 파동 선이 일자로 잦아드는 중심 거리
        var tailDistance: CGFloat { 330 * scale }
        /// 파동 선 높이
        var amplitude: CGFloat { 36 * scale }
    }

    var gradientShading: GraphicsContext.Shading {
        .linearGradient(
            Gradient(colors: [topColor, bottomColor]),
            startPoint: CGPoint(x: 0, y: 0),
            endPoint: CGPoint(x: 0, y: pixelSize.height)
        )
    }

    /// ONB-02 스팀 머신 옆 소리 감지 아이콘
    static let machineSound = SoundRippleSpec(
        baseImage: "IllustMachineSoundBase",
        frameSize: CGSize(width: 251, height: 199),
        pixelSize: CGSize(width: 753, height: 596),
        center: CGPoint(x: 613.6, y: 254.8),
        scale: 91 / 225, // 바깥 링 반지름 ONB-02 91px : ONB-03 225px
        ringLineWidth: 8.4,
        waveLineWidth: 8.4,
        topColor: Color(red: 244 / 255, green: 250 / 255, blue: 255 / 255),
        bottomColor: Color(red: 195 / 255, green: 231 / 255, blue: 250 / 255),
        overflow: 8
    )

    /// ONB-03 공기주입 일러스트
    static let soundWave = SoundRippleSpec(
        baseImage: "IllustSoundWaveCore",
        frameSize: CGSize(width: 219, height: 153),
        pixelSize: CGSize(width: 656, height: 459),
        center: CGPoint(x: 327.5, y: 229.5),
        scale: 1,
        ringLineWidth: 9,
        waveLineWidth: 9,
        topColor: Color(red: 245 / 255, green: 249 / 255, blue: 254 / 255),
        bottomColor: Color(red: 197 / 255, green: 232 / 255, blue: 250 / 255),
        overflow: 24
    )
}

#Preview("ONB-02") {
    SoundRippleIllustration(spec: .machineSound)
        .padding(40)
        .background(AppColors.darkBackground)
}

#Preview("ONB-03") {
    SoundRippleIllustration(spec: .soundWave)
        .padding(40)
        .background(AppColors.darkBackground)
}
