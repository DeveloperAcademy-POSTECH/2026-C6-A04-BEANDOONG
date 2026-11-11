import SwiftUI

/// 소리 막대 3개 일러스트 (STM-02 스티밍 시작 대기 — 막대 그라데이션 점등 · 순차 소등)
///
/// 왼쪽 막대부터 하나씩 위 → 아래로 번지듯 나타나고, 셋 다 켜진 채 잠시 머문 뒤
/// 나타난 순서대로 하나씩 위 → 아래로 녹듯이 사라져요. 화면이 열리면 모두 꺼진 상태에서 시작해요.
///
///     0.00s  모두 꺼진 채 쉼 (0.71초)
///     0.71s  막대 1 나타남 (0.47초) → 0.21초 간격으로 막대 2 · 3
///     1.61s  셋 다 켜짐 (= Hi-Fi), 0.51초 유지
///     2.12s  막대 1 사라짐 (0.56초) → 0.21초 간격으로 막대 2 · 3
///     3.11s  모두 꺼짐 → 0.3초 뒤 처음으로 (한 바퀴 3.41초)
///
/// 나타남과 사라짐은 서로 거꾸로예요. 막대 높이만큼 긴 그라데이션이 위 → 아래로 지나가면서
/// - 나타남: 위부터 차오르고, 흐림이 8pt → 0 으로 걷히고, 투명도가 0 → 1 로 올라요
/// - 사라짐: 위부터 옅어지고, 흐림이 0 → 8pt 로 번지고, 투명도가 1 → 0 으로 빠져요
///
/// - 막대는 원본 일러스트(`IllustSoundBars`)를 막대 사이 틈에서 세로로 잘라 그려요. 그래서 다 켜진 모습이 원본과 똑같고,
///   자른 뒤에 흐리게 해서 흐림이 옆 막대와 섞이지 않아요.
/// - 동작 줄이기(Reduce Motion)가 켜져 있으면 다 켜진 Hi-Fi 정지 화면으로 멈춰 있어요.
struct SoundBarsIllustration: View {
    var body: some View {
        LoopTimeline(period: BarMotion.period, restProgress: BarMotion.restProgress) { progress in
            let time = BarMotion.motionTime(progress: progress)
            ZStack {
                ForEach(Spec.bars.indices, id: \.self) { index in
                    bar(Spec.bars[index], look: BarMotion.look(index: index, time: time, bar: Spec.bars[index]))
                }
            }
            .frame(width: Spec.frameSize.width, height: Spec.frameSize.height)
        }
        .accessibilityHidden(true)
    }

    private func bar(_ bar: Spec.Bar, look: BarLook) -> some View {
        AssetImageView(name: "IllustSoundBars", width: Spec.frameSize.width, height: Spec.frameSize.height)
            // 이 막대가 있는 세로 띠만 남겨요
            .mask(alignment: .topLeading) {
                Rectangle()
                    .frame(width: bar.columnEnd - bar.columnStart, height: Spec.frameSize.height)
                    .offset(x: bar.columnStart)
            }
            // 흐림이 잘리지 않게 둘레를 넓힌 뒤 흐리게 하고, 그 위에 위 → 아래 그라데이션을 씌워요 (벤치와 같은 순서)
            .padding(Spec.blurRoom)
            .blur(radius: look.blur)
            .mask {
                LinearGradient(
                    colors: [.black, .clear],
                    startPoint: UnitPoint(x: 0.5, y: Spec.unitY(look.opaqueEdge)),
                    endPoint: UnitPoint(x: 0.5, y: Spec.unitY(look.clearEdge))
                )
            }
            .opacity(look.opacity)
    }
}

// MARK: - 한 순간의 막대 모습

private struct BarLook {
    /// 그라데이션에서 완전히 보이는 쪽 끝 (일러스트 안 y, pt)
    var opaqueEdge: CGFloat
    /// 그라데이션에서 완전히 안 보이는 쪽 끝 (일러스트 안 y, pt)
    var clearEdge: CGFloat
    var blur: CGFloat
    var opacity: Double

    /// 모두 꺼짐
    static let hidden = BarLook(opaqueEdge: 0, clearEdge: 1, blur: 0, opacity: 0)
    /// 다 켜짐 (= Hi-Fi). 그라데이션이 막대 아래로 완전히 지나가서 막대 전체가 보여요.
    static let lit = BarLook(opaqueEdge: Spec.frameSize.height * 2, clearEdge: Spec.frameSize.height * 3, blur: 0, opacity: 1)
}

// MARK: - 타이밍

/// 값은 애니메이션 벤치(Animation Bench) STM-02 "순차 소등" 시안의 `BAR_FILL` 과 같아요.
///
/// 벤치는 동작을 3.15초 기준(ms)으로 적어 두고, 그걸 길이 2.7초로 줄여서(0.86배) 재생해요.
/// 그리고 한 바퀴마다 앞에 0.71초를 쉬어요. 여기서도 같은 방식으로 계산해요.
private enum BarMotion {
    /// 동작 값의 기준 길이 (벤치 `modes.seq.base`)
    static let base: TimeInterval = 3.15
    /// 실제로 재생하는 길이 (벤치 길이 2700ms)
    static let duration: TimeInterval = 2.7
    /// 한 바퀴를 시작하기 전에 꺼진 채 쉬는 시간 (벤치 지연 710ms)
    static let delay: TimeInterval = 0.71
    /// 한 바퀴 길이 (3.41초)
    static let period: TimeInterval = delay + duration

    // 아래는 기준 길이(3.15초) 안의 시간이에요.
    /// 막대 사이 나타나는 간격
    static let step: TimeInterval = 0.25
    /// 막대 하나가 나타나는 시간
    static let fill: TimeInterval = 0.55
    /// 셋 다 켜진 채 0.6초 머문 뒤 사라지기 시작하는 시점
    static let offAt: TimeInterval = 1.65
    /// 막대 사이 사라지는 간격 (나타난 순서대로)
    static let offStep: TimeInterval = 0.25
    /// 막대 하나가 사라지는 시간. 다 사라지면 0.35초 쉬어요.
    static let off: TimeInterval = 0.65
    /// 가장 흐릴 때의 흐림 (pt, 402pt 화면 기준). 나타나기 시작할 때 · 다 사라질 때
    static let maxBlur: CGFloat = 8

    /// 동작 줄이기에서 멈춰 둘 지점: 셋 다 켜진 채 사라지기 직전 (= Hi-Fi 정지 화면)
    static let restProgress: Double = (delay + (offAt - 0.1) / base * duration) / period

    /// 한 바퀴 진행률(0 이상 1 미만) → 기준 길이 안의 시간(초). 쉬는 동안은 0이에요.
    static func motionTime(progress: Double) -> TimeInterval {
        let played = max(0, progress * period - delay)
        return min(played / duration, 0.9999) * base
    }

    /// `index`번째(0부터, 왼쪽부터) 막대의 모습. `time` 은 기준 길이 안의 시간(초)이에요.
    static func look(index: Int, time: TimeInterval, bar: Spec.Bar) -> BarLook {
        let order = Double(index)
        let height = bar.bottom - bar.top
        // 그라데이션 길이 = 막대 높이. 그래서 그라데이션이 지나가는 거리는 막대 높이의 2배예요.
        let travel = height * 2

        let fading = smooth(clamp01((time - offAt - order * offStep) / off))
        if fading >= 1 { return .hidden }
        if fading > 0 {
            // 그라데이션이 위 → 아래로 쓸고 지나가요: 위쪽부터 옅어지며 흐림이 번지고 전체 투명도도 빠져요
            let clearEdge = bar.top - height + travel * fading
            return BarLook(
                opaqueEdge: clearEdge + height,
                clearEdge: clearEdge,
                blur: maxBlur * fading,
                opacity: 1 - smooth(clamp01((fading - 0.1) / 0.9))
            )
        }

        // 사라짐을 거꾸로: 그라데이션이 위 → 아래로 차오르며 흐림이 걷히고 투명도가 올라요
        let filling = easeOutQuad(clamp01((time - order * step) / fill))
        if filling <= 0 { return .hidden }
        if filling >= 1 { return .lit }
        let clearEdge = bar.top + travel * filling
        return BarLook(
            opaqueEdge: clearEdge - height,
            clearEdge: clearEdge,
            blur: maxBlur * (1 - filling),
            opacity: smooth(clamp01(filling / 0.9))
        )
    }

    private static func clamp01(_ value: Double) -> Double { min(max(value, 0), 1) }
    /// 처음과 끝이 부드러운 곡선 (smoothstep)
    private static func smooth(_ value: Double) -> Double { value * value * (3 - 2 * value) }
    /// 빠르게 출발해 부드럽게 멈춤
    private static func easeOutQuad(_ value: Double) -> Double { 1 - (1 - value) * (1 - value) }
}

// MARK: - 사양

private enum Spec {
    /// 화면에 놓이는 크기(pt). 원본 이미지 `IllustSoundBars` 는 360×544px(4배)예요.
    static let frameSize = CGSize(width: 90, height: 136)
    /// 흐림이 잘리지 않게 막대 둘레에 두는 여유 (가장 큰 흐림의 3배)
    static let blurRoom: CGFloat = BarMotion.maxBlur * 3

    struct Bar {
        /// 이 막대만 남기는 세로 띠의 왼쪽 · 오른쪽 x (이웃 막대와의 틈 한가운데)
        let columnStart: CGFloat
        let columnEnd: CGFloat
        /// 막대가 실제로 보이는 위 · 아래 y
        let top: CGFloat
        let bottom: CGFloat
    }

    /// 왼쪽부터. 원본 이미지에서 잰 값(px ÷ 4): 막대 x 0~16.5 · 23.5~48.75 · 57~90, y 39.75~96 · 17~119.25 · 0~136
    static let bars = [
        Bar(columnStart: 0, columnEnd: 20, top: 39.75, bottom: 96),
        Bar(columnStart: 20, columnEnd: 53, top: 17, bottom: 119.25),
        Bar(columnStart: 53, columnEnd: 90, top: 0, bottom: 136),
    ]

    /// 일러스트 안 y(pt) → 흐림 여유까지 넓힌 상자 안의 0~1 위치
    static func unitY(_ y: CGFloat) -> CGFloat {
        (y + blurRoom) / (frameSize.height + blurRoom * 2)
    }
}

#Preview {
    SoundBarsIllustration()
        .padding(40)
        .background(AppColors.darkBackground)
}
