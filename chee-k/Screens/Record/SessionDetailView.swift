import SwiftUI

/// 연습 상세 화면 (라이트 테마)
/// - 디자인: Hi-Fi/iPhone 17 - 61.png
///
///     ┌ 상단 네비게이션 바: 연습 상세 제목
///     ├ 날짜 타이틀 + "밀크 스티밍 · 32초"
///     ├ 섹션 제목 "소리의 변화"
///     ├ 스펙트로그램 카드 (17초 지점 선택 표시) + 상태 색상 바
///     ├ 선택 지점 상태 카드 (17초 지점 / 공기 주입 소리)
///     └ 안내 문구
struct SessionDetailView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: 상단 네비게이션 바
            TopNavigationHeader(title: "연습 상세 제목 이름 넣기")
                .padding(.top, Layout.headerTop)

            VStack(alignment: .leading, spacing: 0) {
                // MARK: 날짜 타이틀 + 요약
                Text("10월 20일 · 오후 2:32")
                    .font(.pretendard(.bold, size: 28))
                    .tracking(-0.3)
                    .foregroundStyle(AppColors.darkTitle)
                    .padding(.top, Layout.titleTop)

                Text("밀크 스티밍  ·  32초")
                    .font(.pretendard(.regular, size: 16))
                    .foregroundStyle(AppColors.subtitleGray)
                    .padding(.top, Layout.subtitleTop)

                // MARK: 소리의 변화 (스펙트로그램, 17초 선택)
                Text("소리의 변화")
                    .font(.pretendard(.bold, size: 20))
                    .foregroundStyle(AppColors.darkTitle)
                    .padding(.top, Layout.sectionTitleTop)
                    .padding(.bottom, Layout.sectionTitleBottom)

                SpectrogramSectionView(
                    selectedSecond: 17,
                    cardHeight: 222,
                    topHeaderHeight: 38,
                    barTopSpacing: 18
                )

                // MARK: 선택 지점 상태 카드 (y=599...744)
                SelectedPointCard()
                    .padding(.top, Layout.pointCardTop)

                // MARK: 안내 문구
                Text("그래프를 눌러 시간별 소리를 확인해요.")
                    .font(.pretendard(.regular, size: 14))
                    .foregroundStyle(AppColors.subtitleGray)
                    .padding(.top, Layout.captionTop)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, Layout.horizontalPadding)
        }
        .background(Color.white.ignoresSafeArea())
    }
}

// MARK: - 선택 지점 상태 카드

/// 그래프에서 선택한 시점에 화면에 표시됐던 상태를 보여주는 카드 (345 x 146)
///
///     ( 17초 지점 )
///     공기 주입 소리
///     당시 화면에 표시된 상태예요.
private struct SelectedPointCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 시점 배지
            Text("17초 지점")
                .font(.pretendard(.semibold, size: 13))
                .foregroundStyle(AppColors.badgeBlueText)
                .frame(width: 89, height: 28)
                .background(
                    Capsule()
                        .fill(Color.white)
                )

            // 상태 이름
            Text("공기 주입 소리")
                .font(.pretendard(.bold, size: 24))
                .foregroundStyle(AppColors.greenAccent)
                .padding(.top, 23)

            // 설명
            Text("당시 화면에 표시된 상태예요.")
                .font(.pretendard(.regular, size: 14))
                .foregroundStyle(AppColors.subtitleGray)
                .padding(.top, 10)
        }
        .padding(.horizontal, 19)
        .padding(.vertical, 18)
        .frame(width: 345, height: 146, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppColors.cardBackground)
        )
    }
}

// MARK: - Layout

private enum Layout {
    static let horizontalPadding: CGFloat = 29
    static let headerTop: CGFloat = 22          // 상태바 ↔ 네비게이션 바
    static let titleTop: CGFloat = 41           // 네비게이션 바 ↔ 날짜 타이틀
    static let subtitleTop: CGFloat = 15        // 날짜 타이틀 ↔ 요약
    static let sectionTitleTop: CGFloat = 37    // 요약 ↔ "소리의 변화"
    static let sectionTitleBottom: CGFloat = 14 // "소리의 변화" ↔ 스펙트로그램
    static let pointCardTop: CGFloat = 34       // 스펙트로그램 ↔ 선택 지점 카드
    static let captionTop: CGFloat = 28         // 선택 지점 카드 ↔ 안내 문구
}

struct SessionDetailView_Previews: PreviewProvider {
    static var previews: some View {
        SessionDetailView()
    }
}
