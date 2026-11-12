import Foundation

/// 이번 연습에서 공기 주입(파랑) 화면이 떠 있던 시간을 모두 더해요.
/// - 공기 주입 화면이 뜨면 `resume`, 다른 화면으로 바뀌거나 연습이 끝나면 `pause`.
/// - 화면은 `seconds(at:)`로 지금까지의 누적 시간을 읽어 비커 수위를 정해요.
nonisolated struct AerationClock: Equatable {
    /// 이미 끝난 공기 주입 구간들의 합 (초)
    private(set) var accumulated: TimeInterval = 0
    /// 지금 이어지고 있는 공기 주입 구간의 시작 시각. 공기 주입 중이 아니면 nil.
    private(set) var runningSince: Date?

    /// 처음 만들 때는 0초. 미리보기·UI 테스트에서는 이미 쌓인 시간을 넣어 수위를 고정해 볼 수 있어요.
    init(accumulated: TimeInterval = 0) {
        self.accumulated = accumulated
    }

    var isRunning: Bool { runningSince != nil }

    /// 공기 주입 화면이 떴을 때. 이미 세는 중이면 그대로 둬요.
    mutating func resume(at now: Date) {
        guard runningSince == nil else { return }
        runningSince = now
    }

    /// 다른 화면으로 바뀌었거나 연습이 끝났을 때. 지금 구간을 누적 시간에 더해요.
    mutating func pause(at now: Date) {
        guard let start = runningSince else { return }
        accumulated += max(0, now.timeIntervalSince(start))
        runningSince = nil
    }

    /// `now`까지의 누적 공기 주입 시간 (초)
    func seconds(at now: Date) -> TimeInterval {
        guard let start = runningSince else { return accumulated }
        return accumulated + max(0, now.timeIntervalSince(start))
    }
}

/// 누적 공기 주입 시간 → 비커 우유 수위.
/// 값은 비커 그림(`IllustSteamingPitcher`, 322×294pt) 위쪽에서 잰 우유 윗면의 y (pt)예요. 작을수록 수위가 높아요.
/// - 0초: 바닥 근처에서 시작
/// - 2초: 아래 점선
/// - 2~4초: 두 점선 사이 (적정 구간)
/// - 4초 이후: 같은 속도로 넘어선 뒤 입구(`highest`)에 가까워질수록 점점 느려져요. 입구에 닿지는 않아요 (넘치기 직전).
nonisolated enum MilkLevel {
    /// 우유 바닥 (Hi-Fi: 865px / 3)
    static let bottom: CGFloat = 288.3
    /// 시작 수위: 바닥에서 12pt (바닥에 깔린 정도)
    static let start: CGFloat = 276
    /// 아래 점선 (Hi-Fi: 화면 y 544.5 = 비커 위 382 + 162.8)
    static let lowerLine: CGFloat = 162.8
    /// 위 점선 (Hi-Fi: 화면 y 516.5 = 비커 위 382 + 134.8)
    static let upperLine: CGFloat = 134.8
    /// 수위가 다가가기만 하는 가장 높은 곳 (비커 입구 아래)
    static let highest: CGFloat = 80

    /// 아래 점선에 닿는 누적 시간 (초)
    static let lowerLineSeconds: TimeInterval = 2
    /// 위 점선에 닿는 누적 시간 (초)
    static let upperLineSeconds: TimeInterval = 4

    /// 두 점선 사이를 지나는 속도 (pt/초)
    private static var risePerSecond: CGFloat {
        (lowerLine - upperLine) / CGFloat(upperLineSeconds - lowerLineSeconds)
    }

    /// 누적 공기 주입 시간에 맞는 우유 윗면 y (pt)
    static func top(forAeration seconds: TimeInterval) -> CGFloat {
        let t = max(0, seconds)
        if t <= lowerLineSeconds {
            return start - (start - lowerLine) * CGFloat(t / lowerLineSeconds)
        }
        if t <= upperLineSeconds {
            return lowerLine - risePerSecond * CGFloat(t - lowerLineSeconds)
        }
        // 위 점선을 같은 속도로 넘어선 뒤, 남은 거리에 비례해 느려져요 (속도가 끊기지 않는 지수 감속).
        let remaining = upperLine - highest
        let decay = Double(risePerSecond / remaining)
        return highest + remaining * CGFloat(exp(-decay * (t - upperLineSeconds)))
    }
}

/// 화면에 그리는 값이 목표값을 살짝 늦게, 튀지 않고 따라가게 해요 (임계 감쇠 스프링).
/// 목표가 갑자기 움직이기 시작하거나 멈춰도 그리는 값은 천천히 붙고 미끄러지듯 서요. 목표를 넘어가지 않아요.
nonisolated struct SmoothFollower: Equatable {
    /// 지금 그리는 값. 처음에는 nil이고, 첫 `step`에서 목표값으로 바로 맞춰요 (화면이 나타날 때 움직이지 않게).
    private(set) var value: Double?
    private(set) var velocity: Double = 0
    /// 목표에 거의 따라붙는 데 걸리는 시간 (초)
    let smoothTime: Double

    init(smoothTime: Double) {
        self.smoothTime = smoothTime
    }

    /// `dt`초 지난 뒤의 값. 앱이 잠깐 멈췄다 돌아와 `dt`가 크면 0.1초로 줄여 한 번에 튀지 않게 해요.
    @discardableResult
    mutating func step(toward target: Double, dt: Double) -> Double {
        guard let current = value else {
            value = target
            return target
        }
        let dt = min(max(dt, 0), 0.1)
        guard dt > 0 else { return current }
        let omega = 2 / max(smoothTime, 0.0001)
        let x = omega * dt
        let decay = 1 / (1 + x + 0.48 * x * x + 0.235 * x * x * x)
        let change = current - target
        let temp = (velocity + omega * change) * dt
        velocity = (velocity - omega * temp) * decay
        var next = target + (change + temp) * decay
        // 목표를 넘어가면 목표에서 멈춰요.
        if (current < target && next > target) || (current > target && next < target) {
            next = target
            velocity = 0
        }
        value = next
        return next
    }

    /// 목표에 붙어 더 움직일 일이 없는지
    func isSettled(at target: Double) -> Bool {
        guard let value else { return true }
        return abs(value - target) < 0.01 && abs(velocity) < 0.01
    }
}
