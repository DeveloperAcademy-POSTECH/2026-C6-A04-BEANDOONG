import Foundation

/// 알려진 오류는 번역 키를 함께 보내 수신 기기의 언어로 표시합니다.
/// `error` 필드는 이전 버전 앱과 시스템 오류에 대한 호환성을 유지합니다.
nonisolated enum ConnectionError: LocalizedError {
    case message(String)
    case localized(String)

    init?(reply: [String: Any]) {
        if let key = reply["errorKey"] as? String {
            self = .localized(key)
        } else if let message = reply["error"] as? String {
            self = .message(message)
        } else {
            return nil
        }
    }

    var errorDescription: String? { description(in: .main) }

    func description(in bundle: Bundle) -> String {
        switch self {
        case .message(let text): text
        case .localized(let key): bundle.localizedString(forKey: key, value: key, table: nil)
        }
    }

    func reply(in bundle: Bundle = .main) -> [String: String] {
        var reply = ["error": description(in: bundle)]
        if case .localized(let key) = self { reply["errorKey"] = key }
        return reply
    }
}
