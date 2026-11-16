import SwiftUI

// MARK: - 비커

/// 비커 그림 위에 우유·적정 구간·점선을 그려요. 좌표는 비커 그림(322×294pt) 기준, Hi-Fi 3x 에셋에서 잰 값이에요.
///
///     ┌ 비커 + 스팀 노즐 (`IllustSteamingPitcher`, 반투명 흰색)
///     ├ 우유 (윗면 = `milkTop`, 비커 안쪽 벽을 따라 사다리꼴)
///     ├ 적정 구간 (두 점선 사이를 상태 색으로 옅게 칠함)
///     └ 점선 2줄 (위 = 4초, 아래 = 2초)
///
/// 상태별 장식(보라: 물방울 · 주황: 기포)은 `SteamingPitcherDecoration` 이 같은 자리에 따로 겹쳐 그려요.
struct SteamingPitcher: View {
    static let size = CGSize(width: 322, height: 294)
    /// 비커 그림 에셋 이름 (소리 확인 화면이 뜰 때 미리 디코딩해 둬요. `SteamingFeedback.imageNames`)
    static let imageName = "IllustSteamingPitcher"
    let feedback: SteamingFeedback
    /// 우유 윗면 y (`MilkLevel` 값을 부드럽게 따라간 값)
    let milkTop: CGFloat
    /// 우유 윗면 잔물결 높이 (pt, 0이면 잔잔함)와 위상
    var rippleAmplitude: CGFloat = 0
    var ripplePhase: Double = 0

    var body: some View {
        ZStack(alignment: .topLeading) {
            Image.prepared(Self.imageName)
                .resizable()
                .frame(width: Self.size.width, height: Self.size.height)

            MilkSurface(vessel: .steamingPitcher, top: milkTop, amplitude: rippleAmplitude, phase: ripplePhase)
                .fill(AppColors.steamingMilk)

            Band()
                .fill(feedback.bandColor)

            HorizontalDashLine(y: MilkLevel.upperLine, from: Line.upperStart, to: Line.upperEnd)
                .stroke(feedback.lineColor, style: Line.style)
            HorizontalDashLine(y: MilkLevel.lowerLine, from: Line.lowerStart, to: Line.lowerEnd)
                .stroke(feedback.lineColor, style: Line.style)
        }
        .frame(width: Self.size.width, height: Self.size.height, alignment: .topLeading)
    }

    /// 점선 (Hi-Fi: 두께 8px, 선 26px · 틈 10px, 끝이 둥근 점선)
    private enum Line {
        static let style = StrokeStyle(lineWidth: 8.0 / 3, lineCap: .round, dash: [6, 6], dashPhase: 3)
        static let upperStart: CGFloat = 21, upperEnd: CGFloat = 227
        static let lowerStart: CGFloat = 18, lowerEnd: CGFloat = 230
    }
}

/// 비커 위 상태별 장식 (보라: 물방울 · 주황: 기포). 비커(`SteamingPitcher`)와 같은 크기의 칸 위에 같은 자리로 겹쳐요.
///
/// 상태가 바뀌면 이전 장식이 옅어지며 사라지고 새 장식이 나타나요 (`.id` + `.transition(.opacity)`).
/// 비커는 수위를 따라가느라 매 프레임 안쪽을 다시 계산하는 `TimelineView` 안에 있는데, 이 장식은 그 밖에 둬서
/// 사라지는 페이드가 프레임마다 다시 계산되는 일에 끼지 않고, 비커가 그리기를 쉬는 동안(`PitcherMotion.Frame.isResting`)에도 페이드가 그대로 돌아요.
struct SteamingPitcherDecoration: View {
    let feedback: SteamingFeedback

    var body: some View {
        ZStack(alignment: .topLeading) {
            if let decoration = feedback.decoration {
                Image.prepared(decoration.name)
                    .resizable()
                    .frame(width: decoration.size.width, height: decoration.size.height)
                    .offset(x: decoration.origin.x, y: decoration.origin.y)
                    .id(feedback)
                    .transition(.opacity)
            }
        }
        .frame(width: SteamingPitcher.size.width, height: SteamingPitcher.size.height, alignment: .topLeading)
    }
}

/// 비커 안쪽 (우유가 닿는 면). Hi-Fi 3x 에셋에서 잰 직선: 왼쪽 x = 47.33 − 0.15y, 오른쪽 x = 204.51 + 0.1227y
/// 모서리 반지름 (Hi-Fi: 윗면 5pt, 바닥 12pt), 잔물결 한 주기 64pt
private extension MilkVessel {
    static let steamingPitcher = MilkVessel(
        left: Wall(intercept: 47.33, slope: -0.15),
        right: Wall(intercept: 204.51, slope: 0.1227),
        bottom: MilkLevel.bottom,
        topRadius: 5,
        bottomRadius: 12,
        wavelength: 64
    )
}

private enum PitcherWall {
    /// 비커 바깥 테두리 (적정 구간 칠하기용): 왼쪽 x = 42.33 − 0.15y, 오른쪽 x = 209.81 + 0.1247y
    static func outerLeft(_ y: CGFloat) -> CGFloat { 42.33 - 0.15 * y }
    static func outerRight(_ y: CGFloat) -> CGFloat { 209.81 + 0.1247 * y }
}

/// 적정 구간: 두 점선 가운데 사이를 비커 폭만큼 칠해요. (점선이 위에 덮여 경계가 가려져요)
private struct Band: Shape {
    func path(in rect: CGRect) -> Path {
        let top = MilkLevel.upperLine
        let bottom = MilkLevel.lowerLine
        var path = Path()
        path.move(to: CGPoint(x: PitcherWall.outerLeft(top), y: top))
        path.addLine(to: CGPoint(x: PitcherWall.outerRight(top), y: top))
        path.addLine(to: CGPoint(x: PitcherWall.outerRight(bottom), y: bottom))
        path.addLine(to: CGPoint(x: PitcherWall.outerLeft(bottom), y: bottom))
        path.closeSubpath()
        return path
    }
}

// MARK: - 화면 전용 색 (새 연습 중 Hi-Fi 3x 에셋에서 잰 값)

private extension AppColors {
    /// 우유 (에셋 245,250,255 → #F5FAFF)
    static let steamingMilk = Color(hex: 0xF5FAFF)
}
