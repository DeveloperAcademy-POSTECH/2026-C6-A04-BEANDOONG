/// 첫 피드백 이후 종료음·작업 점수 저하·청소음 중 하나를 한 번만 종료로 반환합니다.
nonisolated struct ChicEndRule {
    enum Reason { case endSound, disappearance, cleaning }
    private(set) var isActive = false
    private(set) var isFinished = false
    private var lowWorkCount = 0
    private var purgeCount = 0

    /// 소리 확인 중 화면을 벗어나는 기존 첫 피드백 시점에 활성화합니다.
    mutating func activate() {
        guard !isActive, !isFinished else { return }
        isActive = true
        lowWorkCount = 0
        purgeCount = 0
    }

    /// 소멸은 낮은 작업 점수의 연속 횟수로만 확인합니다.
    mutating func consume(work: Double, end: Double, purge: Double, dropDB: Double) -> Reason? {
        guard isActive, !isFinished else { return nil }
        purgeCount = purge >= 0.5 ? purgeCount + 1 : 0
        lowWorkCount = work < 0.3 ? lowWorkCount + 1 : 0
        let reason: Reason?
        if end >= 0.85 && dropDB >= 3 { reason = .endSound }
        else if lowWorkCount >= 20 { reason = .disappearance }
        else if purgeCount >= 5 { reason = .cleaning }
        else { reason = nil }
        if reason != nil { isFinished = true; isActive = false }
        return reason
    }
}
