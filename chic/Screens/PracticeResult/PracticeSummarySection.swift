//
//  PracticeSummarySection.swift
//
//  연습 결과 화면(PracticeResultView)과 히스토리 상세 화면(HistoryDetailView)이
//  공통으로 사용하는 상단 요약 섹션입니다.
//
//  [구성]
//  - 타이틀: "이번 연습을 / 함께 돌아볼까요?"
//  - 동심원 도넛 차트: 바깥 링(정상소리 비율) · 안쪽 링(주의 소리 비율) · 중앙 전체 시간
//  - 3열 요약 바: 전체 시간 | 정상소리 | 주의 소리
//  - 하단 모서리가 둥근 그라데이션 컨테이너 배경
//

import SwiftUI

/// 상단 히어로 요약 섹션 (타이틀 + 동심원 도넛 차트 + 3열 요약 바)
struct PracticeSummarySection: View {
    let result: PracticeResult

    var body: some View {
        VStack(spacing: 0) {
            Text("이번 연습을\n함께 돌아볼까요?")
                .font(.pretendard(.bold, size: 26))
                .lineSpacing(Metrics.titleLineSpacing)
                .multilineTextAlignment(.center)
                .foregroundStyle(PracticeResultColors.primaryText)
                .padding(.top, Metrics.titleTop)
                .accessibilityAddTraits(.isHeader)

            PracticeDonutChart(result: result)
                .padding(.top, Metrics.donutTop)

            PracticeSummaryRow(result: result)
                .padding(.top, Metrics.summaryRowTop)
                .padding(.bottom, Metrics.summaryRowBottom)
                .padding(.horizontal, Metrics.horizontalPadding)
        }
        .frame(maxWidth: .infinity)
        .background(summaryBackground)
    }

    private var summaryBackground: some View {
        ZStack {
            LinearGradient(
                stops: [
                    .init(color: AppColors.darkBackground, location: 0.0),
                    .init(color: AppColors.darkBackground, location: 0.45),
                    .init(color: PracticeResultColors.heroGradientEdgeBottom, location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [
                    PracticeResultColors.heroGradientCenterBottom,
                    Color.clear
                ],
                center: .bottom,
                startRadius: 0,
                endRadius: Metrics.heroGlowRadius
            )
        }
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: Metrics.containerBottomCornerRadius,
                bottomTrailingRadius: Metrics.containerBottomCornerRadius,
                topTrailingRadius: 0,
                style: .continuous
            )
        )
    }
}

// MARK: - 동심원 도넛 차트

/// 정상소리(바깥 링)와 주의 소리(안쪽 링) 비율을 보여주는 동심원 도넛 차트
struct PracticeDonutChart: View {
    let result: PracticeResult

    var body: some View {
        ZStack {
            // 바깥 링 (정상소리)
            DonutRingArc(
                diameter: Metrics.outerRingDiameter,
                lineWidth: Metrics.ringLineWidth,
                ratio: result.normalRatio,
                foregroundColor: PracticeResultColors.normalSound,
                trackColor: PracticeResultColors.cardBackground
            )

            // 안쪽 링 (주의 소리)
            DonutRingArc(
                diameter: Metrics.innerRingDiameter,
                lineWidth: Metrics.ringLineWidth,
                ratio: result.cautionRatio,
                foregroundColor: PracticeResultColors.cautionSound,
                trackColor: PracticeResultColors.cardBackground
            )

            // 중앙 전체 시간
            VStack(spacing: Metrics.centerTextSpacing) {
                Text("전체 시간")
                    .font(.pretendard(.regular, size: 12))
                    .foregroundStyle(PracticeResultColors.secondaryText)

                Text(result.totalSeconds.practiceSecondsText)
                    .font(.pretendard(.bold, size: 24))
                    .foregroundStyle(PracticeResultColors.primaryText)
            }
        }
        .frame(width: Metrics.outerRingDiameter, height: Metrics.outerRingDiameter)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("전체 연습 시간 \(result.totalSeconds.practiceSecondsText)")
        .accessibilityValue("정상소리 \(result.normalSeconds.practiceSecondsText), 주의 소리 \(result.cautionSeconds.practiceSecondsText)")
    }
}

/// 단일 도넛 링 (트랙 + 비율에 따라 길이가 변하는 둥근 호)
private struct DonutRingArc: View {
    /// 링의 바깥 지름
    let diameter: CGFloat
    let lineWidth: CGFloat
    /// 0.0 ... 1.0 비율
    let ratio: Double
    let foregroundColor: Color
    let trackColor: Color

    /// stroke 중심선 지름
    private var centerlineDiameter: CGFloat {
        diameter - lineWidth
    }

    /// 둥근 끝(lineCap: .round) 하나가 호 바깥으로 튀어나오는 각도
    private var capDegrees: Double {
        let radius = centerlineDiameter / 2
        return Double((lineWidth / 2) / radius) * 180.0 / .pi
    }

    /// 최종 상태의 선 각도: 둥근 양 끝까지 포함한 보이는 호가 정확히 `ratio * 360°`가 되도록 끝 두 개를 뺀 값
    private var finalStrokeDegrees: Double {
        guard ratio > 0 else { return 0 }
        if ratio >= 1 { return 360 }
        return max(0.5, ratio * 360.0 - 2.0 * capDegrees)
    }

    /// 호 시작 각도: Hi-Fi 기준 호 중심 각도(-54°, 12시 방향에서 시계방향 36°)를 중심으로 최종 호를 대칭 배치한 자리
    private var startRotation: Angle {
        .degrees(Metrics.arcCenterDegrees - finalStrokeDegrees / 2.0)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(trackColor, lineWidth: lineWidth)

            if ratio > 0 {
                Circle()
                    .trim(from: 0, to: CGFloat(finalStrokeDegrees / 360.0))
                    .stroke(
                        foregroundColor,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(startRotation)
            }
        }
        .frame(width: centerlineDiameter, height: centerlineDiameter)
    }
}

// MARK: - 3열 요약 바

/// 전체 시간 | 정상소리 | 주의 소리를 세 칸과 구분선으로 보여주는 행
struct PracticeSummaryRow: View {
    let result: PracticeResult

    var body: some View {
        HStack(spacing: 0) {
            summaryColumn(
                title: "전체 시간",
                seconds: result.totalSeconds,
                valueColor: PracticeResultColors.primaryText
            )

            divider

            summaryColumn(
                title: "정상소리",
                seconds: result.normalSeconds,
                valueColor: PracticeResultColors.normalSound
            )

            divider

            summaryColumn(
                title: "주의 소리",
                seconds: result.cautionSeconds,
                valueColor: PracticeResultColors.cautionSound
            )
        }
        .frame(height: Metrics.dividerHeight)
    }

    private func summaryColumn(title: String, seconds: Int, valueColor: Color) -> some View {
        VStack(spacing: Metrics.summaryItemSpacing) {
            Text(title)
                .font(.pretendard(.regular, size: 12))
                .foregroundStyle(PracticeResultColors.secondaryText)

            Text(seconds.practiceSecondsText)
                .font(.pretendard(.bold, size: 20))
                .foregroundStyle(valueColor)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private var divider: some View {
        Rectangle()
            .fill(PracticeResultColors.summaryDivider)
            .frame(width: Metrics.dividerWidth, height: Metrics.dividerHeight)
            .accessibilityHidden(true)
    }
}

// MARK: - Metrics

/// Hi-Fi(402pt 폭) 기준 수치입니다.
private enum Metrics {
    static let horizontalPadding: CGFloat = 20
    static let titleTop: CGFloat = 34
    static let titleLineSpacing: CGFloat = 4
    static let donutTop: CGFloat = 52
    static let outerRingDiameter: CGFloat = 188
    static let innerRingDiameter: CGFloat = 146
    static let ringLineWidth: CGFloat = 13
    static let arcCenterDegrees: Double = -54.0
    static let centerTextSpacing: CGFloat = 8

    static let summaryRowTop: CGFloat = 46
    static let summaryRowBottom: CGFloat = 68
    static let summaryItemSpacing: CGFloat = 8
    static let dividerWidth: CGFloat = 1
    static let dividerHeight: CGFloat = 50

    static let containerBottomCornerRadius: CGFloat = 12
    static let heroGlowRadius: CGFloat = 240
}
