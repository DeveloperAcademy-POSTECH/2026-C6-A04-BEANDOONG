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

    /// 끝 시각에서 구간을 닫습니다. 소리가 끊긴 시각처럼 마지막 기록보다 앞선 시각으로 끝내면, 그 뒤 구간은 잘라 냅니다.
    mutating func finish(at time: TimeInterval) {
        closeSegment(at: time)
        sound = nil
        guard segments.contains(where: { $0.end > time }) else { return }
        segments = segments.compactMap { segment in
            guard segment.start < time else { return nil }
            return segment.end > time ? DetectedSegment(sound: segment.sound, start: segment.start, end: time) : segment
        }
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
        case .idle, .listening, .finished: nil
        }
    }
}
