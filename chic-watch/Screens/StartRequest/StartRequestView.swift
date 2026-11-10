import SwiftUI

struct StartRequestView: View {
    var onStartTap: () -> Void = {}
    @State private var showsCloseInstructions = false

    var body: some View {
        WatchFullScreenStack {
            WatchCapsuleButton(title: "스티밍 연습 시작", action: onStartTap)
        }
        .background(AppColors.watchDarkScreenBackground)
        .watchCloseButton { showsCloseInstructions = true }
        .alert("앱 닫기", isPresented: $showsCloseInstructions) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("워치 옆면의 둥근 버튼(Digital Crown)을 눌러 앱에서 나갈 수 있어요.")
        }
    }
}

#Preview {
    NavigationStack { StartRequestView() }
}
