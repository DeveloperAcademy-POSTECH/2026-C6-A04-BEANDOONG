import SwiftUI

/// 우유가 담기는 비커 안쪽 모양: 기울어진 두 벽 · 바닥 · 모서리 · 잔물결 길이
///
/// 연습 화면(`SteamingFeedbackView`)과 온보딩 4/5(`MilkLevelIllustration`)가 같은 `MilkSurface`로 우유를 그리고,
/// 비커 크기에 맞는 값만 다르게 넣어요. 좌표는 각 비커 그림의 왼쪽 위 기준 pt 예요.
struct MilkVessel {
    /// 벽 한쪽: x = intercept + slope · y
    struct Wall {
        let intercept: CGFloat
        let slope: CGFloat

        func x(at y: CGFloat) -> CGFloat { intercept + slope * y }
    }

    /// 안쪽 왼쪽 벽 · 오른쪽 벽 (우유가 닿는 면)
    let left: Wall
    let right: Wall
    /// 우유 바닥 y
    let bottom: CGFloat
    /// 모서리 반지름 (윗면 · 바닥). 우유가 얕으면 높이의 절반까지 줄여요.
    let topRadius: CGFloat
    let bottomRadius: CGFloat
    /// 잔물결 한 주기 길이 (pt)
    let wavelength: Double
    /// 물결 윗면을 몇 pt 간격으로 이어 그릴지
    var sampleStep: CGFloat = 4
}

/// 우유: 윗면 `top`부터 바닥까지, 비커 안쪽 벽을 따르는 모서리 둥근 사다리꼴.
/// 공기 주입 중에는 윗면이 잔물결처럼 살짝 출렁여요 (`amplitude` = 물결 높이).
struct MilkSurface: Shape {
    let vessel: MilkVessel
    var top: CGFloat
    var amplitude: CGFloat = 0
    var phase: Double = 0

    /// 가로 위치 x에서 윗면이 위아래로 움직인 양. 길이가 다른 물결 두 개를 섞어 규칙적이지 않게 보여요.
    private func ripple(at x: CGFloat) -> CGFloat {
        guard amplitude > 0 else { return 0 }
        let k = 2 * Double.pi / vessel.wavelength
        let wave = 0.7 * sin(k * Double(x) - phase) + 0.3 * sin(1.9 * k * Double(x) + 1.3 * phase)
        return amplitude * CGFloat(wave)
    }

    func path(in rect: CGRect) -> Path {
        let bottom = vessel.bottom
        let top = min(self.top, bottom - 1)
        let height = bottom - top
        let topR = min(vessel.topRadius, height / 2)
        let bottomR = min(vessel.bottomRadius, height / 2)
        let leftX = vessel.left.x(at: top)
        let rightX = vessel.right.x(at: top)
        let topLeft = CGPoint(x: leftX, y: top + ripple(at: leftX))
        let topRight = CGPoint(x: rightX, y: top + ripple(at: rightX))
        let bottomRight = CGPoint(x: vessel.right.x(at: bottom), y: bottom)
        let bottomLeft = CGPoint(x: vessel.left.x(at: bottom), y: bottom)

        var path = Path()
        // 윗면: 왼쪽 모서리 끝에서 오른쪽 모서리 앞까지 물결을 따라 그려요.
        let startX = leftX + topR
        let endX = rightX - topR
        path.move(to: CGPoint(x: startX, y: top + ripple(at: startX)))
        if amplitude > 0 {
            var x = startX + vessel.sampleStep
            while x < endX {
                path.addLine(to: CGPoint(x: x, y: top + ripple(at: x)))
                x += vessel.sampleStep
            }
        }
        path.addLine(to: CGPoint(x: endX, y: top + ripple(at: endX)))
        path.addArc(tangent1End: topRight, tangent2End: bottomRight, radius: topR)
        path.addArc(tangent1End: bottomRight, tangent2End: bottomLeft, radius: bottomR)
        path.addArc(tangent1End: bottomLeft, tangent2End: topLeft, radius: bottomR)
        path.addArc(tangent1End: topLeft, tangent2End: CGPoint(x: startX, y: top + ripple(at: startX)), radius: topR)
        path.closeSubpath()
        return path
    }
}
