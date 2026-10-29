import SwiftUI

/// 마이크 권한 안내 화면 (권한이 꺼져 있을 때 설정으로 유도)
/// - 디자인: Hi-Fi/iPhone 17 - 115.png
///
///     ┌ 상단 네비게이션 바: 마이크 설정
///     ├ 마이크 일러스트
///     ├ 타이틀 + 설명
///     └ 하단 버튼: [설정 열기]
struct MicrophoneAccessView: View {
    var onOpenSettings: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            // MARK: 상단 네비게이션 바
            TopNavigationHeader(title: "마이크 설정", isDark: true)
                .padding(.top, Layout.headerTop)

            // MARK: 일러스트
            AssetImageView(name: "IllustMic", width: 98, height: 170)
                .padding(.top, Layout.illustrationTop)

            // MARK: 타이틀 + 설명
            DarkScreenTitle("공기주입 상태를 분석하려면\n마이크 권한이 필요해요")
                .padding(.top, Layout.titleTop)

            DarkScreenSubtitle("기기 설정에서 chic의 마이크 접근을\n허용한 뒤 돌아와 주세요")
                .padding(.top, Layout.subtitleTop)

            Spacer(minLength: 0)

            // MARK: 하단 버튼
            DarkPrimaryButton(title: "설정 열기", action: onOpenSettings)
                .padding(.bottom, Layout.buttonsBottom)
        }
        .darkScreenBackground()
    }
}

// MARK: - Layout

private enum Layout {
    static let headerTop: CGFloat = 22         // 상태바 ↔ 네비게이션 바
    static let illustrationTop: CGFloat = 129  // 네비게이션 바 ↔ 일러스트
    static let titleTop: CGFloat = 74          // 일러스트 ↔ 타이틀
    static let subtitleTop: CGFloat = 16       // 타이틀 ↔ 설명
    static let buttonsBottom: CGFloat = 12     // 버튼 ↔ 화면 하단(안전 영역)
}

struct MicrophoneAccessView_Previews: PreviewProvider {
    static var previews: some View {
        MicrophoneAccessView()
    }
}
