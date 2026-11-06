import SwiftUI

/// 결과를 저장하고 준비하는 동안 표시합니다. ListeningView와 같은 스피너(LoadingSpinner)를 사용합니다.
/// - 디자인: Hi-Fi 연습 결과 – 결과 로딩중 (iPhone 17 - 220)
///
///     ┌ 타이틀 "연습 결과 로딩 중" + 설명
///     └ 로딩 스피너 (상단 바·정지 버튼 없이 소리 확인 중 화면과 같은 위치)
struct PracticeResultLoadingView: View {
    var body: some View {
        VStack(spacing: 0) {
            Text("연습 결과 로딩 중")
                .font(.pretendard(.bold, size: 26))
                .foregroundStyle(PracticeResultColors.primaryText)
                .padding(.top, Layout.titleTop)

            DarkScreenSubtitle("이번 연습을 함께 돌아봐요", color: PracticeResultColors.primaryText)
                .padding(.top, Layout.subtitleTop)

            LoadingSpinner()
                .padding(.top, Layout.spinnerTop)

            Spacer(minLength: 0)
        }
        .darkScreenBackground()
    }
}

// MARK: - Layout

/// Hi-Fi에서 제목·설명·스피너가 소리 확인 중 화면(`ListeningView`)과 같은 자리에 있어 같은 값을 씁니다.
private enum Layout {
    static let titleTop: CGFloat = 107    // 안전 영역 ↔ 타이틀 (소리 확인 중의 상단 바 13 + 20 + 74)
    static let subtitleTop: CGFloat = 14  // 타이틀 ↔ 설명
    static let spinnerTop: CGFloat = 192  // 설명 ↔ 스피너
}

#Preview {
    PracticeResultLoadingView()
}
