#if PRESENTATION_TESTS
import Foundation

/// 실제 통신 대신 전송 상태와 명령만 받습니다. 앱 빌드에는 포함되지 않습니다.
@MainActor
final class WatchConnection {
    private(set) var state: PracticeState
    private(set) var published: [PracticeState] = []
    var onCommand: ((WatchRequest) async throws -> PracticeState)?

    init(state: PracticeState = PracticeState()) { self.state = state }

    func publish(_ state: PracticeState) {
        self.state = state
        published.append(state)
    }
}

@MainActor
enum PresentationWatchSyncTests {
    static func run() async throws {
        let start = Date(timeIntervalSince1970: 1_000)
        let record = PracticeRecord(id: UUID(), startedAt: start, endedAt: start.addingTimeInterval(20))
        var original = PracticeState()
        original.sessionID = record.id
        original.startedAt = record.startedAt
        original.endedAt = record.endedAt
        original.records = [record]
        original.updatedAt = start
        let connection = WatchConnection(state: original)
        var originalCalls = 0
        connection.onCommand = { _ in originalCalls += 1; return original }

        var starts = 0
        var stops = 0
        var closes = 0
        var presentation = PresentationPractice(startedAt: start)
        var sync: PresentationWatchSync!
        sync = PresentationWatchSync(connection: connection, onStart: {
            starts += 1
            sync.showListening()
        }, onStop: {
            stops += 1
            sync.showFinished(presentation.finish(at: start.addingTimeInterval(60)))
        }, onFinishReview: {
            closes += 1
            sync.disconnect()
        })

        func request(_ command: WatchCommand, id: UUID? = nil) async throws -> PracticeState {
            guard let handler = connection.onCommand else { preconditionFailure("명령 처리 누락") }
            return try await handler(WatchRequest(command: command, sessionID: id,
                                                 expiresAt: Date().addingTimeInterval(8)))
        }

        // 준비 중에도 기존 분석 시작 함수를 호출하지 않고 발표용 시작에만 연결합니다.
        precondition(connection.state.phase == .idle && connection.state.sessionID == nil)
        let listening = try await request(.start)
        precondition(listening.phase == .listening && listening.isWatchEnabled)
        guard let id = listening.sessionID else { preconditionFailure("발표용 세션 ID 누락") }
        precondition(id != original.sessionID)
        _ = try await request(.start, id: id)
        precondition(starts == 1 && originalCalls == 0)

        // 이전 연습의 종료·완료 요청이 발표를 중단하지 않아야 합니다.
        for command: WatchCommand in [.stop, .finishReview] {
            do {
                _ = try await request(command, id: original.sessionID)
                preconditionFailure("이전 세션 명령 허용")
            } catch is ConnectionError {}
        }
        precondition(stops == 0 && closes == 0)

        // 파주보파초와 재연결 시 sync 응답에 같은 세션·시간·기록을 보냅니다.
        sync.showFeedback(presentation)
        precondition(connection.state.phase == .aeration)
        for phase: PracticePhase in [.bubble, .moreAir, .aeration, .milkFlow] {
            presentation.advance()
            sync.showFeedback(presentation)
            let snapshot = try await request(.sync)
            precondition(snapshot.phase == phase && snapshot.sessionID == id)
            precondition(snapshot.startedAt == start && snapshot.records == original.records)
            let restored = try JSONDecoder().decode(PracticeState.self, from: JSONEncoder().encode(snapshot))
            precondition(restored == snapshot)
        }
        presentation.advance()
        sync.showFeedback(presentation)
        precondition(connection.state.phase == .milkFlow && connection.state.duration == 8)

        // 워치 종료는 발표 결과로만 이어지며, 중복 종료나 시작으로 다시 실행하지 않습니다.
        let finished = try await request(.stop, id: id)
        precondition(finished.phase == .finished && finished.duration == 8)
        precondition(finished.records == original.records && stops == 1)
        _ = try await request(.stop, id: id)
        _ = try await request(.start, id: id)
        precondition(stops == 1 && starts == 1 && originalCalls == 0)

        // 완료 시 기존 상태·명령을 복원하고, 늦은 발표 상태는 전송하지 않습니다.
        _ = try await request(.finishReview, id: id)
        precondition(closes == 1)
        var restored = connection.state
        precondition(restored.updatedAt > original.updatedAt)
        restored.updatedAt = original.updatedAt
        precondition(restored == original)
        let count = connection.published.count
        sync.disconnect()
        sync.showListening()
        sync.showFeedback(presentation)
        precondition(connection.published.count == count)
        _ = try await request(.sync)
        precondition(originalCalls == 1)
        _ = try await request(.start)
        precondition(originalCalls == 2)
        sync = nil

        // 폰에서만 시작·종료하는 경우에도 전송과 정리가 같은 경로를 사용합니다.
        let phone = WatchConnection()
        let phoneSync = PresentationWatchSync(connection: phone, onStart: {}, onStop: {}, onFinishReview: {})
        phoneSync.showListening()
        phoneSync.showFinished(PracticeResult(practicedAt: .now, dailyOrder: 1, segments: [], duration: 0))
        precondition(phone.state.phase == .finished && phone.state.duration == 0)
        phoneSync.disconnect()
        precondition(phone.state.phase == .idle && phone.onCommand == nil)

        print("PresentationWatchSyncTests passed (상태 전송, sync 응답, 워치 시작·종료·완료, 이전 세션 거부, 기존 연결 복원)")
    }
}
#endif
