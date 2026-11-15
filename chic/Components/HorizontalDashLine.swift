import SwiftUI

/// 높이 `y` 에서 `from` 부터 `to` 까지 이어지는 가로선 (점선 모양은 `stroke` 의 `dash` 로 정해요)
///
/// 좌표는 이 도형을 놓은 영역의 왼쪽 위 기준 pt 예요. 비커 안 수위선(연습 화면 · 결과 화면 가이드)이 같이 써요.
/// 연습 화면의 `DashLine` · 결과 화면의 `GuideDashLine` 과 같은 경로예요.
///
///     HorizontalDashLine(y: MilkLevel.upperLine, from: 15.5, to: 161.5)
///         .stroke(color, style: StrokeStyle(lineWidth: 7.0 / 3, lineCap: .round, dash: [5, 16.0 / 3]))
///
/// 이름이 `DashLine` 이 아닌 이유: `SteamingFeedbackView.swift` 안에 같은 이름의 `private struct DashLine` 이 있어서,
/// 같은 이름의 타입을 하나 더 만들면 "invalid redeclaration" 으로 컴파일이 안 돼요. 그 private 타입을 지울 때 이름을 바꿔도 돼요.
struct HorizontalDashLine: Shape {
    let y: CGFloat
    let from: CGFloat
    let to: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: from, y: y))
        path.addLine(to: CGPoint(x: to, y: y))
        return path
    }
}
