import SwiftUI

/// 스플래시 화면
/// - 디자인: Hi-Fi/iPhone 17 - 92.png
///
///     ┌ 배경: 검정 + 좌상단/우하단 네이비 글로우
///     └ 화면 중앙(살짝 위) chic 로고
struct LaunchView: View {
    var body: some View {
        ZStack {
            // MARK: 배경
            AppColors.darkBackground
                .ignoresSafeArea()
            LaunchGlow.topLeading
            LaunchGlow.bottomTrailing

            // MARK: 로고 (화면 중앙에서 37pt 위)
            Image("ChicLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 162, height: 60)
                .offset(y: -37)
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - 배경 글로우

/// 배경 모서리에 은은하게 퍼지는 네이비 원형 그라데이션
private enum LaunchGlow {
    /// 상단 좌측 글로우
    static var topLeading: some View {
        RadialGradient(
            colors: [
                Color(hex: 0x162238, opacity: 0.85),
                Color(hex: 0x02040D, opacity: 0.0)
            ],
            center: .topLeading,
            startRadius: 10,
            endRadius: 340
        )
        .ignoresSafeArea()
    }

    /// 하단 우측 글로우
    static var bottomTrailing: some View {
        RadialGradient(
            colors: [
                Color(hex: 0x26354A, opacity: 0.85),
                Color(hex: 0x02040D, opacity: 0.0)
            ],
            center: .bottomTrailing,
            startRadius: 10,
            endRadius: 360
        )
        .ignoresSafeArea()
    }
}

struct LaunchView_Previews: PreviewProvider {
    static var previews: some View {
        LaunchView()
    }
}
