import SwiftUI

/// 히스토리 연습 내역 없음 화면 (빈 상자 일러스트 버전)
/// - 디자인: Hi-Fi/iPhone 17 - 166.png
///
///     ┌ 상단 네비게이션 바: 히스토리
///     ├ 빈 상자 일러스트
///     ├ 타이틀 + 설명
///     └ 하단 버튼: [첫 연습 시작하기]
struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 0) {
            // MARK: 상단 네비게이션 바
            TopNavigationHeader(title: "히스토리", isDark: true)
                .padding(.top, Layout.headerTop)

            // MARK: 일러스트
            AssetImageView(name: "IllustEmptyBox", width: 166, height: 122)
                .padding(.top, Layout.illustrationTop)

            // MARK: 타이틀 + 설명
            DarkScreenTitle("연습 내역이 없어요")
                .padding(.top, Layout.titleTop)

            DarkScreenSubtitle("첫 연습을 통해\n기록을 쌓아볼까요?")
                .padding(.top, Layout.subtitleTop)

            Spacer(minLength: 0)

            // MARK: 하단 버튼
            DarkPrimaryButton(title: "첫 연습 시작하기")
                .padding(.bottom, Layout.buttonBottom)
        }
        .darkScreenBackground()
    }
}

// MARK: - Layout

private enum Layout {
    static let headerTop: CGFloat = 22         // 상태바 ↔ 네비게이션 바
    static let illustrationTop: CGFloat = 240  // 네비게이션 바 ↔ 일러스트
    static let titleTop: CGFloat = 55          // 일러스트 ↔ 타이틀
    static let subtitleTop: CGFloat = 16       // 타이틀 ↔ 설명
    static let buttonBottom: CGFloat = 13      // 버튼 ↔ 화면 하단(안전 영역)
}

struct EmptyHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyHistoryView()
    }
}
