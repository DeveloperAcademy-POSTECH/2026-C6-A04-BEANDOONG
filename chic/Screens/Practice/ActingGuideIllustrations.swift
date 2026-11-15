import SwiftUI

/// 피처와 안내선은 3x 에셋, 주석은 번역·VoiceOver가 가능한 실제 텍스트예요.
struct ActingPositionIllustration: View {
    var body: some View {
        AssetImageView(name: "IllustActingPosition", width: 242, height: 377)
            .accessibilityHidden(true)
            .overlay(alignment: .topLeading) {
                Text(String(localized: "피처를 기울여요"))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(width: 80, alignment: .leading)
                    .padding(.leading, 162)
                    .padding(.top, 85)
            }
            .overlay(alignment: .topLeading) {
                Text(String(localized: "중앙"))
                    .font(.pretendard(.regular, size: 11))
                    .foregroundStyle(AppColors.darkSubtitle)
                    .padding(.leading, 40)
                    .padding(.top, 258)
            }
            .overlay(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(String(localized: "팁 시작 위치 예시"))
                    Text(String(localized: "중앙에서 살짝 옆,\n벽에 닿지 않게"))
                        .foregroundStyle(AppColors.darkSubtitle)
                        .lineSpacing(2)
                }
                .fixedSize(horizontal: false, vertical: true)
                .frame(width: 108, alignment: .leading)
                .padding(.leading, 134)
                .padding(.top, 327)
            }
            .font(.pretendard(.regular, size: 12))
            .foregroundStyle(AppColors.guideStepNumber)
            .accessibilityElement(children: .combine)
    }
}

/// 도해 위의 주석만 원본 안내선 위치에 맞추고, 관련 문구는 VStack으로 묶어요.
struct ActingSteamingIllustration: View {
    let image: String

    var body: some View {
        AssetImageView(name: image, width: 278, height: 194)
            .accessibilityHidden(true)
            .overlay(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "팁 위치"))
                    Text(String(localized: "우유 표면에 가까이"))
                        .foregroundStyle(AppColors.darkSubtitle)
                }
                .fixedSize(horizontal: false, vertical: true)
                .frame(width: 89, alignment: .leading)
                .padding(.leading, 189)
                .padding(.top, 75)
            }
            .overlay(alignment: .topLeading) {
                Text(String(localized: "피처 내리기"))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(width: 82, alignment: .leading)
                    .padding(.leading, 196)
                    .padding(.top, 153)
            }
            .font(.pretendard(.regular, size: 12))
            .foregroundStyle(AppColors.guideStepNumber)
            .accessibilityElement(children: .combine)
    }
}
