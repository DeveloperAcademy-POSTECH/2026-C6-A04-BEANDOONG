import SwiftUI

// MARK: - 히어로

struct ReportHero: View {
    @Environment(\.designScale) private var scale
    let result: PracticeResult
    let headline: String

    var body: some View {
        ZStack(alignment: .topLeading) {
            heroBackground
                .frame(height: ReportLayout.heroHeight.v(scale))

            Text(headline)
                .font(.pretendard(.bold, size: 26))
                .lineSpacing(ReportLayout.headlineLineSpacing)
                .multilineTextAlignment(.center)
                .foregroundStyle(AppColors.darkSecondaryButton)
                .padding(.horizontal, ReportLayout.sectionTitleX.h(scale))
                .frame(maxWidth: .infinity)
                .at(x: 0, y: ReportLayout.headlineY, scale)

            // 링: 언제나 주의 소리 비율 (2026-11-14 시안 304 · 307). 어두운 트랙 위에 12시부터 주의 소리 색 호.
            // 잘 됐을 때(주의 소리 0초)와 감지된 소리가 없을 때는 트랙만 있고 가운데 "0% 주의소리".
            ZStack {
                ArcRing(
                    ratio: result.cautionRatio,
                    lineWidth: ReportLayout.donutLineWidth,
                    color: AppColors.soundCaution,
                    startDegrees: ReportLayout.donutStartDegrees
                )
                VStack(spacing: ReportLayout.donutTextSpacing) {
                    Text("\(Int((result.cautionRatio * 100).rounded()))%")
                        .font(.pretendard(.bold, size: 36))
                        .foregroundStyle(AppColors.soundCaution)
                    Text(String(localized: "주의소리"))
                        .font(.pretendard(.regular, size: ReportLayout.donutLabelSize))
                        .foregroundStyle(AppColors.darkSecondaryButton)
                        .offset(y: ReportLayout.donutLabelDY)
                }
            }
            .frame(width: ReportLayout.donutDiameter.h(scale), height: ReportLayout.donutDiameter.h(scale))
            .at(x: ReportLayout.donutCenterX - ReportLayout.donutDiameter / 2, y: ReportLayout.donutY, scale)

            // 3열 요약
            HStack(spacing: 0) {
                summaryColumn(String(localized: "전체 시간"), result.totalSeconds)
                summaryColumn(String(localized: "정상 소리"), result.normalSeconds)
                summaryColumn(String(localized: "주의 소리"), result.cautionSeconds)
            }
            .frame(width: (ReportLayout.summaryColumnWidth * 3).h(scale), height: ReportLayout.summaryHeight.v(scale))
            .overlay(alignment: .topLeading) {
                ForEach([1, 2], id: \.self) { index in
                    Rectangle()
                        .fill(AppColors.darkSecondaryButton)
                        .frame(width: 1, height: ReportLayout.summaryHeight.v(scale))
                        .offset(x: (ReportLayout.summaryColumnWidth * CGFloat(index)).h(scale) - 0.5)
                }
            }
            .at(x: ReportLayout.summaryX, y: ReportLayout.summaryY, scale)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func summaryColumn(_ label: String, _ seconds: Int) -> some View {
        VStack(spacing: ReportLayout.summaryTextSpacing) {
            Text(label)
                .font(.pretendard(.regular, size: 12))
                .foregroundStyle(ReportColors.summaryLabel)
            Text(seconds.practiceSecondsText)
                .font(.pretendard(.bold, size: 22))
                .foregroundStyle(Color.white)
        }
        .frame(maxWidth: .infinity)
    }

    /// 위는 배경색, 아래로 갈수록 은은한 네이비 글로우가 올라오는 둥근 컨테이너
    private var heroBackground: some View {
        ZStack {
            LinearGradient(
                stops: [
                    .init(color: AppColors.darkBackground, location: 0.0),
                    .init(color: AppColors.darkBackground, location: 0.62),
                    .init(color: PracticeResultColors.heroGradientEdgeBottom, location: 1.0)
                ],
                startPoint: .top, endPoint: .bottom
            )
            RadialGradient(
                colors: [PracticeResultColors.heroGradientCenterBottom.opacity(0.6), Color.clear],
                center: .bottom, startRadius: 0, endRadius: 260
            )
        }
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 0, bottomLeadingRadius: ReportLayout.heroCornerRadius,
                bottomTrailingRadius: ReportLayout.heroCornerRadius, topTrailingRadius: 0, style: .continuous
            )
        )
    }
}
