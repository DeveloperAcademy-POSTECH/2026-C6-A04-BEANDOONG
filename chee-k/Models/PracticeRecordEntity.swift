import Foundation
import SwiftData

/// 결과와 히스토리가 함께 사용하는 영구 저장 모델입니다. 녹음 원본은 audioFilename의 로컬 파일입니다.
@Model
final class PracticeRecordEntity {
    @Attribute(.unique) var id: UUID
    var startedAt: Date
    var endedAt: Date
    var dailyOrder: Int
    var audioFilename: String
    @Relationship(deleteRule: .cascade) var soundSegments: [PracticeSoundSegmentEntity]

    init(record: PracticeRecord, dailyOrder: Int, segments: [DetectedSegment]) {
        id = record.id
        startedAt = record.startedAt
        endedAt = record.endedAt
        self.dailyOrder = dailyOrder
        audioFilename = record.audioFilename
        soundSegments = segments.map(PracticeSoundSegmentEntity.init)
    }

    var record: PracticeRecord {
        PracticeRecord(id: id, startedAt: startedAt, endedAt: endedAt, audioFilename: audioFilename)
    }

    var result: PracticeResult {
        PracticeResult(
            practicedAt: startedAt,
            dailyOrder: dailyOrder,
            segments: soundSegments.compactMap(\.segment).sorted { $0.start < $1.start },
            duration: max(0, endedAt.timeIntervalSince(startedAt))
        )
    }
}

/// 구간의 시작·끝은 연습 시작을 0초로 한 경과 시간입니다.
@Model
final class PracticeSoundSegmentEntity {
    var sound: String
    var start: TimeInterval
    var end: TimeInterval

    init(segment: DetectedSegment) {
        sound = segment.sound.rawValue
        start = segment.start
        end = segment.end
    }

    var segment: DetectedSegment? {
        guard let sound = DetectedSound(rawValue: sound) else { return nil }
        return DetectedSegment(sound: sound, start: start, end: end)
    }
}
