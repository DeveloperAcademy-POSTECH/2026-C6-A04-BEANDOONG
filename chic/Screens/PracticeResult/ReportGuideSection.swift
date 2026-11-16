import SwiftUI

// MARK: - 스팀 가이드

/// "스팀 가이드" 제목 + 비커 그림 + 안내 카드. 위치는 섹션 맨 위(제목 글자 상자 위) 기준 (Hi-Fi 연습 가이드 3종)
struct ReportGuideSection: View {
    @Environment(\.designScale) private var scale
    let guide: PracticeGuide
    /// 이번 연습의 모델과 공기 주입 시간으로 계산한 우유 높이예요.
    let milkTop: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                Text(String(localized: "스팀 가이드"))
                    .font(.pretendard(.bold, size: 20))
                    .foregroundStyle(Color.white)
                    .at(x: ReportLayout.sectionTitleX, y: 0, scale)

                ReportGuidePitcher(milkTop: milkTop)
                    .designScaled(size: ReportLayout.guidePitcherSize, scale)
                    .at(x: ReportLayout.guidePitcherX, y: ReportLayout.guidePitcherTop, scale)
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .frame(height: ReportLayout.guideCardTop.v(scale), alignment: .topLeading)

            ReportGuideCard(guide: guide)
        }
    }
}

/// 가이드 비커: 빈 비커 그림 위에 공기 주입한 만큼 우유를 채우고, 적정 범위의 두 점선을 그려요.
/// 좌표는 비커 그림(289.7×217pt) 기준, Hi-Fi 260과 3x 에셋에서 잰 값이에요.
struct ReportGuidePitcher: View {
    /// 비커 그림 에셋 이름 (결과 로딩 화면이 뜰 때 미리 디코딩해 둬요)
    static let imageName = "IllustPracticeGuidePitcher"

    let milkTop: CGFloat

    var body: some View {
        ZStack(alignment: .topLeading) {
            Image.prepared(Self.imageName)
                .resizable()
                .frame(width: ReportLayout.guidePitcherSize.width, height: ReportLayout.guidePitcherSize.height)

            GuideMilkShape(top: milkTop)
                .fill(PracticeResultColors.guideMilk)

            HorizontalDashLine(y: GuideMilkLevel.upperLine, from: 15.5, to: 161.5)
                .stroke(AppColors.darkSecondaryButton, style: Self.lineStyle(phase: 2.33))
            HorizontalDashLine(y: GuideMilkLevel.lowerLine, from: 13.5, to: 165.8)
                .stroke(AppColors.darkSecondaryButton, style: Self.lineStyle(phase: 2.67))
        }
        .frame(width: ReportLayout.guidePitcherSize.width, height: ReportLayout.guidePitcherSize.height, alignment: .topLeading)
    }

    /// 점선: 두께 7px, 선 22px · 틈 9px (3x 에셋), 끝이 둥근 점선
    private static func lineStyle(phase: CGFloat) -> StrokeStyle {
        StrokeStyle(lineWidth: 7.0 / 3, lineCap: .round, dash: [5, 16.0 / 3], dashPhase: phase)
    }
}

/// 가이드 비커 안쪽 벽 (Hi-Fi 260): 왼쪽 x = 32.9 − 0.1417y, 오른쪽 x = 149.85 + 0.1083y
private struct GuideMilkShape: Shape {
    let top: CGFloat

    func path(in rect: CGRect) -> Path {
        let bottom = GuideMilkLevel.bottom
        let top = min(self.top, bottom - 1)
        let height = bottom - top
        let topR = min(3, height / 2)
        let bottomR = min(10, height / 2)
        func left(_ y: CGFloat) -> CGFloat { 32.9 - 0.1417 * y }
        func right(_ y: CGFloat) -> CGFloat { 149.85 + 0.1083 * y }
        let topLeft = CGPoint(x: left(top), y: top)
        let topRight = CGPoint(x: right(top), y: top)
        let bottomRight = CGPoint(x: right(bottom), y: bottom)
        let bottomLeft = CGPoint(x: left(bottom), y: bottom)
        var path = Path()
        path.move(to: CGPoint(x: (topLeft.x + topRight.x) / 2, y: top))
        path.addArc(tangent1End: topRight, tangent2End: bottomRight, radius: topR)
        path.addArc(tangent1End: bottomRight, tangent2End: bottomLeft, radius: bottomR)
        path.addArc(tangent1End: bottomLeft, tangent2End: topLeft, radius: bottomR)
        path.addArc(tangent1End: topLeft, tangent2End: topRight, radius: topR)
        path.closeSubpath()
        return path
    }
}

/// 안내 카드: 왼쪽 아이콘 + 제목 + 설명
private struct ReportGuideCard: View {
    @Environment(\.designScale) private var scale
    let guide: PracticeGuide

    var body: some View {
        HStack(alignment: .top, spacing: CGFloat(12).h(scale)) {
            Image(systemName: guide.systemImage)
                .font(.system(size: guide == .onTarget ? 19 : 22, weight: guide == .onTarget ? .semibold : .regular))
                .foregroundStyle(Color.white)
                .frame(width: 28, height: 28)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: ReportLayout.guideTitleToMessage.v(scale)) {
                Text(guide.title)
                    .font(.pretendard(.semibold, size: 16))
                    .foregroundStyle(Color.white)
                Text(guide.message)
                    .font(.pretendard(.regular, size: 12))
                    .lineSpacing(ReportLayout.guideMessageLineSpacing)
                    .foregroundStyle(PracticeResultColors.guideMessage)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, CGFloat(18).h(scale))
        .padding(.vertical, ReportLayout.guideTextTop.v(scale))
        .frame(width: ReportLayout.guideCardWidth.h(scale), alignment: .leading)
        .frame(minHeight: ReportLayout.guideCardHeight.v(scale), alignment: .leading)
        .background(PracticeResultColors.cardBackground, in: RoundedRectangle(cornerRadius: ReportLayout.guideCardRadius))
        .accessibilityElement(children: .combine)
    }
}
