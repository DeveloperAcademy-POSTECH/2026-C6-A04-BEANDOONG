import SwiftUI

// 화면에서 필요한 동작을 전달합니다. 아직 연결하지 않은 화면은 기본 빈 동작을 사용합니다.

// MARK: - 다크 화면 버튼 (363 x 52)

/// 다크 화면 주요 버튼: 하늘색 캡슐 + 검정 텍스트
struct DarkPrimaryButton: View {
    let title: String
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.pretendard(.bold, size: 16))
                .foregroundStyle(AppColors.darkChipTextSelected)
                .frame(width: 363, height: 52)
                .background(
                    Capsule()
                        .fill(AppColors.darkChipSelected)
                )
        }
        .buttonStyle(.plain)
    }
}

/// 다크 화면 보조 버튼: 아주 옅은 하늘색 캡슐 + 검정 텍스트
struct DarkSecondaryButton: View {
    let title: String
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.pretendard(.bold, size: 16))
                .foregroundStyle(AppColors.darkChipTextSelected)
                .frame(width: 363, height: 52)
                .background(
                    Capsule()
                        .fill(AppColors.darkSecondaryButton)
                )
        }
        .buttonStyle(.plain)
    }
}

/// 다크 화면 하단의 [주요 버튼 / 보조 버튼] 세로 2단 묶음 (간격 11)
struct DarkButtonPair: View {
    let primaryTitle: String
    let secondaryTitle: String
    var primaryAction: () -> Void = {}
    var secondaryAction: () -> Void = {}

    var body: some View {
        VStack(spacing: 11) {
            DarkPrimaryButton(title: primaryTitle, action: primaryAction)
            DarkSecondaryButton(title: secondaryTitle, action: secondaryAction)
        }
    }
}

// MARK: - 라이트 화면 버튼 (361 x 51)

/// 라이트 화면 주요 버튼: 파란 캡슐 + 흰색 텍스트
struct LightPrimaryButton: View {
    let title: String

    var body: some View {
        Button(action: {}) {
            Text(title)
                .font(.pretendard(.bold, size: 16))
                .foregroundStyle(Color.white)
                .frame(width: 361, height: 51)
                .background(
                    Capsule()
                        .fill(AppColors.primaryButton)
                )
        }
        .buttonStyle(.plain)
    }
}

/// 라이트 화면 보조 버튼: 옅은 하늘색 캡슐 + 검정 텍스트
struct LightSecondaryButton: View {
    let title: String

    var body: some View {
        Button(action: {}) {
            Text(title)
                .font(.pretendard(.bold, size: 16))
                .foregroundStyle(AppColors.pureBlackTitle)
                .frame(width: 361, height: 51)
                .background(
                    Capsule()
                        .fill(AppColors.secondaryButton)
                )
        }
        .buttonStyle(.plain)
    }
}

/// 라이트 화면 하단의 [주요 버튼 / 보조 버튼] 세로 2단 묶음 (간격 13)
struct LightButtonPair: View {
    let primaryTitle: String
    let secondaryTitle: String

    var body: some View {
        VStack(spacing: 13) {
            LightPrimaryButton(title: primaryTitle)
            LightSecondaryButton(title: secondaryTitle)
        }
    }
}

// MARK: - 스티밍 정지 버튼

/// 스티밍 화면 하단 중앙의 원형 정지 버튼: 흰 원(82) 안에 정사각형(25)
struct SteamingStopButton: View {
    /// 가운데 정사각형 색상 (화면 배경색에 맞춤)
    let squareColor: Color

    var body: some View {
        Button(action: {}) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 82, height: 82)
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(squareColor)
                    .frame(width: 25, height: 25)
            }
        }
        .buttonStyle(.plain)
    }
}
