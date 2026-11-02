#if DEBUG
import SwiftUI

/// 디버거 없이 최근 피드백 수신과 진동 호출을 확인하는 임시 진단 화면입니다.
struct WatchFeedbackDiagnosticsView: View {
    @ObservedObject var haptics: WatchFeedbackHaptics

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("진동 진단").font(.headline)
                Button("직접 진동 테스트", action: haptics.testHaptic)
                Divider()
                Text(haptics.history.isEmpty ? "아직 처리한 상태가 없어요" : haptics.history.joined(separator: "\n"))
            }
            .font(.caption)
        }
    }
}
#endif
