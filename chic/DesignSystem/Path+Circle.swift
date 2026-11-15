import SwiftUI

extension CGRect {
    /// 중심 `center`, 반지름 `radius` 인 원이 꼭 맞게 들어가는 정사각형
    ///
    /// 원에 그라데이션을 씌울 때 위 · 아래 끝(`minY` · `maxY`)을 이 정사각형에서 재면 돼요.
    static func circleBounds(center: CGPoint, radius: CGFloat) -> CGRect {
        CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
    }
}

extension Path {
    /// 중심 `center`, 반지름 `radius` 인 원
    ///
    /// `Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))` 와 똑같은 경로예요.
    ///
    ///     context.fill(Path.circle(center: Spec.center, radius: Spec.coreRadius), with: paint)
    static func circle(center: CGPoint, radius: CGFloat) -> Path {
        Path(ellipseIn: .circleBounds(center: center, radius: radius))
    }
}
