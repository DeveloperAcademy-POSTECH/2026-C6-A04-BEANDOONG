/// 첫 피드백 이후 연습이 끝난 것 같은 순간을 알립니다. 연습을 직접 끝내지 않고, 종료 여부는 사용자에게 묻습니다.
/// - 종료음 · 청소음 · 작업 점수 저하(소리 끊김) 중 하나를 알리면,
///   소리가 다시 이어질 때까지(`isAsking`) 어떤 알림도 되풀이하지 않습니다.
/// - 종료음 점수는 스티밍 중에도 순간적으로 문턱을 넘을 수 있어서(문턱 0.6, 1회), 바로 끝내면 연습이 중간에 끊겨요.
nonisolated struct ChicEndRule {
    enum Reason {
        case endSound, disappearance, cleaning

        /// 연습이 끝난 것으로 볼 시각이 알림 시각보다 몇 번의 점수(약 0.107초)만큼 앞서는지
        /// - 종료음: 지금 / 소리 끊김: 낮은 점수가 시작된 때 / 청소음: 청소 소리가 시작된 때
        var lookbackCount: Int {
            switch self {
            case .endSound: 0
            case .disappearance: ChicEndRule.silenceCount
            case .cleaning: ChicEndRule.cleaningCount
            }
        }
    }
    /// 소리 끊김으로 보는 낮은 작업 점수의 연속 횟수 (점수는 약 0.107초마다 → 약 2.1초)
    static let silenceCount = 20
    /// 청소음으로 보는 청소 점수의 연속 횟수 (약 0.3초)
    static let cleaningCount = 3
    /// 알린 뒤 소리가 다시 이어졌다고 보는 작업 점수의 연속 횟수 (약 0.3초)
    static let resumeCount = 3

    private(set) var isActive = false
    /// 끝난 것 같다고 알린 뒤 아직 소리가 다시 이어지지 않았는지
    private(set) var isAsking = false
    private var lowWorkCount = 0
    private var workCount = 0
    private var purgeCount = 0

    /// 소리 확인 중 화면을 벗어나는 기존 첫 피드백 시점에 활성화합니다.
    mutating func activate() {
        guard !isActive else { return }
        isActive = true
        lowWorkCount = 0
        workCount = 0
        purgeCount = 0
    }

    /// 소멸은 낮은 작업 점수의 연속 횟수로만 확인합니다.
    mutating func consume(work: Double, end: Double, purge: Double) -> Reason? {
        guard isActive else { return nil }
        purgeCount = purge >= 0.5 ? purgeCount + 1 : 0
        lowWorkCount = work < 0.3 ? lowWorkCount + 1 : 0
        workCount = work >= 0.3 ? workCount + 1 : 0
        if isAsking, workCount >= Self.resumeCount {
            // 소리가 다시 이어졌어요. 그동안 쌓인 횟수로 바로 다시 묻지 않게 처음부터 셉니다.
            isAsking = false
            purgeCount = 0
        }
        // 이미 물어본 동안에는 다시 알리지 않아요.
        guard !isAsking else { return nil }
        let reason: Reason?
        if end >= 0.6 { reason = .endSound }
        else if lowWorkCount >= Self.silenceCount { reason = .disappearance }
        else if purgeCount >= Self.cleaningCount { reason = .cleaning }
        else { reason = nil }
        // 물어본 뒤의 작업 점수만 세어 '다시 이어짐'을 판단해요.
        if reason != nil { isAsking = true; workCount = 0 }
        return reason
    }
}
