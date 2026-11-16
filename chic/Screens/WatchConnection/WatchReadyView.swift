import SwiftUI

/// Apple Watch 준비 완료 화면
/// - 디자인: Hi-Fi/iPhone 17 - 114.png
///
///     ┌ 상단 네비게이션 바: 애플 워치 연결
///     ├ 워치 일러스트 (준비 완료)
///     ├ 타이틀 + 설명
///     └ 하단 버튼: [완료]
struct WatchReadyView: View {
    var onContinue: (() -> Void)? = nil
    @State private var showsChecklist = false

    var body: some View {
        WatchStatusScreen(
            title: String(localized: "Apple Watch 가\n준비되었어요"),
            subtitle: String(localized: "이제 스팀 연습을 시작하면\n워치에서 진동 피드백을 받을 수 있어요")
        ) {
            AssetImageView(name: "IllustWatchReady", size: ScreenMetrics.WatchStatus.illustrationSize)
        } footer: {
            BottomPrimaryButton(title: String(localized: "완료")) {
                if let onContinue { onContinue() } else { showsChecklist = true }
            }
        }
        .navigationDestination(isPresented: $showsChecklist) {
            PracticePrepGuideView()
                .toolbar(.hidden, for: .navigationBar)
        }
    }
}

#Preview {
    NavigationStack {
        WatchReadyView()
            .toolbar(.hidden, for: .navigationBar)
    }
}
