import Foundation

/// 발표용 가상 연습입니다. 마이크와 기록 저장소를 사용하지 않습니다.
struct PresentationPractice {
    private static let steps: [(phase: PracticePhase, duration: TimeInterval)] = [
        (.aeration, 1.5), (.bubble, 1.5), (.moreAir, 1.5),
        // 누적 3.5초까지 주입해, 수위를 부드럽게 따라가는 지연까지 점선 안에서 마칩니다.
        (.aeration, 2), (.milkFlow, 1.5)
    ]
    static let duration = steps.reduce(0) { $0 + $1.duration }
    var stepDuration: TimeInterval { Self.steps[step].duration }

    private(set) var phase: PracticePhase = .aeration
    private(set) var aerationClock = AerationClock()
    private(set) var isComplete = false
    let startedAt: Date
    private var step = 0
    private var timeline = PracticeTimeline()

    init(startedAt: Date = .now) {
        self.startedAt = startedAt
        aerationClock.resume(at: startedAt)
        timeline.update(phase: phase, at: 0)
    }

    mutating func advance() {
        guard !isComplete else { return }
        let elapsed = Self.steps.prefix(step + 1).reduce(0) { $0 + $1.duration }
        let now = startedAt.addingTimeInterval(elapsed)
        guard step + 1 < Self.steps.count else {
            timeline.finish(at: elapsed)
            isComplete = true
            return
        }
        step += 1
        phase = Self.steps[step].phase
        timeline.update(phase: phase, at: elapsed)
        if phase == .aeration {
            aerationClock.resume(at: now)
        } else {
            aerationClock.pause(at: now)
        }
    }

    mutating func finish(at now: Date = .now) -> PracticeResult {
        let duration = min(Self.duration, max(0, now.timeIntervalSince(startedAt)))
        aerationClock.pause(at: now)
        timeline.finish(at: duration)
        return PracticeResult(practicedAt: startedAt, dailyOrder: 1,
                              segments: timeline.segments, duration: duration)
    }
}
