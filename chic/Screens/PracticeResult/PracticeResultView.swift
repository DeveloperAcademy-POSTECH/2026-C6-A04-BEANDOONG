//
//  PracticeResultView.swift
//
//  연습이 끝난 뒤, 이번 연습에서 감지된 소리를 돌아보는 화면입니다.
//  `PracticeResult` 하나만 받아 `PracticeReportScreen`(도넛 요약 + 소리 유형별 표 + 연습 가이드)으로 그립니다.
//
//  [구성]
//  - PracticeResult.swift       : 화면에 넘기는 데이터 + 더미 데이터 (Foundation 만 써요)
//  - DetectedSound+Color.swift  : 소리 종류별 막대 색
//  - PracticeReport.swift 와 Report*.swift : 결과·기록 상세가 같이 쓰는 리포트 본문
//  - PracticeResultColors.swift : 결과 · 기록 상세가 같이 쓰는 색상
//  - PracticeResultView.swift   : 연습 직후 결과 화면 (이 파일)
//  - HistoryDetailView.swift    : 같은 리포트를 기록 이름 제목으로 보여 주는 기록 상세 (History 폴더)
//

import SwiftUI

/// 연습 결과 화면 — 연습이 끝난 직후 이번 연습을 돌아본다 (다크 테마)
/// - Hi-Fi: iPhone 17 - 304 (2026-11-14) · 연습가이드 공기 과도 · 부족 (2026-11-13) · 267(삭제 팝업)
///
///     ┌ 상단 바: < 스티밍 결과                🗑
///     ├ 히어로: 결과에 따른 타이틀(`PracticeGuide.resultHeadline`) + 주의 소리 링 + 3열 요약
///     ├ 스티밍 기록: 소리 유형별 막대 표
///     ├ 연습 가이드: 비커 그림 + 공기 주입 시간 안내 카드 (기준 안 · 너무 김 · 너무 짧음)
///     └ 안내 문구
/// 공통 본문은 `PracticeReportScreen`이 그립니다. (기록 상세 `HistoryDetailView`와 같은 구성, 상단 바 제목만 기록 이름)
struct PracticeResultView: View {
    let result: PracticeResult
    var onClose: (() -> Void)? = nil
    /// 삭제 팝업에서 "기록 삭제"를 확인했을 때 (저장소에서 지우는 일은 바깥에서). 끝나면 `onClose`로 닫는다
    var onDelete: (() -> Void)? = nil
    var showsDeleteDialog = false

    var body: some View {
        PracticeReportScreen(
            result: result,
            headline: PracticeGuide(result: result).resultHeadline,
            barTitle: String(localized: "스티밍 결과"),
            onBack: onClose,
            onDelete: { onDelete?(); onClose?() },
            showsDeleteDialog: showsDeleteDialog
        )
    }
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
