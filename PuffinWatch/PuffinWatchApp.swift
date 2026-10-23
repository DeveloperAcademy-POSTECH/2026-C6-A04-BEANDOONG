// Watch는 iPhone의 공기음 판정을 보여 주고 진동만 재생합니다.
import SwiftUI

@main struct PuffinWatchApp: App {
    var body: some Scene { WindowGroup { WatchInputView() } }
}

private struct WatchInputView: View {
    // 수신 객체가 iPhone 메시지를 화면 상태로 바꿉니다.
    @StateObject private var receiver = PulseReceiver()
    private var ink: Color { receiver.active ? PuffinStyle.greenInk : .white }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("chee-k").font(.caption.bold())
            // 연결, 연습, 공기음 상태를 글자로도 구분합니다.
            Text(!receiver.connected ? "iPhone 연결 대기" : !receiver.running ? "iPhone에서 연습 시작" : receiver.active ? "공기 주입 소리" : "공기음 미감지")
                .font(.system(size: 20, weight: .bold))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("pulse.status")
            Text("iPhone에서 시작하면 결과를 표시해요.")
                .font(.caption2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding()
        .background((receiver.active ? PuffinStyle.mint : PuffinStyle.night).ignoresSafeArea())
        .foregroundStyle(ink)
        .preferredColorScheme(receiver.active ? .light : .dark)
        // 1초마다 수신 시각을 확인해 끊긴 연결의 이전 표시를 제거합니다.
        .task {
            while !Task.isCancelled {
                receiver.expireIfNeeded()
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }
}
