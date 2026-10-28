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
            ZStack {
                ChicVectorLogo()
                    .frame(width: 150, height: 52)

                Image("ChicLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 162, height: 60)
            }
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

// MARK: - 벡터 로고

/// 이미지 로고 뒤에 깔리는 벡터 로고: 사운드 웨이브 바 3개 + "chic" 텍스트 (그라데이션)
private struct ChicVectorLogo: View {
    var body: some View {
        HStack(alignment: .bottom, spacing: 5) {
            // 좌측 3개 사운드 웨이브 바 (점점 길어짐)
            HStack(alignment: .center, spacing: 4) {
                Capsule()
                    .frame(width: 4, height: 14)
                Capsule()
                    .frame(width: 5, height: 24)
                Capsule()
                    .frame(width: 6, height: 34)
            }
            .padding(.bottom, 2)

            Text("chic")
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .tracking(-2)
        }
        .foregroundStyle(
            LinearGradient(
                colors: [
                    Color(hex: 0x4E6D8C),
                    Color(hex: 0x8EB2D6),
                    Color(hex: 0xA9CAEB)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }
}

struct LaunchView_Previews: PreviewProvider {
    static var previews: some View {
        LaunchView()
    }
}
