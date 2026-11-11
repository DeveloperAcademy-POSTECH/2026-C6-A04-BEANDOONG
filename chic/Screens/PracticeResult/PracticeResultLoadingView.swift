import SwiftUI

/// 결과를 저장하고 준비하는 동안 표시합니다. ListeningView와 같은 스피너(LoadingSpinner)를 사용합니다.
/// - 디자인: Hi-Fi 연습 결과 – 결과 로딩중 (iPhone 17 - 220)
///
///     ┌ 타이틀 "연습 결과 로딩 중" + 설명
///     └ 로딩 스피너 (상단 바·정지 버튼 없이 소리 확인 중 화면과 같은 위치)
struct PracticeResultLoadingView: View {
    @Environment(\.designScale) private var scale
    var body: some View {
        VStack(spacing: 0) {
            Text("연습 결과 로딩 중")
                .font(.pretendard(.bold, size: 26))
                .foregroundStyle(PracticeResultColors.primaryText)
                .padding(.top, Layout.titleTop.v(scale))

            DarkScreenSubtitle("이번 연습을 함께 돌아봐요", color: PracticeResultColors.primaryText)
                .padding(.top, Layout.subtitleTop.v(scale))

            LoadingSpinner()
                .designScaled(width: 62, height: 70, scale)
                .padding(.top, Layout.spinnerTop.v(scale))

            Spacer(minLength: 0)
        }
        .ignoresSafeArea()
        .darkScreenBackground()
    }
}

// MARK: - Layout

/// Hi-Fi에서 제목·설명·스피너가 소리 확인 중 화면(`ListeningView`)과 같은 자리에 있어 같은 값을 씁니다.
private enum Layout {
    static let titleTop: CGFloat = 171.5  // 화면 위 ↔ 타이틀 (Hi-Fi 220: 글자 y0 175, 프레임 보정)
    static let subtitleTop: CGFloat = 14  // 타이틀 ↔ 설명
    static let spinnerTop: CGFloat = 193  // 설명 ↔ 스피너
}

#Preview {
    PracticeResultLoadingView()
}
