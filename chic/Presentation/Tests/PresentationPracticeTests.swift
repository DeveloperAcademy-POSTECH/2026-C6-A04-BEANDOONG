#if PRESENTATION_TESTS
import Foundation

@main
struct PresentationPracticeTests {
    @MainActor
    static func main() async throws {
        let start = Date(timeIntervalSince1970: 1_000)
        func at(_ seconds: TimeInterval) -> Date { start.addingTimeInterval(seconds) }

        var practice = PresentationPractice(startedAt: start)
        precondition(practice.phase == .aeration)
        precondition(practice.aerationClock.isRunning)
        precondition(practice.aerationClock.seconds(at: start) == 0)

        // 두 번째 파랑만 2초, 나머지 구간은 1.5초씩 표시합니다.
        practice.advance()
        precondition(practice.phase == .bubble)
        precondition(!practice.aerationClock.isRunning)
        practice.advance()
        precondition(practice.phase == .moreAir)
        practice.advance()
        precondition(practice.phase == .aeration)
        precondition(practice.stepDuration == 2)
        precondition(practice.aerationClock.seconds(at: at(5.5)) == 2.5)
        var earlySecondAeration = practice
        let partial = earlySecondAeration.finish(at: at(5.5))
        precondition(partial.segments.last == DetectedSegment(sound: .normalAeration, start: 4.5, end: 5.5))
        precondition(partial.timelineLength == 5.5)

        practice.advance()
        precondition(practice.phase == .milkFlow && !practice.isComplete)
        precondition(practice.aerationClock.seconds(at: at(6.5)) == 3.5)
        practice.advance()
        precondition(practice.isComplete && practice.phase == .milkFlow)
        precondition(!practice.aerationClock.isRunning)
        precondition(practice.aerationClock.seconds(at: at(60)) == 3.5)

        // 8초 이후에는 마지막 상태와 수위를 유지하고, 대기 시간은 결과에 더하지 않습니다.
        practice.advance()
        precondition(practice.isComplete && practice.phase == .milkFlow)
        let result = practice.finish(at: at(60))
        precondition(result.segments == [
            DetectedSegment(sound: .normalAeration, start: 0, end: 1.5),
            DetectedSegment(sound: .overAeration, start: 1.5, end: 3),
            DetectedSegment(sound: .lackOfAir, start: 3, end: 4.5),
            DetectedSegment(sound: .normalAeration, start: 4.5, end: 6.5),
            DetectedSegment(sound: .rolling, start: 6.5, end: 8)
        ])
        precondition(result.timelineLength == 8)
        precondition(result.totalSeconds == 8)
        precondition(result.normalSeconds == 5 && result.cautionSeconds == 3)
        precondition(practice.finish(at: at(90)) == result)

        // 첫 배경 도중 종료하거나 진입 직후 종료해도 가상의 나머지 구간을 만들지 않습니다.
        var early = PresentationPractice(startedAt: start)
        precondition(early.finish(at: at(0.5)).segments == [
            DetectedSegment(sound: .normalAeration, start: 0, end: 0.5)
        ])
        var immediate = PresentationPractice(startedAt: start)
        precondition(immediate.finish(at: start).segments.isEmpty)

        // 실제 화면의 수위 추종 계산을 60fps로 재생합니다.
        // 첫 프레임부터 내려가지 않고, 마지막 초록으로 넘어갈 때 이미 두 점선 안에 있어야 합니다.
        var animated = PresentationPractice(startedAt: start)
        let motion = PitcherMotion()
        var nextChange = animated.stepDuration
        var previousTop = MilkLevel.start
        for frameIndex in 0...600 {
            let time = Double(frameIndex) / 60
            if time >= nextChange, !animated.isComplete {
                animated.advance()
                nextChange += animated.stepDuration
            }
            let date = at(time)
            let frame = motion.advance(
                to: date,
                targetTop: MilkLevel.top(forAeration: animated.aerationClock.seconds(at: date)),
                rippling: animated.aerationClock.isRunning || animated.isComplete,
                still: false
            )
            precondition(frame.top <= previousTop + 0.0001)
            if time >= 6.5 {
                precondition(frame.top > MilkLevel.upperLine && frame.top < MilkLevel.lowerLine)
            }
            if time >= PresentationPractice.duration {
                precondition(frame.rippleAmplitude > 0)
            }
            previousTop = frame.top
        }

        print("PresentationPracticeTests passed (파주보파초, 시작 수위, 2초 보충, 하강 없음, 초록 진입 시 적정 수위, 8초 완료, 대기 제외)")
        try await PresentationWatchSyncTests.run()
    }
}
#endif
