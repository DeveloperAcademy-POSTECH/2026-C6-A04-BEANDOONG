import Foundation

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
