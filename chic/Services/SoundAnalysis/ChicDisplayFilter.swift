/// 모델 판정 10개(약 0.107초)를 집계하고 같은 대표 판정이 연속될 때 표시를 바꿉니다.
/// 분석 큐에서 한 세션 동안 유지하고 다음 연습은 새 인스턴스로 시작합니다.
nonisolated struct ChicDisplayFilter {
    private let frameCount: Int
    private let airConsecutive: Int
    private var frames: [ChicModelV3_5.State] = []
    private var candidate: ChicModelV3_5.State?
    private var consecutiveCount = 0
    private var display: ChicModelV3_5.State?
    private var startConfirmed = false

    /// 실시간 피드백은 10프레임·공기주입 2회, 자동 시작 확인은 10프레임·1회를 사용합니다.
    init(frameCount: Int = 10, airConsecutive: Int = 2) {
        precondition(frameCount > 0 && (1...2).contains(airConsecutive))
        self.frameCount = frameCount
        self.airConsecutive = airConsecutive
    }

    /// 시작 게이트를 통과하면 첫 판정이 롤링이어도 피드백을 표시할 수 있습니다.
    mutating func activate() { startConfirmed = true }

    /// 기타를 롤링에 합산하고 롤링은 4묶음, 쇳소리는 2묶음, 파바박은 1묶음으로 확인합니다.
    mutating func consume(_ state: ChicModelV3_5.State) -> ChicModelV3_5.State? {
        frames.append(state == .other ? .rolling : state)
        guard frames.count == frameCount else { return nil }
        let counts = Dictionary(grouping: frames, by: { $0 }).mapValues(\.count)
        let maximum = counts.values.max()!
        // 동률이면 가장 최근에 나온 동률 상태를 대표 판정으로 사용합니다.
        let winner = frames.last { counts[$0] == maximum }!
        frames.removeAll(keepingCapacity: true)

        consecutiveCount = winner == candidate ? min(consecutiveCount + 1, 4) : 1
        candidate = winner
        let required = switch winner {
        case .air: airConsecutive
        case .sputter: 1
        case .metallic: 2
        case .rolling, .other: 4
        }
        if consecutiveCount >= required && (winner != .rolling || display != nil || startConfirmed) {
            display = winner
        }
        return display
    }
}
