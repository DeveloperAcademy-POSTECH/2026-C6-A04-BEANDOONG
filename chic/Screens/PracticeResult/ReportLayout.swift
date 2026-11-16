import SwiftUI

// MARK: - 색상

enum ReportColors {
    static let track = Color(hex: 0x202020)
    static let gridLine = Color(hex: 0x282A2E)
    static let summaryLabel = Color(hex: 0xB9B9B9)
}

// MARK: - Layout (iPhone 17 시안 측정값, pt · 왼쪽 위 기준 절대 좌표)

enum ReportLayout {
    // 상단 바
    static let topBarBottomPadding: CGFloat = 16 // 상단 바 아래 배경 여유
    static let topBarFade: CGFloat = 18           // 상단 바 배경 아래 흐려지는 구간

    // 히어로 (Hi-Fi 연습가이드 적정 · -1: 도넛 106 ~ 296.5 / 270.5 ~ 457.5, 요약 구분선 521.5 ~ 573)
    static let heroHeight: CGFloat = 609.5       // 컨테이너 아래 끝
    static let heroCornerRadius: CGFloat = 26
    static let headlineY: CGFloat = 154.3        // 타이틀 첫 줄 글자 y0 158.5 (측정 보정)
    static let headlineLineSpacing: CGFloat = 4 // 피그마 상단 문구의 두 줄 사이 간격
    static let donutDiameter: CGFloat = 189.2    // 바깥 반지름 94.6
    static let donutLineWidth: CGFloat = 34.2
    static let donutY: CGFloat = 269.2
    static let donutCenterX: CGFloat = 201.2     // (106 + 296.5) / 2
    /// 주의 소리 호가 시작하는 각도: 12시 방향 0°에서 시계 방향 (Hi-Fi 공기 과도: 첫 조각 둥근 끝이 12시 선에 닿음)
    static let donutStartDegrees: Double = 0
    static let donutTextSpacing: CGFloat = 5.3
    static let donutLabelSize: CGFloat = 20.5    // "주의소리" 글자 높이 18
    static let donutLabelDY: CGFloat = -1
    static let summaryX: CGFloat = 18
    static let summaryY: CGFloat = 521.7         // 구분선 y 521.5 ~ 573
    static let summaryHeight: CGFloat = 50
    static let summaryColumnWidth: CGFloat = 122
    static let summaryTextSpacing: CGFloat = 4

    // 섹션 제목 (글자 y0 658)
    static let sectionTitleX: CGFloat = 20
    static let sectionTitleY: CGFloat = 655

    // 눈금: 막대 폭에 대한 비율 (8 · 12 · 16 · 20)
    static let tickFractions: [CGFloat] = [0.182, 0.394, 0.608, 0.820]

    // 소리 유형별 막대 표. 탭 바가 빠져 예전(Hi-Fi 255)보다 78pt 위 (첫 막대 812 → 734)
    static let overviewHeaderY: CGFloat = 709    // 머리 글자 y0 710
    static let overviewFirstRowY: CGFloat = 734  // 첫 막대 위
    static let overviewRowPitch: CGFloat = 34.7
    static let overviewBarHeight: CGFloat = 22.5
    static let overviewLabelX: CGFloat = 20
    static let overviewTrackX: CGFloat = 77
    static let overviewTrackWidth: CGFloat = 214
    static let overviewRatioX: CGFloat = 307.4
    static let overviewTimeRight: CGFloat = 382  // 시간 열 오른쪽 끝 ("시간" · "6초" · "10초" 끝 381.5 ~ 382)
    static let overviewTimeWidth: CGFloat = 40
    static let overviewAxisY: CGFloat = 866      // 눈금 글자 y0 868.5

    // 연습 가이드 (섹션 맨 위 = 제목 글자 상자 위 기준, 제목 글자 y0 929)
    static let guideY: CGFloat = 1003.7 - 78
    static let guidePitcherX: CGFloat = 112.7             // 비커 그림 왼쪽 (Hi-Fi 260: 비커 바닥 왼쪽 114 − 에셋 여백 1.3). 2026-11-13 시안부터 노즐 없음 (에셋 캔버스 크기는 그대로)
    static let guidePitcherTop: CGFloat = 1045.8 - 1003.7 // 제목 ↔ 비커 그림(캔버스) 위 (Hi-Fi 260: 노즐 위 1046)
    static let guidePitcherSize = CGSize(width: 869.0 / 3, height: 651.0 / 3)
    static let guideCardTop: CGFloat = 1289.3 - 1003.7
    static let guideCardWidth: CGFloat = 362.6
    static let guideCardHeight: CGFloat = 87.7
    static let guideCardRadius: CGFloat = 10
    static let guideTextTop: CGFloat = 15.6           // 카드 위 ↔ 제목 글자 상자 (Hi-Fi: 글자 윗선 16.8)
    static let guideTitleToMessage: CGFloat = 7.4     // Hi-Fi: 설명 글자 윗선 43.1
    static let guideMessageLineSpacing: CGFloat = 1.8 // Hi-Fi: 설명 줄 높이 16.1
}
