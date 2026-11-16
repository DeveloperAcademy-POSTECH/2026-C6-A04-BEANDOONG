import SwiftUI

struct StartRequestView: View {
    var onStartTap: () -> Void = {}

    var body: some View {
        WatchFullScreenStack {
            WatchCapsuleButton(title: String(localized: "스티밍 연습 시작"), action: onStartTap)
        }
        .background(AppColors.watchDarkScreenBackground)
    }
}

#Preview {
    NavigationStack { StartRequestView() }
}
