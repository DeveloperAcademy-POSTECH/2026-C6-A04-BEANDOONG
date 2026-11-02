//
//  PracticeResultView.swift
//
//  연습이 끝난 뒤, 이번 연습에서 감지된 소리를 돌아보는 화면입니다.
//  `PracticeResult` 하나만 받아서 상단 도넛 요약 · 전체 타임라인 · 상태별 감지 시간 · 연습 가이드를 그립니다.
//
//  [공통 컴포넌트 구성]
//  - PracticeResult.swift         : 화면에 넘기는 데이터 + 더미 데이터
//  - PracticeSummarySection.swift : 상단 타이틀 · 동심원 도넛 차트 · 3열 요약 바
//  - PracticeTimelineCard.swift   : 전체 타임라인 카드
//  - DetectedDurationCard.swift   : 상태별 감지 시간 카드
//  - PracticeResultView.swift     : 연습 결과 화면 + 카드 공통 스타일 · 색상 (이 파일)
//

import SwiftUI

/// 연습 결과 화면 (다크 테마)
///
///     ┌ 상단 네비게이션 바: "9월 26일 1차"              ← 고정
///     ├ 상단 히어로 요약: 타이틀 + 도넛 차트 + 3열 요약   ← 여기부터 스크롤
///     ├ 스티밍 기록: 전체 타임라인 카드 + 상태별 감지 시간 카드
///     ├ 연습 가이드 카드
///     └ 하단 안내 문구
struct PracticeResultView: View {
    let result: PracticeResult

    var body: some View {
        VStack(spacing: 0) {
            // MARK: 상단 네비게이션 바 (스크롤해도 고정)
            TopNavigationHeader(title: result.title, isDark: true)
                .padding(.top, PracticeResultMetrics.headerTop)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // MARK: 상단 히어로 요약 (타이틀 + 도넛 차트 + 3열 요약)
                    PracticeSummarySection(result: result)

                    // MARK: 스티밍 기록 · 연습 가이드 · 안내 문구
                    VStack(alignment: .leading, spacing: 0) {
                        PracticeResultSectionTitle("스티밍 기록")
                            .padding(.top, PracticeResultMetrics.firstSectionTitleTop)

                        PracticeTimelineCard(result: result)
                            .padding(.top, PracticeResultMetrics.sectionContentTop)

                        DetectedDurationCard(result: result, headerTitleWeight: .bold)
                            .padding(.top, PracticeResultMetrics.cardSpacing)

                        PracticeGuideSection()
                            .padding(.top, PracticeResultMetrics.guideSectionTitleTop)

                        PracticeResultFootnote()
                            .padding(.top, PracticeResultMetrics.footnoteTop)
                            .padding(.bottom, PracticeResultMetrics.footnoteBottom)
                    }
                    .padding(.horizontal, PracticeResultMetrics.horizontalPadding)
                }
            }
            .scrollIndicators(.hidden)
        }
        .darkScreenBackground()
        .toolbar(.hidden, for: .navigationBar)
    }
}

// MARK: - 공통 섹션 컴포넌트

/// "스티밍 기록" · "연습 가이드" 같은 섹션 제목
struct PracticeResultSectionTitle: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.pretendard(.bold, size: 20))
            .foregroundStyle(PracticeResultColors.primaryText)
            .accessibilityAddTraits(.isHeader)
    }
}

/// 연습 가이드 섹션 (제목 + 가이드 카드)
struct PracticeGuideSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: PracticeResultMetrics.sectionContentTop) {
            PracticeResultSectionTitle("연습 가이드")

            RoundedRectangle(cornerRadius: PracticeResultMetrics.cardCornerRadius)
                .fill(PracticeResultColors.cardBackground)
                .frame(height: PracticeResultMetrics.guideCardHeight)
                .accessibilityHidden(true)
        }
    }
}

/// 하단 참고용 안내 문구
struct PracticeResultFootnote: View {
    var body: some View {
        Text("소리 분석에 따른 참고용 안내이며, 실제 공기량을 측정한 결과는 아니에요.")
            .font(.pretendard(.regular, size: 12))
            .foregroundStyle(PracticeResultColors.footnote)
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
    }
}

// MARK: - 카드 공통

/// 타임라인 · 상태별 감지 시간 카드 맨 위의 제목 + 설명
struct PracticeResultCardHeader: View {
    let title: String
    let subtitle: String
    var titleWeight: PretendardWeight = .bold

    var body: some View {
        VStack(alignment: .leading, spacing: PracticeResultMetrics.cardSubtitleTop) {
            Text(title)
                .font(.pretendard(titleWeight, size: 17))
                .foregroundStyle(PracticeResultColors.primaryText)
                .accessibilityAddTraits(.isHeader)

            Text(subtitle)
                .font(.pretendard(.regular, size: 12))
                .foregroundStyle(PracticeResultColors.secondaryText)
        }
    }
}

extension View {
    /// 연습 결과 · 히스토리 상세 카드의 공통 여백 · 배경을 입힙니다.
    func practiceResultCard() -> some View {
        self
            .padding(.horizontal, PracticeResultMetrics.cardHorizontalPadding)
            .padding(.top, PracticeResultMetrics.cardTopPadding)
            .padding(.bottom, PracticeResultMetrics.cardBottomPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: PracticeResultMetrics.cardCornerRadius)
                    .fill(PracticeResultColors.cardBackground)
            )
    }
}

// MARK: - 색상

/// 연습 결과 · 히스토리 상세 화면에서 공통으로 쓰는 색상 (Hi-Fi 원본 픽셀에서 추출)
enum PracticeResultColors {
    /// 카드 배경 · 도넛 차트 트랙 배경
    static let cardBackground = Color(hex: 0x202228)
    /// 카드 안쪽 배경 (타임라인 빈 막대 바탕 · 소리 타일 바탕)
    static let innerBackground = Color(hex: 0x16181F)
    /// 제목 · 큰 숫자
    static let primaryText = Color(hex: 0xDBECFF)
    /// 설명 · 작은 라벨 · 눈금 숫자
    static let secondaryText = Color(hex: 0x919296)
    /// 도넛 바깥 링 · 요약 "정상소리" 숫자
    static let normalSound = Color(hex: 0x76CAF2)
    /// 도넛 안쪽 링 · 요약 "주의 소리" 숫자
    static let cautionSound = Color(hex: 0xF2627C)
    /// 상단 요약 바 세로 구분선
    static let summaryDivider = Color(hex: 0x798494)
    /// 상단 히어로 요약 컨테이너 하단 가장자리 그라데이션 색상
    static let heroGradientEdgeBottom = Color(hex: 0x191F2D)
    /// 상단 히어로 요약 컨테이너 하단 중앙 글로우 색상
    static let heroGradientCenterBottom = Color(hex: 0x242D3C)
    /// 타임라인 눈금 선
    static let tickLine = Color(hex: 0x78797B)
    /// 하단 안내 문구
    static let footnote = Color(hex: 0x828C9B)
}

// MARK: - Metrics

/// Hi-Fi(402pt 폭) 기준 수치입니다.
enum PracticeResultMetrics {
    static let horizontalPadding: CGFloat = 20
    static let headerTop: CGFloat = 22
    static let firstSectionTitleTop: CGFloat = 52
    static let sectionContentTop: CGFloat = 18
    static let cardSpacing: CGFloat = 16
    static let guideSectionTitleTop: CGFloat = 28
    static let guideCardHeight: CGFloat = 88
    static let footnoteTop: CGFloat = 50
    static let footnoteBottom: CGFloat = 24

    static let cardCornerRadius: CGFloat = 16
    static let cardHorizontalPadding: CGFloat = 16
    static let cardTopPadding: CGFloat = 18
    static let cardBottomPadding: CGFloat = 20
    static let cardSubtitleTop: CGFloat = 6
}

// MARK: - 미리보기

#Preview("디자인 (24초)") {
    NavigationStack {
        PracticeResultView(result: .sample)
    }
}

#Preview("1분 넘는 연습") {
    NavigationStack {
        PracticeResultView(result: .longSample)
    }
}

#Preview("감지된 소리 없음") {
    NavigationStack {
        PracticeResultView(result: .empty)
    }
}
