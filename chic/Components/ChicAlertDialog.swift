import SwiftUI

/// 화면 위에 뜨는 흰색 확인 팝업 (스티밍 종료 · 기록 삭제 · 방 삭제에서 같이 써요)
/// - Hi-Fi 265: 팝업 x 40.5~362, y 345~529.5 (321.5x184.5), 화면 가운데
/// - 제목 + 설명(여러 줄 가능) + 버튼 2개 [취소(회색) | 확인(색 지정)], 버튼 142x48
///
///     ┌────────────────────────────┐
///     │ 스티밍이 끝났나요?            │
///     │ 스팀 소리가 감지되지 않아요     │
///     │ 연습을 마쳤다면 기록을 확인해 주세요 │
///     │ [ 계속 연습 ]  [ 연습 종료 ]   │
///     └────────────────────────────┘
struct ChicAlertDialog: View {
    @Environment(\.designScale) private var scale

    let title: String
    let message: String
    let cancelTitle: String
    let confirmTitle: String
    var confirmColor: Color = AppColors.alertBlue
    var onCancel: () -> Void = {}
    var onConfirm: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 글자는 버튼보다 안쪽에서 시작한다 (새 시안: 글자 x 63.5, 버튼 x 55)
            Group {
                Text(title)
                    .font(.pretendard(.semibold, size: Layout.titleSize))
                    .tracking(Layout.tracking)
                    .foregroundStyle(AppColors.alertTitle)
                    .padding(.top, Layout.titleTop.v(scale))

                Text(message)
                    .font(.pretendard(.regular, size: Layout.messageSize))
                    .tracking(Layout.tracking)
                    .lineSpacing(Layout.messageLineSpacing)
                    .foregroundStyle(AppColors.alertMessage)
                    .padding(.top, Layout.messageTop.v(scale))
            }
            .padding(.horizontal, Layout.textInset.h(scale))

            HStack(spacing: Layout.buttonSpacing.h(scale)) {
                alertButton(cancelTitle, background: AppColors.alertCancel, text: AppColors.alertTitle, action: onCancel)
                alertButton(confirmTitle, background: confirmColor, text: Color.white, action: onConfirm)
            }
            .padding(.top, Layout.buttonsTop.v(scale))
            .padding(.bottom, Layout.sidePadding.h(scale))
        }
        .padding(.horizontal, Layout.sidePadding.h(scale))
        .frame(width: Layout.width.h(scale), alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous)
                .fill(Color.white)
        )
    }

    private func alertButton(_ title: String, background: Color, text: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.pretendard(.bold, size: 16))
                .foregroundStyle(text)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 8)
                .frame(maxWidth: .infinity)
                .frame(height: Layout.buttonHeight)
                .background(Capsule().fill(background))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Layout (iPhone 17 시안 측정값, pt)

private enum Layout {
    static let width: CGFloat = 321.5       // Hi-Fi 265: 팝업 폭
    static let cornerRadius: CGFloat = 28   // Hi-Fi 265: 모서리 곡률
    static let sidePadding: CGFloat = 14.5  // 팝업 가장자리 ↔ 버튼 / 버튼 ↔ 팝업 아래
    static let tracking: CGFloat = -0.28    // 새 시안: 글자 폭(제목 134.5 · 설명 195.5/260pt)에 맞춘 자간
    static let textInset: CGFloat = 8.5     // 글자만 버튼보다 안쪽으로 (새 시안: 글자 x 63.5 − 버튼 x 55)
    static let titleSize: CGFloat = 18      // 새 시안: 제목 (세미볼드). 폰트는 정수 크기로 그려져 17.5가 안 됨 → 자간으로 폭을 맞춤
    static let messageSize: CGFloat = 18    // 새 시안: 설명 글자 높이 16pt
    static let messageLineSpacing: CGFloat = 0.5  // 새 시안: 설명 줄 간격 22pt
    static let titleTop: CGFloat = 21.7     // 팝업 위 ↔ 제목
    static let messageTop: CGFloat = 10.8     // 제목 ↔ 설명
    static let buttonsTop: CGFloat = 24     // 설명 ↔ 버튼
    static let buttonSpacing: CGFloat = 8
    static let buttonHeight: CGFloat = 48
    static let dimOpacity: Double = 0.58    // 뒤 화면을 덮는 검정 (Hi-Fi 254·265)
}

// MARK: - 팝업 표시

/// 화면을 어둡게 덮고(검정 58%) 위에서 345pt 자리에 `ChicAlertDialog`를 놓는 레이어
/// - Hi-Fi 254·265: 팝업 위쪽이 화면 위에서 345pt에 고정 (내용 높이에 따라 아래로만 늘어남)
/// - 기본 시스템 Alert처럼 나타난다: 딤은 서서히 어두워지고, 팝업은 1.1배에서 1배로 줄어들며 떠오른다.
///   사라질 때는 짧게 흐려지기만 한다. 애니메이션은 `isPresented` 값이 바뀔 때 여기서 알아서 한다
///   (부르는 쪽이 `withAnimation`을 쓰지 않아도 된다).
private struct ChicAlertLayer: View {
    @Environment(\.designScale) private var scale
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let isPresented: Bool
    let title: String
    let message: String
    let cancelTitle: String
    let confirmTitle: String
    let confirmColor: Color
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            if isPresented {
                Color.black.opacity(Layout.dimOpacity)
                    .ignoresSafeArea()
                    .onTapGesture(perform: onCancel)
                    .transition(.opacity)
                ChicAlertDialog(
                    title: title, message: message,
                    cancelTitle: cancelTitle, confirmTitle: confirmTitle,
                    confirmColor: confirmColor, onCancel: onCancel, onConfirm: onConfirm
                )
                .padding(.top, CGFloat(345).v(scale))
                .transition(dialogTransition)
            }
        }
        .ignoresSafeArea()
        .animation(isPresented ? AlertMotion.present : AlertMotion.dismiss, value: isPresented)
    }

    /// 나타날 때: 1.1배 → 1배 + 흐림 → 선명. 사라질 때: 흐려지기만. 동작 줄이기: 크기 변화 없이 투명도만
    private var dialogTransition: AnyTransition {
        guard !reduceMotion else { return .opacity }
        return .asymmetric(
            insertion: .scale(scale: AlertMotion.presentScale).combined(with: .opacity),
            removal: .opacity
        )
    }
}

private enum AlertMotion {
    /// 처음 크기 (시스템 Alert는 살짝 큰 상태에서 제자리로 줄어들며 나타난다)
    static let presentScale: CGFloat = 1.1
    static let present = Animation.timingCurve(MotionCurve.easeOutQuint, duration: 0.3)
    static let dismiss = Animation.easeOut(duration: 0.18)
}

extension View {
    /// 화면을 어둡게 덮고 `ChicAlertDialog`를 보여 줍니다.
    func chicAlert(
        isPresented: Bool,
        title: String,
        message: String,
        cancelTitle: String,
        confirmTitle: String,
        confirmColor: Color = AppColors.alertBlue,
        onCancel: @escaping () -> Void,
        onConfirm: @escaping () -> Void
    ) -> some View {
        self.overlay {
            ChicAlertLayer(
                isPresented: isPresented,
                title: title, message: message,
                cancelTitle: cancelTitle, confirmTitle: confirmTitle,
                confirmColor: confirmColor, onCancel: onCancel, onConfirm: onConfirm
            )
        }
    }
}

// MARK: - 색상

extension AppColors {
    /// 팝업 확인 버튼 기본(파랑) — Hi-Fi 265 측정
    static let alertBlue = Color(hex: 0x0088FF)
    /// 삭제 확인 버튼 — Hi-Fi 254 측정
    static let alertRed = Color(hex: 0xFF383C)
    /// 팝업 취소 버튼 배경 — Hi-Fi 265 측정
    static let alertCancel = Color(hex: 0xE9E9EA)
    static let alertTitle = Color(hex: 0x01030C)
    static let alertMessage = Color(hex: 0x8A8A8E)
    /// 상단 바 우측 아이콘 · 목록 화살표의 회색 — Hi-Fi 266 · 255 측정
    static let settingsChevron = Color(hex: 0xAEAEAE)
}
