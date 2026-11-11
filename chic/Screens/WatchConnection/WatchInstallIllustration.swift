import SwiftUI

/// chic 설치 안내 일러스트 (WCH-03 진행 링 회전)
///
/// 워치 화면의 chic 아이콘을 둘러싼 파란 호가 1초에 한 바퀴씩 시계 방향으로 돌아요.
///
///     ┌ 베이스: 워치 + chic 아이콘 (링 자리를 비운 이미지, IllustWatchInstallBase)
///     └ 어두운 트랙 + 파란 호: 코드로 그려서 호만 회전
///
/// - 첫 프레임은 Hi-Fi 정지 화면과 같은 자리예요.
/// - 동작 줄이기(Reduce Motion)가 켜져 있으면 Hi-Fi 정지 화면으로 멈춰 있어요.
struct WatchInstallIllustration: View {
    var body: some View {
        ZStack {
            AssetImageView(name: "IllustWatchInstallBase", width: Spec.frameSize.width, height: Spec.frameSize.height)

            LoopTimeline(period: Spec.period) { progress in
                IllustrationCanvas(pixelSize: Spec.frameSize, frameSize: Spec.frameSize) { context in
                    drawRing(in: &context, turned: progress * 360)
                }
            }
        }
        .accessibilityHidden(true)
    }

    /// 파란 호를 `turned`도만큼 시계 방향으로 돌린 자리에 그리고, 나머지 구간은 어두운 트랙으로 채워요.
    ///
    /// 트랙을 원 전체로 그린 위에 같은 굵기의 파란 호를 겹치면, 두 선의 가장자리(안티에일리어싱)가 섞여
    /// 파란 호 바깥·안쪽에 어두운 테두리가 비쳐 보였어요. 그래서 트랙은 파란 호가 없는 구간에만 그려요.
    private func drawRing(in context: inout GraphicsContext, turned: Double) {
        // 베이스 이미지의 비운 자리는 화면에 놓일 때 픽셀 경계에 딱 맞지 않아(일러스트 위치 234.6pt) 링 가장자리 밖으로
        // 뒤의 어두운 배경이 1px 비쳤어요. 링보다 조금 넓게 워치 화면색을 먼저 칠해 비운 자리를 메운 뒤 링을 그려요.
        let fill = Path(ellipseIn: CGRect(
            x: Spec.ringCenter.x - Spec.ringRadius, y: Spec.ringCenter.y - Spec.ringRadius,
            width: Spec.ringRadius * 2, height: Spec.ringRadius * 2
        ))
        context.stroke(fill, with: .linearGradient(Spec.screenGradient, startPoint: Spec.screenGradientStart, endPoint: Spec.screenGradientEnd),
                       lineWidth: Spec.lineWidth + Spec.fillOverhang * 2)

        let arcStart = Spec.arcStart + turned
        let arcEnd = Spec.arcEnd + turned
        // 파란 호가 끝난 곳에서 다음 바퀴의 시작까지가 트랙이에요
        context.stroke(arcPath(from: arcEnd, to: arcStart + 360), with: .color(Spec.trackColor), style: Spec.strokeStyle)
        context.stroke(arcPath(from: arcStart, to: arcEnd), with: .color(Spec.arcColor), style: Spec.strokeStyle)
    }

    /// 12시에서 시계 방향 각도 `from` → `to` 까지의 호
    private func arcPath(from: Double, to: Double) -> Path {
        var path = Path()
        path.addArc(
            center: Spec.ringCenter,
            radius: Spec.ringRadius,
            startAngle: Spec.screenAngle(clockFromTwelve: from),
            endAngle: Spec.screenAngle(clockFromTwelve: to),
            clockwise: false // 화면 좌표(y 아래쪽)에서 false = 눈으로 보기에 시계 방향
        )
        return path
    }
}

// MARK: - 사양 (애니메이션 벤치 WCH-03, 일러스트 왼쪽 위 기준 pt)

private enum Spec {
    /// 한 바퀴 도는 시간(초): iOS 기본 스피너처럼 1초에 한 바퀴
    static let period: TimeInterval = 1.0

    /// 화면에 놓이는 크기(pt) — 기존 일러스트와 같아요
    static let frameSize = CGSize(width: 121, height: 207)

    /// 링 중심과 선 중심 반지름: 베이스 이미지(`IllustWatchInstallBase`, @3x)에 비워 둔 링 자리에 정확히 맞춘 값이에요.
    /// 비운 자리는 픽셀 좌표 가로 96 ~ 237 · 세로 237 ~ 378(바깥), 안쪽 반지름 약 62.7px → 중심 (166.5, 307.5)px, 바깥 반지름 70.5px.
    /// (전에는 시안 좌표 195.92, 337.27 에서 옮긴 중심을 써서 비운 자리보다 0.5px 아래에 그려졌고, 그 틈으로 뒤 배경이 비쳤어요)
    /// 링의 가운데는 워치 화면의 가운데라서, 워치 몸통 가운데(영역 가로 가운데)보다 5pt 왼쪽이에요 (시안 그대로).
    static let ringCenter = CGPoint(x: 166.5 / 3, y: 307.5 / 3)
    static let ringRadius: CGFloat = 66.6 / 3
    /// 선 두께 2.7pt(8.1px): 비운 자리(7.8px)를 양쪽으로 조금씩 넉넉히 덮어요
    static let lineWidth: CGFloat = 2.7
    /// 비운 자리를 메우는 워치 화면색이 링 바깥·안쪽으로 더 나가는 폭 (pt). 주변 이미지와 같은 색이라 보이지 않아요.
    static let fillOverhang: CGFloat = 0.5
    /// 링 자리의 워치 화면색: 베이스 이미지에서 링 바로 위(237px)와 바로 아래(378px)를 잰 위 → 아래 그라데이션
    static let screenGradient = Gradient(colors: [Color(hex: 0xE7F5FE), Color(hex: 0xD5EEFC)])
    static let screenGradientStart = CGPoint(x: ringCenter.x, y: 237.0 / 3)
    static let screenGradientEnd = CGPoint(x: ringCenter.x, y: 378.0 / 3)
    /// 끝은 둥글지 않고 잘린 모양이에요 (시안 그대로)
    static let strokeStyle = StrokeStyle(lineWidth: lineWidth, lineCap: .butt)

    /// 둥글게 한 바퀴 이어진 어두운 트랙
    static let trackColor = Color(hex: 0x080C16)

    /// 파란 호 범위 (12시에서 시계 방향 각도)
    static let arcStart: Double = 204
    static let arcEnd: Double = 360.5
    static let arcColor = Color(hex: 0x3976FA)

    /// "12시에서 시계 방향 각도"를 SwiftUI 각도(3시에서 시계 방향)로 바꿔요.
    static func screenAngle(clockFromTwelve degrees: Double) -> Angle {
        .degrees(degrees - 90)
    }
}

#Preview {
    WatchInstallIllustration()
        .padding(40)
        .background(AppColors.darkBackground)
}
