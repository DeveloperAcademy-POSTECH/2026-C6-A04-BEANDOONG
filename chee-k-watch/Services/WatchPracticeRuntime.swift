import WatchKit

/// 워치와 함께 하는 연습 동안 확장 실행 세션을 유지합니다.
@MainActor
final class WatchPracticeRuntime: NSObject, WKExtendedRuntimeSessionDelegate {
    private var session: WKExtendedRuntimeSession?
    private var desiredID: UUID?
    private var attemptedID: UUID?
    private var stopping = false
    private let record: (String) -> Void

    init(record: @escaping (String) -> Void) {
        self.record = record
    }

    /// 연습 종료·워치 제외·연습 교체 시 이전 세션을 정리합니다.
    func update(for state: PracticeState) {
        desiredID = state.isWatchEnabled && state.phase.isRunning ? state.sessionID : nil
        if let session, desiredID != attemptedID, !stopping {
            stopping = true
            session.invalidate()
        } else {
            startIfNeeded()
        }
    }

    /// 활성 상태에서 연습당 한 번만 요청해 시스템 종료 후 재시작을 반복하지 않습니다.
    private func startIfNeeded() {
        guard session == nil, let desiredID, desiredID != attemptedID,
              WKApplication.shared().applicationState == .active else { return }
        let session = WKExtendedRuntimeSession()
        self.session = session
        attemptedID = desiredID
        session.delegate = self
        session.start()
    }

    /// 같은 연습에서 실행 중인 세션만 손목을 내렸을 때의 햅틱에 사용합니다.
    func isRunning(for practiceID: UUID?) -> Bool {
        !stopping && attemptedID == practiceID && session?.state == .running
    }

    nonisolated func extendedRuntimeSessionDidStart(_ session: WKExtendedRuntimeSession) {
        Task { @MainActor in
            guard self.session === session, !stopping else { return }
            record("확장 세션 실행 중")
        }
    }

    nonisolated func extendedRuntimeSessionWillExpire(_ session: WKExtendedRuntimeSession) {
        Task { @MainActor in
            guard self.session === session else { return }
            record("확장 세션 만료 예정")
        }
    }

    nonisolated func extendedRuntimeSession(_ session: WKExtendedRuntimeSession,
                                            didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason,
                                            error: Error?) {
        Task { @MainActor in
            guard self.session === session else { return }
            self.session = nil
            stopping = false
            record("확장 세션 종료 · 사유 \(reason.rawValue) \(error?.localizedDescription ?? "")")
            startIfNeeded()
        }
    }
}
