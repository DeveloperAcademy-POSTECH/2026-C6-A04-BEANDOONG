//
//  PracticeResultView.swift
//
//  연습이 끝난 뒤, 이번 연습에서 감지된 소리를 돌아보는 화면입니다.
//  `PracticeResult` 하나만 받아 `PracticeReportScreen`(도넛 요약 + 소리 유형별 표 + 연습 가이드)으로 그립니다.
//
//  [구성]
//  - PracticeResult.swift  : 화면에 넘기는 데이터 + 더미 데이터
//  - PracticeReport.swift  : 결과·기록 상세가 같이 쓰는 리포트 본문
//  - PracticeResultView.swift : 연습 직후 결과 화면 + 결과 계열 색상 (이 파일)
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
    static let heroGradientEdgeBottom = Color(hex: 0x141A27) // Hi-Fi 연습가이드: 아래 가장자리 x 8 → 0x151B28
    /// 상단 히어로 요약 컨테이너 하단 중앙 글로우 색상
    static let heroGradientCenterBottom = Color(hex: 0x2C3546) // Hi-Fi 연습가이드: 아래 가운데 0x212938 (글로우 60%와 섞인 값)
    /// 타임라인 눈금 선
    static let tickLine = Color(hex: 0x78797B)
    /// 하단 안내 문구
    static let footnote = Color(hex: 0x98A2B3)
    /// 연습 가이드 비커의 우유 (Hi-Fi 260)
    static let guideMilk = Color(hex: 0x686E79)
    /// 연습 가이드 카드 설명 (Hi-Fi 연습 가이드: 182,184,188)
    static let guideMessage = Color(hex: 0xB6B8BC)
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
