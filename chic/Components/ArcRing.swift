import SwiftUI

/// 도넛 한 줄: 어두운 트랙 위에 비율만큼 색 호를 그린다 (둥근 끝)
/// - 보이는 호(둥근 끝 포함)가 `startDegrees`(12시 = 0°, 기본 −23.5°)에서 시작해 `ratio * 360°` 만큼 시계 방향으로 이어진다.
///   (기본 각도는 Hi-Fi 255 도넛 · 옛 69 기록 카드 링에서 측정. 연습 결과 · 기록 상세의 주의 소리 링은 0°)
/// - 크기는 바깥에서 `.frame(width:height:)`로 정한다 (정사각형).
struct ArcRing: View {
    let ratio: Double
    let lineWidth: CGFloat
    let color: Color
    var trackColor: Color = PracticeResultColors.innerBackground
    /// 보이는 호가 시작하는 각도 (12시 = 0°, 시계 방향이 +)
    var startDegrees: Double = ArcRing.visibleStartDegrees

    /// 기본 시작 각도 (12시 = 0°, 시계 방향이 +)
    static let visibleStartDegrees: Double = -23.5

    var body: some View {
        GeometryReader { proxy in
            let diameter = min(proxy.size.width, proxy.size.height)
            let radius = (diameter - lineWidth) / 2
            let capDegrees = Double(lineWidth / 2 / radius) * 180 / .pi
            let sweep = max(0, ratio * 360 - 2 * capDegrees)
            ZStack {
                Circle().stroke(trackColor, lineWidth: lineWidth)
                if ratio > 0 {
                    Circle()
                        .trim(from: 0, to: sweep / 360)
                        .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                        // SwiftUI 호는 3시 방향에서 시작하므로 12시 기준으로 −90°
                        .rotationEffect(.degrees(-90 + startDegrees + capDegrees))
                }
            }
            .padding(lineWidth / 2)
            .frame(width: diameter, height: diameter)
        }
        .accessibilityHidden(true)
    }
}
