import SwiftUI

/// 스티밍 가이드 화면
/// - 디자인: Hi-Fi/iPhone 17 - 104.png
///
///     ┌ 상단 네비게이션 바: 스티밍 가이드
///     ├ 타이틀
///     ├ 안내 단계 ① 공기가 들어가는 순간  ② 우유가 회전하는 모습
///     ├ 피처 일러스트
///     └ 하단 버튼: [연습 준비하기]
struct SteamingGuideView: View {
    var body: some View {
        VStack(spacing: 0) {
            // MARK: 상단 네비게이션 바
            TopNavigationHeader(title: "스티밍 가이드", isDark: true)
                .padding(.top, Layout.headerTop)

            // MARK: 타이틀
            DarkScreenTitle("우유의 변화를 함께 살펴봐요")
                .padding(.top, Layout.titleTop)

            // MARK: 안내 단계 (왼쪽 정렬, 좌측 여백 92)
            VStack(alignment: .leading, spacing: 26) {
                NumberedGuideStep(
                    number: 1,
                    title: "공기가 들어가는 순간",
                    line1: "소리 피드백과 우유 표면의 변화를",
                    line2: "함께 확인해 보세요."
                )

                NumberedGuideStep(
                    number: 2,
                    title: "우유가 회전하는 모습",
                    line1: "교육받은 방법에 따라",
                    line2: "롤링을 관찰해요."
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, Layout.stepsLeading)
            .padding(.top, Layout.stepsTop)

            // MARK: 일러스트
            AssetImageView(name: "IllustPitchers", width: 242, height: 145)
                .padding(.top, Layout.illustrationTop)

            Spacer(minLength: 0)

            // MARK: 하단 버튼
            DarkPrimaryButton(title: "연습 준비하기")
                .padding(.bottom, Layout.buttonBottom)
        }
        .darkScreenBackground()
    }
}

// MARK: - Layout

private enum Layout {
    static let headerTop: CGFloat = 22        // 상태바 ↔ 네비게이션 바
    static let titleTop: CGFloat = 58         // 네비게이션 바 ↔ 타이틀
    static let stepsTop: CGFloat = 33         // 타이틀 ↔ 안내 단계
    static let stepsLeading: CGFloat = 92     // 안내 단계 좌측 여백
    static let illustrationTop: CGFloat = 95  // 안내 단계 ↔ 일러스트
    static let buttonBottom: CGFloat = 13     // 버튼 ↔ 화면 하단(안전 영역)
}

struct SteamingGuideView_Previews: PreviewProvider {
    static var previews: some View {
        SteamingGuideView()
    }
}
