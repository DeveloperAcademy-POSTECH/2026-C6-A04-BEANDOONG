/// 모델 판정 10개를 집계하고 같은 대표 판정이 연속될 때 표시를 바꿉니다.
/// 분석 큐에서 한 세션 동안 유지하고 다음 연습은 새 인스턴스로 시작합니다.
nonisolated struct ChicDisplayFilter {
    private var frames: [ChicModelV3_5.State?] = []
    private var candidate: ChicModelV3_5.State?
    private var consecutiveCount = 0
    private(set) var display: ChicModelV3_5.State?
    /// 직전 표시를 유지한 경우에는 이번 묶음을 같은 소리의 재확인으로 세지 않습니다.
    var confirmedBlockCount: Int { display == candidate ? consecutiveCount : 0 }

    private var startConfirmed = false

    private let forHome: Bool

    init(forHome: Bool = false) { self.forHome = forHome }

    /// 시작 게이트를 통과하면 첫 판정이 롤링이어도 피드백을 표시할 수 있습니다.
    mutating func activate() { startConfirmed = true }

    /// 드롱기는 모든 소리에서 두 묶음 연속 같은 대표 판정을 확인합니다.
    mutating func consume(_ state: ChicModelV3_5.State?) -> ChicModelV3_5.State? {
        frames.append(state)
        guard frames.count == 10 else { return nil }
        let counts = Dictionary(grouping: frames, by: { $0 }).mapValues(\.count)
        let maximum = counts.values.max()!
        // 동률이면 가장 최근에 나온 동률 상태를 대표 판정으로 사용합니다.
        let winner = frames.last { counts[$0] == maximum }!
        frames.removeAll(keepingCapacity: true)

        // 비스티밍 우세 묶음은 피드백을 내지 않고 작업음의 연속 횟수를 끊습니다.
        guard let winner else {
            candidate = nil
            consecutiveCount = 0
            return nil
        }
        consecutiveCount = winner == candidate ? min(consecutiveCount + 1, 3) : 1
        candidate = winner
        let required = switch winner {
        case .air: forHome ? 2 : 1
        case .sputter, .other: 2
        case .metallic: forHome ? 2 : 3
        }
        if consecutiveCount >= required && (winner != .other || display != nil || startConfirmed) {
            display = winner
        }
        return display
    }
}

/// 결과 기록과 독립적으로 드롱기의 실시간 작업음 피드백을 최소 0.5초 유지합니다.
nonisolated struct ChicLiveFeedbackHold {
    private var shown: ChicModelV3_5.State?
    private var holdUntil = 0.0

    /// 유지 시간이 지난 뒤 도착한 첫 유효 판정으로 전환하거나 같은 작업음을 다시 유지합니다.
    mutating func update(_ state: ChicModelV3_5.State, confirmedBlocks: Int, at now: Double) -> ChicModelV3_5.State? {
        guard now >= holdUntil, confirmedBlocks > 0 else { return shown }
        if state != .other, shown != state, confirmedBlocks < 2 { return shown }
        shown = state
        holdUntil = state == .other ? now : now + 0.5
        return shown
    }
}
