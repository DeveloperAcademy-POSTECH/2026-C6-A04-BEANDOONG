import SwiftUI

/// 온보딩 3페이지 인디케이터: 현재 페이지는 긴 캡슐(38x11), 나머지는 점(11x11)
///
///     activeIndex = 1  →  ●  ━━  ●
struct OnboardingPageIndicator: View {
    /// 현재 페이지 (0부터 시작)
    let activeIndex: Int

    private let pageCount = 3

    var body: some View {
        HStack(spacing: 7) {
            ForEach(0..<pageCount, id: \.self) { idx in
                if idx == activeIndex {
                    Capsule()
                        .fill(AppColors.pageIndicatorActive)
                        .frame(width: 38, height: 11)
                } else {
                    Circle()
                        .fill(AppColors.pageIndicatorInactive)
                        .frame(width: 11, height: 11)
                }
            }
        }
    }
}
