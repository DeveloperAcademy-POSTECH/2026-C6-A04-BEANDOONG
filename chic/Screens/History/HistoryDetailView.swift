//
//  HistoryDetailView.swift
//
//  히스토리 화면(HistoryView)에서 연습 기록 카드를 터치했을 때 이동하는 상세 화면입니다.
//  연습 직후 결과 화면(PracticeResultView)과 같은 리포트 본문(`PracticeReportScreen`)을 쓰고, 상단 문구만 다릅니다.
//

import SwiftUI

/// 히스토리 연습 기록 상세 화면 (다크 테마)
/// - Hi-Fi: iPhone 17 - 269(한 번에 보기) · 270(타임라인) · 271(상태별 감지시간) · 272(삭제 팝업)
///
///     ┌ 상단 바: < 9월 28일 - 1차                🗑
///     ├ 히어로: "그날의 연습을 다시 살펴봐요" (타임라인·상태별은 "연습했던 순간을 다시 살펴봐요") + 도넛 + 3열 요약
///     ├ 스티밍 기록: 탭 [한 번에 보기 | 타임라인 | 상태별 감지시간]
///     └ 안내 문구
struct HistoryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let result: PracticeResult
    /// 삭제 팝업에서 "기록 삭제"를 확인했을 때 (저장소에서 지우는 일은 바깥에서). 끝나면 이 화면을 닫는다
    var onDelete: (() -> Void)? = nil
    var initialTab: PracticeReportTab = .overview
    var showsDeleteDialog = false

    var body: some View {
        PracticeReportScreen(
            result: result,
            headline: { tab in
                tab == .overview ? "그날의 연습을\n다시 살펴봐요" : "연습했던 순간을\n다시 살펴봐요"
            },
            variant: .historyDetail,
            onDelete: { onDelete?(); dismiss() },
            initialTab: initialTab,
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
