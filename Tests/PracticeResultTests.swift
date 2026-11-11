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
        timeline.update(phase: .listening, at: 18)
        timeline.finish(at: 25)
        timeline.finish(at: 25) // 중복 종료로 구간이 늘어나지 않습니다.

        let start = Date(timeIntervalSince1970: 1_000)
        let result = PracticeResult(practicedAt: start, dailyOrder: 1, segments: timeline.segments, duration: 25)
        precondition(timeline.segments.map(\.sound) == [.normalAeration, .overAeration, .lackOfAir, .rolling])
        precondition(result.timelineStart == 2 && result.totalSeconds == 23 && result.timelineLength == 23)
        precondition(result.normalSeconds == 10 && result.cautionSeconds == 6)
        precondition(result.detectedSeconds(of: .normalAeration) == 4)
        precondition(result.detectedSeconds(of: .overAeration) == 3)
        precondition(result.detectedSeconds(of: .lackOfAir) == 3)
        precondition(result.detectedSeconds(of: .rolling) == 6)
        verifyInitialRolling(start: start)
        verifyEarlierFinish()
        precondition(SteamingStage.rolling.sounds == [.rolling])
        precondition(PracticeResult.sample.normalSeconds + PracticeResult.sample.cautionSeconds == PracticeResult.sample.totalSeconds)

        let shortSegments = DetectedSound.allCases.enumerated().map { index, sound in
            DetectedSegment(sound: sound, start: Double(index) * 0.6, end: Double(index + 1) * 0.6)
        }
        let short = PracticeResult(practicedAt: start, dailyOrder: 1, segments: shortSegments, duration: 3)
        precondition(short.timelineStart == 0 && short.totalSeconds == 3)
        precondition(short.normalSeconds + short.cautionSeconds == 2)
        let empty = PracticeResult(practicedAt: start, dailyOrder: 1, segments: [], duration: 5)
        precondition(empty.timelineStart == 0)
        precondition(empty.totalSeconds == 5 && empty.normalSeconds == 0 && empty.cautionSeconds == 0)
        precondition(empty.normalRatio == 0 && empty.cautionRatio == 0)

        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let record = PracticeRecord(id: UUID(), startedAt: start, endedAt: start.addingTimeInterval(25))
        verifyRemovedSound(record: record, expected: result)
        try save(record: record, segments: timeline.segments, directory: directory)
        try verifyReload(record: record, expected: result, directory: directory)
        try verifyLegacyMigration(in: directory.appending(path: "migration"), start: start)
        try verifyDelete(in: directory.appending(path: "delete"), segments: timeline.segments, start: start)
        // 연습 가이드: 공기 주입 2~5초면 기준 안, 그보다 짧거나 길면 안내가 달라져요 (연습 중 비커 점선과 같은 기준).
        precondition(PracticeGuide.aerationRange == 2...5)
        precondition(PracticeGuide(aerationSeconds: 0) == .aerationTooShort)
        precondition(PracticeGuide(aerationSeconds: 1) == .aerationTooShort)
        precondition(PracticeGuide(aerationSeconds: 2) == .onTarget)
        precondition(PracticeGuide(aerationSeconds: 5) == .onTarget)
        precondition(PracticeGuide(aerationSeconds: 6) == .aerationTooLong)
        precondition(PracticeGuide(result: result) == .onTarget)                    // 공기 주입 4초
        precondition(PracticeGuide(result: .sample) == .aerationTooLong)            // 시안 데이터: 공기 주입 6초
        precondition(PracticeGuide(result: .empty) == .aerationTooShort)
        // 가이드 비커 수위: 2초 아래 점선, 5초 위 점선, 3.5초 그 사이, 0초 바닥 근처, 오래 하면 점선 위로
        func near(_ a: CGFloat, _ b: CGFloat) -> Bool { abs(a - b) < 0.01 }
        precondition(near(GuideMilkLevel.top(forAeration: 2), GuideMilkLevel.lowerLine))
        precondition(near(GuideMilkLevel.top(forAeration: 5), GuideMilkLevel.upperLine))
        let midLevel = GuideMilkLevel.top(forAeration: 3.5)
        precondition(midLevel < GuideMilkLevel.lowerLine && midLevel > GuideMilkLevel.upperLine)
        precondition(GuideMilkLevel.top(forAeration: 0) > GuideMilkLevel.lowerLine && GuideMilkLevel.top(forAeration: 0) < GuideMilkLevel.bottom)
        precondition(GuideMilkLevel.top(forAeration: 9) < GuideMilkLevel.upperLine)

        print("PracticeResultTests passed (timeline, summaries, guide, SwiftData persistence, legacy migration, delete)")
    }

    /// 소리가 끊긴 시각(마지막 기록보다 앞)으로 끝내면 그 뒤 구간을 잘라 냅니다.
    private static func verifyEarlierFinish() {
        var timeline = PracticeTimeline()
        timeline.update(phase: .aeration, at: 2)
        timeline.update(phase: .bubble, at: 6)
        timeline.update(phase: .milkFlow, at: 10)
        timeline.finish(at: 8)
        precondition(timeline.segments.map(\.sound) == [.normalAeration, .overAeration])
        precondition(timeline.segments.map(\.start) == [2, 6] && timeline.segments.map(\.end) == [6, 8])
        timeline.finish(at: 8)
        precondition(timeline.segments.count == 2)
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
    private static func verifyRemovedSound(record: PracticeRecord, expected: PracticeResult) {
        let saved = PracticeRecordEntity(record: record, dailyOrder: 1, segments: expected.segments)
        let removed = PracticeSoundSegmentEntity(segment: DetectedSegment(sound: .rolling, start: 18, end: 22))
        removed.sound = "overheated" // 이전 버전에서 저장했을 수 있는 값입니다.
        saved.soundSegments.append(removed)

        let restored = saved.result
        precondition(removed.segment == nil)
        precondition(restored.segments.map(\.sound) == expected.segments.map(\.sound))
        precondition(restored.totalSeconds == expected.totalSeconds)
        precondition(restored.normalSeconds == expected.normalSeconds && restored.cautionSeconds == expected.cautionSeconds)
        precondition(saved.soundSegments.count == expected.segments.count + 1) // 원본 저장 구간은 삭제하지 않습니다.
    }

    @MainActor
    private static func save(record: PracticeRecord, segments: [DetectedSegment], directory: URL) throws {
        let store = try PracticeHistoryStore(directory: directory)
        try store.save(record: record, dailyOrder: 1, segments: segments)
        try store.save(record: record, dailyOrder: 1, segments: segments)
        let saved = try store.records()
        precondition(saved.count == 1)
    }

    /// 기록 삭제: 지정한 기록만 지워지고, 없는 id는 무시하며, 저장소를 다시 열어도 삭제가 유지됩니다.
    @MainActor
    private static func verifyDelete(in directory: URL, segments: [DetectedSegment], start: Date) throws {
        let kept = PracticeRecord(id: UUID(), startedAt: start, endedAt: start.addingTimeInterval(25))
        let removed = PracticeRecord(id: UUID(), startedAt: start.addingTimeInterval(60), endedAt: start.addingTimeInterval(85))
        do {
            let store = try PracticeHistoryStore(directory: directory)
            try store.save(record: kept, dailyOrder: 1, segments: segments)
            try store.save(record: removed, dailyOrder: 2, segments: segments)
            let before = try store.records()
            precondition(before.count == 2)

            try store.delete(id: removed.id)
            let afterDelete = try store.records().map(\.record)
            precondition(afterDelete == [kept])

            try store.delete(id: UUID()) // 없는 id는 아무것도 지우지 않습니다.
            let afterUnknown = try store.records().map(\.record)
            precondition(afterUnknown == [kept])
        }
        // 저장소를 다시 열어 확인합니다. (기록은 저장소가 살아 있는 동안에만 읽을 수 있어 저장소를 변수에 둡니다)
        let reopened = try PracticeHistoryStore(directory: directory)
        let afterReopen = try reopened.records().map(\.record)
        precondition(afterReopen == [kept])
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
