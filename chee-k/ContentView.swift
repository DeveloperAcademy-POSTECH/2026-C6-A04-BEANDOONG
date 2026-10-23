// iPhone 앱의 첫 화면입니다. 실제 연습 UI는 Shared/PulseInputView.swift에 있습니다.
import SwiftUI

// 임시 메인 화면으로 스티밍 소리 분석과 기준값 조절 기능을 확인한다.
struct ContentView: View {
    var body: some View {
        PulseInputView()
    }
}

#Preview {
    ContentView()
}
