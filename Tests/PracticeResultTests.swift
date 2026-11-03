import Foundation

/// 구간 집계와 실제 디스크의 SwiftData 저장·재조회·이전 기록 이전을 검증합니다.
@main
struct PracticeResultTests {
    @MainActor
    static func main() throws {
        var timeline = PracticeTimeline()
        timeline.update(phase: .aeration, at: 2)
        timeline.update(phase: .aeration, at: 3) // 같은 소리는 구간을 나누지 않습니다.
        timeline.update(phase: .bubble, at: 6)
        timeline.update(phase: .moreAir, at: 9)
        timeline.update(phase: .milkFlow, at: 12)
        timeline.update(phase: .sharpSound, at: 18)
        timeline.update(phase: .listening, at: 22)
        timeline.finish(at: 25)
        timeline.finish(at: 25) // 중복 종료로 구간이 늘어나지 않습니다.

        let start = Date(timeIntervalSince1970: 1_000)
        let result = PracticeResult(practicedAt: start, dailyOrder: 1, segments: timeline.segments, duration: 25)
        precondition(timeline.segments.map(\.sound) == [.normalAeration, .overAeration, .lackOfAir, .rolling, .overheated])
        precondition(result.timelineStart == 2 && result.totalSeconds == 23 && result.timelineLength == 23)
        precondition(result.normalSeconds == 10 && result.cautionSeconds == 10)
        precondition(result.detectedSeconds(of: .normalAeration) == 4)
        precondition(result.detectedSeconds(of: .overAeration) == 3)
        precondition(result.detectedSeconds(of: .lackOfAir) == 3)
        precondition(result.detectedSeconds(of: .rolling) == 6)
        precondition(result.detectedSeconds(of: .overheated) == 4)
        verifyInitialRolling(start: start)

        let shortSegments = DetectedSound.allCases.enumerated().map { index, sound in
            DetectedSegment(sound: sound, start: Double(index) * 0.6, end: Double(index + 1) * 0.6)
        }
        let short = PracticeResult(practicedAt: start, dailyOrder: 1, segments: shortSegments, duration: 3)
        precondition(short.timelineStart == 0 && short.totalSeconds == 3)
        precondition(short.normalSeconds + short.cautionSeconds == 3)
        let empty = PracticeResult(practicedAt: start, dailyOrder: 1, segments: [], duration: 5)
        precondition(empty.timelineStart == 0)
        precondition(empty.totalSeconds == 5 && empty.normalSeconds == 0 && empty.cautionSeconds == 0)
        precondition(empty.normalRatio == 0 && empty.cautionRatio == 0)

        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let record = PracticeRecord(id: UUID(), startedAt: start, endedAt: start.addingTimeInterval(25))
        try save(record: record, segments: timeline.segments, directory: directory)
        try verifyReload(record: record, expected: result, directory: directory)
        try verifyLegacyMigration(in: directory.appending(path: "migration"), start: start)
        print("PracticeResultTests passed (timeline, summaries, SwiftData persistence, legacy migration)")
    }

    private static func verifyInitialRolling(start: Date) {
        var timeline = PracticeTimeline()
        timeline.update(phase: .milkFlow, at: 2)
        timeline.update(phase: .listening, at: 6)
        timeline.update(phase: .aeration, at: 8)
        timeline.finish(at: 10)

        let result = PracticeResult(practicedAt: start, dailyOrder: 1, segments: timeline.segments, duration: 10)
        precondition(result.timelineStart == 2 && result.totalSeconds == 8)
        precondition(result.segments.map(\.sound) == [.rolling, .normalAeration])
        // 표시 기준만 옮기고, 연습 기준 시각과 중간의 미분류 구간은 유지합니다.
        precondition(result.duration == 10 && result.segments.map(\.start) == [2, 8])
        precondition(result.segments[0].start - result.timelineStart == 0)
        precondition(result.segments[1].start - result.timelineStart == 6)
        precondition(result.normalSeconds == 6 && result.cautionSeconds == 0)
    }

    @MainActor
    private static func save(record: PracticeRecord, segments: [DetectedSegment], directory: URL) throws {
        let store = try PracticeHistoryStore(directory: directory)
        try store.save(record: record, dailyOrder: 1, segments: segments)
        try store.save(record: record, dailyOrder: 1, segments: segments)
        let saved = try store.records()
        precondition(saved.count == 1)
    }

    @MainActor
    private static func verifyReload(record: PracticeRecord, expected: PracticeResult, directory: URL) throws {
        let store = try PracticeHistoryStore(directory: directory)
        let saved = try store.records()
        precondition(saved.count == 1 && saved[0].record == record)
        let restored = saved[0].result
        precondition(restored.timelineStart == expected.timelineStart)
        precondition(restored.totalSeconds == expected.totalSeconds)
        precondition(restored.normalSeconds == expected.normalSeconds && restored.cautionSeconds == expected.cautionSeconds)
        precondition(restored.segments.map(\.sound) == expected.segments.map(\.sound))
        precondition(restored.segments.map(\.start) == expected.segments.map(\.start))
        precondition(restored.segments.map(\.end) == expected.segments.map(\.end))
    }

    @MainActor
    private static func verifyLegacyMigration(in directory: URL, start: Date) throws {
        let legacy = directory.appending(path: "legacy")
        let destination = directory.appending(path: "history")
        try FileManager.default.createDirectory(at: legacy, withIntermediateDirectories: true)
        let records = (0..<2).map { index in
            PracticeRecord(id: UUID(), startedAt: start.addingTimeInterval(Double(index) * 60),
                           endedAt: start.addingTimeInterval(Double(index) * 60 + 10))
        }
        // 이전 JSON의 파일명 필드는 무시하고 연습 기록만 이전해야 합니다.
        let encoded = try JSONEncoder().encode(records.reversed())
        var legacyRecords = try JSONSerialization.jsonObject(with: encoded) as! [[String: Any]]
        for index in legacyRecords.indices {
            legacyRecords[index]["audioFilename"] = "legacy\(index).m4a"
        }
        try JSONSerialization.data(withJSONObject: legacyRecords).write(to: legacy.appending(path: "records.json"))
        let audioFilename = "legacy0.m4a"
        let audio = Data("test audio placeholder".utf8)
        try audio.write(to: legacy.appending(path: audioFilename))
        // 현재 저장소가 이미 있어도 이전 JSON을 읽을 수 있어야 합니다.
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        let store = try PracticeHistoryStore(directory: destination, legacyDirectory: legacy)
        let restored = try store.records()
        precondition(restored.map(\.dailyOrder) == [2, 1])
        precondition(restored.allSatisfy { $0.result.totalSeconds == 10 && $0.result.segments.isEmpty })
        precondition(!FileManager.default.fileExists(atPath: destination.appending(path: audioFilename).path))
        let existingAudio = try Data(contentsOf: legacy.appending(path: audioFilename))
        precondition(existingAudio == audio)
        let metadata = try JSONSerialization.jsonObject(with: JSONEncoder().encode(restored.map(\.record))) as! [[String: Any]]
        precondition(metadata.allSatisfy { $0["audioFilename"] == nil })
        precondition(!FileManager.default.fileExists(atPath: legacy.appending(path: "records.json").path))
        precondition(!FileManager.default.fileExists(atPath: destination.appending(path: "records.json").path))
    }
}
