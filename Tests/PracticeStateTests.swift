//
//  PracticeStateTests.swift
//
//  기기 없이 실행할 수 있는 연습 동기화 데이터 검증 코드입니다.
//  상태·기록의 JSON 변환, 시간 계산, 종료 요청의 세션 ID 보존과 손상된 데이터 거부를 확인합니다.
//  실제 WatchConnectivity 통신이나 녹음을 검증하는 테스트는 아닙니다. 실행 방법은 docs/watch-connectivity.md에 있습니다.
//

import Foundation

// 실행: docs/watch-connectivity.md의 명령 참고. 기기 없이 동기화 데이터 계약을 검증합니다.
@main
struct PracticeStateTests {
    static func main() throws {
        let start = Date(timeIntervalSince1970: 1_000)
        let end = start.addingTimeInterval(92)
        let id = UUID()
        let record = PracticeRecord(id: id, startedAt: start, endedAt: end, audioFilename: "sample.m4a")
        var state = PracticeState()
        state.sessionID = id
        state.startedAt = start
        state.endedAt = end
        state.records = [record]
        state.updatedAt = end

        // 모든 상태의 전송과 기록 저장 과정에서 세션 ID·시간·기록이 유지되어야 합니다.
        for phase in PracticePhase.allCases {
            state.phase = phase
            let restored = try JSONDecoder().decode(PracticeState.self, from: JSONEncoder().encode(state))
            precondition(restored == state)
        }
        precondition(state.durationText == "01:32")
        precondition(state.records[0].duration == 92)
        state.endedAt = start.addingTimeInterval(-1)
        precondition(state.duration == 0)
        precondition(PracticeState().durationText == "00:00")
        precondition(!PracticePhase.idle.isRunning && !PracticePhase.finished.isRunning)
        precondition(PracticePhase.listening.isRunning && PracticePhase.noiseWarning.isRunning)

        // 종료 요청은 현재 세션 ID를 그대로 전달해야 다른 연습을 종료하지 않습니다.
        let request = WatchRequest(command: .stop, sessionID: id, expiresAt: end)
        let restored = try JSONDecoder().decode(WatchRequest.self, from: JSONEncoder().encode(request))
        precondition(restored.command == .stop && restored.sessionID == id && restored.expiresAt == end)

        // 워치 없이 시작하면 소리 확인·피드백·종료 어느 상태에서도 연습 정보를 보내지 않습니다.
        // 재연결 시 .sync 응답에도 동일한 스냅샷을 사용합니다.
        state.isWatchEnabled = false
        for phase in PracticePhase.allCases {
            state.phase = phase
            let snapshot = state.watchSnapshot
            let received = try JSONDecoder().decode(PracticeState.self, from: JSONEncoder().encode(snapshot))
            precondition(!received.isWatchEnabled && received.phase == .idle)
            precondition(received.sessionID == nil && received.startedAt == nil && received.endedAt == nil)
            precondition(received.records.isEmpty && received.updatedAt == state.updatedAt)
            // 워치에 보내는 정보만 제외하며, iPhone에서 녹음·저장할 데이터는 유지합니다.
            precondition(state.sessionID == id && state.records == [record])
        }

        // 다음 연습에서 워치 사용을 선택하면 정상적인 상태 전송으로 돌아갑니다.
        state.isWatchEnabled = true
        state.phase = .listening
        state.records = Array(repeating: record, count: 25)
        precondition(state.watchSnapshot.isWatchEnabled && state.watchSnapshot.phase == .listening)
        precondition(state.watchSnapshot.sessionID == id && state.watchSnapshot.records.count == 20)
        precondition(state.records.count == 25)
        do {
            _ = try JSONDecoder().decode(PracticeState.self, from: Data("{}".utf8))
            preconditionFailure("손상된 상태를 허용하면 안 됩니다.")
        } catch is DecodingError {}
        print("PracticeStateTests passed")
    }
}
