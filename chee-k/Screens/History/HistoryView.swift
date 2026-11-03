import SwiftUI

/// 히스토리 화면
/// - 디자인: Hi-Fi/iPhone 17 - 69.png
///
///     ┌ 상단 네비게이션 바: 히스토리
///     ├ 타이틀 + 설명
///     ├ 기간 필터 칩: [오늘] 일주일 이번 달 올해 전체
///     └ 연습 기록 카드 목록 (터치 시 HistoryDetailView 로 이동)
struct HistoryView: View {
    @EnvironmentObject private var practice: PracticeSession
    @State private var selectedFilter: HistoryFilter = .today

    private var records: [HistoryRecord] {
        practice.history.map { HistoryRecord(entity: $0) }
    }

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
                    .font(.pretendard(.bold, size: 26))
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
                        if filteredRecords.isEmpty {
                            Text("선택한 기간에 연습 기록이 없어요.")
                                .font(.pretendard(.regular, size: 15))
                                .foregroundStyle(AppColors.darkSubtitle)
                                .padding(.top, 40)
                        }
                        ForEach(filteredRecords) { record in
                            NavigationLink {
                                HistoryDetailView(result: record.result)
                            } label: {
                                HistoryRecordCard(record: record)
                            }
                            .buttonStyle(.plain)
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

/// 기존 카드 레이아웃에 저장된 기록을 전달합니다.
private struct HistoryRecord: Identifiable {
    let id: UUID
    let date: Date
    let dailyOrder: Int
    let durationSeconds: Int
    let result: PracticeResult
    let badge = "저장됨"

    init(entity: PracticeRecordEntity) {
        id = entity.id
        date = entity.startedAt
        dailyOrder = entity.dailyOrder
        result = entity.result
        durationSeconds = result.totalSeconds
    }

    var duration: String {
        durationSeconds.practiceSecondsText
    }

    var title: String {
        let calendar = Calendar.current
        let isThisYear = calendar.isDate(date, equalTo: Date(), toGranularity: .year)
        let yearPrefix = isThisYear ? "" : "\(calendar.component(.year, from: date))년 "
        return "\(yearPrefix)\(calendar.component(.month, from: date))월 \(calendar.component(.day, from: date))일 - \(dailyOrder)차"
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
    static let subtitleTop: CGFloat = 8    // 타이틀 ↔ 설명
    static let filterTop: CGFloat = 36     // 설명 ↔ 필터 칩
    static let filterBottom: CGFloat = 20  // 필터 칩 ↔ 첫 카드
    static let cardSpacing: CGFloat = 14   // 카드 사이 간격
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            let connection = WatchConnection()
            HistoryView()
                .environmentObject(PracticeSession(connection: connection))
        }
    }
}
