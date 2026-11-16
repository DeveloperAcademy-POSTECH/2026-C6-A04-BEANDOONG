import SwiftUI

//
//  PracticeReport.swift
//
//  연습 직후 결과(PracticeResultView)와 기록 상세(HistoryDetailView)가 함께 쓰는 리포트 화면입니다.
//  - 상단 히어로: 결과에 따른 타이틀 + 주의 소리 링 + 3열 요약
//  - "스티밍 기록": 소리 유형별 막대 표 (탭 없음)
//  - "연습 가이드": 비커 그림 + 공기 주입 시간에 따른 안내 카드 (`PracticeGuide`)
//  - 하단 안내 문구
//  Hi-Fi: iPhone 17 - 304 (연습 직후, 상단 바 "스티밍 결과") · 307 (기록 상세, 상단 바 "9월 28일 - 1차") (2026-11-14)
//         연습가이드 공기 과도 · 부족 (2026-11-13, 링을 뺀 나머지)
//
//  [구성] (이 파일은 화면 · 페이지 · 안내 문구, 나머지는 따로)
//  - ReportHero.swift         : 상단 히어로 (타이틀 + 링 + 3열 요약)
//  - ReportOverviewChart.swift: "스티밍 기록" 소리 유형별 막대 표 (+ 막대 · 눈금)
//  - ReportGuideSection.swift : "연습 가이드" 비커 그림 + 안내 카드
//  - ReportLayout.swift       : 리포트 색 · 시안 좌표
//

// MARK: - 화면 (스크롤 + 고정 상단 바 + 삭제 팝업)

struct PracticeReportScreen: View {
    @Environment(\.designScale) private var scale
    let result: PracticeResult
    /// 히어로 타이틀 (결과에 따라 화면마다 정한다)
    let headline: String
    /// 상단 바 제목 (연습 직후 "스티밍 결과", 기록 상세는 기록 이름 "9월 28일 - 1차")
    let barTitle: String
    var onBack: (() -> Void)? = nil
    /// 삭제 팝업에서 "기록 삭제"를 확인했을 때
    var onDelete: (() -> Void)? = nil
    @State private var showsDeleteDialog: Bool

    init(
        result: PracticeResult,
        headline: String,
        barTitle: String,
        onBack: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil,
        showsDeleteDialog: Bool = false
    ) {
        self.result = result
        self.headline = headline
        self.barTitle = barTitle
        self.onBack = onBack
        self.onDelete = onDelete
        _showsDeleteDialog = State(initialValue: showsDeleteDialog)
    }

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                PracticeReportPage(result: result, headline: headline)
            }
            .scrollIndicators(.hidden)
            .ignoresSafeArea()

            // 고정 상단 바: 스크롤한 내용이 비쳐 제목과 겹치지 않도록 뒤에 배경을 깔고 아래쪽은 살짝 흐리게 이어 준다.
            // (맨 위에서는 히어로 위쪽 색과 같아 눈에 보이지 않는다)
            VStack(spacing: 0) {
                TopNavigationHeader(
                    title: barTitle, isDark: true, onBack: onBack,
                    trailingSystemImage: "trash", onTrailingIcon: { showsDeleteDialog = true }
                )
                .padding(.top, ScreenMetrics.topBarTop.v(scale))
                .padding(.bottom, ReportLayout.topBarBottomPadding.v(scale))
                .background(AppColors.darkBackground)

                LinearGradient(colors: [AppColors.darkBackground, AppColors.darkBackground.opacity(0)], startPoint: .top, endPoint: .bottom)
                    .frame(height: ReportLayout.topBarFade.v(scale))
                    .allowsHitTesting(false)
            }
        }
        .ignoresSafeArea()
        .darkScreenBackground()
        .chicAlert(
            isPresented: showsDeleteDialog,
            title: String(localized: "정말 기록을 삭제하시겠어요?"),
            message: String(localized: "삭제한 기록은 다시 복구할 수 없어요"),
            cancelTitle: String(localized: "취소"),
            confirmTitle: String(localized: "기록 삭제"),
            confirmColor: AppColors.alertRed,
            onCancel: { showsDeleteDialog = false },
            onConfirm: { showsDeleteDialog = false; onDelete?() }
        )
        .toolbar(.hidden, for: .navigationBar)
        .swipeBackDisabled(showsDeleteDialog)
    }
}

// MARK: - 페이지 본문 (스크롤 안쪽 · 긴 화면 캡처 공용)

/// 화면 맨 위(상태바 포함)부터 안내 문구 아래까지의 긴 페이지. 모든 위치는 iPhone 17 시안 좌표(pt)입니다.
struct PracticeReportPage: View {
    @Environment(\.designScale) private var scale
    let result: PracticeResult
    let headline: String

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                ReportHero(result: result, headline: headline)

                Text(String(localized: "스티밍 기록"))
                    .font(.pretendard(.bold, size: 20))
                    .foregroundStyle(Color.white)
                    .at(x: ReportLayout.sectionTitleX, y: ReportLayout.sectionTitleY, scale)

                ReportOverviewChart(result: result)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .frame(height: ReportLayout.guideY.v(scale), alignment: .topLeading)

            ReportGuideSection(guide: PracticeGuide(result: result),
                               milkTop: GuideMilkLevel.top(forAeration: result.guideDuration(of: .normalAeration), model: result.model))

            ReportFootnote()
                .padding(.top, CGFloat(36).v(scale))
                .padding(.bottom, CGFloat(32).v(scale))
        }
    }
}

// MARK: - 위치 지정 도우미

extension View {
    /// 시안 좌표(왼쪽 위 기준, iPhone 17 pt)에 놓습니다. 가로는 폭 비율, 세로는 높이 비율로 변환합니다.
    func at(x: CGFloat, y: CGFloat, _ scale: DesignScale) -> some View {
        self.offset(x: x.h(scale), y: y.v(scale))
    }
}

// MARK: - 히어로

private struct ReportHero: View {
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

// MARK: - 연습 가이드

/// "연습 가이드" 제목 + 비커 그림 + 안내 카드. 위치는 섹션 맨 위(제목 글자 상자 위) 기준 (Hi-Fi 연습 가이드 3종)
private struct ReportGuideSection: View {
    @Environment(\.designScale) private var scale
    let guide: PracticeGuide
    let milkTop: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                Text(String(localized: "연습 가이드"))
                    .font(.pretendard(.bold, size: 20))
                    .foregroundStyle(Color.white)
                    .at(x: ReportLayout.sectionTitleX, y: 0, scale)

                ReportGuidePitcher(milkTop: milkTop)
                    .designScaled(width: ReportLayout.guidePitcherSize.width, height: ReportLayout.guidePitcherSize.height, scale)
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
private struct ReportGuidePitcher: View {
    let milkTop: CGFloat

    var body: some View {
        ZStack(alignment: .topLeading) {
            Image("IllustPracticeGuidePitcher")
                .resizable()
                .frame(width: ReportLayout.guidePitcherSize.width, height: ReportLayout.guidePitcherSize.height)

            GuideMilkShape(top: milkTop)
                .fill(PracticeResultColors.guideMilk)

            GuideDashLine(y: GuideMilkLevel.upperLine, from: 15.5, to: 161.5)
                .stroke(AppColors.darkSecondaryButton, style: Self.lineStyle(phase: 2.33))
            GuideDashLine(y: GuideMilkLevel.lowerLine, from: 13.5, to: 165.8)
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

private struct GuideDashLine: Shape {
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

// MARK: - 안내 문구

private struct ReportFootnote: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "info.circle")
                .font(.system(size: 11, weight: .regular))
            Text(String(localized: "소리 분석에 따른 참고용 안내이며, 실제 공기량을 측정한 결과는 아니에요."))
                .font(.pretendard(.regular, size: 11))
        }
        .foregroundStyle(PracticeResultColors.footnote)
        .frame(maxWidth: .infinity)
    }
}
