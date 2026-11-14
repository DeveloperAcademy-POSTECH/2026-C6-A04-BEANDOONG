import Foundation

@main
struct ConnectionErrorTests {
    static func main() throws {
        let app = URL(fileURLWithPath: CommandLine.arguments[1])
        let english = Bundle(url: app.appendingPathComponent("en.lproj"))!
        let korean = Bundle(url: app.appendingPathComponent("ko.lproj"))!
        let key = "iPhone에서 마이크 권한을 허용해주세요."
        let outgoing = ConnectionError.localized(key)
        let koreanReply = outgoing.reply(in: korean)
        let englishReply = outgoing.reply(in: english)
        precondition(koreanReply["error"] == key)
        precondition(englishReply["error"] == "Please allow microphone access on your iPhone.")
        // iPhone과 Watch 언어가 다른 양방향 모두 수신 기기의 번역을 사용합니다.
        let onEnglishWatch = ConnectionError(reply: koreanReply)!
        precondition(onEnglishWatch.description(in: english) == englishReply["error"])
        let onKoreanWatch = ConnectionError(reply: englishReply)!
        precondition(onKoreanWatch.description(in: korean) == key)
        // 이전 앱의 오류 문구와 시스템 오류는 원문 그대로 유지합니다.
        let legacy = ConnectionError(reply: ["error": "Legacy error"])!
        precondition(legacy.description(in: english) == "Legacy error")
        precondition(ConnectionError.message("System error").reply() == ["error": "System error"])
        precondition(ConnectionError(reply: ["state": Data()]) == nil)
        let encoded = try PropertyListSerialization.data(fromPropertyList: koreanReply, format: .binary, options: 0)
        let decoded = try PropertyListSerialization.propertyList(from: encoded, format: nil) as! [String: Any]
        precondition(ConnectionError(reply: decoded)!.description(in: english) == englishReply["error"])
        print("PASS: cross-language errors, legacy replies, system errors, and wire serialization")
    }
}
