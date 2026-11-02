import Foundation

/// 기기 없이 공기주입 진동의 중복·세션·유효 시간 조건을 검증합니다.
@main
struct WatchFeedbackHapticsTests {
    static func main() {
        let now = Date(timeIntervalSince1970: 1_000)
        var previous = PracticeState()
        previous.sessionID = UUID()
        previous.phase = .listening
        previous.updatedAt = now.addingTimeInterval(-1)
        var current = previous
        current.phase = .aeration
        current.updatedAt = now

        precondition(WatchFeedbackHaptics.exclusionReason(previous: previous, current: current, now: now) == nil)
        precondition(WatchFeedbackHaptics.exclusionReason(previous: current, current: current, now: now) != nil)
        precondition(WatchFeedbackHaptics.exclusionReason(previous: PracticeState(), current: current, now: now) != nil)
        precondition(WatchFeedbackHaptics.exclusionReason(previous: previous, current: current, now: now.addingTimeInterval(8)) != nil)

        var changed = current
        changed.updatedAt = previous.updatedAt
        precondition(WatchFeedbackHaptics.exclusionReason(previous: previous, current: changed, now: now) != nil)
        changed = current
        changed.phase = previous.phase
        precondition(WatchFeedbackHaptics.exclusionReason(previous: previous, current: changed, now: now) != nil)
        changed = current
        changed.sessionID = UUID()
        precondition(WatchFeedbackHaptics.exclusionReason(previous: previous, current: changed, now: now) != nil)
        changed.sessionID = nil
        precondition(WatchFeedbackHaptics.exclusionReason(previous: previous, current: changed, now: now) != nil)
        changed = current
        changed.isWatchEnabled = false
        precondition(WatchFeedbackHaptics.exclusionReason(previous: previous, current: changed, now: now) != nil)
        changed = current
        for phase in PracticePhase.allCases where phase != .aeration {
            changed.phase = phase
            precondition(WatchFeedbackHaptics.exclusionReason(previous: previous, current: changed, now: now) != nil)
        }
        previous.phase = .milkFlow
        precondition(WatchFeedbackHaptics.exclusionReason(previous: previous, current: current, now: now) == nil)
        previous.isWatchEnabled = false
        precondition(WatchFeedbackHaptics.exclusionReason(previous: previous, current: current, now: now) != nil)
        print("WatchFeedbackHapticsTests passed")
    }
}
