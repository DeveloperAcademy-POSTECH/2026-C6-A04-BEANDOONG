import SwiftUI

/// 히스토리 화면
/// - 디자인: Hi-Fi/iPhone 17 - 69.png (목록) · 254.png (삭제 팝업)
///
///     ┌ 상단 네비게이션 바: 히스토리
///     ├ 타이틀 + 설명
///     ├ 기간 필터 칩: [오늘] 일주일 이번 달 올해 전체
///     └ 연습 기록 카드 목록 (터치 시 HistoryDetailView 로 이동, 왼쪽으로 밀면 삭제)
struct HistoryView: View {
    @EnvironmentObject private var practice: PracticeSession
    @Environment(\.designScale) private var scale
    let onStartPractice: () -> Void
    @State private var selectedFilter: HistoryFilter = .today
    /// 삭제 팝업을 보여 주는 중인지 (팝업이 떠 있는 동안 카드 오른쪽은 링 대신 휴지통, Hi-Fi 254)
    @State private var showsDeleteDialog: Bool
    /// 스와이프로 삭제를 누른 기록 (팝업에서 확인하면 지움)
    @State private var deleteTarget: HistoryRecord?
    /// 상세로 들어가는 기록
    @State private var selectedRecord: HistoryRecord?
    /// 시안 캡처용: 저장소 대신 이 결과들을 기간 필터 없이 보여 줌 (nil이면 실제 기록)
    private let sampleResults: [PracticeResult]?

    init(onStartPractice: @escaping () -> Void, sampleResults: [PracticeResult]? = nil, showsDeleteDialog: Bool = false) {
        self.onStartPractice = onStartPractice
        self.sampleResults = sampleResults
        _showsDeleteDialog = State(initialValue: showsDeleteDialog)
    }

    private var records: [HistoryRecord] {
        if let sampleResults {
            // 캡처용 샘플은 순번으로 고정 id를 만들어 다시 그려도 같은 카드로 취급합니다.
            return sampleResults.enumerated().map { index, result in
                HistoryRecord(result: result, id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", index)) ?? UUID())
            }
        }
        return practice.history.map { HistoryRecord(entity: $0) }
    }

    private var filteredRecords: [HistoryRecord] {
        if sampleResults != nil { return records }
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
        if sampleResults == nil, practice.history.isEmpty {
            EmptyHistoryView(onStartPractice: onStartPractice)
        } else {
            historyContent
        }
    }

    /// 카드 높이가 고정이라 카드 사이 간격(14)도 모든 기기에서 고정한다 (위·아래 행 여백으로 반씩 나눔).
    /// 비율로 바꾸면 큰 기기에서는 간격이 벌어지고 SE에서는 카드가 붙는다.
    private var rowInset: CGFloat { Layout.cardSpacing / 2 }

    private func delete(_ record: HistoryRecord) {
        guard sampleResults == nil else { return } // 캡처용 샘플은 지우지 않음
        practice.deleteRecord(id: record.id)
    }

    private var historyContent: some View {
        // 기간 필터 결과는 한 번만 계산해 빈 목록 안내와 카드 목록이 함께 써요. (기록마다 결과를 다시 만드는 일이라 두 번 하지 않게)
        let visibleRecords = filteredRecords
        return VStack(alignment: .leading, spacing: 0) {
            // MARK: 상단 네비게이션 바
            TopNavigationHeader(title: "히스토리", isDark: true)
                .padding(.top, Layout.headerTop.v(scale))

            VStack(alignment: .leading, spacing: 0) {
                // MARK: 타이틀 + 설명
                Text("나의 연습이 쌓이는 곳")
                    .font(.pretendard(.bold, size: 26))
                    .tracking(-0.3)
                    .foregroundStyle(Color.white)
                    .padding(.top, Layout.titleTop.v(scale))

                Text("기록을 열어 소리의 변화를 비교해 보세요.")
                    .font(.pretendard(.regular, size: 16))
                    .foregroundStyle(AppColors.darkSubtitle)
                    .padding(.top, Layout.subtitleTop.v(scale))

                // MARK: 기간 필터 칩 (y=246...279)
                HistoryFilterBar(selectedFilter: $selectedFilter)
                    .padding(.top, Layout.filterTop.v(scale))
                    .padding(.bottom, Layout.filterBottom.v(scale) - rowInset)

                // MARK: 연습 기록 카드 목록 (SwiftUI 기본 리스트: 왼쪽으로 밀면 삭제)
                List {
                    if visibleRecords.isEmpty {
                        Text("선택한 기간에 연습 기록이 없어요.")
                            .font(.pretendard(.regular, size: 15))
                            .foregroundStyle(AppColors.darkSubtitle)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                    ForEach(visibleRecords) { record in
                        Button {
                            selectedRecord = record
                        } label: {
                            HistoryRecordCard(record: record, width: Layout.cardWidth.h(scale), showsTrash: showsDeleteDialog)
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets(top: rowInset, leading: 0, bottom: rowInset, trailing: 0))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                deleteTarget = record
                                showsDeleteDialog = true
                            } label: {
                                Label("삭제", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .scrollIndicators(.hidden)
                .navigationDestination(item: $selectedRecord) { record in
                    HistoryDetailView(result: record.result, onDelete: { delete(record) })
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, Layout.horizontalPadding.h(scale))
        }
        .ignoresSafeArea()
        .background(AppColors.darkBackground.ignoresSafeArea())
        .swipeBackDisabled(showsDeleteDialog)
        .chicAlert(
            isPresented: showsDeleteDialog,
            title: "정말 방을 삭제하시겠어요?",
            message: "삭제한 방은 다시 복구할 수 없어요",
            cancelTitle: "취소",
            confirmTitle: "방 삭제",
            confirmColor: AppColors.alertRed,
            onCancel: { showsDeleteDialog = false; deleteTarget = nil },
            onConfirm: {
                if let deleteTarget { delete(deleteTarget) }
                showsDeleteDialog = false
                deleteTarget = nil
            }
        )
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
private struct HistoryRecord: Identifiable, Hashable {
    let id: UUID
    let date: Date
    let dailyOrder: Int
    let durationSeconds: Int
    let result: PracticeResult
    let badge = "보통"

    init(entity: PracticeRecordEntity) {
        self.init(result: entity.result, id: entity.id)
    }

    init(result: PracticeResult, id: UUID = UUID()) {
        self.id = id
        date = result.practicedAt
        dailyOrder = result.dailyOrder
        self.result = result
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

/// 연습 기록 한 줄 카드 (365 x 100)
///
///     ( 보통 )
///     9월 28일 - 1차              ◔   >
///     32초
/// 오른쪽 링은 그 연습의 "주의 소리" 비율이고, 삭제 팝업이 떠 있는 동안에는 휴지통으로 바뀐다. (Hi-Fi 69 · 254)
private struct HistoryRecordCard: View {
    let record: HistoryRecord
    var width: CGFloat = 365
    var showsTrash = false

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                // 평가 배지
                Text(record.badge)
                    .font(.pretendard(.bold, size: 11))
                    .foregroundStyle(AppColors.darkChipTextSelected)
                    .frame(width: 47.5, height: 19)
                    .background(Capsule().fill(AppColors.darkChipSelected))

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

            if showsTrash {
                Image(systemName: "trash")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(AppColors.historyTrash)
                    .frame(width: Layout.ringSize, height: Layout.ringSize)
                    .padding(.trailing, Layout.ringToChevron)
            } else {
                ArcRing(ratio: record.result.cautionRatio, lineWidth: Layout.ringLineWidth, color: AppColors.soundCaution)
                    .frame(width: Layout.ringSize, height: Layout.ringSize)
                    .padding(.trailing, Layout.ringToChevron)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.white)
                .padding(.trailing, 2)
        }
        .padding(.leading, 12)
        .padding(.trailing, 17)
        .frame(width: width, height: Layout.cardHeight)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColors.darkCard)
        )
    }
}

// MARK: - Layout

private enum Layout {
    static let horizontalPadding: CGFloat = 19  // Hi-Fi 69: 카드·칩 x 19 ~ 384
    static let headerTop: CGFloat = 84     // 화면 위 ↔ 네비게이션 바 (Hi-Fi 69: 글자 y0 86 − 2)
    static let titleTop: CGFloat = 46.3    // 네비게이션 바 아래(104) ↔ 타이틀 (Hi-Fi 69: 154, 측정 보정)
    static let subtitleTop: CGFloat = 8.7  // 타이틀 ↔ 설명
    static let filterTop: CGFloat = 36     // 설명 ↔ 필터 칩 (Hi-Fi 69: 209 → 246)
    static let filterBottom: CGFloat = 12.3 // 필터 칩 ↔ 첫 카드 (Hi-Fi 69: 281 → 300, 측정 보정). 코드에서는 리스트 행 위 여백만큼 뺀다
    static let cardSpacing: CGFloat = 14   // 카드 사이 간격 (Hi-Fi 69: 100 + 14, 리스트 행 위·아래 여백 7씩)
    static let cardWidth: CGFloat = 365    // Hi-Fi 69: 카드 폭
    static let cardHeight: CGFloat = 100   // Hi-Fi 69: 카드 높이
    static let ringSize: CGFloat = 58.6    // Hi-Fi 69: 도넛 지름
    static let ringLineWidth: CGFloat = 10 // Hi-Fi 69: 도넛 두께
    static let ringToChevron: CGFloat = 8  // 링 오른쪽 ↔ 화살표
}

// MARK: - 이 화면 전용 색상

private extension AppColors {
    /// 삭제 팝업이 떠 있을 때 카드 오른쪽 휴지통 (Hi-Fi 254, 딤 처리된 상태)
    static let historyTrash = Color(hex: 0xAEAEAE)
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            let connection = WatchConnection()
            HistoryView(onStartPractice: {})
                .environmentObject(PracticeSession(connection: connection))
        }
    }
}
