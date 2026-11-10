import SwiftUI

/// 도넛 한 줄: 어두운 트랙 위에 비율만큼 색 호를 그린다 (둥근 끝)
/// - 보이는 호(둥근 끝 포함)가 12시 방향에서 −23.5° 지점에서 시작해 `ratio * 360°` 만큼 시계 방향으로 이어진다.
///   (Hi-Fi 255 도넛 지름 189 · 두께 34, Hi-Fi 69 기록 카드 링 지름 58.6 · 두께 10에서 같은 각도로 측정)
/// - 크기는 바깥에서 `.frame(width:height:)`로 정한다 (정사각형).
struct ArcRing: View {
    let ratio: Double
    let lineWidth: CGFloat
    let color: Color
    var trackColor: Color = PracticeResultColors.innerBackground
    /// 차오르는 등장 애니메이션용: 최종 비율. 지정하면 처음에는 둥근 끝 하나 크기의 점으로 나타나며 서서히 진해져요 (`ratio`를 0 → 최종 비율로 키워 쓰세요).
    var introTarget: Double? = nil

    /// 보이는 호가 시작하는 각도 (12시 = 0°, 시계 방향이 +)
    static let visibleStartDegrees: Double = -23.5

    var body: some View {
        GeometryReader { proxy in
            let diameter = min(proxy.size.width, proxy.size.height)
            let radius = (diameter - lineWidth) / 2
            let capDegrees = Double(lineWidth / 2 / radius) * 180 / .pi
            let sweep = max(0, ratio * 360 - 2 * capDegrees)
            // 등장 애니메이션: 처음 둥근 끝 하나가 점으로 나타나는 동안 서서히 진해져요 (길이 0인 호는 그려지지 않아서 아주 조금 길이를 줘요)
            let introOpacity = introTarget.map { min(1, ratio * 360 / min(2 * capDegrees, max($0 * 360, 0.01))) } ?? 1
            ZStack {
                Circle().stroke(trackColor, lineWidth: lineWidth)
                if ratio > 0 {
                    Circle()
                        .trim(from: 0, to: (introTarget == nil ? sweep : max(sweep, 0.02)) / 360)
                        .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                        // SwiftUI 호는 3시 방향에서 시작하므로 12시 기준으로 −90°
                        .rotationEffect(.degrees(-90 + Self.visibleStartDegrees + capDegrees))
                        .opacity(introOpacity)
                }
            }
            .padding(lineWidth / 2)
            .frame(width: diameter, height: diameter)
        }
        .accessibilityHidden(true)
    }
}

/// 도넛 한 칸: 12시 기준 `startDegrees`에서 시계 방향으로 `seenDegrees`(둥근 끝 포함)만큼 차오른 호 하나 (트랙 없음)
/// - 연습 결과 상태별 감지 시간 원이 차오르는 애니메이션에 써요 (애니메이션 벤치 `ringArc`와 같은 계산).
/// - `closed`: 한 바퀴를 다 채우는 원이에요. 끝에서 머리와 꼬리가 맞물려 틈이 없어요.
/// - `fullDegrees`: 이 호가 다 차오른 모습의 각도. 처음 둥근 끝 하나 크기의 점이 서서히 진해지는 길이의 기준이에요.
/// - 크기는 바깥에서 `.frame(width:height:)`로 정한다 (정사각형).
struct ArcFill: View {
    let seenDegrees: Double
    let startDegrees: Double
    let lineWidth: CGFloat
    let color: Color
    var closed = false
    var fullDegrees: Double = 360

    var body: some View {
        GeometryReader { proxy in
            let diameter = min(proxy.size.width, proxy.size.height)
            let radius = (diameter - lineWidth) / 2
            let capDegrees = Double(lineWidth / 2 / radius) * 180 / .pi
            let bodyDegrees = max(0, seenDegrees - 2 * capDegrees * (closed ? 1 - seenDegrees / 360 : 1))
            Circle()
                .trim(from: 0, to: max(bodyDegrees, 0.02) / 360)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                // 호가 둥근 끝 두 개보다 짧으면 점 하나가 호의 가운데에 놓여요
                .rotationEffect(.degrees(-90 + startDegrees + min(capDegrees, fullDegrees / 2)))
                .padding(lineWidth / 2)
                .frame(width: diameter, height: diameter)
                .opacity(seenDegrees <= 0 ? 0 : min(1, seenDegrees / min(2 * capDegrees, max(fullDegrees, 0.01))))
        }
        .accessibilityHidden(true)
    }
}
