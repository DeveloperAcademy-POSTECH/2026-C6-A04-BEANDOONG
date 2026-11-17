import Foundation

/// 기존 공기주입 대표 판정 또는 별도 시작음 점수로 한 번만 시작합니다.
nonisolated struct ChicStartRule {
    enum Reason: String { case air, startSound }
    static let threshold = 0.85
    private(set) var isStarted = false
    private(set) var meanScore: Double?
    private var sum = 0.0
    private var frames = 0
    private var airFilter = ChicDisplayFilter()

    /// 공기주입은 시작음 점수와 관계없이 기존 10프레임 표시 기준으로 확인합니다.
    mutating func consume(_ score: Double, state: ChicModelV3_5.State) -> Reason? {
        guard !isStarted else { return nil }
        let air = airFilter.consume(state) == .air
        sum += score
        frames += 1
        guard frames == 10 else { return nil }
        meanScore = sum / 10
        sum = 0
        frames = 0
        guard air || meanScore! >= Self.threshold else { return nil }
        isStarted = true
        return air ? .air : .startSound
    }
}

/// 독립 공기주입·시작음 경로 중 하나가 확인되면 시작음 모델 추론을 중단합니다.
nonisolated final class ChicStartGate {
    private var classifier: ChicModelV3_5.Classifier?
    private var rule = ChicStartRule()
    var isStarted: Bool { rule.isStarted }
    var meanScore: Double? { rule.meanScore }

    /// 작업음을 비시작 반례로 학습한 시작음 전용 모델을 불러옵니다.
    init(url: URL) throws {
        classifier = try ChicModelV3_5.Classifier(url: url, labels: ["not_start", "start"])
    }

    /// 어느 경로로 시작했든 이후에는 특징 검사나 Core ML 호출을 하지 않습니다.
    func consume(_ features: [Double], state: ChicModelV3_5.State) throws -> ChicStartRule.Reason? {
        guard !rule.isStarted else { return nil }
        guard let classifier else { throw ChicModelV3_5.Failure.alignment }
        let reason = rule.consume(try classifier.scores(features)[1], state: state)
        if reason != nil { self.classifier = nil }
        return reason
    }
}
