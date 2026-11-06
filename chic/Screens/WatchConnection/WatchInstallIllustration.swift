import SwiftUI

/// chic 설치 안내 일러스트 (WCH-03 진행 링 회전)
///
/// 워치 화면의 chic 아이콘을 둘러싼 파란 호가 1초에 한 바퀴씩 시계 방향으로 돌아요.
///
///     ┌ 베이스: 워치 + chic 아이콘 (파란 호만 뺀 이미지, IllustWatchInstallBase)
///     └ 파란 호: 코드로 그려서 회전
///
/// - 첫 프레임은 Hi-Fi 정지 화면과 같은 자리예요.
/// - 동작 줄이기(Reduce Motion)가 켜져 있으면 Hi-Fi 정지 화면으로 멈춰 있어요.
struct WatchInstallIllustration: View {
    var body: some View {
        ZStack {
            AssetImageView(name: "IllustWatchInstallBase", width: Spec.frameSize.width, height: Spec.frameSize.height)

            LoopTimeline(period: Spec.period) { progress in
                IllustrationCanvas(pixelSize: Spec.pixelSize, frameSize: Spec.frameSize) { context in
                    drawArc(in: &context, turned: progress * 360)
                }
            }
        }
        .accessibilityHidden(true)
    }

    /// 파란 호를 `turned`도만큼 시계 방향으로 돌린 자리에 그려요.
    private func drawArc(in context: inout GraphicsContext, turned: Double) {
        var arc = Path()
        arc.addArc(
            center: Spec.ringCenter,
            radius: Spec.ringRadius,
            startAngle: Spec.screenAngle(clockFromTwelve: Spec.arcStart + turned),
            endAngle: Spec.screenAngle(clockFromTwelve: Spec.arcEnd + turned),
            clockwise: false // 화면 좌표(y 아래쪽)에서 false = 눈으로 보기에 시계 방향
        )
        context.stroke(arc, with: .color(Spec.arcColor), style: StrokeStyle(lineWidth: Spec.lineWidth, lineCap: .round))
    }
}

// MARK: - 사양 (Hi-Fi 일러스트 실측값, 일러스트 픽셀 단위)

private enum Spec {
    /// 한 바퀴 도는 시간(초)
    static let period: TimeInterval = 1.0

    /// 화면에 놓이는 크기(pt) — 기존 일러스트와 같아요
    static let frameSize = CGSize(width: 121, height: 207)
    /// 일러스트 PNG 크기(px, 3배)
    static let pixelSize = CGSize(width: 363, height: 620)

    /// 링 중심과 선 중심 반지름
    static let ringCenter = CGPoint(x: 165.57, y: 307.3)
    static let ringRadius: CGFloat = 65.74
    /// 선 두께 (2.8pt)
    static let lineWidth: CGFloat = 8.4

    /// 파란 호 범위 (12시에서 시계 방향 각도, 둥근 끝 제외)
    static let arcStart: Double = 206
    static let arcEnd: Double = 359
    static let arcColor = Color(hex: 0x1BA7E9)

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
