// iPhone의 판정 상태만 Watch에 전달합니다. 마이크 샘플과 FFT 결과는 보내지 않습니다.
import Foundation
import WatchConnectivity

@MainActor final class PulseSender: NSObject, WCSessionDelegate {
    // Watch가 늦게 열려도 현재 상태를 다시 보낼 수 있도록 마지막 판정을 기억합니다.
    private var running = false
    private var active = false
    private var lastSent = -Double.infinity
    private let session = WCSession.default

    override init() {
        super.init()
        // 양쪽 앱이 세션을 활성화해야 실시간 메시지를 주고받을 수 있습니다.
        guard WCSession.isSupported() else { return }
        session.delegate = self
        session.activate()
    }

    func publish(running: Bool, active: Bool, pulse: Bool = false) {
        let changed = self.running != running || self.active != active
        self.running = running
        self.active = active
        // 상태 변화와 진동은 즉시, 변하지 않는 상태는 1초마다 보내 Watch의 끊김 감지에 씁니다.
        let now = ProcessInfo.processInfo.systemUptime
        guard changed || pulse || now - lastSent >= 1 else { return }
        send(pulse: pulse)
    }

    private func send(pulse: Bool) {
        // 연결되지 않은 동안 메시지를 쌓지 않습니다. 재연결 시 현재 상태만 보냅니다.
        guard session.activationState == .activated, session.isReachable else { return }
        lastSent = ProcessInfo.processInfo.systemUptime
        session.sendMessage(["running": running, "active": active, "pulse": pulse],
                            replyHandler: nil,
                            errorHandler: { error in NSLog("Watch 상태 전송 실패: %@", error.localizedDescription) })
    }

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // 세션 활성화가 끝나면 그 사이 시작된 연습의 최신 상태를 전송합니다.
        Task { @MainActor [weak self] in self?.send(pulse: false) }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        // Watch 앱이 나중에 열려도 과거 진동 없이 현재 표시 상태만 동기화합니다.
        Task { @MainActor [weak self] in self?.send(pulse: false) }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        // 다른 Watch로 전환 중에는 새 세션이 활성화되기를 기다립니다.
    }

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        // 페어링된 Watch가 바뀌었을 때 새 세션을 다시 활성화합니다.
        session.activate()
    }
}
