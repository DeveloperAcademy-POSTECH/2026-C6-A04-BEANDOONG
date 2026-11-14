//
//  HistoryDetailView.swift
//
//  히스토리 화면(HistoryView)에서 연습 기록 카드를 터치했을 때 이동하는 상세 화면입니다.
//  연습 직후 결과 화면(PracticeResultView)과 같은 리포트 본문(`PracticeReportScreen`)을 쓰고, 상단 바 제목만 다릅니다.
//

import SwiftUI

/// 히스토리 연습 기록 상세 화면 (다크 테마)
/// - Hi-Fi: iPhone 17 - 307 (2026-11-14) · 272(삭제 팝업)
///
///     ┌ 상단 바: < 9월 28일 - 1차                🗑   (기록 이름, 연습 결과 화면은 "스티밍 결과")
///     ├ 히어로: 결과에 따른 타이틀(`PracticeGuide.historyHeadline`) + 주의 소리 링 + 3열 요약
///     ├ 스티밍 기록: 소리 유형별 막대 표
///     ├ 연습 가이드: 비커 그림 + 공기 주입 시간 안내 카드 (기준 안 · 너무 김 · 너무 짧음)
///     └ 안내 문구
struct HistoryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let result: PracticeResult
    /// 삭제 팝업에서 "기록 삭제"를 확인했을 때 (저장소에서 지우는 일은 바깥에서). 끝나면 이 화면을 닫는다
    var onDelete: (() -> Void)? = nil
    var showsDeleteDialog = false

    var body: some View {
        PracticeReportScreen(
            result: result,
            headline: PracticeGuide(result: result).historyHeadline,
            barTitle: result.title,
            onDelete: { onDelete?(); dismiss() },
            showsDeleteDialog: showsDeleteDialog
        )
    }
}

// MARK: - 미리보기

#Preview("디자인 (24초)") {
    NavigationStack {
        HistoryDetailView(result: .hifiSample)
    }
}

#Preview("1분 넘는 연습") {
    NavigationStack {
        HistoryDetailView(result: .longSample)
    }
}
