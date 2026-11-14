import SwiftUI

// 화면에서 필요한 동작을 전달합니다. 아직 연결하지 않은 화면은 기본 빈 동작을 사용합니다.

// MARK: - 다크 화면 버튼 (363 x 52)

/// 다크 화면 주요 버튼: 하늘색 캡슐 + 검정 텍스트
/// 화면 하단 큰 버튼의 공통 치수 (시안: 버튼 위 754.5 ~ 아래 809.5, 화면 아래와 64.5 간격). 모든 하단 버튼 화면이 같은 자리에 오도록 여기서만 정한다.
enum BottomButton {
    static let height: CGFloat = 55
    static let bottomGap: CGFloat = 64.5
}

struct DarkPrimaryButton: View {
    let title: String
    /// 버튼 폭 (기본 363 = iPhone 17 시안. 다른 기기에서는 `363.h(scale)`을 넘깁니다)
    var width: CGFloat = 363
    var height: CGFloat = 52
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.pretendard(.bold, size: 16))
                .foregroundStyle(AppColors.darkChipTextSelected)
                .frame(width: width, height: height)
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
    var width: CGFloat = 363
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.pretendard(.bold, size: 16))
                .foregroundStyle(AppColors.darkChipTextSelected)
                .frame(width: width, height: 52)
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
    var width: CGFloat = 363
    /// 두 버튼 사이 간격. 버튼 높이 52가 고정이라 간격도 모든 기기에서 11로 고정한다(비율로 바꾸면 화면이 짧은 기기에서 버튼이 붙는다)
    var spacing: CGFloat = 11
    var primaryAction: () -> Void = {}
    var secondaryAction: () -> Void = {}

    var body: some View {
        VStack(spacing: spacing) {
            DarkPrimaryButton(title: primaryTitle, width: width, action: primaryAction)
            DarkSecondaryButton(title: secondaryTitle, width: width, action: secondaryAction)
        }
    }
}

// MARK: - 스티밍 정지 버튼

/// 스티밍 화면 하단 중앙의 원형 정지 버튼: 아주 옅은 하늘빛 흰 원(82) 안에 정사각형(25)
struct SteamingStopButton: View {
    /// 가운데 정사각형 색상 (화면 배경색에 맞춤)
    let squareColor: Color
    var action: () -> Void = {}
    /// 바깥 원 색상 (순백보다 아주 옅은 하늘빛)
    private let circleColor = Color(hex: 0xF5FAFF)

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(circleColor)
                    .frame(width: 82, height: 82)
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(squareColor)
                    .frame(width: 25, height: 25)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: "연습 종료"))
    }
}

// MARK: - 스티밍 종료하기 버튼

/// 스티밍 피드백 화면 하단의 "종료하기" 캡슐 버튼: 옅은 하늘빛 흰 캡슐(274x60) 안에 상태색 사각형(20) + 글자
/// - Hi-Fi 160: 캡슐 x 64~338, y 720~780 / 사각형 20x20(모서리 3) / 글자와 간격 9
struct SteamingEndButton: View {
    /// 사각형 색상 (화면 배경 아래쪽 색 = 상태 팔레트 색)
    let squareColor: Color
    /// 버튼 폭 (기본 274 = iPhone 17 시안. 다른 기기에서는 `274.h(scale)`을 넘깁니다)
    var width: CGFloat = 274
    /// 캡슐 배경 불투명도 (기본 1 = 불투명. 새 연습 중 시안은 0.73으로 배경색이 비쳐요)
    var backgroundOpacity: Double = 1
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(squareColor)
                    .frame(width: 20, height: 20)
                Text(String(localized: "종료하기"))
                    .font(.pretendard(.semibold, size: 20))
                    .foregroundStyle(AppColors.darkChipTextSelected)
            }
            .frame(width: width, height: 60)
            .background(Capsule().fill(AppColors.darkSecondaryButton.opacity(backgroundOpacity)))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: "연습 종료"))
    }
}
