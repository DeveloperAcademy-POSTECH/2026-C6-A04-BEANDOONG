@main
struct PracticeFeedbackHoldTests {
    /// 실제 시간을 기다리지 않고 1초 경계와 롤링·연습 재개 예외를 검증합니다.
    static func main() {
        let start = ContinuousClock.now
        func at(_ milliseconds: Int64) -> ContinuousClock.Instant {
            start.advanced(by: .milliseconds(milliseconds))
        }

        for protected in [PracticePhase.aeration, .bubble, .moreAir] {
            var hold = PracticeFeedbackHold()
            precondition(hold.allowsTransition(from: .listening, to: protected, at: at(0)))
            for next in [PracticePhase.aeration, .bubble, .moreAir, .milkFlow] where next != protected {
                precondition(!hold.allowsTransition(from: protected, to: next, at: at(999)))
            }
            precondition(hold.allowsTransition(from: protected, to: protected, at: at(999)))
            precondition(hold.allowsTransition(from: protected, to: .milkFlow, at: at(1000)))
            precondition(hold.allowsTransition(from: .milkFlow, to: protected, at: at(1001)))
            precondition(!hold.allowsTransition(from: protected, to: .milkFlow, at: at(2000)))
            precondition(hold.allowsTransition(from: protected, to: .milkFlow, at: at(2001)))
        }

        var hold = PracticeFeedbackHold()
        precondition(hold.allowsTransition(from: .listening, to: .aeration, at: at(0)))
        precondition(!hold.allowsTransition(from: .aeration, to: .bubble, at: at(100)))
        precondition(!hold.allowsTransition(from: .aeration, to: .moreAir, at: at(700)))
        precondition(hold.allowsTransition(from: .aeration, to: .bubble, at: at(1000)))
        precondition(!hold.allowsTransition(from: .bubble, to: .moreAir, at: at(1999)))
        precondition(hold.allowsTransition(from: .bubble, to: .moreAir, at: at(2000)))
        precondition(hold.allowsTransition(from: .listening, to: .aeration, at: at(2001)))
        precondition(!hold.allowsTransition(from: .aeration, to: .milkFlow, at: at(3000)))
        precondition(hold.allowsTransition(from: .aeration, to: .milkFlow, at: at(3001)))
        print("PASS 1-second feedback hold, rolling exception, repeated results and resumed sessions")
    }
}
