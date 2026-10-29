import SwiftUI
import UIKit

/// 안내 화면 위에 실제 iOS 마이크 권한 팝업을 표시합니다. 딤 처리는 시스템이 담당합니다.
struct MicrophoneAlertView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var requestID = 0
    @State private var isRequesting = false
    @State private var showsSettingsAlert = false

    var onPermissionGranted: () -> Void = {}

    var body: some View {
        MicrophoneAccessView(
            onOpenSettings: openSettings,
            onRetry: { requestID += 1 }
        )
        .disabled(isRequesting)
        .task(id: requestID) {
            isRequesting = true
            defer { isRequesting = false }

            let granted = await MicrophonePermission.request()
            guard !Task.isCancelled else { return }

            if granted {
                onPermissionGranted()
            } else {
                // 거절 직후에는 안내 화면에 머무르고, 다시 확인할 때만 설정 알림을 띄웁니다.
                showsSettingsAlert = requestID > 0
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active, !isRequesting, MicrophonePermission.isGranted {
                onPermissionGranted()
            }
        }
        .alert("마이크 권한이 꺼져 있어요", isPresented: $showsSettingsAlert) {
            Button("취소", role: .cancel) {}
            Button("설정 열기", action: openSettings)
        } message: {
            Text("설정에서 마이크 접근을 허용해 주세요. 한 번 거절한 권한은 설정에서 변경할 수 있어요.")
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
