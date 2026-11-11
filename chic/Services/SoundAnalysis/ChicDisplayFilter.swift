/// 모델 판정 10개를 집계하고 같은 대표 판정이 연속될 때 표시를 바꿉니다.
/// 분석 큐에서 한 세션 동안 유지하고 다음 연습은 새 인스턴스로 시작합니다.
nonisolated struct ChicDisplayFilter {
    private var frames: [ChicModelV3_5.State] = []
    private var candidate: ChicModelV3_5.State?
    private var consecutiveCount = 0
    private var display: ChicModelV3_5.State?

    /// 공기주입은 1회, 롤링·파바박은 2회, 쇳소리는 3회 연속된 대표 판정을 확인합니다.
    mutating func consume(_ state: ChicModelV3_5.State) -> ChicModelV3_5.State? {
        frames.append(state)
        guard frames.count == 10 else { return nil }
        let counts = Dictionary(grouping: frames, by: { $0 }).mapValues(\.count)
        let maximum = counts.values.max()!
        // 동률이면 가장 최근에 나온 동률 상태를 대표 판정으로 사용합니다.
        let winner = frames.last { counts[$0] == maximum }!
        frames.removeAll(keepingCapacity: true)

        consecutiveCount = winner == candidate ? min(consecutiveCount + 1, 3) : 1
        candidate = winner
        let required = switch winner {
        case .air: 1
        case .other, .sputter: 2
        case .metallic: 3
        }
        if consecutiveCount >= required && (winner != .other || display != nil) {
            display = winner
        }
        return display
    }
}
