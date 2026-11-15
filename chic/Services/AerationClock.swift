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
