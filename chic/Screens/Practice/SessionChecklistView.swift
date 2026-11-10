import SwiftUI

/// 연습 준비 확인 화면
/// - 디자인: Hi-Fi 변경사항 18
///
///     ┌ 상단 네비게이션 바: 연습 준비
///     ├ 타이틀 "시작 전 잠깐 확인해요" ('잠깐 확인해요'만 강조색)
///     ├ 안내 단계 ① 휴대폰은 머신 가까이  ② 색상과 문구를 함께 확인
///     ├ 상태 안내 카드 (329 x 234, 2열 x 3줄)
///     │   ├ 공기 주입          │ 공기가 부족해요
///     │   ├ 롤링 소리          │ 노즐이 너무 높아요
///     │   └ 소리 확인 중
///     └ 하단 버튼: [스팀 연습 시작하기]
struct SessionChecklistView: View {
    @EnvironmentObject private var practice: PracticeSession
    /// 진입 경로에서 정한 워치 사용 여부
    var usesWatch = true

    var body: some View {
        VStack(spacing: 0) {
            // MARK: 상단 네비게이션 바
            TopNavigationHeader(title: "연습 준비", isDark: true)
                .padding(.top, Layout.headerTop)

            // MARK: 타이틀
            title
                .padding(.top, Layout.titleTop)

            // MARK: 안내 단계 (왼쪽 정렬, 좌측 여백 92)
            VStack(alignment: .leading, spacing: Layout.stepSpacing) {
                NumberedGuideStep(
                    number: 1,
                    title: "휴대폰은 머신 가까이",
                    line1: "물과 열이 직접 닿지 않는",
                    line2: "안정적인 곳에 두고 연습해 주세요.",
                    descriptionLineGap: Layout.stepDescriptionLineGap
                )

                NumberedGuideStep(
                    number: 2,
                    title: "색상과 문구를 함께 확인해요.",
                    line1: "색상 변화로 공기주입 상태를 쉽게",
                    line2: "확인할 수 있어요.",
                    descriptionLineGap: Layout.stepDescriptionLineGap
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, Layout.stepsLeading)
            .padding(.top, Layout.stepsTop)

            // MARK: 상태 안내 카드
            StatusLegendCard()
                .padding(.top, Layout.legendCardTop)

            Spacer(minLength: 0)

            // MARK: 하단 버튼
            DarkPrimaryButton(title: "스팀 연습 시작하기") {
                Task { await practice.start(usingWatch: usesWatch) }
            }
            .padding(.bottom, Layout.buttonBottom)
        }
        .darkScreenBackground()
    }

    /// 문장 전체를 번역하면서 확인 문구의 강조색과 언어별 어순을 유지합니다.
    private var title: some View {
        Text("시작 전 \(Text("잠깐 확인해요").foregroundStyle(AppColors.darkChipSelected))")
            .font(.pretendard(.bold, size: 26))
            .foregroundStyle(Color.white)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - 상태 안내 카드

/// 스티밍 상태별로 워치 화면에 어떤 색이 표시되는지 알려주는 카드 (329 x 234, 2열 x 3줄)
private struct StatusLegendCard: View {
    private let columns = Array(
        repeating: GridItem(.fixed(LegendLayout.columnWidth), spacing: 0, alignment: .leading),
        count: 2
    )

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: LegendLayout.rowSpacing) {
            ForEach(StatusLegendItem.all) { item in
                StatusLegendRow(item: item)
            }
        }
        .padding(.leading, LegendLayout.leadingPadding)
        .frame(width: LegendLayout.cardWidth, height: LegendLayout.cardHeight, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColors.darkCard)
        )
    }
}

/// 상태 안내 카드의 한 칸에 들어갈 내용
private struct StatusLegendItem: Identifiable {
    let title: String
    /// 두 줄 설명 (\n 으로 줄바꿈)
    let description: String
    /// 워치 아이콘 화면 색
    let screenColor: Color

    var id: String { title }

    /// 왼쪽 → 오른쪽, 위 → 아래 순서 (Hi-Fi 문구 그대로)
    static let all: [StatusLegendItem] = [
        StatusLegendItem(title: "공기 주입", description: "일반적인\n공기 주입 소리", screenColor: AppColors.aerationTop),
        StatusLegendItem(title: "공기가 부족해요", description: "공기 주입 소리가\n작거나 없음", screenColor: AppColors.moreAirTop),
        StatusLegendItem(title: "롤링 소리", description: "우유가\n회전하는 소리", screenColor: AppColors.milkFlowTop),
        StatusLegendItem(title: "노즐이 너무 높아요", description: "큰 거품과\n파열음 발생", screenColor: AppColors.bubbleTop),
        StatusLegendItem(title: "소리 확인 중", description: "상태를 확인할\n때까지 기다려요.", screenColor: .black)
    ]
}

/// 상태 안내 카드의 한 칸: [워치 아이콘] 제목 / 설명 2줄
private struct StatusLegendRow: View {
    let item: StatusLegendItem

    var body: some View {
        HStack(alignment: .top, spacing: LegendLayout.iconTextSpacing) {
            WatchMiniIcon(screenColor: item.screenColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.pretendard(.bold, size: 12))
                    .foregroundStyle(Color.white)
                Text(item.description)
                    .font(.pretendard(.regular, size: 11))
                    .lineSpacing(1)
                    .foregroundStyle(AppColors.darkSubtitle)
            }
        }
    }
}

// MARK: - 미니 아이콘

/// 워치 모양 아이콘: 밴드(14 x 47) + 본체(24 x 28) + 화면(18 x 22, 상태 색상)
private struct WatchMiniIcon: View {
    let screenColor: Color

    var body: some View {
        ZStack {
            // 밴드
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(AppColors.legendWatchBody)
                .frame(width: 14, height: 47)
            // 본체
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(AppColors.legendWatchBody)
                .frame(width: 24, height: 28)
            // 화면
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(screenColor)
                .frame(width: 18, height: 22)
        }
        .frame(width: 24, height: 47)
    }
}

// MARK: - Layout

private enum Layout {
    static let headerTop: CGFloat = 22      // 상태바 ↔ 네비게이션 바
    static let titleTop: CGFloat = 68       // 네비게이션 바 ↔ 타이틀
    static let stepsTop: CGFloat = 49       // 타이틀 ↔ 안내 단계
    static let stepsLeading: CGFloat = 92   // 안내 단계 좌측 여백
    static let stepSpacing: CGFloat = 32    // 안내 단계 ① ↔ ②
    /// 안내 단계 설명 두 줄 사이 (스티밍 가이드 화면보다 촘촘함)
    static let stepDescriptionLineGap: CGFloat = 0
    static let legendCardTop: CGFloat = 38  // 안내 단계 ↔ 상태 안내 카드
    static let buttonBottom: CGFloat = 9    // 버튼 ↔ 화면 하단(안전 영역)
}

/// 상태 안내 카드 내부 치수 (Hi-Fi 측정값)
private enum LegendLayout {
    static let cardWidth: CGFloat = 329
    static let cardHeight: CGFloat = 234
    static let leadingPadding: CGFloat = 27   // 카드 왼쪽 ↔ 첫 열 아이콘
    static let columnWidth: CGFloat = 150     // 한 열의 폭 (왼쪽 아이콘 ↔ 오른쪽 아이콘)
    static let rowSpacing: CGFloat = 26       // 줄 사이 간격 (아이콘 높이 47 + 26 = 줄 간격 73)
    static let iconTextSpacing: CGFloat = 14  // 아이콘 ↔ 글자
}

// MARK: - 이 화면 전용 색상

private extension AppColors {
    static let legendWatchBody = Color(hex: 0xF5FAFF)
}

struct SessionChecklistView_Previews: PreviewProvider {
    static var previews: some View {
        SessionChecklistView()
    }
}
