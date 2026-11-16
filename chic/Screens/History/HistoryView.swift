import SwiftUI

/// 히스토리 화면
/// - 디자인: Hi-Fi/iPhone 17 - 69.png (목록, 2026-11-14 시안: 기간 필터 · 카드 링 없음) · 254.png (삭제 팝업)
///
///     ┌ 상단 네비게이션 바: 히스토리
///     ├ 타이틀 + 설명
///     └ 연습 기록 카드 목록: 모든 기록을 최신순으로 (터치 시 HistoryDetailView 로 이동, 왼쪽으로 밀면 삭제)
struct HistoryView: View {
    @EnvironmentObject private var practice: PracticeSession
    @Environment(\.designScale) private var scale
    let onStartPractice: () -> Void
    /// 삭제 팝업을 보여 주는 중인지
    @State private var showsDeleteDialog: Bool
    /// 스와이프로 삭제를 누른 기록 (팝업에서 확인하면 지움)
    @State private var deleteTarget: HistoryRecord?
    /// 상세로 들어가는 기록
    @State private var selectedRecord: HistoryRecord?
    /// 왼쪽으로 밀어 삭제 버튼을 꺼내 둔 기록 (한 번에 하나만)
    @State private var openRecordID: UUID?
    /// 시안 캡처용: 저장소 대신 이 결과들을 보여 줌 (nil이면 실제 기록)
    private let sampleResults: [PracticeResult]?
    /// `sampleResults` 를 카드용 기록으로 바꾼 것. 샘플은 바뀌지 않아서 한 번만 만들어요.
    private let sampleRecords: [HistoryRecord]?
    /// 저장소 기록을 카드용 기록으로 바꾼 결과. 기록 id 목록이 바뀔 때만 다시 만들어요 (`records`)
    @State private var recordCache = HistoryRecordCache()

    init(onStartPractice: @escaping () -> Void, sampleResults: [PracticeResult]? = nil, showsDeleteDialog: Bool = false) {
        self.onStartPractice = onStartPractice
        self.sampleResults = sampleResults
        // 캡처용 샘플은 순번으로 고정 id를 만들어 다시 그려도 같은 카드로 취급합니다.
        sampleRecords = sampleResults?.enumerated().map { index, result in
            HistoryRecord(result: result, id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", index)) ?? UUID())
        }
        _showsDeleteDialog = State(initialValue: showsDeleteDialog)
    }

    private var records: [HistoryRecord] {
        if let sampleRecords { return sampleRecords }
        // 저장소 목록이 이미 시작 시각 최신순이에요 (`PracticeHistoryStore.records()`).
        return recordCache.records(for: practice.history)
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

    /// 결과 화면의 가이드 비커 그림 (`PracticeReport` 가 그리는 이름과 같아요)
    private static let resultPitcherImage = "IllustPracticeGuidePitcher"

    private func delete(_ record: HistoryRecord) {
        guard sampleResults == nil else { return } // 캡처용 샘플은 지우지 않음
        practice.deleteRecord(id: record.id)
    }

    private var historyContent: some View {
        // 기록마다 결과를 다시 만드는 일이라 한 번만 계산해요 (기록이 그대로면 이전 결과를 써요).
        let visibleRecords = records
        return VStack(alignment: .leading, spacing: 0) {
            // MARK: 상단 네비게이션 바
            TopNavigationHeader(title: String(localized: "히스토리"), isDark: true)
                .padding(.top, ScreenMetrics.topBarTop.v(scale))

            VStack(alignment: .leading, spacing: 0) {
                // MARK: 타이틀 + 설명
                Text(String(localized: "나의 기록이 쌓이는 곳"))
                    .font(.pretendard(.bold, size: 26))
                    .tracking(-0.3)
                    .foregroundStyle(Color.white)
                    .padding(.top, Layout.titleTop.v(scale))

                Text(String(localized: "기록을 열어 소리의 변화를 비교해 보세요."))
                    .font(.pretendard(.regular, size: 16))
                    .foregroundStyle(AppColors.darkSubtitle)
                    .padding(.top, Layout.subtitleTop.v(scale))
                    .padding(.bottom, Layout.listTop.v(scale) - rowInset)

                // MARK: 연습 기록 카드 목록 (SwiftUI 기본 리스트: 왼쪽으로 밀면 삭제)
                List {
                    ForEach(visibleRecords) { record in
                        // 시스템 `swipeActions`는 밀린 카드를 목록 끝에서 각지게 자르고, 밀린 거리를 SwiftUI에 정확히 알려 주지 않아
                        // 둥글게 오려 그릴 수 없다. 그래서 밀기·삭제 버튼을 직접 그린다 (`SwipeToDeleteRow`).
                        SwipeToDeleteRow(
                            isOpen: Binding(
                                get: { openRecordID == record.id },
                                set: { openRecordID = $0 ? record.id : (openRecordID == record.id ? nil : openRecordID) }
                            ),
                            width: Layout.cardWidth.h(scale),
                            revealWidth: Layout.deleteRevealWidth.h(scale),
                            cornerRadius: Layout.cardCornerRadius.h(scale),
                            cardColor: AppColors.darkCard,
                            onDelete: {
                                deleteTarget = record
                                showsDeleteDialog = true
                            }
                        ) {
                            Button {
                                // 다른 카드의 삭제 버튼이 열려 있으면 먼저 닫기만 한다
                                if openRecordID != nil {
                                    openRecordID = nil
                                } else {
                                    selectedRecord = record
                                }
                            } label: {
                                HistoryRecordCard(record: record, width: Layout.cardWidth.h(scale))
                            }
                            .buttonStyle(.plain)
                        }
                        .listRowInsets(EdgeInsets(top: rowInset, leading: 0, bottom: rowInset, trailing: 0))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
                .onScrollPhaseChange { _, phase in
                    // 목록을 위아래로 움직이면 열려 있던 삭제 버튼을 닫는다 (시스템 스와이프와 같은 동작)
                    if phase != .idle, openRecordID != nil, !showsDeleteDialog { openRecordID = nil }
                }
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
        .onAppear {
            // 기록을 누르면 밀려 들어오는 첫 프레임에 결과 화면 전체를 처음 그려요. 그때 비커 그림(869×651)을 디코딩하느라
            // 넘어가는 애니메이션이 멈칫하지 않게, 목록이 나타날 때 백그라운드에서 미리 디코딩해 둬요.
            PreparedImage.prepare([Self.resultPitcherImage])
        }
        .chicAlert(
            isPresented: showsDeleteDialog,
            title: String(localized: "정말 방을 삭제하시겠어요?"),
            message: String(localized: "삭제한 방은 다시 복구할 수 없어요"),
            cancelTitle: String(localized: "취소"),
            confirmTitle: String(localized: "방 삭제"),
            confirmColor: AppColors.alertRed,
            onCancel: { showsDeleteDialog = false; deleteTarget = nil; openRecordID = nil },
            onConfirm: {
                if let deleteTarget { delete(deleteTarget) }
                showsDeleteDialog = false
                deleteTarget = nil
                openRecordID = nil
            }
        )
        .preferredColorScheme(.dark)
    }
}

// MARK: - 연습 기록 카드

/// 기존 카드 레이아웃에 저장된 기록을 전달합니다.
private struct HistoryRecord: Identifiable, Hashable {
    let id: UUID
    let result: PracticeResult

    init(entity: PracticeRecordEntity) {
        self.init(result: entity.result, id: entity.id)
    }

    init(result: PracticeResult, id: UUID = UUID()) {
        self.id = id
        self.result = result
    }

    var duration: String {
        result.totalSeconds.practiceSecondsText
    }

    /// 올해가 아니면 연도도 표시합니다. 기록 상세 상단 바 제목과 같아요.
    var title: String { result.title }
}

/// 저장소 기록(`PracticeRecordEntity`)을 카드용 기록(`HistoryRecord`)으로 바꾼 결과를 기록 id 목록이 같은 동안 다시 써요.
///
/// 바꾸는 일은 기록마다 SwiftData 구간을 꺼내 정렬하고 제목(날짜 형식)을 만들어서 가볍지 않은데, 화면은 행을 밀거나 팝업을 열 때도
/// 다시 계산돼요. 저장된 기록은 id 가 같으면 내용도 같아서, id 목록이 그대로면 이전 결과를 그대로 돌려줘요.
/// 화면 상태가 아니라 계산을 기억해 두는 곳이라, 값을 바꿔도 화면을 다시 그리라고 알리지 않아요.
private final class HistoryRecordCache {
    private var ids: [UUID] = []
    private var records: [HistoryRecord] = []

    func records(for entities: [PracticeRecordEntity]) -> [HistoryRecord] {
        let currentIDs = entities.map(\.id)
        if currentIDs != ids {
            records = entities.map { HistoryRecord(entity: $0) }
            ids = currentIDs
        }
        return records
    }
}

/// 연습 기록 한 줄 카드 (365 x 100)
///
///     9월 28일 - 1차                  >
///     32초
/// (2026-11-14 시안부터 오른쪽 주의 소리 링 없음, Hi-Fi 69)
/// 카드 배경(둥근 사각형)은 감싸는 `SwipeToDeleteRow`가 그린다. 밀었을 때 남은 폭만큼만 그려야 해서다.
private struct HistoryRecordCard: View {
    let record: HistoryRecord
    var width: CGFloat = 365

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            // 날짜·시간 묶음은 카드 세로 가운데 (Hi-Fi 69: 글자 y 334.5 ~ 365.5, 카드 300 ~ 400)
            VStack(alignment: .leading, spacing: Layout.titleToDuration) {
                // 날짜 - 회차
                Text(record.title)
                    .font(.pretendard(.bold, size: Layout.titleFontSize))
                    .foregroundStyle(Color.white)

                // 스티밍 시간
                Text(record.duration)
                    .font(.pretendard(.regular, size: Layout.durationFontSize))
                    .foregroundStyle(Color.white.opacity(0.85))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.white)
                .padding(.trailing, 2)
        }
        .padding(.leading, 12)
        .padding(.trailing, Layout.cardTrailing)
        .frame(width: width, height: Layout.cardHeight)
        .contentShape(Rectangle())
    }
}

// MARK: - Layout

private enum Layout {
    static let horizontalPadding: CGFloat = 19  // Hi-Fi 69: 카드·칩 x 19 ~ 384
    static let titleTop: CGFloat = 46.3    // 네비게이션 바 아래(104) ↔ 타이틀 (Hi-Fi 69: 154, 측정 보정)
    static let subtitleTop: CGFloat = 8.7  // 타이틀 ↔ 설명
    static let listTop: CGFloat = 35.5     // 설명 ↔ 첫 카드 (Hi-Fi 69 2026-11-14: 카드 위 245.5). 코드에서는 리스트 행 위 여백만큼 뺀다
    static let cardSpacing: CGFloat = 14   // 카드 사이 간격 (Hi-Fi 69: 100 + 14, 리스트 행 위·아래 여백 7씩)
    static let cardWidth: CGFloat = 365    // Hi-Fi 69: 카드 폭
    static let cardHeight: CGFloat = 100   // Hi-Fi 69: 카드 높이
    static let cardCornerRadius: CGFloat = 16 // Hi-Fi 69: 카드 모서리. 카드 폭과 같이 화면 폭 비율로 바꿔 쓴다 (작은 기기에서 상대적으로 더 둥글어지지 않게)
    static let deleteRevealWidth: CGFloat = 102 // 삭제 버튼을 열었을 때 카드가 밀리는 거리 (시스템 스와이프: 카드 오른쪽 383 → 281)
    static let cardTrailing: CGFloat = 15.5  // 카드 오른쪽 안쪽 여백 (Hi-Fi 69: 화살표 오른쪽 365.5, 카드 383.5)
    static let titleFontSize: CGFloat = 16   // Hi-Fi 69 (2026-11-13): 날짜 숫자 높이 11.5pt
    static let durationFontSize: CGFloat = 12 // Hi-Fi 69 (2026-11-13): 시간 숫자 높이 8.4pt
    static let titleToDuration: CGFloat = 5 // 날짜 ↔ 스티밍 시간 (Hi-Fi 69: 날짜 글자 아래 345 → 시간 글자 아래 365.5, 캡처 보정)
}

#Preview {
    NavigationStack {
        let connection = WatchConnection()
        HistoryView(onStartPractice: {})
            .environmentObject(PracticeSession(connection: connection))
    }
}
