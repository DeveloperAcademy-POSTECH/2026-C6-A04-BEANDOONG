//
//  DetectedDurationCard.swift
//
//  연습 결과 화면의 "상태별 감지 시간" 카드입니다.
//  스티밍 단계마다 감지될 수 있는 소리를 2열 타일로 놓고, 소리마다 감지된 시간을 보여줍니다.
//
//  - 타일 순서와 단계 구분은 `DetectedSound`(PracticeResult.swift)의 case 순서 · stage 를 따릅니다.
//    소리를 추가하거나 순서를 바꾸고 싶다면 이 파일이 아니라 `DetectedSound` 를 고치면 됩니다.
//  - 한 번도 감지되지 않은 소리도 "0초" 타일로 보여줍니다.
//    연습마다 타일 개수 · 위치가 바뀌지 않아 결과를 비교하기 쉽고, "0초"도 의미 있는 피드백이기 때문입니다.
//

import SwiftUI

/// 상태별 감지 시간 카드
///
///     ┌───────────────────────────────────────┐
///     │ 상태별 감지 시간                          │
///     │ 이번 연습에서 각 소리가 ... 확인해요         │
///     │ 공기 주입                                │
///     │ [정상 공기 주입 6초] [공기과다 2초]          │
///     │ [공기 부족 2초]                          │
///     │ 롤링                                    │
///     │ [롤링 10초]       [음료 과열 4초]          │
///     └───────────────────────────────────────┘
struct DetectedDurationCard: View {
    let result: PracticeResult

    /// 같은 폭의 2열. 소리가 홀수 개면 마지막 타일은 왼쪽에 혼자 놓입니다. (공기 부족 타일처럼)
    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: Metrics.tileColumnSpacing),
        count: 2
    )

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PracticeResultCardHeader(
                title: "상태별 감지 시간",
                subtitle: "이번 연습에서 각 소리가 얼마나 오래 감지되었는지 확인해요"
            )

            // 단계마다 "단계 이름 + 타일 묶음" (공기 주입 → 롤링 순서)
            ForEach(SteamingStage.allCases, id: \.self) { stage in
                Text(stage.title)
                    .font(.pretendard(.semibold, size: 12))
                    .foregroundStyle(PracticeResultColors.primaryText)
                    .padding(.top, Metrics.stageTitleTop)
                    .accessibilityAddTraits(.isHeader)

                LazyVGrid(columns: columns, spacing: Metrics.tileRowSpacing) {
                    ForEach(stage.sounds, id: \.self) { sound in
                        DetectedDurationTile(
                            sound: sound,
                            seconds: result.detectedSeconds(of: sound)
                        )
                    }
                }
                .padding(.top, Metrics.gridTop)
            }
        }
        .practiceResultCard()
    }
}

// MARK: - 소리 타일

/// 소리 하나의 감지 시간 타일
///
///     ┌──────────────┐
///     │ 정상 공기 주입   │  ← 소리 이름 (소리 색상)
///     │ 6초            │  ← 감지 시간
///     └──────────────┘
private struct DetectedDurationTile: View {
    let sound: DetectedSound
    /// 감지된 시간 (초, 이미 반올림된 값)
    let seconds: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.tileTextSpacing) {
            Text(sound.title)
                .font(.pretendard(.semibold, size: 12))
                .foregroundStyle(sound.labelColor)

            Text(seconds.practiceSecondsText)
                .font(.pretendard(.bold, size: 26))
                .foregroundStyle(PracticeResultColors.primaryText)
        }
        .padding(.horizontal, Metrics.tileHorizontalPadding)
        // 글자 길이와 상관없이 타일 크기가 같도록 폭은 열 전체, 높이는 최소 높이로 맞춥니다.
        .frame(maxWidth: .infinity, minHeight: Metrics.tileHeight, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Metrics.tileCornerRadius)
                .fill(PracticeResultColors.innerBackground)
        )
        // VoiceOver 에서 "정상 공기 주입, 6초" 처럼 한 번에 읽히게 묶습니다.
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Metrics

/// Hi-Fi(402pt 폭) 기준 수치입니다.
private enum Metrics {
    static let stageTitleTop: CGFloat = 14         // 위 요소 ↔ "공기 주입" · "롤링"
    static let gridTop: CGFloat = 10               // 단계 이름 ↔ 타일
    static let tileColumnSpacing: CGFloat = 10     // 타일 사이 가로 간격
    static let tileRowSpacing: CGFloat = 8         // 타일 사이 세로 간격
    static let tileHeight: CGFloat = 80
    static let tileCornerRadius: CGFloat = 8
    static let tileHorizontalPadding: CGFloat = 12
    static let tileTextSpacing: CGFloat = 12       // 소리 이름 ↔ 감지 시간
}
