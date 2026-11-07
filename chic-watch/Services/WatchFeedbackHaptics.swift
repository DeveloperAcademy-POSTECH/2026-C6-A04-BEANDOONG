import Combine
import Foundation
import OSLog
#if os(watchOS)
import WatchKit
#endif

/// 아이폰에서 받은 스티밍 소리 판정에 맞춰 워치 햅틱을 재생합니다.
@MainActor
final class WatchFeedbackHaptics: ObservableObject {
    private let logger = Logger(subsystem: "com.beandoong.cheek", category: "watch-feedback")
    #if os(watchOS)
    private lazy var runtime = WatchPracticeRuntime { [weak self] in self?.record($0) }
    #endif
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

    nonisolated enum Feedback: Equatable {
        case failure, skip(String)
    }

    /// 연습의 실행 상태를 반영하고 판정에 맞는 햅틱을 한 번 요청합니다.
    func receive(previous: PracticeState, current: PracticeState) {
        #if os(watchOS)
        runtime.update(for: current)
        let now = Date()
        switch Self.feedback(previous: previous, current: current, now: now) {
        case .failure: break
        case .skip(let reason):
            record("\(current.phase.title) · 제외(\(reason))")
            return
        }
        let isActive = WKApplication.shared().applicationState == .active
        guard isActive || runtime.isRunning(for: current.sessionID) else {
            record("\(current.phase.title) · 확장 세션 없음 · 진동 생략")
            return
        }
        let source = isActive ? "활성" : "확장 세션"
        playHaptic(.failure, for: "\(current.phase.title) · \(source)")
        #endif
    }

    /// 쇳소리·파바박 상태에 진입할 때만 경고합니다.
    nonisolated static func feedback(previous: PracticeState, current: PracticeState, now: Date) -> Feedback {
        guard current.isWatchEnabled, current.sessionID != nil else { return .skip("워치 연습 아님") }
        guard current.updatedAt > previous.updatedAt else { return .skip("이미 받았거나 오래된 판정") }
        guard abs(now.timeIntervalSince(current.updatedAt)) < 2 else { return .skip("지연된 판정") }
        let samePhase = previous.sessionID == current.sessionID && previous.phase == current.phase
        switch current.phase {
        case .moreAir, .bubble:
            return samePhase ? .skip("같은 경고 상태") : .failure
        default:
            return .skip("진동 대상 아님")
        }
    }

    #if os(watchOS)
    /// 워치에 햅틱을 요청하고 API 호출이 돌아온 시점을 기록합니다.
    private func playHaptic(_ type: WKHapticType, for source: String) {
        WKInterfaceDevice.current().play(type)
        record("\(source) · 직접 진동 호출")
    }

    #if DEBUG
    /// 연습 상태 수신과 분리해 같은 햅틱을 워치에서 한 번 요청합니다.
    func testHaptic() {
        guard WKApplication.shared().applicationState == .active else {
            record("수동 테스트 · 앱 비활성")
            return
        }
        playHaptic(.failure, for: "수동 테스트")
    }
    #endif
    #endif
}
