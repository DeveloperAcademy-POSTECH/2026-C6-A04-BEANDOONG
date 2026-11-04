import SwiftUI

extension View {
    /// 다크 화면 공통 배경: 화면 전체를 채우고, 안전 영역까지 `darkBackground`로 칠한 뒤 다크 모드로 고정합니다.
    func darkScreenBackground() -> some View {
        self
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColors.darkBackground.ignoresSafeArea())
            .preferredColorScheme(.dark)
    }

    /// 다크 화면 공통 배경 + 화면 위쪽 가운데에서 퍼지는 은은한 네이비 글로우
    /// (온보딩, 마이크 권한, 워치 연결, 빈 히스토리 화면에서 사용)
    ///
    /// Hi-Fi 측정값: 위쪽 가운데가 가장 밝고(`darkTopGlow`), 약 400pt 떨어진 곳에서 배경색과 같아집니다.
    func darkScreenBackgroundWithTopGlow() -> some View {
        self
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                RadialGradient(
                    colors: [AppColors.darkTopGlow, AppColors.darkBackground],
                    center: .top,
                    startRadius: 0,
                    endRadius: TopGlow.radius
                )
                .background(AppColors.darkBackground)
                .ignoresSafeArea()
            }
            .preferredColorScheme(.dark)
    }
}

// MARK: - 상단 글로우

private enum TopGlow {
    /// 글로우가 배경색으로 완전히 사라지는 거리
    static let radius: CGFloat = 400
}
