import Foundation

/// 화면 애니메이션 계산에 같이 쓰는 쉬운 수학 함수
///
/// 식은 여러 화면에서 따로 쓰던 것과 **부동소수점 연산 순서까지 같아요**. 그래서 이 함수로 바꿔도 결과 숫자가 한 비트도 달라지지 않아요.
/// `Double` 과 `CGFloat` 둘 다 쓸 수 있게 `BinaryFloatingPoint` 로 만들어서, 부르는 쪽이 타입을 바꿔 감쌀 일이 없어요.
///
///     let fade = Easing.smoothstep((time - fadeStart) / fadeDuration)
enum Easing {
    /// 0 ... 1 범위로 자르기
    static func clamp01<T: BinaryFloatingPoint>(_ value: T) -> T {
        min(max(value, 0), 1)
    }

    /// 처음과 끝이 부드러운 곡선 (smoothstep): 먼저 0 ... 1 로 자른 뒤 `t * t * (3 - 2 * t)`
    ///
    /// 이미 0 ... 1 로 자른 값을 넣어도 결과는 같아요 (자르기는 두 번 해도 같은 값이에요).
    static func smoothstep<T: BinaryFloatingPoint>(_ value: T) -> T {
        let t = clamp01(value)
        return t * t * (3 - 2 * t)
    }

    /// 빠르게 출발해 부드럽게 멈춤 (ease-out-quad): `1 - (1 - x)²`
    ///
    /// 0 ... 1 로 자르지 않아요. 범위 밖 값이 올 수 있으면 `clamp01` 을 먼저 거치세요.
    /// (`MotionCurve.easeOutQuad` 는 `withAnimation` 에 쓰는 곡선이고, 이 함수는 값을 직접 계산할 때 써요.)
    static func easeOutQuad<T: BinaryFloatingPoint>(_ value: T) -> T {
        1 - (1 - value) * (1 - value)
    }

    /// 칸 수가 `count` 인 원 위에서 두 칸 `a` · `b` 사이의 거리 (시계 · 반시계 중 가까운 쪽, 0 ... count/2)
    ///
    /// 칸은 소수여도 돼요 (칸 사이를 부드럽게 지나감). 방향이 없는 거리예요.
    /// 방향 있는 거리(−count/2 ..< +count/2)는 `signedCircularOffset` 을 써요.
    static func circularDistance(_ a: Double, _ b: Double, count: Int) -> Double {
        let n = Double(count)
        let forward = (a - b).truncatingRemainder(dividingBy: n)
        let wrapped = forward < 0 ? forward + n : forward
        return min(wrapped, n - wrapped)
    }

    /// 칸 수가 `count` 인 원 위에서 `raw` 만큼 떨어진 칸의 방향 있는 거리: −count/2 이상 +count/2 미만
    ///
    /// 가장 가까운 쪽으로 재고, 정확히 반대편(count/2)은 −count/2 로 놓아요. `circularDistance` 와 식이 달라 서로 바꿔 쓸 수 없어요.
    static func signedCircularOffset(_ raw: Double, count: Int) -> Double {
        let n = Double(count)
        let wrapped = (raw.truncatingRemainder(dividingBy: n) + n).truncatingRemainder(dividingBy: n)
        return wrapped >= n / 2 ? wrapped - n : wrapped
    }
}
