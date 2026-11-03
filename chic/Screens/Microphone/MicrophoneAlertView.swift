import SwiftUI
import UIKit

/// 안내 화면 위에 실제 iOS 마이크 권한 팝업을 표시합니다. 딤 처리는 시스템이 담당합니다.
struct MicrophoneAlertView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var isRequesting = false

    var onPermissionGranted: () -> Void = {}

    var body: some View {
        MicrophoneAccessView(onOpenSettings: openSettings)
        .disabled(isRequesting)
        .task {
            isRequesting = true
            defer { isRequesting = false }

            let granted = await MicrophonePermission.request()
            guard !Task.isCancelled else { return }

            if granted {
                onPermissionGranted()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active, !isRequesting, MicrophonePermission.isGranted {
                onPermissionGranted()
            }
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url, options: [:])
    }
}

struct MicrophoneAlertView_Previews: PreviewProvider {
    static var previews: some View {
        // 실제 권한 팝업은 앱 실행으로 확인하고, 캔버스에서는 배경 화면만 확인합니다.
        MicrophoneAccessView()
    }
}
