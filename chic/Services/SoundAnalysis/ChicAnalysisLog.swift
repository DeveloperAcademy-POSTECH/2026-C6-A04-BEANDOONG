import Foundation
import OSLog

/// 분석 큐에서 얻은 점수와 오디오 시각을 함께 보관하고 이벤트가 발생할 때만 출력합니다.
nonisolated struct ChicAnalysisLog: Sendable {
    enum Event {
        case start(ChicStartRule.Reason)
        case feedback(String)
        case end(ChicEndRule.Reason?)
    }

    private static let logger = Logger(subsystem: "com.beandoong.cheek", category: "SteamingEnd")
    let selection: ChicModelSelection
    private var time: TimeInterval = 0
    private var work: ChicModelV3_5.WorkScores?
    private(set) var isStartFrame = false
    private var start: (time: Double, score: Double)?
    private var end: (time: Double, scores: ChicEndDetector.Scores)?

    init(selection: ChicModelSelection) { self.selection = selection }

    /// 작업음 프레임과 같은 시점에 갱신된 시작·종료 점수를 보관합니다.
    mutating func record(_ frame: ChicModelV3_5.Frame, endScores: ChicEndDetector.Scores?) {
        time = frame.audioTime
        work = frame.scores
        isStartFrame = frame.startReason != nil
        if let score = frame.newStartMean { start = (time, score) }
        if let endScores { end = (time, endScores) }
    }

    /// 각 모델의 측정 시각을 남겨 이전 묶음의 점수와 이번 프레임을 구분합니다.
    func message(_ event: Event, elapsed: Double? = nil) -> String {
        func number(_ value: Double) -> String { String(format: "%.3f", value) }
        func scores(_ output: ChicModelV3_5.Output) -> String {
            zip(output.labels, output.values).map { "\($0)=\(number($1))" }.joined(separator: " ")
        }
        var fields = ["[스티밍 +\(number(elapsed ?? time))초]", selection.rawValue]
        switch event {
        case .start(let reason):
            fields.append("스티밍 시작 (\(reason.rawValue))")
            if let start { fields.append("시작음@\(number(start.time))초 start=\(number(start.score))") }
        case .feedback(let title):
            fields.append("피드백: \(title)")
            if let work {
                fields.append("Gate[\(scores(work.primary))]")
                if let secondary = work.secondary { fields.append("\(secondary.name)[\(scores(secondary.output))]") }
            }
        case .end(let reason):
            fields.append(reason.map { "종료 감지 (\($0))" } ?? "연습 종료")
            if let end {
                let s = end.scores
                fields.append("종료@\(number(end.time))초 other=\(number(s.other)) work=\(number(s.work)) end=\(number(s.end)) purge=\(number(s.purge))")
            } else {
                fields.append("종료 점수 없음")
            }
        }
        return fields.joined(separator: " | ")
    }

    func write(_ event: Event, elapsed: Double? = nil) {
        Self.logger.notice("\(message(event, elapsed: elapsed), privacy: .public)")
    }
}
