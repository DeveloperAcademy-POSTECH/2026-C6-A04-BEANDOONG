//
//  DetectedDurationCard.swift
//
//  연습 결과 화면(PracticeResultView)과 히스토리 상세 화면(HistoryDetailView)의
//  "상태별 감지 시간" 공통 카드 컴포넌트입니다.
//
//  스티밍 단계마다 해당 단계의 소리들을 한 줄(공기 주입 3열 · 롤링 1열) 타일로 배치하고,
//  각 소리가 감지된 시간을 가운데 정렬로 보여줍니다.
//

import SwiftUI

/// 상태별 감지 시간 카드
///
///     ┌────────────────────────────────────────────────────┐
///     │ 상태별 감지 시간                                      │
///     │ 이번 연습에서 각 소리가 얼마나 오래 감지되었는지 확인해요    │
///     │ 공기 주입                                            │
///     │ [정상 공기 주입 7초]  [공기과다 3초]  [공기 부족 3초]     │
///     │ 롤링                                                │
///     │ [                   롤링 11초                  ]     │
///     └────────────────────────────────────────────────────┘
struct DetectedDurationCard: View {
    let result: PracticeResult
    var headerTitleWeight: PretendardWeight = .bold

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PracticeResultCardHeader(
                title: "상태별 감지 시간",
                subtitle: "이번 연습에서 각 소리가 얼마나 오래 감지되었는지 확인해요",
                titleWeight: headerTitleWeight
            )

            // 튜플 키패스(enumerated + \.element)는 Xcode 프리뷰에서 크래시가 나서, 단계 값 자체를 id로 씁니다.
            ForEach(SteamingStage.allCases, id: \.self) { stage in
                Text(stage.title)
                    .font(.pretendard(.semibold, size: 12))
                    .foregroundStyle(PracticeResultColors.primaryText)
                    .padding(.top, stage == SteamingStage.allCases.first ? Metrics.firstStageTitleTop : Metrics.nextStageTitleTop)
                    .accessibilityAddTraits(.isHeader)

                HStack(spacing: tileSpacing(for: stage)) {
                    ForEach(stage.sounds, id: \.self) { sound in
                        DetectedDurationTile(
                            sound: sound,
                            seconds: result.detectedSeconds(of: sound)
                        )
                    }
                }
                .padding(.top, Metrics.tilesTop)
            }
        }
        .practiceResultCard()
    }

    private func tileSpacing(for stage: SteamingStage) -> CGFloat {
        switch stage {
        case .aeration: Metrics.aerationTileSpacing
        case .rolling: Metrics.rollingTileSpacing
        }
    }
}

// MARK: - 소리 타일

/// 소리 하나의 감지 시간 타일 (가운데 정렬)
private struct DetectedDurationTile: View {
    let sound: DetectedSound
    /// 감지된 시간 (초, 이미 반올림된 값)
    let seconds: Int

    var body: some View {
        VStack(spacing: Metrics.tileTextSpacing) {
            Text(sound.title)
                .font(.pretendard(.semibold, size: 12))
                .foregroundStyle(sound.labelColor)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Text(seconds.practiceSecondsText)
                .font(.pretendard(.bold, size: 20))
                .foregroundStyle(PracticeResultColors.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .padding(.horizontal, Metrics.tileHorizontalPadding)
        .frame(maxWidth: .infinity, minHeight: Metrics.tileHeight)
        .background(
            RoundedRectangle(cornerRadius: Metrics.tileCornerRadius)
                .fill(PracticeResultColors.innerBackground)
        )
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Metrics

/// Hi-Fi(402pt 폭) 기준 수치입니다.
private enum Metrics {
    static let firstStageTitleTop: CGFloat = 24
    static let nextStageTitleTop: CGFloat = 16
    static let tilesTop: CGFloat = 8
    static let aerationTileSpacing: CGFloat = 10
    static let rollingTileSpacing: CGFloat = 20
    static let tileHeight: CGFloat = 70
    static let tileCornerRadius: CGFloat = 8
    static let tileHorizontalPadding: CGFloat = 6
    static let tileTextSpacing: CGFloat = 8
}
