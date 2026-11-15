import SwiftUI

//
//  PracticeReport.swift
//
//  연습 직후 결과(PracticeResultView)와 기록 상세(HistoryDetailView)가 함께 쓰는 리포트 화면입니다.
//  - 상단 히어로: 결과에 따른 타이틀 + 주의 소리 링 + 3열 요약
//  - "스티밍 기록": 소리 유형별 막대 표 (탭 없음)
//  - "연습 가이드": 비커 그림 + 공기 주입 시간에 따른 안내 카드 (`PracticeGuide`)
//  - 하단 안내 문구
//  Hi-Fi: iPhone 17 - 304 (연습 직후, 상단 바 "스티밍 결과") · 307 (기록 상세, 상단 바 "9월 28일 - 1차") (2026-11-14)
//         연습가이드 공기 과도 · 부족 (2026-11-13, 링을 뺀 나머지)
//
//  [구성] (이 파일은 화면 · 페이지 · 안내 문구, 나머지는 따로)
//  - ReportHero.swift         : 상단 히어로 (타이틀 + 링 + 3열 요약)
//  - ReportOverviewChart.swift: "스티밍 기록" 소리 유형별 막대 표 (+ 막대 · 눈금)
//  - ReportGuideSection.swift : "연습 가이드" 비커 그림 + 안내 카드
//  - ReportLayout.swift       : 리포트 색 · 시안 좌표
//

// MARK: - 화면 (스크롤 + 고정 상단 바 + 삭제 팝업)

struct PracticeReportScreen: View {
    @Environment(\.designScale) private var scale
    let result: PracticeResult
    /// 히어로 타이틀 (결과에 따라 화면마다 정한다)
    let headline: String
    /// 상단 바 제목 (연습 직후 "스티밍 결과", 기록 상세는 기록 이름 "9월 28일 - 1차")
    let barTitle: String
    var onBack: (() -> Void)? = nil
    /// 삭제 팝업에서 "기록 삭제"를 확인했을 때
    var onDelete: (() -> Void)? = nil
    @State private var showsDeleteDialog: Bool

    init(
        result: PracticeResult,
        headline: String,
        barTitle: String,
        onBack: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil,
        showsDeleteDialog: Bool = false
    ) {
        self.result = result
        self.headline = headline
        self.barTitle = barTitle
        self.onBack = onBack
        self.onDelete = onDelete
        _showsDeleteDialog = State(initialValue: showsDeleteDialog)
    }

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                PracticeReportPage(result: result, headline: headline)
            }
            .scrollIndicators(.hidden)
            .ignoresSafeArea()

            // 고정 상단 바: 스크롤한 내용이 비쳐 제목과 겹치지 않도록 뒤에 배경을 깔고 아래쪽은 살짝 흐리게 이어 준다.
            // (맨 위에서는 히어로 위쪽 색과 같아 눈에 보이지 않는다)
            VStack(spacing: 0) {
                TopNavigationHeader(
                    title: barTitle, isDark: true, onBack: onBack,
                    trailingSystemImage: "trash", onTrailingIcon: { showsDeleteDialog = true }
                )
                .padding(.top, ScreenMetrics.topBarTop.v(scale))
                .padding(.bottom, ReportLayout.topBarBottomPadding.v(scale))
                .background(AppColors.darkBackground)

                LinearGradient(colors: [AppColors.darkBackground, AppColors.darkBackground.opacity(0)], startPoint: .top, endPoint: .bottom)
                    .frame(height: ReportLayout.topBarFade.v(scale))
                    .allowsHitTesting(false)
            }
        }
        .ignoresSafeArea()
        .darkScreenBackground()
        .chicAlert(
            isPresented: showsDeleteDialog,
            title: String(localized: "정말 기록을 삭제하시겠어요?"),
            message: String(localized: "삭제한 기록은 다시 복구할 수 없어요"),
            cancelTitle: String(localized: "취소"),
            confirmTitle: String(localized: "기록 삭제"),
            confirmColor: AppColors.alertRed,
            onCancel: { showsDeleteDialog = false },
            onConfirm: { showsDeleteDialog = false; onDelete?() }
        )
        .toolbar(.hidden, for: .navigationBar)
        .swipeBackDisabled(showsDeleteDialog)
    }
}

// MARK: - 페이지 본문 (스크롤 안쪽 · 긴 화면 캡처 공용)

/// 화면 맨 위(상태바 포함)부터 안내 문구 아래까지의 긴 페이지. 모든 위치는 iPhone 17 시안 좌표(pt)입니다.
struct PracticeReportPage: View {
    @Environment(\.designScale) private var scale
    let result: PracticeResult
    let headline: String

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                ReportHero(result: result, headline: headline)

                Text(String(localized: "스티밍 기록"))
                    .font(.pretendard(.bold, size: 20))
                    .foregroundStyle(Color.white)
                    .at(x: ReportLayout.sectionTitleX, y: ReportLayout.sectionTitleY, scale)

                ReportOverviewChart(result: result)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .frame(height: ReportLayout.guideY.v(scale), alignment: .topLeading)

            ReportGuideSection(guide: PracticeGuide(result: result),
                               aerationSeconds: result.guideDuration(of: .normalAeration))

            ReportFootnote()
                .padding(.top, CGFloat(36).v(scale))
                .padding(.bottom, CGFloat(32).v(scale))
        }
    }
}

// MARK: - 위치 지정 도우미

extension View {
    /// 시안 좌표(왼쪽 위 기준, iPhone 17 pt)에 놓습니다. 가로는 폭 비율, 세로는 높이 비율로 변환합니다.
    func at(x: CGFloat, y: CGFloat, _ scale: DesignScale) -> some View {
        self.offset(x: x.h(scale), y: y.v(scale))
    }
}

// MARK: - 안내 문구

private struct ReportFootnote: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "info.circle")
                .font(.system(size: 11, weight: .regular))
            Text(String(localized: "소리 분석에 따른 참고용 안내이며, 실제 공기량을 측정한 결과는 아니에요."))
                .font(.pretendard(.regular, size: 11))
        }
        .foregroundStyle(PracticeResultColors.footnote)
        .frame(maxWidth: .infinity)
    }
}
