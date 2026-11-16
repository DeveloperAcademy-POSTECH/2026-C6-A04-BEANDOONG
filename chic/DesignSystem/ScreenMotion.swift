import SwiftUI

// MARK: - 홈으로 돌아올 때

/// 연습 결과 화면에서 뒤로가기로 메인에 돌아갈 때의 움직임 (시스템 화면 뒤로가기와 같은 느낌)
enum ScreenPopMotion {
    /// 결과 화면이 오른쪽으로 밀려 나가고 홈이 제자리로 오는 시간·곡선
    static let animation = Animation.timingCurve(MotionCurve.easeOutQuint, duration: 0.42)
    /// 홈이 밀려 들어오기 전에 왼쪽으로 물러나 있는 거리(pt)
    static let homeParallax: CGFloat = 90
    /// 결과 화면 뒤에서 홈을 덮고 있다가 걷히는 검정 (0이면 안 덮음)
    static let homeDim: Double = 0.35
}

// MARK: - 홈 등장 애니메이션

/// 홈 요소가 차례로 떠오르는 타이밍
/// - 온보딩이 걷히기 시작하고 0.15초 뒤에 첫 요소가 출발하고, 요소 사이는 0.06초씩 늦게 출발해요.
/// - 각 요소는 12pt 아래에서 0.45초 동안 떠오르며 나타나요 (스플래시·온보딩과 같은 ease-out-expo).
enum HomeEntranceMotion {
    static let startDelay: TimeInterval = 0.15
    static let stagger: TimeInterval = 0.06
    static let duration: TimeInterval = 0.45
    static let riseDistance: CGFloat = 12

    static func animation(order: Int) -> Animation {
        Animation.timingCurve(MotionCurve.easeOutExpo, duration: duration)
            .delay(startDelay + stagger * Double(order))
    }
}

extension View {
    /// `order`번째로 나타나는 홈 요소: 나타나기 전에는 투명하게 조금 아래에 있다가 제자리로 떠올라요.
    func homeEntrance(order: Int, hasEntered: Bool) -> some View {
        self
            .opacity(hasEntered ? 1 : 0)
            .offset(y: hasEntered ? 0 : HomeEntranceMotion.riseDistance)
            .animation(HomeEntranceMotion.animation(order: order), value: hasEntered)
    }
}
