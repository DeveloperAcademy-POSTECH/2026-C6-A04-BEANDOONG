//
//  PracticeResultView.swift
//
//  연습이 끝난 뒤, 이번 연습에서 감지된 소리를 돌아보는 화면입니다.
//  `PracticeResult` 하나만 받아서 요약 · 전체 타임라인 · 상태별 감지 시간을 그립니다.
//
//  [사용 방법]
//      NavigationStack {
//          PracticeResultView(result: .sample)   // 실제 기록이 생기면 PracticeResult 만 바꿔 넘기면 됩니다.
//      }
//
//  - 화면만 그립니다. 화면 안에 상태(@State)가 없고, 받은 데이터를 그대로 보여주기만 합니다.
//  - 뒤로가기(<)는 공통 상단 바(TopNavigationHeader)가 `dismiss()` 로 처리하므로,
//    NavigationStack 으로 push 하거나 sheet 로 띄우면 별도 처리 없이 이전 화면으로 돌아갑니다.
//  - 시스템 네비게이션 바는 숨기고, 디자인과 같은 공통 상단 바를 직접 그립니다.
//
//  [파일 구성]
//  - PracticeResult.swift       : 화면에 넘기는 데이터 + 더미 데이터
//  - PracticeResultView.swift   : 화면 전체 · 요약 카드 · 카드 공통 스타일 · 색상 (이 파일)
//  - PracticeTimelineCard.swift : 전체 타임라인 카드
//  - DetectedDurationCard.swift : 상태별 감지 시간 카드
//

import SwiftUI

/// 연습 결과 화면 (다크 테마)
/// - 디자인: hifi/practice-result.png
///
///     ┌ 상단 네비게이션 바: "9월 26일 1차"          ← 고정
///     ├ 타이틀 "이번 연습 결과를 살펴볼까요?"         ← 여기부터 스크롤
///     ├ 요약 카드: 전체 시간 · 정상소리 · 주의 소리
///     ├ 스티밍 기록: 전체 타임라인 카드 + 상태별 감지 시간 카드
///     ├ 연습 가이드 카드 (내용은 디자인 확정 후 추가)
///     └ 하단 안내 문구
struct PracticeResultView: View {
    let result: PracticeResult

    var body: some View {
        VStack(spacing: 0) {
            // MARK: 상단 네비게이션 바 (스크롤해도 고정)
            TopNavigationHeader(title: result.title, isDark: true)
                .padding(.top, Metrics.headerTop)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // MARK: 타이틀
                    titleText
                        .padding(.top, Metrics.titleTop)

                    // MARK: 요약
                    PracticeSummaryCard(result: result)
                        .padding(.top, Metrics.summaryTop)

                    // MARK: 스티밍 기록
                    sectionTitle("스티밍 기록")
                        .padding(.top, Metrics.sectionTitleTop)

                    PracticeTimelineCard(result: result)
                        .padding(.top, Metrics.sectionContentTop)

                    DetectedDurationCard(result: result)
                        .padding(.top, Metrics.cardSpacing)

                    // MARK: 연습 가이드
                    sectionTitle("연습 가이드")
                        .padding(.top, Metrics.sectionTitleTop)

                    // TODO: 연습 가이드 내용이 디자인에 확정되면 카드 안을 채웁니다.
                    //       지금은 디자인처럼 빈 카드만 자리를 잡아 둡니다.
                    RoundedRectangle(cornerRadius: Metrics.cardCornerRadius)
                        .fill(PracticeResultColors.cardBackground)
                        .frame(height: Metrics.guideCardHeight)
                        .padding(.top, Metrics.sectionContentTop)
                        .accessibilityHidden(true)

                    // MARK: 하단 안내 문구
                    Text("소리 분석에 따른 참고용 안내이며, 실제 공기량을 측정한 결과는 아니에요.")
                        .font(.pretendard(.regular, size: 12))
                        .foregroundStyle(PracticeResultColors.footnote)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .padding(.top, Metrics.footnoteTop)
                        .padding(.bottom, Metrics.footnoteBottom)
                }
                .padding(.horizontal, Metrics.horizontalPadding)
            }
            .scrollIndicators(.hidden)
        }
        .darkScreenBackground()
        .toolbar(.hidden, for: .navigationBar)
    }

    /// "이번 연습 결과를 살펴볼까요?" — "연습 결과"만 강조색으로 칠합니다.
    private var titleText: some View {
        Text("이번 \(Text("연습 결과").foregroundStyle(PracticeResultColors.titleAccent))를\n살펴볼까요?")
            .font(.pretendard(.bold, size: 26))
            .lineSpacing(Metrics.titleLineSpacing)
            .foregroundStyle(PracticeResultColors.primaryText)
            .accessibilityAddTraits(.isHeader)
    }

    /// "스티밍 기록" · "연습 가이드" 같은 섹션 제목
    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.pretendard(.bold, size: 20))
            .foregroundStyle(PracticeResultColors.primaryText)
            .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - 요약 카드

/// 전체 시간 · 정상소리 · 주의 소리를 세 칸으로 나눠 보여주는 카드
/// - 세 숫자는 모두 `PracticeResult` 에서 계산된 값이라, 항상 "정상 + 주의 = 전체"가 맞습니다.
///
///     ┌──────────────────────────────────┐
///     │  전체 시간     정상소리     주의 소리  │
///     │    24초        16초        8초     │
///     └──────────────────────────────────┘
private struct PracticeSummaryCard: View {
    let result: PracticeResult

    var body: some View {
        HStack(spacing: 0) {
            summaryItem("전체 시간", seconds: result.totalSeconds, color: PracticeResultColors.primaryText)
            summaryItem("정상소리", seconds: result.normalSeconds, color: PracticeResultColors.normalSound)
            summaryItem("주의 소리", seconds: result.cautionSeconds, color: PracticeResultColors.cautionSound)
        }
        .frame(height: Metrics.summaryCardHeight)
        .background(
            RoundedRectangle(cornerRadius: Metrics.cardCornerRadius)
                .fill(PracticeResultColors.cardBackground)
        )
    }

    /// 요약 한 칸 (제목 + 큰 숫자). 세 칸이 같은 폭을 나눠 가집니다.
    private func summaryItem(_ title: String, seconds: Int, color: Color) -> some View {
        VStack(spacing: Metrics.summaryTextSpacing) {
            Text(title)
                .font(.pretendard(.regular, size: 13))
                .foregroundStyle(PracticeResultColors.secondaryText)
            Text(seconds.practiceSecondsText)
                .font(.pretendard(.bold, size: 26))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        // VoiceOver 에서 "전체 시간, 24초" 처럼 한 번에 읽히게 묶습니다.
        .accessibilityElement(children: .combine)
    }
}

// MARK: - 카드 공통

/// 타임라인 · 상태별 감지 시간 카드 맨 위의 제목 + 설명
///
///     전체 타임라인                          ← 제목
///     시간에 따른 스티밍 단계와 ... 확인해요     ← 설명
struct PracticeResultCardHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.cardSubtitleTop) {
            Text(title)
                .font(.pretendard(.bold, size: 17))
                .foregroundStyle(PracticeResultColors.primaryText)
                .accessibilityAddTraits(.isHeader)
            Text(subtitle)
                .font(.pretendard(.regular, size: 12))
                .foregroundStyle(PracticeResultColors.secondaryText)
        }
    }
}

extension View {
    /// 연습 결과 화면 카드의 공통 여백 · 배경을 입힙니다.
    /// - 타임라인 카드와 상태별 감지 시간 카드가 같은 모양을 유지하도록 한곳에 모았습니다.
    func practiceResultCard() -> some View {
        self
            .padding(.horizontal, Metrics.cardHorizontalPadding)
            .padding(.top, Metrics.cardTopPadding)
            .padding(.bottom, Metrics.cardBottomPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Metrics.cardCornerRadius)
                    .fill(PracticeResultColors.cardBackground)
            )
    }
}

// MARK: - 색상

/// 연습 결과 화면에서만 쓰는 색상 (Hi-Fi 원본 픽셀에서 추출)
/// - 다른 다크 화면의 공통 색(AppColors.darkCard 등)과 미세하게 달라서 이 화면 전용으로 둡니다.
/// - 소리별 색상은 `DetectedSound` 에 있습니다.
enum PracticeResultColors {
    /// 카드 배경
    static let cardBackground = Color(hex: 0x171E2E)
    /// 카드 안쪽 배경 (타임라인 막대 바탕 · 소리 타일)
    static let innerBackground = Color(hex: 0x202228)
    /// 제목 · 큰 숫자
    static let primaryText = Color(hex: 0xDBECFF)
    /// 설명 · 작은 라벨 · 눈금 숫자
    static let secondaryText = Color(hex: 0x919296)
    /// 타이틀의 "연습 결과" 강조
    static let titleAccent = Color(hex: 0xA6DDF7)
    /// 요약 카드 "정상소리" 숫자
    static let normalSound = Color(hex: 0x76CAF2)
    /// 요약 카드 "주의 소리" 숫자
    static let cautionSound = Color(hex: 0xF2627C)
    /// 타임라인 눈금 선
    static let tickLine = Color(hex: 0x404551)
    /// 하단 안내 문구
    static let footnote = Color(hex: 0xC0C1C3)
}

// MARK: - Metrics

/// Hi-Fi(402pt 폭) 기준 수치입니다.
private enum Metrics {
    static let horizontalPadding: CGFloat = 20
    static let headerTop: CGFloat = 22          // 상태바 ↔ 네비게이션 바
    static let titleTop: CGFloat = 48           // 네비게이션 바 ↔ 타이틀
    static let titleLineSpacing: CGFloat = 4    // 타이틀 두 줄 사이
    static let summaryTop: CGFloat = 30         // 타이틀 ↔ 요약 카드
    static let summaryCardHeight: CGFloat = 80
    static let summaryTextSpacing: CGFloat = 8  // "전체 시간" ↔ "24초"
    static let sectionTitleTop: CGFloat = 40    // 위 카드 ↔ 섹션 제목
    static let sectionContentTop: CGFloat = 16  // 섹션 제목 ↔ 카드
    static let cardSpacing: CGFloat = 16        // 타임라인 카드 ↔ 상태별 감지 시간 카드
    static let guideCardHeight: CGFloat = 88
    static let footnoteTop: CGFloat = 148       // 연습 가이드 카드 ↔ 하단 안내 문구
    static let footnoteBottom: CGFloat = 24     // 하단 안내 문구 ↔ 스크롤 끝

    static let cardCornerRadius: CGFloat = 16
    static let cardHorizontalPadding: CGFloat = 16
    static let cardTopPadding: CGFloat = 16
    static let cardBottomPadding: CGFloat = 18
    static let cardSubtitleTop: CGFloat = 6     // 카드 제목 ↔ 설명
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
