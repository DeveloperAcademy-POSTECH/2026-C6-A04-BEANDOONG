import SwiftUI

/// 마이크 권한 요청 시스템 팝업 화면
/// - 디자인: Hi-Fi/iPhone 17 - 118.png
///
///     ┌ 뒤 배경: 마이크 권한 안내 화면(MicrophoneAccessView)
///     ├ 반투명 검정 딤 (45%)
///     └ 가운데 권한 다이얼로그 (320 x 228)
///         ├ 제목 + 설명
///         └ [허용안함] [허용]
struct MicrophoneAlertView: View {
    var body: some View {
        ZStack {
            // MARK: 뒤 배경 화면 + 딤
            MicrophoneAccessView()

            Color.black.opacity(0.45)
                .ignoresSafeArea()

            // MARK: 권한 다이얼로그 (x=41...360, y=322...550)
            MicrophonePermissionDialog()
                .offset(y: -14)
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - 권한 다이얼로그

/// iOS 시스템 알림 모양을 흉내 낸 흰색 다이얼로그 (320 x 228, 모서리 28)
private struct MicrophonePermissionDialog: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 제목 (디자인과 동일하게 줄바꿈 위치를 고정)
            Text("chic이(가) 마이크에 접근하려고 합니\n다.")
                .font(.pretendard(.semibold, size: 17))
                .lineSpacing(4)
                .foregroundStyle(AppColors.dialogTitle)
                .padding(.top, 22)

            // 설명
            Text("우유 스티밍 소리를 실시간으로 분석하\n고, 현재 상태를 화면 색상으로 안내하기\n위해 마이크를 사용합니다.")
                .font(.pretendard(.regular, size: 15))
                .lineSpacing(4)
                .foregroundStyle(AppColors.dialogMessage)
                .padding(.top, 12)

            Spacer(minLength: 0)

            // 버튼 2개 (가로 반반)
            HStack(spacing: 8) {
                DialogButton(
                    title: "허용안함",
                    textColor: AppColors.dialogTitle,
                    fillColor: AppColors.dialogDenyButton
                )
                DialogButton(
                    title: "허용",
                    textColor: Color.white,
                    fillColor: AppColors.dialogAllowButton
                )
            }
            .padding(.bottom, 16)
        }
        .padding(.horizontal, 20)
        .frame(width: 320, height: 228)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white)
        )
    }
}

/// 다이얼로그 하단의 캡슐 버튼 (높이 46, 가로는 남은 폭을 채움)
private struct DialogButton: View {
    let title: String
    let textColor: Color
    let fillColor: Color

    var body: some View {
        Button(action: {}) {
            Text(title)
                .font(.pretendard(.bold, size: 16))
                .foregroundStyle(textColor)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(
                    Capsule()
                        .fill(fillColor)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 이 화면 전용 색상

private extension AppColors {
    static let dialogTitle = Color(hex: 0x0A0A0A)
    static let dialogMessage = Color(hex: 0x6C6C70)
    static let dialogDenyButton = Color(hex: 0xE5E5EA)
    static let dialogAllowButton = Color(hex: 0x0088FF)
}

struct MicrophoneAlertView_Previews: PreviewProvider {
    static var previews: some View {
        MicrophoneAlertView()
    }
}
