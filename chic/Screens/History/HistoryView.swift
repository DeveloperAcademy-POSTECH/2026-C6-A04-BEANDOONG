import SwiftUI
import UIKit

/// 히스토리 화면
/// - 디자인: Hi-Fi/iPhone 17 - 69.png (목록, 2026-11-14 시안: 기간 필터 없음) · 254.png (삭제 팝업)
///
///     ┌ 상단 네비게이션 바: 히스토리
///     ├ 타이틀 + 설명
///     └ 연습 기록 카드 목록: 모든 기록을 최신순으로 (터치 시 HistoryDetailView 로 이동, 왼쪽으로 밀면 삭제)
struct HistoryView: View {
    @EnvironmentObject private var practice: PracticeSession
    @Environment(\.designScale) private var scale
    let onStartPractice: () -> Void
    /// 삭제 팝업을 보여 주는 중인지 (팝업이 떠 있는 동안 카드 오른쪽은 링 대신 휴지통, Hi-Fi 254)
    @State private var showsDeleteDialog: Bool
    /// 스와이프로 삭제를 누른 기록 (팝업에서 확인하면 지움)
    @State private var deleteTarget: HistoryRecord?
    /// 상세로 들어가는 기록
    @State private var selectedRecord: HistoryRecord?
    /// 왼쪽으로 밀어 삭제 버튼을 꺼내 둔 기록 (한 번에 하나만)
    @State private var openRecordID: UUID?
    /// 시안 캡처용: 저장소 대신 이 결과들을 보여 줌 (nil이면 실제 기록)
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
        // 저장소 목록이 이미 시작 시각 최신순이에요 (`PracticeHistoryStore.records()`).
        return practice.history.map { HistoryRecord(entity: $0) }
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
        // 기록마다 결과를 다시 만드는 일이라 한 번만 계산해요.
        let visibleRecords = records
        return VStack(alignment: .leading, spacing: 0) {
            // MARK: 상단 네비게이션 바
            TopNavigationHeader(title: "히스토리", isDark: true)
                .padding(.top, Layout.headerTop.v(scale))

            VStack(alignment: .leading, spacing: 0) {
                // MARK: 타이틀 + 설명
                Text("나의 기록이 쌓이는 곳")
                    .font(.pretendard(.bold, size: 26))
                    .tracking(-0.3)
                    .foregroundStyle(Color.white)
                    .padding(.top, Layout.titleTop.v(scale))

                Text("기록을 열어 소리의 변화를 비교해 보세요.")
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
                                HistoryRecordCard(record: record, width: Layout.cardWidth.h(scale), showsTrash: showsDeleteDialog)
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
        .chicAlert(
            isPresented: showsDeleteDialog,
            title: "정말 방을 삭제하시겠어요?",
            message: "삭제한 방은 다시 복구할 수 없어요",
            cancelTitle: "취소",
            confirmTitle: "방 삭제",
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
    let date: Date
    let dailyOrder: Int
    let durationSeconds: Int
    let result: PracticeResult

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
///     9월 28일 - 1차              ◔   >
///     32초
/// 오른쪽 링은 그 연습의 "주의 소리" 비율이고, 삭제 팝업이 떠 있는 동안에는 휴지통으로 바뀐다. (Hi-Fi 69 · 254)
/// 카드 배경(둥근 사각형)은 감싸는 `SwipeToDeleteRow`가 그린다. 밀었을 때 남은 폭만큼만 그려야 해서다.
private struct HistoryRecordCard: View {
    let record: HistoryRecord
    var width: CGFloat = 365
    var showsTrash = false

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
        .padding(.trailing, Layout.cardTrailing)
        .frame(width: width, height: Layout.cardHeight)
        .contentShape(Rectangle())
    }
}

// MARK: - 왼쪽으로 밀어 삭제

/// 카드를 왼쪽으로 밀면 오른쪽에 삭제 버튼이 나오는 줄.
///
/// 밀린 카드는 목록 왼쪽 끝 밖으로 나가는데, 잘린 쪽도 카드 모서리와 같은 둥근 모서리로 오려 그린다.
/// 그래서 각지게 잘리지 않고 둥근 끝을 유지한 채 밀려 나간다.
/// 모서리 반경은 카드 폭처럼 화면 폭 비율로 바꿔 받으므로, 기기가 달라도 카드와 모서리의 비율이 같다.
///
/// 삭제 버튼의 모양·위치는 이전에 쓰던 시스템 `swipeActions` 버튼을 iPhone 17에서 재서 맞췄다.
private struct SwipeToDeleteRow<Content: View>: View {
    @Binding var isOpen: Bool
    let width: CGFloat
    /// 삭제 버튼을 열었을 때 카드가 밀리는 거리
    let revealWidth: CGFloat
    let cornerRadius: CGFloat
    /// 카드 배경색. 남은 폭만큼의 둥근 사각형으로 직접 칠한다
    let cardColor: Color
    let onDelete: () -> Void
    @ViewBuilder let content: () -> Content

    /// 손가락으로 끄는 중의 이동량 (왼쪽이 −). 끄는 중이 아니면 nil
    @State private var dragTranslation: CGFloat?

    /// 지금 카드가 왼쪽으로 밀린 거리 (0이면 닫힘)
    private var offset: CGFloat {
        let base = isOpen ? revealWidth : 0
        guard let dragTranslation else { return base }
        let raw = base - dragTranslation
        if raw <= 0 { return 0 }
        // 열린 거리보다 더 끌면 고무줄처럼 덜 따라온다
        if raw > revealWidth { return revealWidth + (raw - revealWidth) * SwipeLayout.overdragResistance }
        return raw
    }

    /// 삭제 버튼이 드러난 정도 (0 ~ 1)
    private var progress: CGFloat { min(1, offset / revealWidth) }

    var body: some View {
        ZStack(alignment: .trailing) {
            deleteButton
                .frame(width: revealWidth)
                .opacity(progress)
                .scaleEffect(SwipeLayout.buttonStartScale + (1 - SwipeLayout.buttonStartScale) * progress)
                .allowsHitTesting(isOpen && dragTranslation == nil)

            content()
                // 밀기와 둥글게 오리기를 한 값으로 매 프레임 함께 계산해, 애니메이션 중에도 잘린 끝이 둥글게 따라간다
                .modifier(SwipedCardClip(offset: offset, cornerRadius: cornerRadius, cardColor: cardColor))
                .gesture(
                    HorizontalPanGesture(
                        allowsRightward: isOpen,
                        onChanged: { dragTranslation = $0 },
                        onEnded: { translation, velocity in
                            let base = isOpen ? revealWidth : 0
                            // 손을 뗀 속도까지 더해 반 넘게 열릴 것 같으면 연다
                            let projected = base - translation - velocity * SwipeLayout.velocityProjection
                            withAnimation(SwipeLayout.settle) {
                                isOpen = projected > revealWidth / 2
                                dragTranslation = nil
                            }
                        }
                    )
                )
        }
        .frame(width: width)
        .animation(SwipeLayout.settle, value: isOpen)
        .accessibilityAction(named: "삭제", onDelete)
    }

    private var deleteButton: some View {
        Button(action: onDelete) {
            VStack(spacing: SwipeLayout.labelGap) {
                Image(systemName: "trash")
                    .font(.system(size: SwipeLayout.iconSize, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .frame(width: SwipeLayout.circleSize, height: SwipeLayout.circleSize)
                    .background(Circle().fill(AppColors.swipeDeleteRed))
                Text("삭제")
                    .font(.system(size: SwipeLayout.labelSize, weight: .regular))
                    .foregroundStyle(Color(uiColor: .secondaryLabel))
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("삭제")
    }
}

/// 카드를 왼쪽으로 `offset`만큼 민다.
/// - 카드 겉모양(배경)은 옮기지 않고, 목록 안에 남은 폭만큼의 둥근 사각형으로 그 자리에 다시 그린다.
///   옮긴 사각형을 오려 내면 이동과 오리기가 화면에 한 프레임씩 어긋나 끝이 각져 보이는데, 도형 하나로 그리면 그럴 일이 없다.
/// - 글자·링·화살표만 옮기고 같은 모양으로 오린다.
/// - 남은 폭이 모서리 두 개보다 좁으면 알약 모양이 된다.
/// - `Animatable`이라 제자리로 돌아가는 애니메이션 중에도 배경과 내용이 같은 값으로 그려진다.
private struct SwipedCardClip: ViewModifier, Animatable {
    var offset: CGFloat
    let cornerRadius: CGFloat
    let cardColor: Color

    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }

    func body(content: Content) -> some View {
        let shape = VisibleCardShape(hiddenWidth: offset, cornerRadius: cornerRadius)
        content
            .offset(x: -offset)
            .clipShape(shape)
            .background(shape.fill(cardColor))
            // 보간은 이 수정자가 매 프레임 하므로, 안쪽 이동이 같은 애니메이션을 한 번 더 받아 뒤처지지 않게 한다
            .transaction(value: offset) { $0.animation = nil }
    }
}

/// 카드에서 왼쪽으로 밀려 나간 폭(`hiddenWidth`)을 뺀 나머지를 둥근 사각형으로 오리는 모양.
/// 모서리 반경은 남은 폭·높이의 절반을 넘지 않아, 좁아지면 알약 모양이 된다.
private struct VisibleCardShape: Shape {
    let hiddenWidth: CGFloat
    let cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        let visibleWidth = max(0, rect.width - hiddenWidth)
        let radius = min(cornerRadius, visibleWidth / 2, rect.height / 2)
        return RoundedRectangle(cornerRadius: radius, style: .continuous)
            .path(in: CGRect(x: rect.minX, y: rect.minY, width: visibleWidth, height: rect.height))
    }
}

/// 가로로 끄는 것만 받는 팬 제스처. 위아래로 끄면 시작하지 않아 목록 스크롤을 막지 않는다.
/// 닫힌 카드를 오른쪽으로 끌어도 시작해서(카드는 움직이지 않음) 손을 뗄 때 카드 탭으로 처리되지 않게 한다.
/// 단, 화면 왼쪽 가장자리에서 시작한 오른쪽 끌기는 뒤로가기 스와이프에 양보한다.
private struct HorizontalPanGesture: UIGestureRecognizerRepresentable {
    var allowsRightward: Bool
    var onChanged: (CGFloat) -> Void
    /// (이동량, 손을 뗄 때 속도 pt/s). 둘 다 왼쪽이 −
    var onEnded: (CGFloat, CGFloat) -> Void

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
        Coordinator()
    }

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let recognizer = UIPanGestureRecognizer()
        recognizer.delegate = context.coordinator
        return recognizer
    }

    func updateUIGestureRecognizer(_ recognizer: UIPanGestureRecognizer, context: Context) {
        context.coordinator.allowsRightward = allowsRightward
    }

    func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context: Context) {
        let translation = recognizer.translation(in: recognizer.view).x
        switch recognizer.state {
        case .began, .changed:
            onChanged(translation)
        case .ended, .cancelled, .failed:
            onEnded(translation, recognizer.state == .ended ? recognizer.velocity(in: recognizer.view).x : 0)
        default:
            break
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var allowsRightward = false

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return false }
            let velocity = pan.velocity(in: pan.view)
            guard abs(velocity.x) > abs(velocity.y) else { return false }
            if velocity.x < 0 || allowsRightward { return true }
            // 닫힌 카드를 오른쪽으로: 끌기 시작한 곳이 화면 왼쪽 가장자리면 뒤로가기에 양보
            let startX = pan.location(in: nil).x - pan.translation(in: nil).x
            return startX > SwipeLayout.backSwipeEdgeWidth
        }
    }
}

/// 밀어서 삭제 수치 (iPhone 17에서 시스템 `swipeActions` 버튼을 잰 값, pt)
private enum SwipeLayout {
    static let circleSize: CGFloat = 54.5   // 빨간 원 지름 (x 308.3 ~ 363, y 311.7 ~ 366.3)
    static let iconSize: CGFloat = 20       // 휴지통 아이콘 (19 x 22)
    static let labelSize: CGFloat = 15      // "삭제" 글자 (글자 높이 12)
    static let labelGap: CGFloat = 3        // 원 아래 366.3 → 글줄 위 약 369.5
    static let buttonStartScale: CGFloat = 0.6 // 밀기 시작할 때 버튼 크기 (드러날수록 1로)
    static let overdragResistance: CGFloat = 0.25
    static let backSwipeEdgeWidth: CGFloat = 24 // 이 폭 안에서 시작한 오른쪽 끌기는 뒤로가기 스와이프 몫 (`PracticePrepGuideView`와 같은 값)
    static let velocityProjection: CGFloat = 0.15 // 손을 뗀 속도 × 이 시간(초)만큼 더 간다고 보고 열지 정함
    static let settle = Animation.spring(duration: 0.35, bounce: 0)
}

// MARK: - Layout

private enum Layout {
    static let horizontalPadding: CGFloat = 19  // Hi-Fi 69: 카드·칩 x 19 ~ 384
    static let headerTop: CGFloat = 84     // 화면 위 ↔ 네비게이션 바 (Hi-Fi 69: 글자 y0 86 − 2)
    static let titleTop: CGFloat = 46.3    // 네비게이션 바 아래(104) ↔ 타이틀 (Hi-Fi 69: 154, 측정 보정)
    static let subtitleTop: CGFloat = 8.7  // 타이틀 ↔ 설명
    static let listTop: CGFloat = 35.5     // 설명 ↔ 첫 카드 (Hi-Fi 69 2026-11-14: 카드 위 245.5). 코드에서는 리스트 행 위 여백만큼 뺀다
    static let cardSpacing: CGFloat = 14   // 카드 사이 간격 (Hi-Fi 69: 100 + 14, 리스트 행 위·아래 여백 7씩)
    static let cardWidth: CGFloat = 365    // Hi-Fi 69: 카드 폭
    static let cardHeight: CGFloat = 100   // Hi-Fi 69: 카드 높이
    static let cardCornerRadius: CGFloat = 16 // Hi-Fi 69: 카드 모서리. 카드 폭과 같이 화면 폭 비율로 바꿔 쓴다 (작은 기기에서 상대적으로 더 둥글어지지 않게)
    static let deleteRevealWidth: CGFloat = 102 // 삭제 버튼을 열었을 때 카드가 밀리는 거리 (시스템 스와이프: 카드 오른쪽 383 → 281)
    static let ringSize: CGFloat = 58.6    // Hi-Fi 69: 도넛 지름
    static let ringLineWidth: CGFloat = 10 // Hi-Fi 69: 도넛 두께
    static let ringToChevron: CGFloat = 18.5 // 링 오른쪽 ↔ 화살표 (Hi-Fi 69: 호 오른쪽 335.5 → 화살표 357, 캡처 보정)
    static let cardTrailing: CGFloat = 15.5  // 카드 오른쪽 안쪽 여백 (Hi-Fi 69: 화살표 오른쪽 365.5, 카드 383.5)
    static let titleFontSize: CGFloat = 16   // Hi-Fi 69 (2026-11-13): 날짜 숫자 높이 11.5pt
    static let durationFontSize: CGFloat = 12 // Hi-Fi 69 (2026-11-13): 시간 숫자 높이 8.4pt
    static let titleToDuration: CGFloat = 5 // 날짜 ↔ 스티밍 시간 (Hi-Fi 69: 날짜 글자 아래 345 → 시간 글자 아래 365.5, 캡처 보정)
}

// MARK: - 이 화면 전용 색상

private extension AppColors {
    /// 삭제 팝업이 떠 있을 때 카드 오른쪽 휴지통 (Hi-Fi 254, 딤 처리된 상태)
    static let historyTrash = Color(hex: 0xAEAEAE)
    /// 밀어서 삭제 버튼의 빨간 원 (시스템 스와이프 삭제 버튼 측정값)
    static let swipeDeleteRed = Color(hex: 0xFF4245)
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
