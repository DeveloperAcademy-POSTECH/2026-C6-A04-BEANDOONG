import SwiftUI

/// 히스토리 화면
/// - 디자인: Hi-Fi/iPhone 17 - 69.png
///
///     ┌ 상단 네비게이션 바: 히스토리
///     ├ 타이틀 + 설명
///     ├ 기간 필터 칩: [오늘] 일주일 이번 달 올해 전체
///     └ 연습 기록 카드 x 4
struct HistoryView: View {
    private let filters = ["오늘", "일주일", "이번 달", "올해", "전체"]
    private let selectedFilter = "오늘"
    private let records = Array(repeating: HistoryRecord.sample, count: 4)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: 상단 네비게이션 바
            TopNavigationHeader(title: "히스토리", isDark: true)
                .padding(.top, Layout.headerTop)

            VStack(alignment: .leading, spacing: 0) {
                // MARK: 타이틀 + 설명
                Text("나의 연습이 쌓이는 곳")
                    .font(.pretendard(.bold, size: 28))
                    .tracking(-0.3)
                    .foregroundStyle(Color.white)
                    .padding(.top, Layout.titleTop)

                Text("기록을 열어 소리의 변화를 비교해 보세요.")
                    .font(.pretendard(.regular, size: 16))
                    .foregroundStyle(AppColors.darkSubtitle)
                    .padding(.top, Layout.subtitleTop)

                // MARK: 기간 필터 칩 (y=246...279)
                HistoryFilterBar(filters: filters, selectedFilter: selectedFilter)
                    .padding(.top, Layout.filterTop)
                    .padding(.bottom, Layout.filterBottom)

                // MARK: 연습 기록 카드 목록
                VStack(spacing: Layout.cardSpacing) {
                    ForEach(records.indices, id: \.self) { index in
                        HistoryRecordCard(record: records[index])
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, Layout.horizontalPadding)
        }
        .background(AppColors.darkBackground.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }
}

// MARK: - 기간 필터 칩

/// 가로로 균등하게 나뉜 캡슐 칩 (높이 34, 간격 9). 선택된 칩만 하늘색 + Bold
private struct HistoryFilterBar: View {
    let filters: [String]
    let selectedFilter: String

    var body: some View {
        HStack(spacing: 9) {
            ForEach(filters, id: \.self) { filter in
                let isSelected = (filter == selectedFilter)
                Text(filter)
                    .font(.pretendard(isSelected ? .bold : .medium, size: 15))
                    .foregroundStyle(
                        isSelected
                            ? AppColors.darkChipTextSelected
                            : AppColors.darkChipTextUnselected
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 34)
                    .background(
                        Capsule()
                            .fill(
                                isSelected
                                    ? AppColors.darkChipSelected
                                    : AppColors.darkChipUnselected
                            )
                    )
            }
        }
    }
}

// MARK: - 연습 기록 카드

/// 카드에 표시할 연습 기록 (현재는 디자인용 고정 데이터)
private struct HistoryRecord {
    let badge: String
    let title: String
    let duration: String

    static let sample = HistoryRecord(badge: "보통", title: "9월 28일 - 1차", duration: "32초")
}

/// 연습 기록 한 줄 카드 (361 x 101)
///
///     ( 보통 )
///     9월 28일 - 1차                     >
///     32초
private struct HistoryRecordCard: View {
    let record: HistoryRecord

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                // 평가 배지
                Text(record.badge)
                    .font(.pretendard(.bold, size: 11))
                    .foregroundStyle(AppColors.darkChipTextSelected)
                    .frame(width: 48, height: 20)
                    .background(
                        Capsule()
                            .fill(AppColors.darkChipSelected)
                    )

                // 날짜 - 회차
                Text(record.title)
                    .font(.pretendard(.bold, size: 18))
                    .foregroundStyle(Color.white)
                    .padding(.top, 1)

                // 스티밍 시간
                Text(record.duration)
                    .font(.pretendard(.regular, size: 13))
                    .foregroundStyle(Color.white.opacity(0.85))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.9))
                .padding(.trailing, 2)
        }
        .padding(.horizontal, 16)
        .frame(width: 361, height: 101)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColors.darkCard)
        )
    }
}

// MARK: - Layout

private enum Layout {
    static let horizontalPadding: CGFloat = 20
    static let headerTop: CGFloat = 22     // 상태바 ↔ 네비게이션 바
    static let titleTop: CGFloat = 48      // 네비게이션 바 ↔ 타이틀
    static let subtitleTop: CGFloat = 11   // 타이틀 ↔ 설명
    static let filterTop: CGFloat = 31     // 설명 ↔ 필터 칩
    static let filterBottom: CGFloat = 20  // 필터 칩 ↔ 첫 카드
    static let cardSpacing: CGFloat = 14   // 카드 사이 간격
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView()
    }
}
