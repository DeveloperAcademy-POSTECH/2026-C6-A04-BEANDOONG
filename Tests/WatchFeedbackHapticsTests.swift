import Foundation

/// 스티밍 소리별 햅틱과 중복·지연 수신 처리를 검증합니다.
@main
struct WatchFeedbackHapticsTests {
    static func main() {
        let start = Date(timeIntervalSince1970: 1_000)
        var state = PracticeState()
        state.sessionID = UUID()
        state.phase = .listening
        state.updatedAt = start
        var lastHaptic: Date?

        func receive(_ phase: PracticePhase, at second: Double, delay: Double = 0) -> WatchFeedbackHaptics.Feedback? {
            var update = state
            update.phase = phase
            update.updatedAt = start.addingTimeInterval(second)
            let arrival = update.updatedAt.addingTimeInterval(delay)
            let feedback = WatchFeedbackHaptics.feedback(previous: state, current: update,
                                                         now: arrival, lastHapticAt: lastHaptic)
            if update.updatedAt >= state.updatedAt { state = update }
            if case .skip = feedback { return nil }
            lastHaptic = arrival
            return feedback
        }

        precondition(receive(.aeration, at: 1) == .notification)
        precondition(receive(.aeration, at: 1) == nil)
        precondition(receive(.aeration, at: 2) == .notification)
        precondition(receive(.aeration, at: 1) == nil)
        precondition(receive(.milkFlow, at: 3) == nil)
        precondition(receive(.aeration, at: 4, delay: 0.8) == .notification)
        precondition(receive(.aeration, at: 5) == nil)
        precondition(receive(.aeration, at: 6) == .notification)
        precondition(receive(.moreAir, at: 6.1) == .failure)
        precondition(receive(.moreAir, at: 6.1) == nil)
        precondition(receive(.moreAir, at: 7) == nil)
        precondition(receive(.bubble, at: 8) == .failure)
        precondition(receive(.bubble, at: 9) == nil)
        precondition(receive(.aeration, at: 10) == .notification)
        precondition(receive(.bubble, at: 11, delay: 2) == nil)
        for (index, phase) in [PracticePhase.idle, .listening, .milkFlow, .finished].enumerated() {
            precondition(receive(phase, at: 14 + Double(index)) == nil)
        }
        state.isWatchEnabled = false
        precondition(receive(.moreAir, at: 21) == nil)
        state.isWatchEnabled = true
        state.sessionID = nil
        precondition(receive(.bubble, at: 22) == nil)
        print("WatchFeedbackHapticsTests passed")
    }
}
