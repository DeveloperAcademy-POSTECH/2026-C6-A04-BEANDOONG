/// 첫 피드백 이후의 종료 판단입니다.
/// - 종료음 · 청소음: 한 번만 종료로 반환하고 끝납니다 (자동 종료).
/// - 작업 점수 저하(소리 끊김): `.disappearance`를 알리기만 하고 끝내지 않습니다. 종료 여부는 사용자에게 묻습니다.
///   소리가 다시 이어질 때까지(`isSilent`) 같은 알림을 되풀이하지 않습니다.
nonisolated struct ChicEndRule {
    enum Reason {
        case endSound, disappearance, cleaning

        /// 이 사유로 연습을 바로 끝내는지 (소리 끊김은 묻기만 해요)
        var finishes: Bool { self != .disappearance }
    }
    /// 소리 끊김으로 보는 낮은 작업 점수의 연속 횟수 (점수는 약 0.107초마다 → 약 2.1초)
    static let silenceCount = 20
    /// 소리 끊김 뒤 소리가 다시 이어졌다고 보는 작업 점수의 연속 횟수 (약 0.3초)
    static let resumeCount = 3

    private(set) var isActive = false
    private(set) var isFinished = false
    /// 소리 끊김을 알린 뒤 아직 소리가 다시 이어지지 않았는지
    private(set) var isSilent = false
    private var lowWorkCount = 0
    private var workCount = 0
    private var purgeCount = 0

    /// 소리 확인 중 화면을 벗어나는 기존 첫 피드백 시점에 활성화합니다.
    mutating func activate() {
        guard !isActive, !isFinished else { return }
        isActive = true
        lowWorkCount = 0
        workCount = 0
        purgeCount = 0
    }

    /// 소멸은 낮은 작업 점수의 연속 횟수로만 확인합니다.
    mutating func consume(work: Double, end: Double, purge: Double) -> Reason? {
        guard isActive, !isFinished else { return nil }
        purgeCount = purge >= 0.5 ? purgeCount + 1 : 0
        lowWorkCount = work < 0.3 ? lowWorkCount + 1 : 0
        workCount = work >= 0.3 ? workCount + 1 : 0
        if isSilent, workCount >= Self.resumeCount { isSilent = false }
        let reason: Reason?
        if end >= 0.6 { reason = .endSound }
        // 이미 알린 소리 끊김 중에는 건너뛰어, 그사이 청소음은 그대로 종료로 판단해요.
        else if lowWorkCount >= Self.silenceCount, !isSilent { reason = .disappearance }
        else if purgeCount >= 3 { reason = .cleaning }
        else { reason = nil }
        if reason == .disappearance { isSilent = true }
        if reason?.finishes == true { isFinished = true; isActive = false }
        return reason
    }
}
