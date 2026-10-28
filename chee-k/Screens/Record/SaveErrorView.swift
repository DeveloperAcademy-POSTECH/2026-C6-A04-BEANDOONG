import SwiftUI

/// 연습 기록 저장 실패 화면 (라이트 테마)
/// - 디자인: Hi-Fi/iPhone 17 - 75.png
///
///     ┌ 상단 네비게이션 바: 연습 기록
///     ├ 타이틀 + 설명
///     ├ 소리의 변화 (스펙트로그램 카드 + 상태 색상 바)
///     └ 하단 버튼: [저장 다시 시도] [기록 확인하기]
struct SaveErrorView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: 상단 네비게이션 바
            TopNavigationHeader(title: "연습 기록")
                .padding(.top, Layout.headerTop)

            VStack(alignment: .leading, spacing: 0) {
                // MARK: 타이틀 + 설명
                Text("기록을 저장하지 못했어요.")
                    .font(.pretendard(.bold, size: 28))
                    .tracking(-0.3)
                    .foregroundStyle(AppColors.pureBlackTitle)
                    .padding(.top, Layout.titleTop)

                Text("이 화면에서 다시 저장해주세요.")
                    .font(.pretendard(.regular, size: 16))
                    .foregroundStyle(AppColors.saveErrorSubtitle)
                    .padding(.top, Layout.subtitleTop)
                    .padding(.bottom, Layout.subtitleBottom)

                // MARK: 소리의 변화 (스펙트로그램)
                SpectrogramSectionView(
                    selectedSecond: nil,
                    cardHeight: 210,
                    topHeaderHeight: 38,
                    barTopSpacing: 17
                )
                .padding(.leading, Layout.spectrogramLeading)

                Spacer(minLength: 0)

                // MARK: 하단 버튼
                LightButtonPair(primaryTitle: "저장 다시 시도", secondaryTitle: "기록 확인하기")
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
    static let headerTop: CGFloat = 22          // 상태바 ↔ 네비게이션 바
    static let titleTop: CGFloat = 36           // 네비게이션 바 ↔ 타이틀
    static let subtitleTop: CGFloat = 11        // 타이틀 ↔ 설명
    static let subtitleBottom: CGFloat = 98     // 설명 ↔ 스펙트로그램
    static let spectrogramLeading: CGFloat = 9  // 스펙트로그램 추가 좌측 여백
    static let buttonsBottom: CGFloat = 23      // 버튼 ↔ 화면 하단(안전 영역)
}

// MARK: - 이 화면 전용 색상

private extension AppColors {
    static let saveErrorSubtitle = Color(hex: 0x3A454D)
}

struct SaveErrorView_Previews: PreviewProvider {
    static var previews: some View {
        SaveErrorView()
    }
}
