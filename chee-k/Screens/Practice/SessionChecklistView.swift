import SwiftUI

/// 연습 준비 확인 화면
/// - 디자인: Hi-Fi/iPhone 17 - 95.png
///
///     ┌ 상단 네비게이션 바: 연습 준비
///     ├ 타이틀 "시작 전, 잠깐 확인해요" ('잠깐 확인해요'만 강조색)
///     ├ 안내 단계 ① 휴대폰은 머신 가까이  ② 색상과 문구를 함께 확인
///     ├ 상태 안내 카드 (264 x 192)
///     │   ├ [휴대폰]      소리 확인 중
///     │   ├ [워치·파랑]   공기 주입 소리
///     │   └ [워치·분홍]   날카로운 소리
///     └ 하단 버튼: [연습 시작하기] [워치 없이 연습하기]
struct SessionChecklistView: View {
    @EnvironmentObject private var practice: PracticeSession
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
            VStack(alignment: .leading, spacing: 26) {
                NumberedGuideStep(
                    number: 1,
                    title: "휴대폰은 머신 가까이",
                    line1: "물과 열이 직접 닿지 않는",
                    line2: "안정적인 곳에 두고 연습해 주세요."
                )

                NumberedGuideStep(
                    number: 2,
                    title: "색상과 문구를 함께 확인해요.",
                    line1: "색상 변화로 공기주입 상태를",
                    line2: "쉽게 확인할 수 있어요."
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, Layout.stepsLeading)
            .padding(.top, Layout.stepsTop)

            // MARK: 상태 안내 카드 (x=69...332)
            StatusLegendCard()
                .padding(.top, Layout.legendCardTop)

            Spacer(minLength: 0)

            // MARK: 하단 버튼
            DarkButtonPair(
                primaryTitle: "연습 시작하기", secondaryTitle: "워치 없이 연습하기",
                primaryAction: { Task { await practice.start(usingWatch: usesWatch) } },
                secondaryAction: { Task { await practice.start(usingWatch: false) } }
            )
                .padding(.bottom, Layout.buttonsBottom)
        }
        .darkScreenBackground()
    }

    /// "시작 전, **잠깐 확인해요**"
    private var title: some View {
        HStack(spacing: 0) {
            Text("시작 전, ")
                .foregroundStyle(Color.white)
            Text("잠깐 확인해요")
                .foregroundStyle(AppColors.darkChipSelected)
        }
        .font(.pretendard(.bold, size: 26))
    }
}

// MARK: - 상태 안내 카드

/// 화면 상태별로 어떤 표시/진동이 나오는지 알려주는 카드 (264 x 192)
private struct StatusLegendCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            StatusLegendRow(title: "소리 확인 중", description: "상태를 확인할 때까지 기다려요.") {
                PhoneMiniIcon()
            }

            StatusLegendRow(title: "공기 주입 소리", description: "짧은 진동 한 번") {
                WatchMiniIcon(screenColor: AppColors.aerationBlue)
            }

            StatusLegendRow(title: "날카로운 소리", description: "짧은 진동 두 번") {
                WatchMiniIcon(screenColor: AppColors.sharpSoundPink)
            }
        }
        .padding(.horizontal, 28)
        .frame(width: 264, height: 192, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColors.darkCard)
        )
    }
}

/// 상태 안내 카드의 한 줄: [아이콘] 제목 / 설명
private struct StatusLegendRow<Icon: View>: View {
    let title: String
    let description: String
    @ViewBuilder let icon: () -> Icon

    var body: some View {
        HStack(spacing: 18) {
            icon()

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.pretendard(.bold, size: 13))
                    .foregroundStyle(Color.white)
                Text(description)
                    .font(.pretendard(.regular, size: 12))
                    .foregroundStyle(AppColors.darkSubtitle)
            }
        }
    }
}

// MARK: - 미니 아이콘

/// 흰 테두리의 검정 휴대폰 모양 아이콘 (21 x 36, 아이콘 칸 폭 26)
private struct PhoneMiniIcon: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 5, style: .continuous)
            .stroke(Color.white, lineWidth: 3.5)
            .background(RoundedRectangle(cornerRadius: 5).fill(Color.black))
            .frame(width: 21, height: 36)
            .frame(width: 26)
    }
}

/// 워치 모양 아이콘: 밴드(14 x 42) + 본체(24 x 28) + 화면(18 x 22, 상태 색상)
private struct WatchMiniIcon: View {
    let screenColor: Color

    var body: some View {
        ZStack {
            // 밴드
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(Color.white)
                .frame(width: 14, height: 42)
            // 본체
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(Color.white)
                .frame(width: 24, height: 28)
            // 화면
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(screenColor)
                .frame(width: 18, height: 22)
        }
        .frame(width: 26, height: 42)
    }
}

// MARK: - Layout

private enum Layout {
    static let headerTop: CGFloat = 22      // 상태바 ↔ 네비게이션 바
    static let titleTop: CGFloat = 97       // 네비게이션 바 ↔ 타이틀
    static let stepsTop: CGFloat = 23       // 타이틀 ↔ 안내 단계
    static let stepsLeading: CGFloat = 92   // 안내 단계 좌측 여백
    static let legendCardTop: CGFloat = 38  // 안내 단계 ↔ 상태 안내 카드
    static let buttonsBottom: CGFloat = 9   // 버튼 ↔ 화면 하단(안전 영역)
}

struct SessionChecklistView_Previews: PreviewProvider {
    static var previews: some View {
        SessionChecklistView()
    }
}
