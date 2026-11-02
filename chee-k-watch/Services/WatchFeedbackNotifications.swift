import Foundation
import OSLog
import UserNotifications

/// 워치가 받은 연습 상태 변화를 로컬 시스템 알림으로 전달합니다.
@MainActor
final class WatchFeedbackNotifications: NSObject, UNUserNotificationCenterDelegate {
    private let center = UNUserNotificationCenter.current()
    private let identifier = "practice-feedback"
    private let logger = Logger(subsystem: "com.beandoong.cheek", category: "watch-feedback")

    override init() {
        super.init()
        center.delegate = self
    }

    /// 워치 앱을 연 상태에서 피드백 알림 권한을 요청합니다.
    func requestAuthorization() async {
        do { _ = try await center.requestAuthorization(options: [.alert, .sound]) }
        catch { logger.error("피드백 알림 권한 요청 실패: \(error.localizedDescription, privacy: .public)") }
    }

    /// 같은 연습의 새 상태만 알리고 알림 센터에는 최신 피드백 하나를 유지합니다.
    func receive(previous: PracticeState, current: PracticeState) async {
        if !current.isWatchEnabled || current.phase == .idle {
            center.removePendingNotificationRequests(withIdentifiers: [identifier])
            center.removeDeliveredNotifications(withIdentifiers: [identifier])
            return
        }
        guard Self.shouldNotify(previous: previous, current: current, now: Date()) else { return }
        let content = UNMutableNotificationContent()
        content.title = "chic 스티밍 피드백"
        content.body = current.phase.title
        content.sound = .default
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        do { try await center.add(request) }
        catch { logger.error("피드백 알림 등록 실패: \(error.localizedDescription, privacy: .public)") }
    }

    /// 초기 동기화·중복 수신·지난 연습과 8초 이상 지연된 피드백은 알리지 않습니다.
    nonisolated static func shouldNotify(previous: PracticeState, current: PracticeState, now: Date) -> Bool {
        previous.isWatchEnabled && current.isWatchEnabled && current.sessionID != nil &&
        previous.sessionID == current.sessionID && previous.phase != current.phase &&
        current.phase != .idle && current.updatedAt > previous.updatedAt &&
        abs(current.updatedAt.timeIntervalSince(now)) < 8
    }

    /// 화면을 보고 있을 때도 알림의 소리·햅틱을 요청하고 화면 배너는 생략합니다.
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                           willPresent notification: UNNotification,
                                           withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.sound])
    }
}
