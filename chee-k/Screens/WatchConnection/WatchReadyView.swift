import SwiftUI

/// Apple Watch 준비 완료 화면
/// - 디자인: Hi-Fi/iPhone 17 - 114.png
///
///     ┌ 상단 네비게이션 바: 애플 워치 연결
///     ├ 워치 일러스트 (준비 완료)
///     ├ 타이틀 + 설명
///     └ 하단 버튼: [스팀 연습 시작]
struct WatchReadyView: View {
    var onContinue: (() -> Void)? = nil
    @State private var showsChecklist = false

    var body: some View {
        VStack(spacing: 0) {
            // MARK: 상단 네비게이션 바
            TopNavigationHeader(title: "애플 워치 연결", isDark: true)
                .padding(.top, Layout.headerTop)

            // MARK: 일러스트
            AssetImageView(name: "IllustWatchReady", width: 126, height: 210)
                .padding(.top, Layout.illustrationTop)

            // MARK: 타이틀 + 설명
            DarkScreenTitle("Apple Watch 가\n준비되었어요")
                .padding(.top, Layout.titleTop)

            DarkScreenSubtitle("이제 스팀 연습을 시작하면\n워치에서 진동 피드백을 받을 수 있어요")
                .padding(.top, Layout.subtitleTop)

            Spacer(minLength: 0)

            // MARK: 하단 버튼
            DarkPrimaryButton(title: "스팀 연습 시작") {
                if let onContinue { onContinue() } else { showsChecklist = true }
            }
                .padding(.bottom, Layout.buttonBottom)
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
    static let illustrationTop: CGFloat = 129  // 네비게이션 바 ↔ 일러스트
    static let titleTop: CGFloat = 76          // 일러스트 ↔ 타이틀
    static let subtitleTop: CGFloat = 18       // 타이틀 ↔ 설명
    static let buttonBottom: CGFloat = 13      // 버튼 ↔ 화면 하단(안전 영역)
}

struct WatchReadyView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            WatchReadyView()
                .toolbar(.hidden, for: .navigationBar)
        }
    }
}
