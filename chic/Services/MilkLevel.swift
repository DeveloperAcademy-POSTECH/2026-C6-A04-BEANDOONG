import Foundation

/// 누적 공기 주입 시간 → 비커 우유 수위.
/// 값은 비커 그림(`IllustSteamingPitcher`, 322×294pt) 위쪽에서 잰 우유 윗면의 y (pt)예요. 작을수록 수위가 높아요.
/// - 0초: 바닥 근처에서 시작
/// - 2초: 아래 점선
/// - 2~4초: 두 점선 사이 (적정 구간)
/// - 4초 이후: 같은 속도로 넘어선 뒤 입구(`highest`)에 가까워질수록 점점 느려져요. 입구에 닿지는 않아요 (넘치기 직전).
nonisolated enum MilkLevel {
    /// 우유 바닥 (Hi-Fi: 865px / 3)
    static let bottom: CGFloat = 288.3
    /// 시작 수위: 바닥에서 12pt (바닥에 깔린 정도)
    static let start: CGFloat = 276
    /// 아래 점선 (Hi-Fi: 화면 y 544.5 = 비커 위 382 + 162.8)
    static let lowerLine: CGFloat = 162.8
    /// 위 점선 (Hi-Fi: 화면 y 516.5 = 비커 위 382 + 134.8)
    static let upperLine: CGFloat = 134.8
    /// 수위가 다가가기만 하는 가장 높은 곳 (비커 입구 아래)
    static let highest: CGFloat = 80

    /// 아래 점선에 닿는 누적 시간 (초)
    static let lowerLineSeconds: TimeInterval = 2
    /// 위 점선에 닿는 누적 시간 (초)
    static let upperLineSeconds: TimeInterval = 4

    /// 두 점선 사이를 지나는 속도 (pt/초)
    private static var risePerSecond: CGFloat {
        (lowerLine - upperLine) / CGFloat(upperLineSeconds - lowerLineSeconds)
    }

    /// 누적 공기 주입 시간에 맞는 우유 윗면 y (pt)
    static func top(forAeration seconds: TimeInterval) -> CGFloat {
        let t = max(0, seconds)
        if t <= lowerLineSeconds {
            return start - (start - lowerLine) * CGFloat(t / lowerLineSeconds)
        }
        if t <= upperLineSeconds {
            return lowerLine - risePerSecond * CGFloat(t - lowerLineSeconds)
        }
        // 위 점선을 같은 속도로 넘어선 뒤, 남은 거리에 비례해 느려져요 (속도가 끊기지 않는 지수 감속).
        let remaining = upperLine - highest
        let decay = Double(risePerSecond / remaining)
        return highest + remaining * CGFloat(exp(-decay * (t - upperLineSeconds)))
    }
}
