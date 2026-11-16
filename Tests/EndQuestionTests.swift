//
//  EndQuestionTests.swift
//
//  "스티밍이 끝났나요?" 묻기 상태를 기기 없이 확인합니다.
//  한 번 물으면 사용자가 답할 때까지 닫히지 않고, 기록할 종료 시각은 처음 물어본 시각 그대로인지 봅니다.
//  실행: Tests/verify-end-question.sh
//

import Foundation

@main
struct EndQuestionTests {
    static func main() {
        let t0 = Date(timeIntervalSince1970: 1_000)
        var question = EndQuestion()
        precondition(!question.isAsking && question.endedAt == nil)

        // 소리가 끊겨 처음 물음 → 창이 뜸
        question.ask(endedAt: t0)
        precondition(question.isAsking && question.endedAt == t0)

        // 창이 떠 있는 동안 소리가 다시 이어졌다가 또 끝난 것 같아도: 창은 그대로, 종료 시각도 처음 그대로
        question.ask(endedAt: t0.addingTimeInterval(8))
        question.ask(endedAt: t0.addingTimeInterval(20))
        precondition(question.isAsking && question.endedAt == t0)

        // '계속 연습' → 닫힘. 그 뒤 다시 끝난 것 같으면 새 시각으로 다시 물음
        question.close()
        precondition(!question.isAsking && question.endedAt == nil)
        question.ask(endedAt: t0.addingTimeInterval(30))
        precondition(question.isAsking && question.endedAt == t0.addingTimeInterval(30))

        print("EndQuestionTests passed (답할 때까지 유지, 처음 시각 유지, 계속 연습 뒤 다시 묻기)")
    }
}
