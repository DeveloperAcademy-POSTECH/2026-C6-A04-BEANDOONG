import SwiftUI

//
//  PracticeReport.swift
//
//  연습 직후 결과(PracticeResultView)와 기록 상세(HistoryDetailView)가 함께 쓰는 리포트 화면입니다.
//  - 상단 히어로: 결과에 따른 타이틀 + 소리 종류별 도넛 + 3열 요약
//  - "스티밍 기록": 소리 유형별 막대 표 (탭 없음)
//  - "연습 가이드": 비커 그림 + 공기 주입 시간에 따른 안내 카드 (`PracticeGuide`)
//  - 하단 안내 문구
//  Hi-Fi (2026-11-13): 연습가이드 공기 적정 · 과도 · 부족 (연습 직후, "스티밍 결과"),
//                      같은 이름 -1 (기록 상세, "스팀 결과"). 도넛 · 연습 가이드는 -1 없는 쪽을 따름
//

// MARK: - 화면 (스크롤 + 고정 상단 바 + 삭제 팝업)

struct PracticeReportScreen: View {
    @Environment(\.designScale) private var scale
    let result: PracticeResult
    /// 히어로 타이틀 (결과에 따라 화면마다 정한다)
    let headline: String
    /// 상단 바 제목 (연습 직후 "스티밍 결과", 기록 상세 "스팀 결과")
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

                Text("스티밍 기록")
                    .font(.pretendard(.bold, size: 20))
                    .foregroundStyle(Color.white)
                    .at(x: ReportLayout.sectionTitleX, y: ReportLayout.sectionTitleY, scale)

                ReportOverviewChart(result: result)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .frame(height: ReportLayout.guideY.v(scale), alignment: .topLeading)

            ReportGuideSection(guide: PracticeGuide(result: result),
                               aerationSeconds: result.guideDuration(of: .normalAeration))

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

    /// 주의 소리가 없으면 가운데에 정상 소리 비율을 보여요 (Hi-Fi 적정: "100% 정상소리")
    private var showsNormalRatio: Bool { result.cautionSeconds == 0 && result.normalSeconds > 0 }

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

            // 도넛: 소리 종류별 시간 (12시부터 공기 주입 · 과다 · 부족 · 롤링). 과다 · 부족은 주의 소리 색
            ZStack {
                if result.normalSeconds + result.cautionSeconds == 0 {
                    // 감지된 소리가 없으면 빈 트랙만
                    Circle()
                        .stroke(PracticeResultColors.innerBackground, lineWidth: ReportLayout.donutLineWidth)
                        .padding(ReportLayout.donutLineWidth / 2)
                }
                ReportSliceDonut(
                    values: Self.donutSounds.map { Double(result.detectedSeconds(of: $0.sound)) },
                    colors: Self.donutSounds.map(\.color)
                )
                .frame(width: ReportLayout.donutDiameter.h(scale), height: ReportLayout.donutDiameter.h(scale))
                VStack(spacing: ReportLayout.donutTextSpacing) {
                    Text(showsNormalRatio
                         ? "\(Int((result.normalRatio * 100).rounded()))%"
                         : "\(Int((result.cautionRatio * 100).rounded()))%")
                        .font(.pretendard(.bold, size: 36))
                        .foregroundStyle(showsNormalRatio ? PracticeResultColors.normalRatioText : AppColors.soundCaution)
                    Text(showsNormalRatio ? "정상소리" : "주의소리")
                        .font(.pretendard(.regular, size: ReportLayout.donutLabelSize))
                        .foregroundStyle(AppColors.darkSecondaryButton)
                        .offset(y: ReportLayout.donutLabelDY)
                }
            }
            .frame(width: ReportLayout.donutDiameter.h(scale), height: ReportLayout.donutDiameter.h(scale))
            .at(x: ReportLayout.donutCenterX - ReportLayout.donutDiameter / 2, y: ReportLayout.donutY, scale)

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

    /// 도넛 조각 순서와 색 (Hi-Fi 공기 과도 · 부족)
    private static let donutSounds: [(sound: DetectedSound, color: Color)] = [
        (.normalAeration, AppColors.soundNormalAeration),
        (.overAeration, AppColors.soundCaution),
        (.lackOfAir, AppColors.soundCaution),
        (.rolling, AppColors.soundRolling)
    ]

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
    /// 이번 연습의 공기 주입 시간 (초). 비커 우유 높이가 이 값을 따라가요.
    let aerationSeconds: Double

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                Text("연습 가이드")
                    .font(.pretendard(.bold, size: 20))
                    .foregroundStyle(Color.white)
                    .at(x: ReportLayout.sectionTitleX, y: 0, scale)

                ReportGuidePitcher(milkTop: GuideMilkLevel.top(forAeration: aerationSeconds))
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

/// 가이드 비커: 빈 비커 그림 위에 공기 주입한 만큼 우유를 채우고, 두 점선(2초 · 4초)을 그려요.
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

    private static let rows: [(String, DetectedSound)] = [
        ("공기 주입", .normalAeration), ("버블링", .overAeration), ("스크레칭", .lackOfAir), ("롤링 소리", .rolling)
    ]

    var body: some View {
        ZStack(alignment: .topLeading) {
            Group {
                Text("소리 유형").at(x: ReportLayout.overviewLabelX, y: ReportLayout.overviewHeaderY, scale)
                Text("비율").at(x: ReportLayout.overviewRatioX, y: ReportLayout.overviewHeaderY, scale)
                timeText("시간", y: ReportLayout.overviewHeaderY)
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

                timeText("\(seconds)초", y: y)
                    .font(.pretendard(.regular, size: 12))
                    .foregroundStyle(Color.white)
                    .frame(height: ReportLayout.overviewBarHeight.v(scale))
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

    /// 시간 열: 오른쪽 끝(Hi-Fi: x 382)에 맞춰 오른쪽 정렬 ("6초" · "10초"의 끝이 같은 자리)
    private func timeText(_ text: String, y: CGFloat) -> some View {
        Text(text)
            .fixedSize()
            .frame(width: ReportLayout.overviewTimeWidth.h(scale), alignment: .trailing)
            .at(x: ReportLayout.overviewTimeRight - ReportLayout.overviewTimeWidth, y: y, scale)
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

/// 값 비율대로 나뉜 둥근 호들 (호끼리 맞닿음)
/// - 보이는 호(둥근 끝 포함)가 12시 방향(0°)에서 시작해 `비율 × 360°`씩 이어지고, 호 사이는 0.4°만 비어 있다.
///   (Hi-Fi 공기 과도: 파랑 6 · 분홍 2 · 분홍 2 · 초록 10초)
private struct ReportSliceDonut: View {
    let values: [Double]
    let colors: [Color]

    private let lineWidth = ReportLayout.donutLineWidth
    private let gapDegrees = 0.4

    var body: some View {
        GeometryReader { proxy in
            let diameter = min(proxy.size.width, proxy.size.height)
            let total = max(values.reduce(0, +), 1)
            ZStack {
                ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                    // 감지되지 않은(0초) 항목은 호도 아이콘도 그리지 않아요.
                    if value > 0 {
                        let visible = visibleRange(index: index, total: total)
                        let full = visible.upperBound - visible.lowerBound
                        // 한 가지 소리만 있으면 끊김 없는 한 바퀴
                        ArcFill(seenDegrees: full, startDegrees: visible.lowerBound,
                                lineWidth: lineWidth, color: colors[index], closed: value >= total, fullDegrees: full)
                    }
                }
            }
            .frame(width: diameter, height: diameter)
        }
    }

    private func visibleRange(index: Int, total: Double) -> ClosedRange<Double> {
        var start = ReportLayout.donutStartDegrees
        for i in 0..<index { start += 360 * values[i] / total }
        // 호가 간격(0.4°)보다 짧아도 범위의 끝이 시작보다 앞서지 않게 해요.
        return start...max(start, start + 360 * values[index] / total - gapDegrees)
    }
}

// MARK: - 색상

enum ReportColors {
    static let track = Color(hex: 0x202020)
    static let gridLine = Color(hex: 0x282A2E)
    static let summaryLabel = Color(hex: 0xB9B9B9)
}

// MARK: - Layout (iPhone 17 시안 측정값, pt · 왼쪽 위 기준 절대 좌표)

enum ReportLayout {
    // 페이지 높이 (Hi-Fi 연습가이드 3종: 402x1384)
    static let pageHeight: CGFloat = 1384

    // 상단 바
    static let topBarBottomPadding: CGFloat = 16 // 상단 바 아래 배경 여유
    static let topBarFade: CGFloat = 18           // 상단 바 배경 아래 흐려지는 구간
    static let topBarTop: CGFloat = 84           // 글자 y0 83~86 (Hi-Fi 255: 제목 글자 y0 86.5 − 2.5)

    // 히어로 (Hi-Fi 연습가이드 적정 · -1: 도넛 106 ~ 296.5 / 270.5 ~ 457.5, 요약 구분선 521.5 ~ 573)
    static let heroHeight: CGFloat = 609.5       // 컨테이너 아래 끝
    static let heroCornerRadius: CGFloat = 26
    static let headlineY: CGFloat = 154.3        // 타이틀 첫 줄 글자 y0 158.5 (측정 보정)
    static let headlineLineSpacing: CGFloat = 3.7 // 줄 높이 35
    static let donutDiameter: CGFloat = 189.2    // 바깥 반지름 94.6
    static let donutLineWidth: CGFloat = 34.2
    static let donutY: CGFloat = 269.2
    static let donutCenterX: CGFloat = 201.2     // (106 + 296.5) / 2
    /// 도넛 첫 조각이 시작하는 각도: 12시 방향 0°에서 시계 방향 (Hi-Fi 공기 과도: 파랑 둥근 끝이 12시 선에 닿음)
    static let donutStartDegrees: Double = 0
    static let donutTextSpacing: CGFloat = 5.3
    static let donutLabelSize: CGFloat = 20.5    // "주의소리" · "정상소리" 글자 높이 18
    static let donutLabelDY: CGFloat = -1
    static let summaryX: CGFloat = 18
    static let summaryY: CGFloat = 521.7         // 구분선 y 521.5 ~ 573
    static let summaryHeight: CGFloat = 50
    static let summaryColumnWidth: CGFloat = 122
    static let summaryTextSpacing: CGFloat = 4

    // 섹션 제목 (글자 y0 658)
    static let sectionTitleX: CGFloat = 20
    static let sectionTitleY: CGFloat = 655

    // 눈금: 막대 폭에 대한 비율 (8 · 12 · 16 · 20)
    static let tickFractions: [CGFloat] = [0.182, 0.394, 0.608, 0.820]

    // 소리 유형별 막대 표. 탭 바가 빠져 예전(Hi-Fi 255)보다 78pt 위 (첫 막대 812 → 734)
    static let overviewHeaderY: CGFloat = 709    // 머리 글자 y0 710
    static let overviewFirstRowY: CGFloat = 734  // 첫 막대 위
    static let overviewRowPitch: CGFloat = 34.7
    static let overviewBarHeight: CGFloat = 22.5
    static let overviewLabelX: CGFloat = 20
    static let overviewTrackX: CGFloat = 77
    static let overviewTrackWidth: CGFloat = 214
    static let overviewRatioX: CGFloat = 307.4
    static let overviewTimeRight: CGFloat = 382  // 시간 열 오른쪽 끝 ("시간" · "6초" · "10초" 끝 381.5 ~ 382)
    static let overviewTimeWidth: CGFloat = 40
    static let overviewAxisY: CGFloat = 866      // 눈금 글자 y0 868.5

    // 연습 가이드 (섹션 맨 위 = 제목 글자 상자 위 기준, 제목 글자 y0 929)
    static let guideY: CGFloat = 1003.7 - 78
    static let guidePitcherX: CGFloat = 112.7             // 비커 그림 왼쪽 (Hi-Fi 260: 비커 바닥 왼쪽 114 − 에셋 여백 1.3). 2026-11-13 시안부터 노즐 없음 (에셋 캔버스 크기는 그대로)
    static let guidePitcherTop: CGFloat = 1045.8 - 1003.7 // 제목 ↔ 비커 그림(캔버스) 위 (Hi-Fi 260: 노즐 위 1046)
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

    // 안내 문구 (글자 y0 1337)
    static let footnoteY: CGFloat = 1412.7 - 78
}
