import Foundation

/// "스티밍이 끝났나요?" 묻기 상태.
/// - 한 번 물으면 사용자가 '계속 연습' 또는 '연습 종료'를 누를 때까지 그대로 둬요.
///   스팀 소리가 다시 들려도 창을 닫지 않아요. (전에는 소리가 이어지면 창이 저절로 사라졌어요)
/// - 묻는 동안 다시 "끝난 것 같다"는 알림이 와도, '연습 종료' 때 기록할 시각은 처음 물어본 시각 그대로예요.
nonisolated struct EndQuestion: Equatable {
    /// 끝난 것으로 볼 시각. 값이 있는 동안 묻는 창이 떠 있어요.
    private(set) var endedAt: Date?

    var isAsking: Bool { endedAt != nil }

    /// 끝난 것 같다는 알림. 이미 묻는 중이면 아무것도 바꾸지 않아요.
    mutating func ask(endedAt time: Date) {
        guard endedAt == nil else { return }
        endedAt = time
    }

    /// 사용자가 답했거나 연습이 끝났을 때 창을 닫아요.
    mutating func close() {
        endedAt = nil
    }
}
