//
//  HistoryDetailView.swift
//
//  히스토리 화면(HistoryView)에서 연습 기록 카드를 터치했을 때 이동하는 상세 화면입니다.
//  `PracticeResult` 데이터를 받아 상단 도넛 요약 · 전체 타임라인 · 상태별 감지 시간 · 연습 가이드를
//  공통 컴포넌트로 구성해 표시합니다.
//

import SwiftUI

/// 히스토리 연습 기록 상세 화면 (다크 테마)
///
///     ┌ 상단 네비게이션 바: "9월 26일 1차"              ← 고정
///     ├ 상단 히어로 요약: 타이틀 + 도넛 차트 + 3열 요약   ← 여기부터 스크롤
///     ├ 스티밍 기록: 전체 타임라인 카드 + 상태별 감지 시간 카드
///     ├ 연습 가이드 카드
///     └ 하단 안내 문구
struct HistoryDetailView: View {
    let result: PracticeResult

    var body: some View {
        VStack(spacing: 0) {
            // MARK: 상단 네비게이션 바 (스크롤해도 고정)
            TopNavigationHeader(title: result.title, isDark: true)
                .padding(.top, PracticeResultMetrics.headerTop)
                .padding(.bottom, PracticeResultMetrics.headerBottom)

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

                        DetectedDurationCard(result: result, headerTitleWeight: .semibold)
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

// MARK: - 미리보기

#Preview("디자인 (24초)") {
    NavigationStack {
        HistoryDetailView(result: .sample)
    }
}

#Preview("1분 넘는 연습") {
    NavigationStack {
        HistoryDetailView(result: .longSample)
    }
}
