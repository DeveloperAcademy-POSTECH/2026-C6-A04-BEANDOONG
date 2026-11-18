/// 공기주입·버블링·스크래칭 화면이 표시된 뒤 최소 1초 동안 전환을 보류합니다.
nonisolated struct PracticeFeedbackHold {
    private var changedAt: ContinuousClock.Instant?

    /// 같은 판정은 유지 시간을 연장하지 않고, 롤링·소리 확인 화면에서는 즉시 전환합니다.
    mutating func allowsTransition(from current: PracticePhase, to next: PracticePhase,
                                   at now: ContinuousClock.Instant = .now) -> Bool {
        guard current != next else { return true }
        if [.aeration, .bubble, .moreAir].contains(current),
           let changedAt, changedAt.duration(to: now) < .seconds(1) {
            return false
        }
        changedAt = now
        return true
    }
}
