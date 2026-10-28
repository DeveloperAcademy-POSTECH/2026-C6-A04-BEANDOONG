import SwiftUI

/// 연습 기록 완료 화면 (라이트 테마)
/// - 디자인: Hi-Fi/iPhone 17 - 74.png
///
///     ┌ 상단 네비게이션 바: 연습 기록
///     ├ 타이틀 "한 번의 연습이 쌓였어요"
///     ├ 스티밍 시간 라벨 + 큰 시간 "00:32"
///     ├ 소리의 변화 (스펙트로그램 카드 + 상태 색상 바)
///     ├ 안내 문구
///     └ 하단 버튼: [기록 자세히 보기] [다시 연습]
struct SessionSummaryView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: 상단 네비게이션 바
            TopNavigationHeader(title: "연습 기록")
                .padding(.top, Layout.headerTop)

            VStack(alignment: .leading, spacing: 0) {
                // MARK: 타이틀
                Text("한 번의 연습이 쌓였어요")
                    .font(.pretendard(.bold, size: 28))
                    .tracking(-0.3)
                    .foregroundStyle(AppColors.pureBlackTitle)
                    .padding(.top, Layout.titleTop)

                // MARK: 스티밍 시간
                Text("스티밍 시간")
                    .font(.pretendard(.regular, size: 15))
                    .foregroundStyle(AppColors.subtitleGray)
                    .padding(.top, Layout.durationLabelTop)

                Text("00:32")
                    .font(.pretendard(.bold, size: 54))
                    .foregroundStyle(AppColors.darkTitle)
                    .padding(.top, Layout.durationTop)
                    .padding(.bottom, Layout.durationBottom)

                // MARK: 소리의 변화 (스펙트로그램)
                SpectrogramSectionView(
                    selectedSecond: nil,
                    cardHeight: 200,
                    topHeaderHeight: 34,
                    barTopSpacing: 14
                )

                // MARK: 안내 문구
                Text("소리의 변화와 표시된 상태를 돌아보세요.")
                    .font(.pretendard(.regular, size: 15))
                    .foregroundStyle(AppColors.subtitleGray)
                    .padding(.top, Layout.captionTop)

                Spacer(minLength: 0)

                // MARK: 하단 버튼
                LightButtonPair(primaryTitle: "기록 자세히 보기", secondaryTitle: "다시 연습")
                    .padding(.bottom, Layout.buttonsBottom)
            }
            .padding(.horizontal, Layout.horizontalPadding)
        }
        .background(Color.white.ignoresSafeArea())
    }
}

// MARK: - Layout

private enum Layout {
    static let horizontalPadding: CGFloat = 20
    static let headerTop: CGFloat = 22         // 상태바 ↔ 네비게이션 바
    static let titleTop: CGFloat = 36          // 네비게이션 바 ↔ 타이틀
    static let durationLabelTop: CGFloat = 55  // 타이틀 ↔ "스티밍 시간"
    static let durationTop: CGFloat = 14       // "스티밍 시간" ↔ "00:32"
    static let durationBottom: CGFloat = 22    // "00:32" ↔ 스펙트로그램
    static let captionTop: CGFloat = 26        // 스펙트로그램 ↔ 안내 문구
    static let buttonsBottom: CGFloat = 23     // 버튼 ↔ 화면 하단(안전 영역)
}

struct SessionSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        SessionSummaryView()
    }
}
