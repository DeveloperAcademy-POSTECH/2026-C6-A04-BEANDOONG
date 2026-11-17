import SwiftUI
import UIKit

// MARK: - 한 번에 보기

struct ReportOverviewChart: View {
    @Environment(\.designScale) private var scale
    @ScaledMetric(relativeTo: .body) private var labelFontSize: CGFloat = 12
    let result: PracticeResult

    /// 줄 순서: 시안 304 · 307처럼 스크래칭이 버블링보다 위 (2026-11-14).
    /// 이름과 소리의 짝은 앱 전체와 같아요: 스크래칭 = 공기 부족(보라), 버블링 = 공기 과다(주황).
    /// 시안은 2번째 줄 막대가 주황이지만, 이름을 기준으로 맞춰서 앱에서는 보라 → 주황 순이에요.
    private static let rows: [(String, DetectedSound)] = [
        (String(localized: "공기 주입"), .normalAeration), (String(localized: "스크래칭"), .lackOfAir), (String(localized: "버블링"), .overAeration), (String(localized: "롤링 소리"), .rolling)
    ]

    /// 번역된 이름의 실제 폭만큼 공간을 확보하고 막대·눈금의 시작점을 함께 옮깁니다.
    private var trackX: CGFloat {
        max(ReportLayout.overviewTrackX, ReportLayout.overviewLabelX + (Self.labelColumnWidth(fontSize: labelFontSize) + 8) / scale.x)
    }

    /// 글자 크기별로 한 번만 잰 이름 열의 글자 폭 (올림). 같은 글자 크기면 폭이 같아서, 다시 그릴 때마다 글꼴을 만들고 글자를 재지 않아요.
    private static var labelColumnWidths: [CGFloat: CGFloat] = [:]

    private static func labelColumnWidth(fontSize: CGFloat) -> CGFloat {
        if let cached = labelColumnWidths[fontSize] { return cached }
        FontRegistrar.registerIfNeeded()
        let font = UIFont(name: PretendardWeight.regular.rawValue, size: fontSize)
            ?? UIFont.systemFont(ofSize: fontSize)
        let names = rows.map(\.0) + [String(localized: "소리 유형")]
        let textWidth = names.map { ($0 as NSString).size(withAttributes: [.font: font]).width }.max() ?? 0
        let width = ceil(textWidth)
        labelColumnWidths[fontSize] = width
        return width
    }

    private var trackWidth: CGFloat {
        max(1, ReportLayout.overviewTrackX + ReportLayout.overviewTrackWidth - trackX).h(scale)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Group {
                Text(String(localized: "소리 유형")).at(x: ReportLayout.overviewLabelX, y: ReportLayout.overviewHeaderY, scale)
                Text(String(localized: "비율")).at(x: ReportLayout.overviewRatioX, y: ReportLayout.overviewHeaderY, scale)
                timeText(String(localized: "시간"), y: ReportLayout.overviewHeaderY)
            }
            .font(.pretendard(.regular, size: 11))
            .foregroundStyle(PracticeResultColors.secondaryText)

            ForEach(Array(Self.rows.enumerated()), id: \.offset) { index, row in
                let y = ReportLayout.overviewFirstRowY + CGFloat(index) * ReportLayout.overviewRowPitch
                let seconds = result.detectedSeconds(of: row.1)

                rowText(row.0, color: .white, x: ReportLayout.overviewLabelX, y: y)

                ReportBar(result: result, sounds: [row.1], width: trackWidth, height: ReportLayout.overviewBarHeight.v(scale))
                    .at(x: trackX, y: y, scale)

                rowText(Self.percentText(seconds: seconds, total: result.totalSeconds), color: ReportColors.summaryLabel,
                        x: ReportLayout.overviewRatioX, y: y)

                timeText(String(localized: "\(seconds)초"), y: y)
                    .font(.pretendard(.regular, size: 12))
                    .foregroundStyle(Color.white)
                    .frame(height: ReportLayout.overviewBarHeight.v(scale))
            }

            ReportAxis(width: trackWidth, ticks: result.tickLabels) // 막대(.h(scale))와 같은 폭이어야 눈금 숫자가 막대 눈금선에 맞는다
                .at(x: trackX, y: ReportLayout.overviewAxisY, scale)
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

            // 구간은 id 가 없어서(같은 소리 · 시각이 겹쳐도 되도록) 순서를 id 로 써요
            ForEach(Array(result.segments.filter { sounds.contains($0.sound) }.enumerated()), id: \.offset) { _, segment in
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
        return seconds.enumerated().map { index, value in index == seconds.count - 1 ? String(localized: "\(value)초") : "\(value)" }
    }
}
