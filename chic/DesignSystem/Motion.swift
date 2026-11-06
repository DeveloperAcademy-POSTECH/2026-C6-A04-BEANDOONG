import SwiftUI

// MARK: - 모션 곡선

/// 화면 애니메이션에서 같이 쓰는 가감속 곡선 (CSS cubic-bezier 와 같은 값)
///
/// 값은 애니메이션 벤치(Animation Bench)에서 정한 사양을 그대로 옮겼어요.
enum MotionCurve {
    /// 빠르게 출발해 끝에서 아주 길게 멈춤 (ease-out-expo)
    /// - 스플래시 로고가 떠오를 때, 온보딩 내용이 들어올 때
    static let easeOutExpo = UnitCurve.bezier(
        startControlPoint: UnitPoint(x: 0.16, y: 1),
        endControlPoint: UnitPoint(x: 0.3, y: 1)
    )

    /// 빠르게 출발해 부드럽게 멈춤 (ease-out-quart)
    /// - 연습 결과 도넛 링이 차오를 때
    static let easeOutQuart = UnitCurve.bezier(
        startControlPoint: UnitPoint(x: 0.25, y: 1),
        endControlPoint: UnitPoint(x: 0.5, y: 1)
    )

    /// 끝에서 덜 늘어지는 ease-out (ease-out-quad)
    /// - 스플래시 로고의 흐림이 걷힐 때
    static let easeOutQuad = UnitCurve.bezier(
        startControlPoint: UnitPoint(x: 0.5, y: 1),
        endControlPoint: UnitPoint(x: 0.89, y: 1)
    )

    /// 천천히 출발해 점점 빨라짐 (ease-in)
    /// - 온보딩 내용이 밀려 나갈 때
    static let easeIn = UnitCurve.bezier(
        startControlPoint: UnitPoint(x: 0.4, y: 0),
        endControlPoint: UnitPoint(x: 1, y: 1)
    )

    /// 천천히 출발해 천천히 멈춤 (ease-in-out)
    /// - 온보딩 페이지 표시가 다음 자리로 옮겨 갈 때
    static let easeInOut = UnitCurve.bezier(
        startControlPoint: UnitPoint(x: 0.65, y: 0),
        endControlPoint: UnitPoint(x: 0.35, y: 1)
    )
}
