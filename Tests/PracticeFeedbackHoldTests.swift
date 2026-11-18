@main
struct PracticeFeedbackHoldTests {
    /// 실제 시간을 기다리지 않고 최소 유지 시간과 롤링 예외를 검증합니다.
    static func main() {
        let start = ContinuousClock.now
        func at(_ milliseconds: Int64) -> ContinuousClock.Instant {
            start.advanced(by: .milliseconds(milliseconds))
        }

        for protected in [PracticePhase.aeration, .bubble, .moreAir] {
            var hold = PracticeFeedbackHold()
            precondition(hold.allowsTransition(from: .listening, to: protected, at: at(0)))
            for next in [PracticePhase.aeration, .bubble, .moreAir, .milkFlow] where next != protected {
                precondition(!hold.allowsTransition(from: protected, to: next, at: at(499)))
            }
            precondition(hold.allowsTransition(from: protected, to: protected, at: at(499)))
            precondition(hold.allowsTransition(from: protected, to: .milkFlow, at: at(500)))
            precondition(hold.allowsTransition(from: .milkFlow, to: protected, at: at(501)))
            precondition(!hold.allowsTransition(from: protected, to: .milkFlow, at: at(1000)))
            precondition(hold.allowsTransition(from: protected, to: .milkFlow, at: at(1001)))
        }

        var hold = PracticeFeedbackHold()
        precondition(hold.allowsTransition(from: .listening, to: .aeration, at: at(0)))
        precondition(!hold.allowsTransition(from: .aeration, to: .bubble, at: at(100)))
        precondition(!hold.allowsTransition(from: .aeration, to: .moreAir, at: at(400)))
        precondition(hold.allowsTransition(from: .aeration, to: .milkFlow, at: at(500)))
        precondition(hold.allowsTransition(from: .milkFlow, to: .bubble, at: at(501)))
        precondition(!hold.allowsTransition(from: .bubble, to: .moreAir, at: at(1000)))
        precondition(hold.allowsTransition(from: .bubble, to: .moreAir, at: at(1001)))

        // 일시 정지 또는 새 연습으로 소리 확인 화면에 돌아왔으면 이전 유지 시간을 넘겨받지 않습니다.
        precondition(hold.allowsTransition(from: .listening, to: .aeration, at: at(1002)))
        precondition(!hold.allowsTransition(from: .aeration, to: .milkFlow, at: at(1501)))
        precondition(hold.allowsTransition(from: .aeration, to: .milkFlow, at: at(1502)))
        print("PASS feedback holds for 0.5 seconds, rolling exits immediately, repeated results and resumed sessions")
    }
}
