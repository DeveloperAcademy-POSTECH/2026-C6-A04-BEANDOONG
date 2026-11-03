/// 48 kHz 모델 프레임을 100 ms마다 한 번만 표시 후보로 사용합니다.
/// 분석 큐에서 한 세션 동안 유지하고 다음 연습은 새 인스턴스로 시작합니다.
nonisolated struct ChicDisplayFilter {
    private var frameEnd = 2048
    private var recent: [ChicModelV2.State] = []
    private var display: ChicModelV2.State?

    mutating func consume(_ state: ChicModelV2.State) -> ChicModelV2.State? {
        let end = frameEnd
        frameEnd += 512
        guard (end - 1) / 4800 != (frameEnd - 1) / 4800 else { return nil }
        recent.append(state)
        if recent.count > 4 { recent.removeFirst() }
        let lastThree = recent.suffix(3)
        switch state {
        case .air where recent.filter({ $0 == .air || $0 == .sputter }).count >= 3:
            display = .air
        case .other where display == nil:
            break // 첫 스티밍 소리가 확인될 때까지 소리 확인 화면을 유지합니다.
        case .sputter, .metallic, .other:
            if lastThree.filter({ $0 == state }).count >= 2 { display = state }
        default:
            break
        }
        return display
    }
}
