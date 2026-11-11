//
//  PracticeResultView.swift
//
//  연습이 끝난 뒤, 이번 연습에서 감지된 소리를 돌아보는 화면입니다.
//  `PracticeResult` 하나만 받아 `PracticeReportScreen`(도넛 요약 + 탭 3개)으로 그립니다.
//
//  [구성]
//  - PracticeResult.swift  : 화면에 넘기는 데이터 + 더미 데이터
//  - PracticeReport.swift  : 결과·기록 상세가 같이 쓰는 리포트 본문
//  - PracticeResultView.swift : 연습 직후 결과 화면 + 결과 계열 색상 (이 파일)
//

import SwiftUI

/// 연습 결과 화면 — 연습이 끝난 직후 이번 연습을 돌아본다 (다크 테마)
/// - Hi-Fi: iPhone 17 - 255(한 번에 보기) · 243(타임라인) · 257(상태별 감지시간) · 267(삭제 팝업)
///
///     ┌ 상단 바: < 연습 결과                🗑
///     ├ 히어로: "이번 연습을 함께 돌아볼까요?" + 도넛 + 3열 요약
///     ├ 스티밍 기록: 탭 [한 번에 보기 | 타임라인 | 상태별 감지시간]
///     └ 안내 문구
/// 공통 본문은 `PracticeReportScreen`이 그립니다. (기록 상세 `HistoryDetailView`와 같은 구성)
struct PracticeResultView: View {
    let result: PracticeResult
    var onClose: (() -> Void)? = nil
    /// 삭제 팝업에서 "기록 삭제"를 확인했을 때 (저장소에서 지우는 일은 바깥에서). 끝나면 `onClose`로 닫는다
    var onDelete: (() -> Void)? = nil
    var initialTab: PracticeReportTab = .overview
    var showsDeleteDialog = false

    var body: some View {
        PracticeReportScreen(
            result: result,
            headline: { _ in "이번 연습을\n함께 돌아볼까요?" },
            barTitle: "연습 결과",
            onBack: onClose,
            onDelete: { onDelete?(); onClose?() },
            initialTab: initialTab,
            showsDeleteDialog: showsDeleteDialog
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
    static let footnote = Color(hex: 0x98A2B3)
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
