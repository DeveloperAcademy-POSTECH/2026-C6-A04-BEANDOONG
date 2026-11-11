//
//  AerationClockTests.swift
//
//  기기 없이 실행할 수 있는 비커 수위 계산 검증 코드입니다.
//  공기 주입 화면이 켜졌다 꺼질 때의 누적 시간과, 누적 시간에 따른 우유 수위를 확인합니다.
//  실행: Tests/verify-aeration-clock.sh
//

import Foundation

@main
struct AerationClockTests {
    static func main() {
        let t0 = Date(timeIntervalSince1970: 1_000)
        func at(_ s: TimeInterval) -> Date { t0.addingTimeInterval(s) }
        func near(_ a: Double, _ b: Double) -> Bool { abs(a - b) < 0.001 }

        // 시작 전에는 0초, 멈춰 있으면 시간이 흘러도 그대로입니다.
        var clock = AerationClock()
        precondition(clock.seconds(at: at(5)) == 0 && !clock.isRunning)

        // 파랑 0.5초 → 다른 색 2초 → 파랑 1.2초 → 연습 종료
        clock.resume(at: at(0))
        precondition(near(clock.seconds(at: at(0.3)), 0.3))
        clock.pause(at: at(0.5))
        precondition(near(clock.seconds(at: at(2.5)), 0.5))
        clock.resume(at: at(2.5))
        clock.resume(at: at(3.0))   // 이미 세는 중이면 시작 시각을 바꾸지 않아요
        precondition(near(clock.seconds(at: at(3.7)), 1.7))
        clock.pause(at: at(3.7))
        clock.pause(at: at(9))      // 두 번 멈춰도 더하지 않아요
        precondition(near(clock.seconds(at: at(20)), 1.7))

        // 종료 시각이 구간 시작보다 앞서면(소리가 끊긴 시각으로 종료) 음수로 빼지 않아요.
        var early = AerationClock(accumulated: 1)
        early.resume(at: at(10))
        early.pause(at: at(8))
        precondition(near(early.seconds(at: at(20)), 1))

        // 수위: 0초 바닥 근처 → 2초 아래 점선 → 5초 위 점선 → 입구에 가까워질수록 느려짐 (닿지는 않음)
        precondition(MilkLevel.top(forAeration: 0) == MilkLevel.start)
        precondition(MilkLevel.top(forAeration: -1) == MilkLevel.start)
        precondition(near(MilkLevel.top(forAeration: 2), MilkLevel.lowerLine))
        precondition(near(MilkLevel.top(forAeration: 5), MilkLevel.upperLine))
        let mid = MilkLevel.top(forAeration: 3.5)
        precondition(mid < MilkLevel.lowerLine && mid > MilkLevel.upperLine)   // 2~5초는 두 점선 사이
        precondition(MilkLevel.top(forAeration: 6) < MilkLevel.upperLine)
        let far = MilkLevel.top(forAeration: 60)
        precondition(far > MilkLevel.highest && far - MilkLevel.highest < 0.5)
        // 5초 앞뒤로 오르는 속도가 끊기지 않고, 그 뒤로는 점점 느려져요.
        let before = MilkLevel.top(forAeration: 4.99) - MilkLevel.top(forAeration: 5)
        let after = MilkLevel.top(forAeration: 5) - MilkLevel.top(forAeration: 5.01)
        precondition(abs(before - after) < 0.01)
        let later = MilkLevel.top(forAeration: 9) - MilkLevel.top(forAeration: 9.01)
        precondition(later < after)
        // 시간이 늘면 수위는 내려가지 않아요.
        var last = CGFloat.infinity
        for step in 0...200 {
            let top = MilkLevel.top(forAeration: Double(step) * 0.1)
            precondition(top <= last)
            last = top
        }
        // 부드럽게 따라가기: 처음 값은 목표로 바로, 그 뒤로는 늦게 따라가며 목표를 넘지 않아요.
        var follower = SmoothFollower(smoothTime: 0.35)
        precondition(follower.step(toward: 276, dt: 0) == 276)
        var previous = 276.0
        for _ in 0..<120 {   // 2초 동안 목표가 162.8로 갑자기 바뀜
            let v = follower.step(toward: 162.8, dt: 1.0 / 60)
            precondition(v <= previous && v >= 162.8)
            previous = v
        }
        precondition(follower.isSettled(at: 162.8) || abs(previous - 162.8) < 0.05)
        // 첫 프레임은 아주 조금만 움직여요 (출발이 부드러움).
        var fresh = SmoothFollower(smoothTime: 0.35)
        fresh.step(toward: 100, dt: 0)
        let first = fresh.step(toward: 0, dt: 1.0 / 60)
        precondition(100 - first < 2)
        // 앱이 멈췄다 돌아와 dt가 커도 한 번에 튀지 않아요.
        var paused = SmoothFollower(smoothTime: 0.35)
        paused.step(toward: 100, dt: 0)
        precondition(paused.step(toward: 0, dt: 30) > 10)

        print("AerationClockTests passed (누적 시간, 수위 0·2·3.5·5초, 입구 감속, 부드럽게 따라가기)")
    }
}
