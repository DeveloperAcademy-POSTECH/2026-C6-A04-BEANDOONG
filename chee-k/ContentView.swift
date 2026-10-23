// iPhone 앱의 첫 화면입니다. 실제 연습 UI는 Shared/PulseInputView.swift에 있습니다.
import SwiftUI // iPhone 첫 화면을 SwiftUI View로 정의합니다.

// 임시 메인 화면으로 스티밍 소리 분석과 기준값 조절 기능을 확인한다.
struct ContentView: View {
    var body: some View {
        // 앱 진입점은 실제 연습 화면에 연결하는 얇은 통로만 맡습니다.
        PulseInputView()
    }
}

#Preview {
    ContentView()
}
