// Watch는 iPhone의 판정만 받습니다. Watch 마이크와 DSP는 실행하지 않습니다.
import Foundation
import SwiftUI
import WatchConnectivity
import WatchKit

@MainActor final class PulseReceiver: NSObject, ObservableObject, WCSessionDelegate {
    // 화면은 최근 iPhone 메시지와 연습 상태를 관찰합니다.
    @Published private(set) var connected = false
    @Published private(set) var running = false
    @Published private(set) var active = false
    private var lastReceived: Date?
    private let session = WCSession.default

    override init() {
        super.init()
        // iPhone 전송 파일과 별개로 Watch 쪽 세션도 활성화해야 합니다.
        guard WCSession.isSupported() else { return }
        session.delegate = self
        session.activate()
    }

    func expireIfNeeded() {
        // iPhone 앱이 종료되거나 메시지가 끊겨도 공기음 표시가 남지 않게 합니다.
        guard let lastReceived, Date().timeIntervalSince(lastReceived) < 3 else {
            clear()
            return
        }
    }

    private func clear() {
        connected = false
        running = false
        active = false
        lastReceived = nil
    }

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // 첫 상태 메시지는 iPhone의 연결 가능 알림 또는 다음 상태 전송으로 받습니다.
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        // iPhone과 실시간 통신이 끊기면 이전 판정을 즉시 숨깁니다.
        guard !session.isReachable else { return }
        Task { @MainActor [weak self] in self?.clear() }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        // 필수 값이 빠진 메시지는 화면과 진동에 사용하지 않습니다.
        guard let running = message["running"] as? Bool,
              let active = message["active"] as? Bool,
              let pulse = message["pulse"] as? Bool else { return }
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.connected = true
            self.running = running
            self.active = running && active
            self.lastReceived = Date()
            // 진동은 iPhone DSP가 요청한 순간에만 Watch에서 실행합니다.
            if running && active && pulse { WKInterfaceDevice.current().play(.click) }
        }
    }
}
