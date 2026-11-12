import SwiftUI

//
//  PracticeReport.swift
//
//  연습 직후 결과(PracticeResultView)와 기록 상세(HistoryDetailView)가 함께 쓰는 리포트 화면입니다.
//  - 상단 히어로: 타이틀 + 도넛(주의 소리 비율) + 3열 요약
//  - "스티밍 기록": 탭 3개 (한 번에 보기 / 타임라인 / 상태별 감지시간)
//  - "연습 가이드": 비커 그림 + 공기 주입 시간에 따른 안내 카드 (`PracticeGuide`)
//  - 하단 안내 문구
//  Hi-Fi: 255 · 243 · 257 · 267 (연습 직후), 269 · 270 · 271 · 272 (기록 상세)
//

/// 연습 직후 결과와 기록 상세는 시안에서 몇 군데 다르게 그려져 있어 그 차이만 값으로 둡니다.
/// (Hi-Fi 255 vs 269: 도넛 중심 x 199 → 201.2, "주의소리" 글자 16 → 20, 한 번에 보기 표 +2.4pt)
struct ReportVariant {
    var donutCenterX: CGFloat
    var cautionLabelSize: CGFloat
    var cautionLabelDY: CGFloat
    var overviewShiftX: CGFloat

    static let practiceResult = ReportVariant(donutCenterX: 199, cautionLabelSize: 15, cautionLabelDY: 0, overviewShiftX: 0)
    static let historyDetail = ReportVariant(donutCenterX: 201.2, cautionLabelSize: 20.5, cautionLabelDY: -1, overviewShiftX: 2.4)
}

/// 리포트 탭
enum PracticeReportTab: CaseIterable, Hashable {
    case overview
    case timeline
    case durations

    /// 선택된 "상태별 감지 시간"만 띄어쓰기가 있는 것이 Hi-Fi 257 · 271 그대로입니다.
    func title(isSelected: Bool) -> String {
        switch self {
        case .overview: "한 번에 보기"
        case .timeline: "타임라인"
        case .durations: isSelected ? "상태별 감지 시간" : "상태별 감지시간"
        }
    }
}

// MARK: - 화면 (스크롤 + 고정 상단 바 + 삭제 팝업)

struct PracticeReportScreen: View {
    @Environment(\.designScale) private var scale
    let result: PracticeResult
    /// 탭에 따라 달라지는 상단 문구
    let headline: (PracticeReportTab) -> String
    var variant: ReportVariant = .practiceResult
    /// 상단 바 제목. nil이면 날짜 제목(기록 상세). 연습 직후 결과는 "연습 결과"를 넘긴다
    var barTitle: String? = nil
    var onBack: (() -> Void)? = nil
    /// 삭제 팝업에서 "기록 삭제"를 확인했을 때
    var onDelete: (() -> Void)? = nil
    @State private var tab: PracticeReportTab
    @State private var showsDeleteDialog: Bool

    init(
        result: PracticeResult,
        headline: @escaping (PracticeReportTab) -> String,
        variant: ReportVariant = .practiceResult,
        barTitle: String? = nil,
        onBack: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil,
        initialTab: PracticeReportTab = .overview,
        showsDeleteDialog: Bool = false
    ) {
        self.result = result
        self.headline = headline
        self.variant = variant
        self.barTitle = barTitle
        self.onBack = onBack
        self.onDelete = onDelete
        _tab = State(initialValue: initialTab)
        _showsDeleteDialog = State(initialValue: showsDeleteDialog)
    }

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                PracticeReportPage(result: result, tab: tab, headline: headline(tab), variant: variant, onSelectTab: selectTab)
                    // 스크롤한 채로 탭을 바꿔도 탭 바가 제자리에 있도록 스크롤 영역 높이를 가장 긴 탭에 맞춰 고정해요.
                    // (짧은 탭으로 바꾸면 영역이 줄면서 스크롤 위치가 당겨져 탭 바가 갑자기 아래로 튀었어요)
                    .frame(height: ReportLayout.durationsPageHeight.v(scale), alignment: .top)
            }
            .scrollIndicators(.hidden)
            .ignoresSafeArea()

            // 고정 상단 바: 스크롤한 내용이 비쳐 제목과 겹치지 않도록 뒤에 배경을 깔고 아래쪽은 살짝 흐리게 이어 준다.
            // (맨 위에서는 히어로 위쪽 색과 같아 눈에 보이지 않는다)
            VStack(spacing: 0) {
                TopNavigationHeader(
                    title: barTitle ?? result.title, isDark: true, onBack: onBack,
                    trailingSystemImage: "trash", onTrailingIcon: { showsDeleteDialog = true }
                )
                .padding(.top, ReportLayout.topBarTop.v(scale))
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
            title: "정말 기록을 삭제하시겠어요?",
            message: "삭제한 기록은 다시 복구할 수 없어요",
            cancelTitle: "취소",
            confirmTitle: "기록 삭제",
            confirmColor: AppColors.alertRed,
            onCancel: { showsDeleteDialog = false },
            onConfirm: { showsDeleteDialog = false; onDelete?() }
        )
        .toolbar(.hidden, for: .navigationBar)
        .swipeBackDisabled(showsDeleteDialog)
    }

    /// 탭을 눌렀을 때: 내용을 바로 바꿔요.
    private func selectTab(_ newTab: PracticeReportTab) {
        tab = newTab
    }
}

// MARK: - 페이지 본문 (스크롤 안쪽 · 긴 화면 캡처 공용)

/// 화면 맨 위(상태바 포함)부터 안내 문구 아래까지의 긴 페이지. 모든 위치는 iPhone 17 시안 좌표(pt)입니다.
struct PracticeReportPage: View {
    @Environment(\.designScale) private var scale
    let result: PracticeResult
    let tab: PracticeReportTab
    let headline: String
    var variant: ReportVariant = .practiceResult
    var onSelectTab: (PracticeReportTab) -> Void = { _ in }

    private var pageHeight: CGFloat {
        tab == .durations ? ReportLayout.durationsPageHeight : ReportLayout.pageHeight
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            ReportHero(result: result, headline: headline, variant: variant)

            Text("스티밍 기록")
                .font(.pretendard(.bold, size: 20))
                .foregroundStyle(Color.white)
                .at(x: ReportLayout.sectionTitleX, y: ReportLayout.sectionTitleY, scale)

            ReportTabBar(selected: tab, onSelect: onSelectTab)
                .at(x: ReportLayout.tabBarX, y: ReportLayout.tabBarY, scale)

            // 탭을 바꾸면 내용이 바로 바뀌어요 (나타나는 효과 없음)
            ZStack(alignment: .topLeading) {
                switch tab {
                case .overview: ReportOverviewChart(result: result, shiftX: variant.overviewShiftX)
                case .timeline: ReportTimelineChart(result: result)
                case .durations: ReportDurationsChart(result: result)
                }
            }

            // 연습 가이드: 세 탭 모두 보여요. 탭마다 차트 길이가 달라, 차트 바로 아래에서 시작해요.
            ReportGuideSection(guide: PracticeGuide(result: result),
                               aerationSeconds: Double(result.detectedSeconds(of: .normalAeration)))
                .at(x: 0, y: tab == .durations ? ReportLayout.durationsGuideY : ReportLayout.guideY, scale)

            ReportFootnote()
                .at(x: 0, y: tab == .durations ? ReportLayout.durationsFootnoteY : ReportLayout.footnoteY, scale)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .frame(height: pageHeight.v(scale), alignment: .topLeading)
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
    let variant: ReportVariant

    var body: some View {
        ZStack(alignment: .topLeading) {
            heroBackground
                .frame(height: ReportLayout.heroHeight.v(scale))

            Text(headline)
                .font(.pretendard(.bold, size: 26))
                .lineSpacing(ReportLayout.headlineLineSpacing)
                .multilineTextAlignment(.center)
                .foregroundStyle(AppColors.darkSecondaryButton)
                .frame(maxWidth: .infinity)
                .at(x: 0, y: ReportLayout.headlineY, scale)

            // 도넛: 주의 소리 비율
            ZStack {
                // 분홍 호는 처음부터 다 그려져 있어요. (introTarget: 아주 작은 비율도 둥근 끝 하나 크기의 점으로 보여요)
                ArcRing(ratio: result.cautionRatio, lineWidth: ReportLayout.donutLineWidth,
                        color: AppColors.soundCaution, introTarget: result.cautionRatio)
                    .frame(width: ReportLayout.donutDiameter.h(scale), height: ReportLayout.donutDiameter.h(scale))
                VStack(spacing: ReportLayout.donutTextSpacing) {
                    Text("\(Int((result.cautionRatio * 100).rounded()))%")
                        .font(.pretendard(.bold, size: 36))
                        .foregroundStyle(AppColors.soundCaution)
                    Text("주의소리")
                        .font(.pretendard(.regular, size: variant.cautionLabelSize))
                        .foregroundStyle(AppColors.darkSecondaryButton)
                        .offset(y: variant.cautionLabelDY)
                }
            }
            .frame(width: ReportLayout.donutDiameter.h(scale), height: ReportLayout.donutDiameter.h(scale))
            .at(x: variant.donutCenterX - ReportLayout.donutDiameter / 2, y: ReportLayout.donutY, scale)

            // 3열 요약
            HStack(spacing: 0) {
                summaryColumn("전체 시간", result.totalSeconds)
                summaryColumn("정상 소리", result.normalSeconds)
                summaryColumn("주의 소리", result.cautionSeconds)
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
                colors: [PracticeResultColors.heroGradientCenterBottom.opacity(0.4), Color.clear],
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

// MARK: - 탭 바

private struct ReportTabBar: View {
    @Environment(\.designScale) private var scale
    let selected: PracticeReportTab
    let onSelect: (PracticeReportTab) -> Void

    /// 알약과 글자의 가운데 x (탭 바 왼쪽 기준). 글자는 어느 탭이 선택돼도 제자리에 있고 알약만 옮겨 가요.
    /// 시안은 선택된 탭에 따라 글자 위치를 최대 17pt 다르게 그려 두었지만, 글자가 같이 움직여 어색해서 알약 가운데로 고정했어요.
    private static let pillCenters: [CGFloat] = [58.5, 180.5, 302.5]

    var body: some View {
        ZStack(alignment: .topLeading) {
            Capsule().fill(ReportColors.tabBarBackground)

            // 선택 표시는 누른 탭으로 바로 옮겨 가요 (미끄러지는 효과 없음)
            Capsule()
                .fill(ReportColors.tabSelected)
                .frame(width: ReportLayout.tabPillWidth.h(scale), height: ReportLayout.tabPillHeight.v(scale))
                .offset(x: (Self.pillCenters[index(of: selected)] - ReportLayout.tabPillWidth / 2).h(scale),
                        y: ReportLayout.tabPillTop.v(scale))

            ForEach(Array(PracticeReportTab.allCases.enumerated()), id: \.offset) { index, tab in
                let isSelected = tab == selected
                Button { onSelect(tab) } label: {
                    Text(tab.title(isSelected: isSelected))
                        .font(.pretendard(.semibold, size: 12))
                        .foregroundStyle(Color.white)
                        .fixedSize()
                        .frame(width: CGFloat(130).h(scale), height: ReportLayout.tabBarHeight.v(scale))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
                .offset(x: (Self.pillCenters[index] - 65).h(scale))
            }
        }
        .frame(width: ReportLayout.tabBarWidth.h(scale), height: ReportLayout.tabBarHeight.v(scale), alignment: .topLeading)
    }

    private func index(of tab: PracticeReportTab) -> Int {
        PracticeReportTab.allCases.firstIndex(of: tab) ?? 0
    }
}

// MARK: - 연습 가이드

/// "연습 가이드" 제목 + 비커 그림 + 안내 카드. 위치는 섹션 맨 위(제목 글자 상자 위) 기준 (Hi-Fi 연습 가이드 3종)
private struct ReportGuideSection: View {
    @Environment(\.designScale) private var scale
    let guide: PracticeGuide
    /// 이번 연습의 공기 주입 시간 (초). 비커 우유 높이가 이 값을 따라가요.
    let aerationSeconds: Double

    var body: some View {
        ZStack(alignment: .topLeading) {
            Text("연습 가이드")
                .font(.pretendard(.bold, size: 20))
                .foregroundStyle(Color.white)
                .at(x: ReportLayout.sectionTitleX, y: 0, scale)

            ReportGuidePitcher(milkTop: GuideMilkLevel.top(forAeration: aerationSeconds))
                .designScaled(width: ReportLayout.guidePitcherSize.width, height: ReportLayout.guidePitcherSize.height, scale)
                .at(x: ReportLayout.guidePitcherX, y: ReportLayout.guidePitcherTop, scale)
                .accessibilityHidden(true)

            ReportGuideCard(guide: guide)
                .at(x: ReportLayout.guideCardX, y: ReportLayout.guideCardTop, scale)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

/// 가이드 비커: 빈 비커 그림 위에 공기 주입한 만큼 우유를 채우고, 두 점선(2초 · 5초)을 그려요.
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
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: ReportLayout.guideCardRadius, style: .continuous)
                .fill(PracticeResultColors.cardBackground)

            Image(systemName: guide.systemImage)
                .font(.system(size: guide == .onTarget ? 19 : 22, weight: guide == .onTarget ? .semibold : .regular))
                .foregroundStyle(Color.white)
                .frame(width: 28, height: 28)
                .position(x: ReportLayout.guideIconCenter.x.h(scale), y: ReportLayout.guideIconCenter.y.v(scale))
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
            .frame(width: ReportLayout.guideTextWidth.h(scale), alignment: .leading)
            .at(x: ReportLayout.guideTextX, y: ReportLayout.guideTextTop, scale)
        }
        .frame(width: ReportLayout.guideCardWidth.h(scale), height: ReportLayout.guideCardHeight.v(scale), alignment: .topLeading)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - 안내 문구

private struct ReportFootnote: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "info.circle")
                .font(.system(size: 11, weight: .regular))
            Text("소리 분석에 따른 참고용 안내이며, 실제 공기량을 측정한 결과는 아니에요.")
                .font(.pretendard(.regular, size: 11))
        }
        .foregroundStyle(PracticeResultColors.footnote)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 한 번에 보기

private struct ReportOverviewChart: View {
    @Environment(\.designScale) private var scale
    let result: PracticeResult
    var shiftX: CGFloat = 0

    private static let rows: [(String, DetectedSound)] = [
        ("공기 주입", .normalAeration), ("공기 과다", .overAeration), ("공기 부족", .lackOfAir), ("롤링 소리", .rolling)
    ]

    var body: some View {
        ZStack(alignment: .topLeading) {
            overviewContent
        }
        .offset(x: shiftX.h(scale))
    }

    private var overviewContent: some View {
        ZStack(alignment: .topLeading) {
            Group {
                Text("소리 유형").at(x: ReportLayout.overviewLabelX, y: ReportLayout.overviewHeaderY, scale)
                Text("비율").at(x: ReportLayout.overviewRatioX, y: ReportLayout.overviewHeaderY, scale)
                Text("시간").at(x: ReportLayout.overviewTimeX, y: ReportLayout.overviewHeaderY, scale)
            }
            .font(.pretendard(.regular, size: 11))
            .foregroundStyle(PracticeResultColors.secondaryText)

            ForEach(Array(Self.rows.enumerated()), id: \.offset) { index, row in
                let y = ReportLayout.overviewFirstRowY + CGFloat(index) * ReportLayout.overviewRowPitch
                let seconds = result.detectedSeconds(of: row.1)

                rowText(row.0, color: .white, x: ReportLayout.overviewLabelX, y: y)

                ReportBar(result: result, sounds: [row.1], width: ReportLayout.overviewTrackWidth.h(scale), height: ReportLayout.overviewBarHeight.v(scale))
                    .at(x: ReportLayout.overviewTrackX, y: y, scale)

                rowText(Self.percentText(seconds: seconds, total: result.totalSeconds), color: ReportColors.summaryLabel,
                        x: ReportLayout.overviewRatioX, y: y)

                rowText("\(seconds)초", color: .white, x: ReportLayout.overviewTimeX, y: y)
            }

            ReportAxis(width: ReportLayout.overviewTrackWidth.h(scale), ticks: result.tickLabels) // 막대(.h(scale))와 같은 폭이어야 눈금 숫자가 막대 눈금선에 맞는다
                .at(x: ReportLayout.overviewTrackX, y: ReportLayout.overviewAxisY, scale)
        }
    }

    /// 줄 하나의 글자 (막대와 같은 높이 안에서 세로 가운데)
    private func rowText(_ text: String, color: Color, x: CGFloat, y: CGFloat) -> some View {
        Text(text)
            .font(.pretendard(.regular, size: 12))
            .foregroundStyle(color)
            .frame(height: ReportLayout.overviewBarHeight.v(scale))
            .at(x: x, y: y, scale)
    }

    /// 25 → "25%", 2/24 → "8.33%", 10/24 → "41.67%"
    static func percentText(seconds: Int, total: Int) -> String {
        guard total > 0 else { return "0%" }
        var text = String(format: "%.2f", Double(seconds) / Double(total) * 100)
        while text.hasSuffix("0") { text.removeLast() }
        if text.hasSuffix(".") { text.removeLast() }
        return text + "%"
    }
}

// MARK: - 타임라인

private struct ReportTimelineChart: View {
    @Environment(\.designScale) private var scale
    let result: PracticeResult

    private static let groups: [(String, [DetectedSound])] = [
        ("공기 주입", [.normalAeration, .overAeration, .lackOfAir]),
        ("롤링 소리", [.rolling])
    ]

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(Self.groups.enumerated()), id: \.offset) { index, group in
                let top = ReportLayout.timelineFirstGroupY + CGFloat(index) * ReportLayout.timelineGroupPitch

                Text(group.0)
                    .font(.pretendard(.semibold, size: 14))
                    .foregroundStyle(Color.white)
                    .at(x: ReportLayout.timelineTrackX, y: top, scale)

                ReportBar(result: result, sounds: group.1, width: ReportLayout.timelineTrackWidth.h(scale), height: ReportLayout.timelineBarHeight.v(scale))
                    .at(x: ReportLayout.timelineTrackX, y: top + ReportLayout.timelineLabelToBar, scale)

                ReportAxis(width: ReportLayout.timelineTrackWidth.h(scale), ticks: result.tickLabels)
                    .at(x: ReportLayout.timelineTrackX, y: top + ReportLayout.timelineBarToAxis, scale)
            }
        }
    }
}

// MARK: - 막대 · 눈금

/// 어두운 트랙 위에 소리 구간을 칠하고, 눈금 위치(8 · 12 · 16 · 20)에 가는 선을 긋는 막대
private struct ReportBar: View {
    let result: PracticeResult
    let sounds: [DetectedSound]
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        let length = max(result.timelineLength, 1)
        return ZStack(alignment: .topLeading) {
            Rectangle().fill(ReportColors.track)

            tickLines(ReportColors.gridLine)

            ForEach(result.segments.filter { sounds.contains($0.sound) }) { segment in
                let start = (segment.start - result.timelineStart) / length
                let end = (segment.end - result.timelineStart) / length
                Rectangle()
                    .fill(segment.sound.timelineColor)
                    .frame(width: max(0, width * (end - start)))
                    .offset(x: width * start)
            }

            tickLines(Color.black.opacity(0.3))
        }
        .frame(width: width, height: height, alignment: .topLeading)
        .clipped()
    }

    /// 눈금 위치(8 · 12 · 16 · 20)의 가는 세로선. 트랙 위(구간 아래)와 구간 위에 한 번씩 그려요.
    private func tickLines(_ color: Color) -> some View {
        ForEach(Array(ReportLayout.tickFractions.enumerated()), id: \.offset) { _, fraction in
            Rectangle().fill(color).frame(width: 1).offset(x: width * fraction)
        }
    }
}

/// 막대 아래 눈금 숫자 (0 · 8 · 12 · 16 · 20 · 24초). 가운데 네 개는 막대 폭의 같은 비율 자리에 놓입니다.
private struct ReportAxis: View {
    let width: CGFloat
    let ticks: [String]

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(ticks.enumerated()), id: \.offset) { index, text in
                Text(text)
                    .font(.pretendard(.regular, size: 11))
                    .foregroundStyle(PracticeResultColors.secondaryText)
                    .fixedSize()
                    .position(x: centerX(index: index, count: ticks.count), y: 7)
            }
        }
        .frame(width: width, height: 14, alignment: .topLeading)
    }

    private func centerX(index: Int, count: Int) -> CGFloat {
        if index == 0 { return 2 }
        if index == count - 1 { return width - 0.7 }
        let fractions = ReportLayout.tickFractions
        return width * fractions[min(index - 1, fractions.count - 1)]
    }
}

extension PracticeResult {
    /// 막대 아래 눈금 문구: 마지막만 "초"가 붙는다 ("0 8 12 16 20 24초")
    var tickLabels: [String] {
        let seconds: [Int]
        if let customTickSeconds { seconds = customTickSeconds }
        else {
            let end = max(Int(timelineLength.rounded()), 1)
            seconds = [0, end / 3, end / 2, end * 2 / 3, end * 5 / 6, end]
        }
        return seconds.enumerated().map { index, value in index == seconds.count - 1 ? "\(value)초" : "\(value)" }
    }
}

// MARK: - 상태별 감지시간

private struct ReportDurationsChart: View {
    @Environment(\.designScale) private var scale
    let result: PracticeResult

    private static let slices: [(DetectedSound, String, String, Color)] = [
        (.normalAeration, "정상 공기 주입", "wind", AppColors.soundNormalAeration),
        (.overAeration, "공기 과다", "sun.max", AppColors.soundOverAeration),
        (.lackOfAir, "공기 부족", "waveform.path.ecg", AppColors.soundLackOfAir)
    ]

    var body: some View {
        let seconds = Self.slices.map { result.detectedSeconds(of: $0.0) }
        let aerationTotal = seconds.reduce(0, +)
        ZStack(alignment: .topLeading) {
            // 공기 주입 도넛 (정상 · 과다 · 부족)
            ReportSliceDonut(values: seconds.map(Double.init), colors: Self.slices.map(\.3), symbols: Self.slices.map(\.2))
                .frame(width: ReportLayout.durationsDonutDiameter.h(scale), height: ReportLayout.durationsDonutDiameter.h(scale))
                .overlay { donutCaption(seconds: aerationTotal, label: "전체 공기주입", labelSize: 12) }
                .at(x: ReportLayout.durationsDonutX, y: ReportLayout.durationsDonut1Y, scale)

            // 범례
            ForEach(Array(Self.slices.enumerated()), id: \.offset) { index, slice in
                HStack(spacing: 0) {
                    Image(systemName: slice.2)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(slice.3)
                        .frame(width: 30)
                    Text(slice.1)
                        .font(.pretendard(.semibold, size: 12))
                        .foregroundStyle(Color.white)
                        .padding(.leading, 21)
                    Spacer(minLength: 0)
                    Text("\(seconds[index]) 초")
                        .font(.pretendard(.semibold, size: 16))
                        .foregroundStyle(Color.white)
                }
                .frame(width: ReportLayout.legendWidth.h(scale), height: ReportLayout.legendRowHeight.v(scale))
                .at(x: ReportLayout.legendX, y: ReportLayout.legendFirstY + CGFloat(index) * ReportLayout.legendPitch + ReportLayout.legendRowAdjust[index], scale)
            }

            // 롤링 도넛: 한 바퀴
            ArcFill(seenDegrees: 360, startDegrees: ReportLayout.durationsRingStartDegrees,
                    lineWidth: ReportLayout.donutLineWidth, color: AppColors.soundRolling, closed: true)
                .frame(width: ReportLayout.durationsDonutDiameter.h(scale), height: ReportLayout.durationsDonutDiameter.h(scale))
                .overlay { donutCaption(seconds: result.detectedSeconds(of: .rolling), label: "롤링 소리", labelSize: 14) }
                .at(x: ReportLayout.durationsDonutX, y: ReportLayout.durationsDonut2Y, scale)
        }
    }

    /// 도넛 가운데: 큰 초 숫자 + 아래 설명
    private func donutCaption(seconds: Int, label: String, labelSize: CGFloat) -> some View {
        VStack(spacing: 2) {
            Text("\(seconds)초")
                .font(.pretendard(.bold, size: 36))
                .foregroundStyle(Color.white)
            Text(label)
                .font(.pretendard(.regular, size: labelSize))
                .foregroundStyle(AppColors.darkSecondaryButton)
        }
    }
}

/// 값 비율대로 나뉜 둥근 호들 (호끼리 맞닿고, 호 끝에 아이콘)
/// - 보이는 호(둥근 끝 포함)가 12시 방향(0°)에서 시작해 (Hi-Fi 257 측정은 −23.5°였으나 새 요청으로 12시부터 시작) `비율 × 360°`씩 이어지고, 호 사이는 0.4°만 비어 있다.
///   (파랑 216.6° · 주황 71.4° · 보라 70.7° = 6 : 2 : 2). 아이콘은 각 호의 끝 둥근 끝 중심에 놓인다.
private struct ReportSliceDonut: View {
    let values: [Double]
    let colors: [Color]
    let symbols: [String]

    private let lineWidth = ReportLayout.donutLineWidth
    private let gapDegrees = 0.4

    var body: some View {
        GeometryReader { proxy in
            let diameter = min(proxy.size.width, proxy.size.height)
            let radius = (diameter - lineWidth) / 2
            let capDegrees = Double(lineWidth / 2 / radius) * 180 / .pi
            let total = max(values.reduce(0, +), 1)
            ZStack {
                ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                    // 감지되지 않은(0초) 항목은 호도 아이콘도 그리지 않아요.
                    if value > 0 {
                        let visible = visibleRange(index: index, total: total)
                        let full = visible.upperBound - visible.lowerBound
                        let arc = centerline(of: visible, capDegrees: capDegrees)
                        ArcFill(seenDegrees: full, startDegrees: visible.lowerBound,
                                lineWidth: lineWidth, color: colors[index], fullDegrees: full)
                        Image(systemName: symbols[index])
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(Color.white)
                            .position(iconPoint(diameter: diameter, radius: radius, degrees: arc.upperBound))
                    }
                }
            }
            .frame(width: diameter, height: diameter)
        }
    }

    private func visibleRange(index: Int, total: Double) -> ClosedRange<Double> {
        var start = ReportLayout.durationsRingStartDegrees
        for i in 0..<index { start += 360 * values[i] / total }
        // 호가 간격(0.4°)보다 짧아도 범위의 끝이 시작보다 앞서지 않게 해요.
        return start...max(start, start + 360 * values[index] / total - gapDegrees)
    }

    /// 보이는 호에서 둥근 끝 두 개를 뺀 중심선 호. 호가 둥근 끝보다 짧으면 가운데에 점 하나로 그려요.
    private func centerline(of visible: ClosedRange<Double>, capDegrees: Double) -> ClosedRange<Double> {
        let start = visible.lowerBound + capDegrees
        let end = visible.upperBound - capDegrees
        guard start > end else { return start...end }
        let middle = (visible.lowerBound + visible.upperBound) / 2
        // 길이가 0인 호는 둥근 끝도 그려지지 않아서 아주 조금 길이를 줘요.
        return (middle - 0.01)...(middle + 0.01)
    }

    private func iconPoint(diameter: CGFloat, radius: CGFloat, degrees: Double) -> CGPoint {
        let radians = degrees * .pi / 180
        return CGPoint(x: diameter / 2 + radius * CGFloat(sin(radians)), y: diameter / 2 - radius * CGFloat(cos(radians)))
    }
}

// MARK: - 색상

enum ReportColors {
    static let tabBarBackground = Color(hex: 0x0F111A)
    static let tabSelected = Color(hex: 0x4B4F5A)
    static let track = Color(hex: 0x202020)
    static let gridLine = Color(hex: 0x282A2E)
    static let summaryLabel = Color(hex: 0xB9B9B9)
}

// MARK: - Layout (iPhone 17 시안 측정값, pt · 왼쪽 위 기준 절대 좌표)

enum ReportLayout {
    // 페이지 높이: Hi-Fi 255 · 243 (1079) / 257 (1568)에 연습 가이드(+383)를 더함 (Hi-Fi 연습 가이드: 1462)
    static let guideSectionHeight: CGFloat = 383
    static let pageHeight: CGFloat = 1079 + guideSectionHeight
    static let durationsPageHeight: CGFloat = 1568 + guideSectionHeight

    // 상단 바
    static let topBarBottomPadding: CGFloat = 16 // 상단 바 아래 배경 여유
    static let topBarFade: CGFloat = 18           // 상단 바 배경 아래 흐려지는 구간
    static let topBarTop: CGFloat = 84           // 글자 y0 83~86 (Hi-Fi 255: 제목 글자 y0 86.5 − 2.5)

    // 히어로 (Hi-Fi 255)
    static let heroHeight: CGFloat = 609.5       // 컨테이너 아래 끝
    static let heroCornerRadius: CGFloat = 26
    static let headlineY: CGFloat = 154.3        // 타이틀 첫 줄 글자 y0 158 (측정 보정)
    static let headlineLineSpacing: CGFloat = 3.7 // 줄 높이 35
    static let donutDiameter: CGFloat = 189.2    // 바깥 반지름 94.6
    static let donutLineWidth: CGFloat = 34.2
        static let donutY: CGFloat = 269.2
    static let donutTextSpacing: CGFloat = 5.3
    static let summaryX: CGFloat = 18
    static let summaryY: CGFloat = 521.7         // 구분선 y 521.7 ~ 571.6
    static let summaryHeight: CGFloat = 50
    static let summaryColumnWidth: CGFloat = 122
    static let summaryTextSpacing: CGFloat = 4

    // 섹션 제목 · 탭 바
    static let sectionTitleX: CGFloat = 20
    static let sectionTitleY: CGFloat = 655
    static let tabBarX: CGFloat = 20.5
    static let tabBarY: CGFloat = 715.8
    static let tabBarWidth: CGFloat = 361
    static let tabBarHeight: CGFloat = 41
    static let tabBarInset: CGFloat = 1.5
    static let tabPillWidth: CGFloat = 114
    static let tabPillHeight: CGFloat = 38
    static let tabPillTop: CGFloat = 1.2       // 탭 바 위 ↔ 알약 (717 − 715.8)
    static let tabPillGap: CGFloat = 8

    // 눈금: 막대 폭에 대한 비율 (8 · 12 · 16 · 20)
    static let tickFractions: [CGFloat] = [0.182, 0.394, 0.608, 0.820]

    // 한 번에 보기 (Hi-Fi 255)
    static let overviewHeaderY: CGFloat = 787
    static let overviewFirstRowY: CGFloat = 812
    static let overviewRowPitch: CGFloat = 34.7
    static let overviewBarHeight: CGFloat = 22.5
    static let overviewLabelX: CGFloat = 20
    static let overviewTrackX: CGFloat = 77
    static let overviewTrackWidth: CGFloat = 214
    static let overviewRatioX: CGFloat = 307.4
    static let overviewTimeX: CGFloat = 359
    static let overviewAxisY: CGFloat = 944

    // 타임라인 (Hi-Fi 243)
    static let timelineTrackX: CGFloat = 31.5
    static let timelineTrackWidth: CGFloat = 327.5
    static let timelineFirstGroupY: CGFloat = 792.5
    static let timelineGroupPitch: CGFloat = 88
    static let timelineLabelToBar: CGFloat = 24.5
    static let timelineBarHeight: CGFloat = 29.5
    static let timelineBarToAxis: CGFloat = 62.5

    // 상태별 감지시간 (Hi-Fi 257)
    static let durationsDonutDiameter: CGFloat = 190
    /// 상태별 감지시간 도넛(공기 주입 · 롤링)이 시작하는 각도: 12시 방향 0°에서 시계 방향 (첫 호의 둥근 끝 왼쪽이 12시 선에 닿음).
    /// 위쪽 요약 도넛(ArcRing)은 시안대로 −23.5°에서 시작한다.
    static let durationsRingStartDegrees: Double = 0
    static let durationsDonutX: CGFloat = 106
    static let durationsDonut1Y: CGFloat = 816
    static let durationsDonut2Y: CGFloat = 1226.5
    static let legendX: CGFloat = 100.5
    static let legendWidth: CGFloat = 201
    static let legendFirstY: CGFloat = 1040
    static let legendPitch: CGFloat = 41.5
    static let legendRowHeight: CGFloat = 28.5
    static let legendRowAdjust: [CGFloat] = [-1.5, 1.5, 0] // 줄마다 아이콘 높이가 달라 위쪽 끝이 시안과 맞도록 보정

    // 연습 가이드 (Hi-Fi 연습 가이드 3종, 섹션 맨 위 = 제목 글자 상자 위 기준)
    // 예전 안내 문구 자리(1020 / 1509.5)에서 16.3pt 위에서 시작해요 (Hi-Fi: 제목 글자 윗선 1006.5 − 2.8)
    static let guideY: CGFloat = 1020 - 16.3
    static let durationsGuideY: CGFloat = 1509.5 - 16.3
    static let guidePitcherX: CGFloat = 112.7             // 비커 그림 왼쪽 (Hi-Fi 260: 비커 바닥 왼쪽 114 − 에셋 여백 1.3, 노즐이 화면 오른쪽 끝까지)
    static let guidePitcherTop: CGFloat = 1045.8 - 1003.7 // 제목 ↔ 비커 그림 위 (Hi-Fi 260: 노즐 위 1046)
    static let guidePitcherSize = CGSize(width: 869.0 / 3, height: 651.0 / 3)
    static let guideCardX: CGFloat = 19.7
    static let guideCardTop: CGFloat = 1289.3 - 1003.7
    static let guideCardWidth: CGFloat = 362.6
    static let guideCardHeight: CGFloat = 87.7
    static let guideCardRadius: CGFloat = 10
    static let guideIconCenter = CGPoint(x: 51.8 - 19.7, y: 1316.6 - 1289.3)
    static let guideTextX: CGFloat = 78.9 - 19.7
    static let guideTextTop: CGFloat = 15.6           // 카드 위 ↔ 제목 글자 상자 (Hi-Fi: 글자 윗선 16.8)
    static let guideTextWidth: CGFloat = 290
    static let guideTitleToMessage: CGFloat = 7.4     // Hi-Fi: 설명 글자 윗선 43.1
    static let guideMessageLineSpacing: CGFloat = 1.8 // Hi-Fi: 설명 줄 높이 16.1

    // 안내 문구 (연습 가이드 아래로 내려감)
    static let footnoteY: CGFloat = 1020 + 392.7
    static let durationsFootnoteY: CGFloat = 1509.5 + 392.7
}
