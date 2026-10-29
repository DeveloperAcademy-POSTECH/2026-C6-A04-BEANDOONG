import SwiftUI

/// 히스토리 화면
/// - 디자인: Hi-Fi/iPhone 17 - 69.png
///
///     ┌ 상단 네비게이션 바: 히스토리
///     ├ 타이틀 + 설명
///     ├ 기간 필터 칩: [오늘] 일주일 이번 달 올해 전체
///     └ 연습 기록 카드 목록
struct HistoryView: View {
    @State private var selectedFilter: HistoryFilter = .today

    // MARK: - 임시 목 데이터
    // TODO: 엔티티 설계 후 아래 records 생성 코드를 삭제하고 실제 연습 기록으로 교체합니다.
    // 실행 날짜 기준으로 오늘 / 최근 7일 / 이번 달 / 이전 달 / 작년 기록을 구성합니다.
    private let records: [HistoryRecord] = {
        let calendar = Calendar.current
        let now = Date()
        let recentDate = calendar.date(byAdding: .day, value: -3, to: now) ?? now
        let earlierThisMonth = calendar.date(byAdding: .day, value: -10, to: now) ?? now
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        let earlierThisYear = calendar.date(byAdding: .month, value: -3, to: now) ?? now
        let lastYear = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        let earlierLastYear = calendar.date(byAdding: .month, value: -2, to: lastYear) ?? lastYear

        return [
            HistoryRecord(date: now, badge: "보통", duration: "32초"),
            HistoryRecord(date: recentDate, badge: "좋음", duration: "28초"),
            HistoryRecord(date: earlierThisMonth, badge: "보통", duration: "35초"),
            HistoryRecord(date: lastMonth, badge: "좋음", duration: "30초"),
            HistoryRecord(date: earlierThisYear, badge: "보통", duration: "38초"),
            HistoryRecord(date: lastYear, badge: "좋음", duration: "33초"),
            HistoryRecord(date: earlierLastYear, badge: "보통", duration: "40초")
        ]
    }()

    private var filteredRecords: [HistoryRecord] {
        let calendar = Calendar.current
        let now = Date()

        return records.filter { record in
            switch selectedFilter {
            case .today:
                return calendar.isDate(record.date, inSameDayAs: now)
            case .week:
                let start = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: now)) ?? now
                return record.date >= start && record.date <= now
            case .month:
                return calendar.isDate(record.date, equalTo: now, toGranularity: .month)
            case .year:
                return calendar.isDate(record.date, equalTo: now, toGranularity: .year)
            case .all:
                return true
            }
        }
    }

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
                HistoryFilterBar(selectedFilter: $selectedFilter)
                    .padding(.top, Layout.filterTop)
                    .padding(.bottom, Layout.filterBottom)

                // MARK: 연습 기록 카드 목록
                ScrollView {
                    VStack(spacing: Layout.cardSpacing) {
                        ForEach(filteredRecords.indices, id: \.self) { index in
                            HistoryRecordCard(record: filteredRecords[index])
                        }
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

private enum HistoryFilter: String, CaseIterable {
    case today = "오늘"
    case week = "일주일"
    case month = "이번 달"
    case year = "올해"
    case all = "전체"
}

/// 가로로 균등하게 나뉜 캡슐 칩 (높이 34, 간격 9). 선택된 칩만 하늘색 + Bold
private struct HistoryFilterBar: View {
    @Binding var selectedFilter: HistoryFilter

    var body: some View {
        HStack(spacing: 9) {
            ForEach(HistoryFilter.allCases, id: \.self) { filter in
                let isSelected = (filter == selectedFilter)
                Button {
                    selectedFilter = filter
                } label: {
                    Text(filter.rawValue)
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
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }
}

// MARK: - 연습 기록 카드

/// 카드에 표시할 임시 연습 기록
// TODO: 엔티티 설계 후 이 임시 타입을 실제 모델로 교체합니다.
private struct HistoryRecord {
    let date: Date
    let badge: String
    let duration: String

    var title: String {
        let calendar = Calendar.current
        let isThisYear = calendar.isDate(date, equalTo: Date(), toGranularity: .year)
        let yearPrefix = isThisYear ? "" : "\(calendar.component(.year, from: date))년 "
        return "\(yearPrefix)\(calendar.component(.month, from: date))월 \(calendar.component(.day, from: date))일 - 1차"
    }
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
