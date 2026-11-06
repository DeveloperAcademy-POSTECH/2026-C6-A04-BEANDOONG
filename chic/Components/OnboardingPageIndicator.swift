import SwiftUI

/// 온보딩 3페이지 인디케이터: 현재 페이지는 긴 캡슐(38x11), 나머지는 점(11x11)
///
///     activeIndex = 1  →  ●  ━━  ●
///
/// 점과 캡슐을 같은 캡슐 모양으로 그리고 폭과 색만 바꿔요.
/// 그래서 `activeIndex`를 애니메이션과 함께 바꾸면, 캡슐이 다음 자리로 폭·색이 이어서 바뀌며 옮겨 가요.
struct OnboardingPageIndicator: View {
    /// 현재 페이지 (0부터 시작)
    let activeIndex: Int

    private let pageCount = 3

    var body: some View {
        HStack(spacing: 7) {
            ForEach(0..<pageCount, id: \.self) { idx in
                let isActive = idx == activeIndex
                Capsule()
                    .fill(isActive ? AppColors.pageIndicatorActive : AppColors.pageIndicatorInactive)
                    .frame(width: isActive ? 38 : 11, height: 11)
            }
        }
    }
}
