import Combine
import Foundation
import OSLog
#if os(watchOS)
import WatchKit
#endif

/// 아이폰에서 새 공기주입 상태가 도착하면 워치에서 직접 진동을 요청합니다.
@MainActor
final class WatchFeedbackHaptics: ObservableObject {
    private let logger = Logger(subsystem: "com.beandoong.cheek", category: "watch-feedback")
    #if DEBUG && os(watchOS)
    @Published private(set) var history: [String] = []
    #endif

    /// 디버거 없이도 워치에서 최근 피드백의 처리 결과를 확인할 수 있게 기록합니다.
    private func record(_ message: String) {
        logger.notice("\(message, privacy: .public)")
        #if DEBUG && os(watchOS)
        history = ["\(Date().formatted(date: .omitted, time: .standard))  \(message)"] + history.prefix(11)
        #endif
    }

    /// 같은 연습에서 공기주입에 진입한 순간만 손목에 전달합니다.
    func receive(previous: PracticeState, current: PracticeState) {
        if let reason = Self.exclusionReason(previous: previous, current: current, now: Date()) {
            record("\(current.phase.title) · 제외(\(reason))")
            return
        }
        #if os(watchOS)
        guard WKApplication.shared().applicationState == .active else {
            record("공기주입 · 비활성 · 진동 생략")
            return
        }
        playHaptic(for: "공기주입 · 활성")
        #endif
    }

    /// 초기 동기화·중복 수신·지난 연습과 8초 이상 지연된 피드백은 알리지 않습니다.
    nonisolated static func exclusionReason(previous: PracticeState, current: PracticeState, now: Date) -> String? {
        guard previous.isWatchEnabled && current.isWatchEnabled else { return "워치 제외" }
        guard current.sessionID != nil, previous.sessionID == current.sessionID else { return "첫 수신 또는 다른 연습" }
        guard current.phase == .aeration else { return "공기주입 아님" }
        guard previous.phase != current.phase else { return "같은 상태" }
        guard current.updatedAt > previous.updatedAt else { return "같거나 오래된 갱신 시각" }
        let age = now.timeIntervalSince(current.updatedAt)
        guard abs(age) < 8 else { return "갱신 시각 차이 \(age.formatted(.number.precision(.fractionLength(1))))초" }
        return nil
    }

    #if os(watchOS)
    /// 워치에 햅틱을 요청하고 API 호출이 돌아온 시점을 기록합니다.
    private func playHaptic(for source: String) {
        WKInterfaceDevice.current().play(.notification)
        record("\(source) · 직접 진동 호출")
    }

    #if DEBUG
    /// 연습 상태 수신과 분리해 같은 햅틱을 워치에서 한 번 요청합니다.
    func testHaptic() {
        guard WKApplication.shared().applicationState == .active else {
            record("수동 테스트 · 앱 비활성")
            return
        }
        playHaptic(for: "수동 테스트")
    }
    #endif
    #endif
}
