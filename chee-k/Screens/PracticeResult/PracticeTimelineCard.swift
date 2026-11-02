//
//  PracticeTimelineCard.swift
//
//  연습 결과 화면(PracticeResultView)과 히스토리 상세 화면(HistoryDetailView)의
//  "전체 타임라인" 공통 카드 컴포넌트입니다.
//
//  스티밍 단계(공기 주입 · 롤링 소리)마다 왼쪽에 단계 이름을, 오른쪽에 타임라인 막대와
//  시간 눈금 축을 가로로 나란히 배치합니다.
//

import SwiftUI

/// 전체 타임라인 카드
///
///     ┌───────────────────────────────────────────────┐
///     │ 전체 타임라인                                    │
///     │ 시간에 따른 스티밍 단계와 소리 상태를 확인해요          │
///     │                                               │
///     │ 공기 주입   ▬▬▬            ▬▬▬▬▬▬▬▬▬▬▬          │
///     │           0초   8초   12초  16초  20초  24초     │
///     │ 롤링 소리      ▬▬▬▬▬▬▬▬▬▬                       │
///     │           0초   8초   12초  16초  20초  24초     │
///     └───────────────────────────────────────────────┘
struct PracticeTimelineCard: View {
    let result: PracticeResult

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PracticeResultCardHeader(
                title: "전체 타임라인",
                subtitle: "시간에 따른 스티밍 단계와 소리 상태를 확인해요"
            )

            VStack(spacing: Metrics.rowSpacing) {
                ForEach(SteamingStage.allCases, id: \.self) { stage in
                    HStack(alignment: .top, spacing: 0) {
                        Text(stage.timelineTitle)
                            .font(.pretendard(.medium, size: 12))
                            .foregroundStyle(PracticeResultColors.secondaryText)
                            .frame(
                                width: Metrics.stageLabelWidth,
                                height: Metrics.trackHeight,
                                alignment: .leading
                            )
                            .accessibilityHidden(true)

                        VStack(spacing: Metrics.axisTop) {
                            TimelineTrack(
                                stage: stage,
                                segments: result.segments.filter { $0.sound.stage == stage },
                                timelineLength: result.timelineLength
                            )

                            TimelineAxis(
                                timelineLength: result.timelineLength,
                                customTickSeconds: result.customTickSeconds
                            )
                            .accessibilityHidden(true)
                        }
                    }
                }
            }
            .padding(.top, Metrics.rowsTop)
        }
        .practiceResultCard()
    }
}

// MARK: - 타임라인 한 줄

/// 한 단계의 막대 한 줄
private struct TimelineTrack: View {
    let stage: SteamingStage
    let segments: [DetectedSegment]
    /// 막대 전체가 나타내는 시간 (초)
    let timelineLength: TimeInterval

    var body: some View {
        GeometryReader { geometry in
            let pointsPerSecond = timelineLength > 0 ? geometry.size.width / timelineLength : 0

            ZStack(alignment: .leading) {
                PracticeResultColors.innerBackground

                ForEach(segments) { segment in
                    segment.sound.timelineColor
                        .frame(width: max(segment.duration * pointsPerSecond, Metrics.minimumSegmentWidth))
                        .offset(x: segment.start * pointsPerSecond)
                }
            }
        }
        .frame(height: Metrics.trackHeight)
        .clipShape(RoundedRectangle(cornerRadius: Metrics.trackCornerRadius))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(stage.timelineTitle)
        .accessibilityValue(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        guard !segments.isEmpty else { return "감지된 소리 없음" }
        return segments
            .map { segment in
                let start = Int(segment.start.rounded()).practiceSecondsText
                let end = Int(segment.end.rounded()).practiceSecondsText
                return "\(start)부터 \(end)까지 \(segment.sound.title)"
            }
            .joined(separator: ", ")
    }
}

// MARK: - 시간 축

/// 각 막대 바로 아래에 놓이는 눈금 + 시간 라벨
private struct TimelineAxis: View {
    let timelineLength: TimeInterval
    let customTickSeconds: [Int]?

    /// 눈금 간격 후보 (초)
    private static let tickStepCandidates = [1, 2, 4, 5, 10, 15, 20, 30, 60, 120, 300]
    /// 한 줄에 놓을 수 있는 최대 눈금 수
    private static let maxTickCount = 6

    private var tickSeconds: [Int] {
        if let customTickSeconds, !customTickSeconds.isEmpty {
            return customTickSeconds
        }
        let length = Int(timelineLength.rounded(.down))
        guard length > 0 else { return [0] }
        let step = Self.tickStepCandidates.first { length / $0 + 1 <= Self.maxTickCount }
            ?? length
        return Array(stride(from: 0, through: length, by: step))
    }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let count = tickSeconds.count

            ForEach(Array(tickSeconds.enumerated()), id: \.offset) { index, second in
                let xPosition = tickXPosition(index: index, count: count, second: second, width: width)

                // 눈금 선
                Rectangle()
                    .fill(PracticeResultColors.tickLine)
                    .frame(width: Metrics.tickWidth, height: Metrics.tickHeight)
                    .position(x: xPosition, y: Metrics.tickHeight / 2)

                // 시간 라벨 (첫 라벨은 좌측 정렬, 마지막 라벨은 우측 정렬, 중간 라벨은 중앙 정렬)
                Text("\(second)초")
                    .font(.pretendard(.regular, size: 10))
                    .foregroundStyle(PracticeResultColors.secondaryText)
                    .fixedSize()
                    .frame(
                        width: Metrics.labelFrameWidth,
                        alignment: labelAlignment(index: index, count: count)
                    )
                    .position(
                        x: labelCenterX(index: index, count: count, tickX: xPosition),
                        y: Metrics.tickHeight + Metrics.tickLabelTop + Metrics.labelHeight / 2
                    )
            }
        }
        .frame(height: Metrics.axisHeight)
    }

    private func tickXPosition(index: Int, count: Int, second: Int, width: CGFloat) -> CGFloat {
        if customTickSeconds != nil, count > 1 {
            return width * CGFloat(index) / CGFloat(count - 1)
        }
        guard timelineLength > 0 else { return 0 }
        return width * CGFloat(Double(second) / timelineLength)
    }

    private func labelAlignment(index: Int, count: Int) -> Alignment {
        if index == 0 { return .leading }
        if count > 1 && index == count - 1 { return .trailing }
        return .center
    }

    private func labelCenterX(index: Int, count: Int, tickX: CGFloat) -> CGFloat {
        if index == 0 {
            return tickX + Metrics.labelFrameWidth / 2
        }
        if count > 1 && index == count - 1 {
            return tickX - Metrics.labelFrameWidth / 2
        }
        return tickX
    }
}

// MARK: - Metrics

/// Hi-Fi(402pt 폭) 기준 수치입니다.
private enum Metrics {
    static let rowsTop: CGFloat = 24
    static let rowSpacing: CGFloat = 16
    static let stageLabelWidth: CGFloat = 58
    static let trackHeight: CGFloat = 18
    static let trackCornerRadius: CGFloat = 4
    static let minimumSegmentWidth: CGFloat = 2

    static let axisTop: CGFloat = 2
    static let tickWidth: CGFloat = 1
    static let tickHeight: CGFloat = 4
    static let tickLabelTop: CGFloat = 4
    static let labelHeight: CGFloat = 12
    static let labelFrameWidth: CGFloat = 40
    static let axisHeight: CGFloat = 20
}
