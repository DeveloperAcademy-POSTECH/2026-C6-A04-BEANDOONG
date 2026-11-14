import CoreGraphics
import Foundation

/// 온보딩 4/5 우유 피처(ONB-04)의 한 바퀴(3.4초)를 미리 계산한 표
///
/// 연습 화면(`SteamingFeedbackView`)과 같은 방식으로 움직여요.
///
///     0.00 ~ 1.60s  공기 주입: 목표 수위가 위 점선까지 일정하게 오르고 잔물결이 켜짐
///     1.60 ~ 2.20s  목표 수위 유지, 잔물결이 0.6초에 걸쳐 잦아듦
///     2.20 ~ 2.65s  원래 높이로 내려감 (smoothstep). 반복을 위한 부분이라 연습 화면에는 없어요
///     2.65 ~ 3.40s  수위가 원래 높이로 거의 다 내려온 채 다음 바퀴로 이어짐 (원래 높이보다 약 0.8pt 위, 벤치와 같음)
///
/// - 수위·잔물결 세기는 앱의 `SmoothFollower`(임계 감쇠 스프링)로 1/240초마다 계산해요.
///   스프링은 목표에 천천히 붙어서 한 바퀴만 돌리면 끝 수위가 시작보다 조금 낮아요.
///   그래서 세 바퀴를 이어 돌리고 마지막 바퀴를 저장해, 끝이 다음 바퀴의 시작과 그대로 이어지게 해요.
/// - 표에서 꺼내 쓰기 때문에 언제 봐도 같은 시점에는 같은 프레임이 나와요.
/// - 값은 애니메이션 벤치 ONB-04 사양이에요. 연습 화면 비커(322×294pt) 값을 온보딩 비커 크기에 맞춰 0.604배로 줄였어요
///   (벽 기울기는 같고, 바닥 ~ 위 점선 거리가 153.5 → 92.5pt).
nonisolated struct MilkLevelLoop {
    /// 한 바퀴 길이 (초)
    static let period: TimeInterval = 3.4
    /// 공기 주입이 끝나는 시점 (초)
    static let aerationEnd: TimeInterval = 1.6
    /// 원래 높이로 내려가는 구간 (초)
    static let drainStart: TimeInterval = 2.2
    static let drainEnd: TimeInterval = 2.65

    /// 시작 수위: 우유 윗면 y (일러스트 왼쪽 위 기준 pt, Hi-Fi 302 수위)
    static let restTop: CGFloat = 83
    /// 공기 주입이 끝날 때 목표 수위: 위 점선(y 54) 바로 아래
    static let fullTop: CGFloat = 55.5

    /// 연습 화면 비커 → 온보딩 비커 크기 비율
    static let scale: CGFloat = 0.604
    /// 잔물결 높이 (pt): 연습 화면 1.6pt × 0.604
    static let rippleHeight: CGFloat = 1.6 * scale
    /// 1초에 지나가는 잔물결 수 (연습 화면과 같음)
    static let rippleSpeed: Double = 1.1
    /// 수위가 목표를 따라가는 시간 · 잔물결이 잦아드는 시간 (연습 화면과 같음)
    static let levelSmoothTime: Double = 0.35
    static let rippleSmoothTime: Double = 0.6
    /// 꽉 찼을 때 화살표가 올라가는 거리 (pt)
    static let arrowLift: CGFloat = 6

    /// 계산 간격 (초). 한 바퀴 = 816칸
    static let step: TimeInterval = 1.0 / 240
    /// 이어 돌리는 바퀴 수 (마지막 바퀴를 저장)
    static let laps = 3

    /// 한 시점의 우유 상태
    struct Frame: Equatable {
        /// 우유 윗면 y (pt)
        let top: CGFloat
        /// 잔물결 세기 (0 = 잔잔함, 1 = 공기 주입 중)
        let rippleStrength: Double
    }

    /// 앱 전체에서 한 번만 계산해 써요.
    static let shared = MilkLevelLoop()

    /// 한 바퀴의 프레임 (1/240초 간격)
    let frames: [Frame]

    init() {
        let stepsPerLap = Int((Self.period / Self.step).rounded())
        var level = SmoothFollower(smoothTime: Self.levelSmoothTime)
        var ripple = SmoothFollower(smoothTime: Self.rippleSmoothTime)
        level.step(toward: Double(Self.restTop), dt: 0)   // 첫 step 은 목표값으로 바로 맞춰요
        ripple.step(toward: 0, dt: 0)

        var frames: [Frame] = []
        frames.reserveCapacity(stepsPerLap)
        for index in 0..<(stepsPerLap * Self.laps) {
            let time = Double(index % stepsPerLap) * Self.step
            if index > 0 {
                level.step(toward: Double(Self.targetTop(at: time)), dt: Self.step)
                ripple.step(toward: Self.isAerating(at: time) ? 1 : 0, dt: Self.step)
            }
            if index >= stepsPerLap * (Self.laps - 1) {
                frames.append(Frame(top: CGFloat(level.value ?? Double(Self.restTop)), rippleStrength: ripple.value ?? 0))
            }
        }
        self.frames = frames
    }

    /// 한 바퀴 안의 시간 `time`(초)에 우유가 따라가는 목표 수위
    static func targetTop(at time: TimeInterval) -> CGFloat {
        if time < aerationEnd {
            return restTop - (restTop - fullTop) * CGFloat(time / aerationEnd)
        }
        if time < drainStart {
            return fullTop
        }
        let t = min(max((time - drainStart) / (drainEnd - drainStart), 0), 1)
        return fullTop + (restTop - fullTop) * CGFloat(t * t * (3 - 2 * t))
    }

    /// 공기 주입 중(잔물결 켜짐)인지
    static func isAerating(at time: TimeInterval) -> Bool {
        time >= 0 && time < aerationEnd
    }

    /// 한 바퀴 진행률(0 이상 1 미만)의 프레임
    func frame(at progress: Double) -> Frame {
        // 끝에서 반올림한 칸은 다음 바퀴의 첫 칸(0)이에요.
        let index = Int((progress * Double(frames.count)).rounded()) % frames.count
        return frames[max(index, 0)]
    }

    /// 잔물결 위상. 바퀴가 넘어갈 때는 잔물결이 이미 잦아들어 있어 위상이 끊겨도 보이지 않아요.
    static func ripplePhase(at progress: Double) -> Double {
        progress * period * rippleSpeed * 2 * .pi
    }

    /// 화살표가 수위를 따라 위로 움직인 거리 (pt, 위쪽이 −)
    static func arrowOffset(forTop top: CGFloat) -> CGFloat {
        let filled = min(max((restTop - top) / (restTop - fullTop), 0), 1)
        return -arrowLift * filled
    }
}
