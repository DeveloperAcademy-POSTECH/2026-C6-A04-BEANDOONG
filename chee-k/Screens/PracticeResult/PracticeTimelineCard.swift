//
//  PracticeTimelineCard.swift
//
//  연습 결과 화면의 "전체 타임라인" 카드입니다.
//  스티밍 단계(공기 주입 · 롤링)마다 막대를 한 줄씩 두고,
//  감지된 구간을 "언제부터 언제까지"에 맞춰 색칠합니다.
//
//  [막대를 그리는 원리]
//  "1초 = 몇 pt" 비율(pointsPerSecond) 하나로 모든 위치를 계산합니다.
//    - 비율      = 막대 실제 폭 ÷ 연습 전체 길이   (예: 330pt ÷ 24초 = 13.75pt)
//    - 구간 위치 = 시작 시점 × 비율                (예: 16초 → 220pt)
//    - 구간 길이 = 구간 길이 × 비율                (예: 2초  → 27.5pt)
//  막대 폭은 GeometryReader 로 그때그때 읽기 때문에, 기기 화면 폭이나 연습 길이가 달라져도
//  따로 손댈 필요 없이 알맞게 늘어나고 줄어듭니다.
//  아래 시간 축 눈금도 같은 비율을 써서, 막대 위치와 눈금이 항상 정확히 맞습니다.
//

import SwiftUI

/// 전체 타임라인 카드
///
///     ┌───────────────────────────────────────┐
///     │ 전체 타임라인                            │
///     │ 시간에 따른 스티밍 단계와 소리 상태를 확인해요  │
///     │ 공기 주입                                │
///     │ ▬▬▬            ▬▬▬▬▬▬▬▬▬▬▬            │
///     │ 롤링                                    │
///     │    ▬▬▬▬▬▬▬▬▬▬               ▬▬▬▬     │
///     │ 0초   4초   8초  ...            24초     │
///     └───────────────────────────────────────┘
struct PracticeTimelineCard: View {
    let result: PracticeResult

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PracticeResultCardHeader(
                title: "전체 타임라인",
                subtitle: "시간에 따른 스티밍 단계와 소리 상태를 확인해요"
            )

            // 단계마다 "단계 이름 + 막대" 한 줄씩 (공기 주입 → 롤링 순서)
            ForEach(SteamingStage.allCases, id: \.self) { stage in
                Text(stage.title)
                    .font(.pretendard(.semibold, size: 12))
                    .foregroundStyle(PracticeResultColors.primaryText)
                    .padding(.top, Metrics.stageTitleTop)
                    // 단계 이름은 아래 막대의 VoiceOver 설명에 함께 읽히므로 따로 읽지 않습니다.
                    .accessibilityHidden(true)

                // 이 단계에 속한 구간만 넘깁니다.
                // 그래서 공기 주입 소리가 나는 동안에는 롤링 줄이 빈칸(어두운 바탕)으로 남습니다.
                TimelineTrack(
                    stage: stage,
                    segments: result.segments.filter { $0.sound.stage == stage },
                    timelineLength: result.timelineLength
                )
                .padding(.top, Metrics.trackTop)
            }

            TimelineAxis(timelineLength: result.timelineLength)
                .padding(.top, Metrics.axisTop)
                // 눈금 숫자는 화면을 보는 사람을 위한 보조 정보라 VoiceOver 에서는 건너뜁니다.
                .accessibilityHidden(true)
        }
        .practiceResultCard()
    }
}

// MARK: - 타임라인 한 줄

/// 한 단계의 막대 한 줄
///
/// 어두운 바탕을 깔고, 그 위에 구간마다 색 막대를 "시작 위치"로 옮겨 놓습니다.
/// 마지막에 줄 전체를 둥근 사각형으로 잘라내서,
/// 맨 앞 · 맨 뒤 구간만 바깥 모서리가 둥글고 가운데 구간끼리는 딱 붙어 보이게 합니다.
private struct TimelineTrack: View {
    let stage: SteamingStage
    let segments: [DetectedSegment]
    /// 막대 전체가 나타내는 시간 (초) — 막대 오른쪽 끝 = 이 시간
    let timelineLength: TimeInterval

    var body: some View {
        GeometryReader { geometry in
            // 1초가 몇 pt 인지. 기록이 비어 있으면(길이 0) 0으로 두어 아무 구간도 그리지 않습니다.
            let pointsPerSecond = timelineLength > 0 ? geometry.size.width / timelineLength : 0

            ZStack(alignment: .leading) {
                PracticeResultColors.innerBackground

                ForEach(segments) { segment in
                    segment.sound.timelineColor
                        // 아주 짧게 감지된 구간도 눈에 보이도록 최소 폭을 보장합니다.
                        .frame(width: max(segment.duration * pointsPerSecond, Metrics.minimumSegmentWidth))
                        .offset(x: segment.start * pointsPerSecond)
                }
            }
        }
        .frame(height: Metrics.trackHeight)
        .clipShape(RoundedRectangle(cornerRadius: Metrics.trackCornerRadius))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(stage.title)
        .accessibilityValue(accessibilityDescription)
    }

    /// VoiceOver 가 읽을 설명 (예: "0초부터 3초까지 정상 공기 주입, 13초부터 16초까지 정상 공기 주입")
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

/// 막대 아래 눈금 + 시간 라벨 (0초, 4초, 8초 ...)
///
/// 눈금 간격은 연습 길이에 맞춰 자동으로 고릅니다.
///
///     연습 길이   간격    눈금
///     24초       4초     0, 4, 8, ... 24
///     45초       10초    0, 10, ... 40
///     90초       15초    0, 15, ... 90   (라벨은 1분이 넘어도 "90초"처럼 초로만 씁니다)
private struct TimelineAxis: View {
    let timelineLength: TimeInterval

    /// 눈금 간격 후보 (초) — 앞에서부터 차례로 시도합니다.
    private static let tickStepCandidates = [1, 2, 4, 5, 10, 15, 20, 30, 60, 120, 300]
    /// 한 줄에 놓을 수 있는 최대 눈금 수 (0초 포함). 이보다 많으면 라벨끼리 겹칩니다.
    private static let maxTickCount = 7

    /// 눈금을 놓을 시간들 (초)
    /// - 후보 중 "눈금 수가 maxTickCount 이하가 되는 가장 작은 간격"을 고릅니다.
    /// - 연습 길이가 간격으로 딱 나누어떨어지지 않으면 마지막 눈금은 끝보다 조금 앞에 놓입니다.
    private var tickSeconds: [Int] {
        let length = Int(timelineLength.rounded(.down))
        guard length > 0 else { return [0] }
        let step = Self.tickStepCandidates.first { length / $0 + 1 <= Self.maxTickCount }
            ?? length
        return Array(stride(from: 0, through: length, by: step))
    }

    var body: some View {
        GeometryReader { geometry in
            // 막대와 같은 방식으로 계산해야 눈금이 막대 위치와 정확히 맞습니다.
            let pointsPerSecond = timelineLength > 0 ? geometry.size.width / timelineLength : 0

            ForEach(tickSeconds, id: \.self) { second in
                VStack(spacing: Metrics.tickLabelTop) {
                    Rectangle()
                        .fill(PracticeResultColors.tickLine)
                        .frame(width: Metrics.tickWidth, height: Metrics.tickHeight)
                    // 1분이 넘어도 "1분 15초" 대신 "75초"로 짧게 씁니다.
                    // 긴 라벨은 마지막 눈금에서 카드 밖으로 삐져나오기 때문입니다.
                    Text("\(second)초")
                        .font(.pretendard(.regular, size: 11))
                        .foregroundStyle(PracticeResultColors.secondaryText)
                        // 라벨이 좁은 자리에서 줄바꿈되지 않게 원래 크기를 유지합니다.
                        .fixedSize()
                }
                // 눈금 선의 가운데가 정확히 해당 시간 위치에 오도록 놓습니다.
                // (그래서 "0초" · 마지막 라벨은 막대 양 끝에서 살짝 바깥으로 나옵니다. 디자인과 같습니다.)
                .position(
                    x: Double(second) * pointsPerSecond,
                    y: Metrics.axisHeight / 2
                )
            }
        }
        .frame(height: Metrics.axisHeight)
    }
}

// MARK: - Metrics

/// Hi-Fi(402pt 폭) 기준 수치입니다.
private enum Metrics {
    static let stageTitleTop: CGFloat = 14       // 위 요소 ↔ "공기 주입" · "롤링"
    static let trackTop: CGFloat = 8             // 단계 이름 ↔ 막대
    static let trackHeight: CGFloat = 18
    static let trackCornerRadius: CGFloat = 5
    /// 아무리 짧은 구간이라도 이 폭보다 얇게 그리지 않습니다.
    static let minimumSegmentWidth: CGFloat = 2
    static let axisTop: CGFloat = 8              // 마지막 막대 ↔ 눈금
    static let tickWidth: CGFloat = 1
    static let tickHeight: CGFloat = 6
    static let tickLabelTop: CGFloat = 6         // 눈금 ↔ 시간 라벨
    static let axisHeight: CGFloat = 26
}
