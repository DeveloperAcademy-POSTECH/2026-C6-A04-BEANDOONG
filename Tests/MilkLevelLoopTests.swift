//
//  MilkLevelLoopTests.swift
//
//  기기 없이 실행할 수 있는 온보딩 4/5 우유 피처(ONB-04) 반복 표 검증 코드입니다.
//  한 바퀴가 이음새 없이 이어지는지, 수위가 위 점선 근처까지 오르는지, 바퀴가 넘어갈 때 잔물결이 잦아들어 있는지 확인합니다.
//  실행: Tests/verify-milk-level-loop.sh
//

import Foundation

@main
struct MilkLevelLoopTests {
    static func main() {
        let loop = MilkLevelLoop()
        let frames = loop.frames

        // 한 바퀴 = 3.4초 × 240 = 816칸
        precondition(frames.count == 816, "칸 수 \(frames.count)")

        // 끝과 시작이 0.05pt 안으로 이어져요 (이음새 없음)
        let first = frames[0], last = frames[frames.count - 1]
        precondition(abs(last.top - first.top) < 0.05, "수위 이음새 \(last.top) → \(first.top)")
        // 시작은 원래 높이(Hi-Fi 수위 83pt)에서 1pt 안쪽. 스프링이 바퀴 끝까지 다 붙지 않아 벤치처럼 조금 높아요.
        precondition(first.top <= MilkLevelLoop.restTop && MilkLevelLoop.restTop - first.top < 1, "시작 수위 \(first.top)")

        // 바퀴가 넘어가는 순간 잔물결은 거의 0 (위상이 끊겨도 보이지 않아요: 0.97pt × 세기 < 0.03pt)
        precondition(first.rippleStrength < 0.03 && last.rippleStrength < 0.03,
                     "잔물결 세기 \(last.rippleStrength) → \(first.rippleStrength)")

        // 수위가 위 점선(55.5pt) 근처까지 오르고, 점선을 넘지 않아요
        let highest = frames.map(\.top).min()!
        precondition(highest < MilkLevelLoop.fullTop + 1, "가장 높은 수위 \(highest)")
        precondition(highest >= MilkLevelLoop.fullTop - 0.001, "점선을 넘음 \(highest)")

        // 공기 주입 중에는 잔물결이 켜져요
        let peakRipple = frames.map(\.rippleStrength).max()!
        precondition(peakRipple > 0.9, "잔물결 최대 세기 \(peakRipple)")

        // 진행률 → 프레임: 0과 끝(반올림하면 다음 바퀴 첫 칸)은 같은 칸
        precondition(loop.frame(at: 0) == first)
        precondition(loop.frame(at: 0.99999) == first)

        // 화살표: 원래 높이 0, 꽉 차면 6pt 위
        precondition(MilkLevelLoop.arrowOffset(forTop: MilkLevelLoop.restTop) == 0)
        precondition(abs(MilkLevelLoop.arrowOffset(forTop: MilkLevelLoop.fullTop) + 6) < 0.0001)

        // 프레임 사이 수위 변화가 한 칸(1/240초)에 0.5pt 를 넘지 않아요 (튐 없음)
        for i in 1..<frames.count {
            precondition(abs(frames[i].top - frames[i - 1].top) < 0.5, "\(i)번째 칸에서 튐")
        }

        print("✅ MilkLevelLoop: \(frames.count)칸, 가장 높은 수위 \(String(format: "%.2f", highest))pt, 이음새 \(String(format: "%.4f", abs(last.top - first.top)))pt, 바퀴 끝 잔물결 \(String(format: "%.4f", last.rippleStrength))")
    }
}
