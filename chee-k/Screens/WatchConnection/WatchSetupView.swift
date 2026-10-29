import SwiftUI

/// 애플 워치 연결 안내 화면
/// - 디자인: Hi-Fi/iPhone 17 - 93.png
///
///     ┌ 상단 네비게이션 바: 애플 워치 연결
///     ├ 아이폰 + 워치 일러스트
///     ├ 타이틀 + 설명
///     └ 하단 버튼: [연결 확인하기] [휴대폰만 사용하기]
struct WatchSetupView: View {
    @State private var showsChecklist = false

    var body: some View {
        VStack(spacing: 0) {
            // MARK: 상단 네비게이션 바
            TopNavigationHeader(title: "애플 워치 연결", isDark: true)
                .padding(.top, Layout.headerTop)

            // MARK: 일러스트
            AssetImageView(name: "IllustPhoneWatch", width: 234, height: 198)
                .padding(.top, Layout.illustrationTop)

            // MARK: 타이틀 + 설명
            DarkScreenTitle("워치에서도 실시간 상태를\n확인할 수 있어요")
                .padding(.top, Layout.titleTop)

            DarkScreenSubtitle("Apple Watch에서 chic 앱을 열어주세요\n손목 진동으로 스팀 상태를 알려드려요")
                .padding(.top, Layout.subtitleTop)

            Spacer(minLength: 0)

            // MARK: 하단 버튼
            DarkButtonPair(
                primaryTitle: "연결 확인하기",
                secondaryTitle: "휴대폰만 사용하기",
                secondaryAction: { showsChecklist = true }
            )
                .padding(.bottom, Layout.buttonsBottom)
        }
        .darkScreenBackground()
        .navigationDestination(isPresented: $showsChecklist) {
            SessionChecklistView()
                .toolbar(.hidden, for: .navigationBar)
        }
    }
}

// MARK: - Layout

private enum Layout {
    static let headerTop: CGFloat = 22         // 상태바 ↔ 네비게이션 바
    static let illustrationTop: CGFloat = 141  // 네비게이션 바 ↔ 일러스트
    static let titleTop: CGFloat = 65          // 일러스트 ↔ 타이틀
    static let subtitleTop: CGFloat = 16       // 타이틀 ↔ 설명
    static let buttonsBottom: CGFloat = 12     // 버튼 ↔ 화면 하단(안전 영역)
}

struct WatchSetupView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            WatchSetupView()
                .toolbar(.hidden, for: .navigationBar)
        }
    }
}
