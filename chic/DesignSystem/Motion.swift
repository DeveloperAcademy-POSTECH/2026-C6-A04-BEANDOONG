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

// MARK: - 반복 애니메이션 시계

/// 반복 애니메이션용 시계: 화면에 나타난 순간부터 흐른 시간을 한 주기 안의 진행률(0 이상 1 미만)로 넘겨 줘요.
///
/// - 화면에 나타날 때마다 0부터 다시 시작해서, 첫 프레임이 항상 Hi-Fi 정지 화면과 같아요.
/// - 경과 시간을 주기로 나눈 나머지를 쓰기 때문에 반복할 때 이음새가 튀지 않아요.
/// - 동작 줄이기(Reduce Motion)가 켜져 있으면 시계를 멈추고 0(Hi-Fi 정지 화면)만 넘겨요.
///
///     LoopTimeline(period: 1.4) { progress in
///         Spinner(progress: progress)
///     }
struct LoopTimeline<Content: View>: View {
    /// 한 주기 길이(초)
    let period: TimeInterval
    @ViewBuilder let content: (_ progress: Double) -> Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var startDate = Date.now

    var body: some View {
        if reduceMotion {
            content(0)
        } else {
            TimelineView(.animation) { context in
                content(progress(at: context.date))
            }
            .onAppear { startDate = .now }
        }
    }

    private func progress(at date: Date) -> Double {
        let elapsed = max(0, date.timeIntervalSince(startDate))
        return elapsed.truncatingRemainder(dividingBy: period) / period
    }
}
