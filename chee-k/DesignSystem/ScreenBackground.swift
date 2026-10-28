import SwiftUI

extension View {
    /// 다크 화면 공통 배경: 화면 전체를 채우고, 안전 영역까지 `darkBackground`로 칠한 뒤 다크 모드로 고정합니다.
    func darkScreenBackground() -> some View {
        self
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColors.darkBackground.ignoresSafeArea())
            .preferredColorScheme(.dark)
    }
}
