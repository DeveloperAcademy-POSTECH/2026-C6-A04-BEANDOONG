import SwiftUI

/// 결과를 저장하고 준비하는 동안 표시합니다. ListeningView와 같은 스피너 에셋을 사용합니다.
struct PracticeResultLoadingView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isRotating = false

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Text("연습 결과 로딩 중")
                    .font(.pretendard(.bold, size: 26))
                    .foregroundStyle(PracticeResultColors.primaryText)
                    .padding(.top, geometry.size.height * 0.14)

                DarkScreenSubtitle("이번 연습을 함께 돌아봐요", color: PracticeResultColors.primaryText)
                    .padding(.top, 14)

                AssetImageView(name: "IllustSpinner", width: 72, height: 80)
                    .rotationEffect(.degrees(isRotating ? 360 : 0))
                    .padding(.top, geometry.size.height * 0.23)
                    .accessibilityHidden(true)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .darkScreenBackground()
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) { isRotating = true }
        }
    }
}

#Preview {
    PracticeResultLoadingView()
}
