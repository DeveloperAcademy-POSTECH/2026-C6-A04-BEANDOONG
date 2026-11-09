import SwiftUI

/// 스플래시 화면
/// - 디자인: Hi-Fi/iPhone 17 - 92.png
///
///     ┌ 배경: 검정 + 좌상단/우하단 네이비 글로우
///     └ 화면 중앙(살짝 위) chic 로고 (SplashLogoReveal 등장 애니메이션)
struct LaunchView: View {
    var body: some View {
        ZStack {
            // MARK: 배경
            AppColors.darkBackground
                .ignoresSafeArea()
            LaunchGlow.topLeading
            LaunchGlow.bottomTrailing

            // MARK: 로고 (화면 중앙에서 35pt 위) — 조각별로 떠오르며 흐림이 걷히는 등장 애니메이션
            SplashLogoReveal()
                .offset(y: -35)
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - 표시 시간

/// 앱을 켰을 때 스플래시를 보여 주는 시간 (AppRootView 가 사용)
enum SplashTiming {
    /// 로고 등장 애니메이션(1.35초)이 끝난 뒤 로고를 잠깐 더 보여 주는 시간
    private static let holdAfterReveal: TimeInterval = 0.5
    /// 스플래시를 보여 주는 시간 (로고 등장 + 머무름)
    static let displayDuration: TimeInterval = SplashLogoReveal.revealDuration + holdAfterReveal
    /// 스플래시가 걷히며 다음 화면이 드러나는 시간
    static let fadeOutDuration: TimeInterval = 0.35
}

// MARK: - 배경 글로우

/// 배경 모서리에 은은하게 퍼지는 네이비 원형 그라데이션
private enum LaunchGlow {
    /// 상단 좌측 글로우
    static var topLeading: some View {
        RadialGradient(
            colors: [
                Color(hex: 0x323E50),
                Color(hex: 0x01030C, opacity: 0.0)
            ],
            center: .topLeading,
            startRadius: 0,
            endRadius: 380
        )
        .ignoresSafeArea()
    }

    /// 하단 우측 글로우
    static var bottomTrailing: some View {
        RadialGradient(
            colors: [
                Color(hex: 0x3E4C61),
                Color(hex: 0x01030C, opacity: 0.0)
            ],
            center: .bottomTrailing,
            startRadius: 0,
            endRadius: 375
        )
        .ignoresSafeArea()
    }
}

struct LaunchView_Previews: PreviewProvider {
    static var previews: some View {
        LaunchView()
    }
}
