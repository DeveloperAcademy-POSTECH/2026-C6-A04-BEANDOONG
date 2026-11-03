import Foundation

/// 화면에 표시한 소리의 전환 시점을 기록합니다. 소리 확인 중인 구간은 미분류로 남깁니다.
struct PracticeTimeline {
    private(set) var segments: [DetectedSegment] = []
    private var sound: DetectedSound?
    private var startedAt: TimeInterval = 0

    mutating func update(phase: PracticePhase, at time: TimeInterval) {
        let next = phase.detectedSound
        guard next != sound else { return }
        closeSegment(at: time)
        sound = next
    }

    mutating func finish(at time: TimeInterval) {
        closeSegment(at: time)
        sound = nil
    }

    private mutating func closeSegment(at time: TimeInterval) {
        let end = max(startedAt, time)
        if let sound, end > startedAt {
            segments.append(DetectedSegment(sound: sound, start: startedAt, end: end))
        }
        startedAt = end
    }
}

private extension PracticePhase {
    var detectedSound: DetectedSound? {
        switch self {
        case .aeration: .normalAeration
        case .bubble: .overAeration
        case .moreAir: .lackOfAir
        case .milkFlow: .rolling
        case .sharpSound: .overheated
        case .idle, .listening, .finished: nil
        }
    }
}
