//
//  PracticeState.swift
//
//  iPhone과 Apple Watch가 함께 사용하는 연습 데이터 정의입니다.
//  연습 상태, 세션 ID, 시작·종료 시간, 기록 메타데이터와 워치 명령의 전송 형식을 통일합니다.
//  화면 디자인과 녹음 처리는 포함하지 않습니다.
//

import Foundation

// iPhone이 유일한 상태 원본입니다. 워치는 이 값만 표시합니다.
nonisolated enum PracticePhase: String, Codable, CaseIterable {
    case idle, listening, aeration, bubble, moreAir, milkFlow, finished

    var isRunning: Bool { self != .idle && self != .finished }

    var title: String {
        switch self {
        case .idle: String(localized: "연결 확인")
        case .listening: String(localized: "소리 확인 중")
        case .aeration: String(localized: "공기 주입 소리")
        case .bubble: String(localized: "버블링")
        case .moreAir: String(localized: "스크래칭")
        case .milkFlow: String(localized: "롤링")
        case .finished: String(localized: "연습을 마쳤어요")
        }
    }
}

nonisolated struct PracticeRecord: Codable, Identifiable, Equatable {
    let id: UUID
    let startedAt: Date
    let endedAt: Date
    var pausedDuration: TimeInterval?
    var duration: TimeInterval { max(0, endedAt.timeIntervalSince(startedAt) - (pausedDuration ?? 0)) }
}

nonisolated struct PracticeState: Codable, Equatable {
    var phase: PracticePhase = .idle
    // 이번 연습을 워치와 함께 진행하는지 구분합니다. 페어링 여부와는 별개입니다.
    var isWatchEnabled = true
    var sessionID: UUID?
    var startedAt: Date?
    var endedAt: Date?
    var pausedAt: Date?
    var pausedDuration: TimeInterval?
    var records: [PracticeRecord] = []
    var updatedAt: Date = .distantPast

    // 워치 없이 진행 중이면 중단 안내만 보내고, 연습 상태·시간·기록은 전달하지 않습니다.
    // 즉시 전송과 재연결 시 응답 모두 이 값을 사용해야 연습 정보가 새지 않습니다.
    var watchSnapshot: PracticeState {
        guard isWatchEnabled else {
            var snapshot = PracticeState()
            snapshot.isWatchEnabled = false
            snapshot.updatedAt = updatedAt
            return snapshot
        }
        var snapshot = self
        snapshot.records = Array(records.prefix(20))
        return snapshot
    }

    /// 잠금과 선택 대기 시간을 제외한 실제 연습 시간입니다.
    func duration(at time: Date) -> TimeInterval {
        guard let startedAt else { return 0 }
        return max(0, min(time, pausedAt ?? time).timeIntervalSince(startedAt) - (pausedDuration ?? 0))
    }

    /// 마이크를 다시 켠 시각까지 한 번의 일시 정지 시간을 합산합니다.
    mutating func resume(at time: Date) {
        guard let pausedAt else { return }
        pausedDuration = (pausedDuration ?? 0) + max(0, time.timeIntervalSince(pausedAt))
        self.pausedAt = nil
    }

    var duration: TimeInterval { duration(at: endedAt ?? Date()) }

    var durationText: String {
        let seconds = Int(duration)
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

nonisolated enum WatchCommand: String, Codable {
    case sync, start, stop, finishReview
}

nonisolated struct WatchRequest: Codable {
    let command: WatchCommand
    let sessionID: UUID?
    let expiresAt: Date
}
