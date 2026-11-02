import Foundation

/// 기기 없이 상태 변경 알림의 중복·세션·유효 시간 조건을 검증합니다.
@main
struct WatchFeedbackNotificationsTests {
    static func main() {
        let now = Date(timeIntervalSince1970: 1_000)
        var previous = PracticeState()
        previous.sessionID = UUID()
        previous.phase = .listening
        previous.updatedAt = now.addingTimeInterval(-1)
        var current = previous
        current.phase = .aeration
        current.updatedAt = now

        precondition(WatchFeedbackNotifications.shouldNotify(previous: previous, current: current, now: now))
        precondition(!WatchFeedbackNotifications.shouldNotify(previous: current, current: current, now: now))
        precondition(!WatchFeedbackNotifications.shouldNotify(previous: PracticeState(), current: current, now: now))
        precondition(!WatchFeedbackNotifications.shouldNotify(previous: previous, current: current, now: now.addingTimeInterval(8)))

        var changed = current
        changed.updatedAt = previous.updatedAt
        precondition(!WatchFeedbackNotifications.shouldNotify(previous: previous, current: changed, now: now))
        changed = current
        changed.phase = previous.phase
        precondition(!WatchFeedbackNotifications.shouldNotify(previous: previous, current: changed, now: now))
        changed = current
        changed.sessionID = UUID()
        precondition(!WatchFeedbackNotifications.shouldNotify(previous: previous, current: changed, now: now))
        changed.sessionID = nil
        precondition(!WatchFeedbackNotifications.shouldNotify(previous: previous, current: changed, now: now))
        changed = current
        changed.isWatchEnabled = false
        precondition(!WatchFeedbackNotifications.shouldNotify(previous: previous, current: changed, now: now))
        changed = current
        changed.phase = .idle
        precondition(!WatchFeedbackNotifications.shouldNotify(previous: previous, current: changed, now: now))
        changed.phase = .finished
        precondition(WatchFeedbackNotifications.shouldNotify(previous: previous, current: changed, now: now))
        previous.isWatchEnabled = false
        precondition(!WatchFeedbackNotifications.shouldNotify(previous: previous, current: current, now: now))
        print("WatchFeedbackNotificationsTests passed")
    }
}
