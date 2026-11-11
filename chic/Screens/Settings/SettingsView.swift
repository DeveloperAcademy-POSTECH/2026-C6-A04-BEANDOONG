import SwiftUI

/// 설정 화면
/// - 디자인: Hi-Fi iPhone 17 - 266(새 버전 있음) · 241(최신 버전 사용 중)
///
///     ┌ 상단 바: < 설정
///     ├ 앱 아이콘 + 버전 정보 ("최신 버전 …" / "현재 버전 …")
///     └ 정보 및 지원 카드: 개인정보 처리방침 · 문의하기
struct SettingsView: View {
    @Environment(\.designScale) private var scale
    @Environment(\.openURL) private var openURL
    @State private var showsMailCompose = false
    @State private var showsNoMailAlert = false
    /// 새 버전 번호. nil이면 "최신 버전 사용중"으로 표시 (버전 확인 기능은 아직 없음)
    var latestVersion: String? = nil

    /// 개인정보 처리방침 및 이용약관 (Notion 공개 페이지)
    static let privacyPolicyURL = URL(string: "https://continuous-aunt-5ff.notion.site/chic-40e194eb59d380eba395e8bc183cc53b")!
    /// 문의하기: 서비스 제공자 메일 (개인정보 처리방침에 적힌 주소)
    static let contactEmail = "beandoong.support@gmail.com"

    var body: some View {
        VStack(spacing: 0) {
            // MARK: 상단 바
            TopNavigationHeader(title: "설정", isDark: true)
                .padding(.top, Layout.topBarTop.v(scale))

            VStack(spacing: 0) {
            // MARK: 앱 아이콘 + 버전
            SettingsAppIcon()
                .designScaled(width: Layout.iconSize, height: Layout.iconSize, scale)
                .padding(.top, Layout.iconTop.v(scale))

            Text(latestVersion.map { "최신 버전 \($0)" } ?? "최신 버전 사용중")
                .font(.pretendard(.regular, size: 12))
                .foregroundStyle(AppColors.guideStepNumber)
                .padding(.top, Layout.latestVersionTop.v(scale))

            Text("현재 버전 \(Self.currentVersion)")
                .font(.pretendard(.medium, size: 16))
                .foregroundStyle(Color.white)
                .padding(.top, Layout.currentVersionTop.v(scale))

            // MARK: 정보 및 지원
            Text("정보 및 지원")
                .font(.pretendard(.bold, size: 16))
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, Layout.sectionTitleTop.v(scale))

            VStack(spacing: 0) {
                SettingsRow(symbol: "shield", title: "개인정보 처리방침") { openURL(Self.privacyPolicyURL) }
                Rectangle()
                    .fill(AppColors.settingsDivider)
                    .frame(height: 1)
                    .padding(.leading, Layout.dividerLeading)
                    .padding(.trailing, Layout.dividerTrailing)
                SettingsRow(symbol: "envelope", title: "문의하기") { contact() }
            }
            .padding(.vertical, Layout.cardVerticalPadding)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppColors.darkCard)
            )
            .padding(.top, Layout.cardTop.v(scale))

            Spacer(minLength: 0)
            }
            .padding(.horizontal, Layout.horizontalPadding.h(scale))
        }
        .ignoresSafeArea()
        .darkScreenBackground()
        .chicAlert(
            isPresented: showsNoMailAlert,
            title: "메일 계정이 없어요",
            message: "메일 앱에 계정을 추가하거나\n아래 주소로 직접 문의해 주세요\n\(Self.contactEmail)",
            cancelTitle: "닫기",
            confirmTitle: "주소 복사",
            onCancel: { showsNoMailAlert = false },
            onConfirm: {
                UIPasteboard.general.string = Self.contactEmail
                showsNoMailAlert = false
            }
        )
        .sheet(isPresented: $showsMailCompose) {
            MailComposeView(recipient: Self.contactEmail, subject: "[chic] 문의", body: Self.mailBody)
                .ignoresSafeArea()
        }
    }

    /// 애플 메일 작성 화면을 모달로 띄워요. 메일 계정이 없어 못 띄우면 안내 팝업을 보여 줘요.
    private func contact() {
        if MailComposeView.canSend {
            showsMailCompose = true
        } else {
            showsNoMailAlert = true
        }
    }

    /// 문의 메일 본문: 위쪽은 비워 두고, 아래에 문의 처리에 필요한 앱·기기 정보를 적어 둬요.
    private static var mailBody: String {
        let device = UIDevice.current
        return "\n\n\n---\n앱 버전: \(currentVersion)\n기기: \(device.model) · iOS \(device.systemVersion)\n"
    }

    /// Info.plist 버전(1.0.0)을 시안 표기(1.00.0)로 바꿔 보여 줍니다.
    private static var currentVersion: String {
        let raw = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let parts = raw.split(separator: ".").map { Int($0) ?? 0 } + [0, 0, 0]
        return "\(parts[0]).\(String(format: "%02d", parts[1])).\(parts[2])"
    }
}

// MARK: - 앱 아이콘

/// 설정 상단의 앱 아이콘: 어두운 둥근 사각형 + 소리 막대 (유리 테두리는 근사 표현)
private struct SettingsAppIcon: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppColors.darkBackground)
            AssetImageView(name: "IllustSoundBars", width: 47.3, height: 71.4)
                .offset(x: -0.5, y: -0.9)
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.55), Color.white.opacity(0.06), Color.white.opacity(0.45)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        }
        .frame(width: 98.5, height: 98.5)
        .shadow(color: Color.white.opacity(0.14), radius: 14)
        .accessibilityHidden(true)
    }
}

// MARK: - 목록 한 줄

private struct SettingsRow: View {
    let symbol: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                Image(systemName: symbol)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(AppColors.guideStepNumber)
                    .frame(width: 26.5, height: 26.5)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(AppColors.settingsIconTile)
                    )
                    .padding(.leading, 11.5)

                Text(title)
                    .font(.pretendard(.regular, size: 16))
                    .foregroundStyle(Color.white)
                    .padding(.leading, 18.5)

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColors.settingsChevron)
                    .padding(.trailing, 19)
            }
            .frame(height: 47)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Layout (iPhone 17 시안 측정값, pt)

private enum Layout {
    static let horizontalPadding: CGFloat = 20
    static let topBarTop: CGFloat = 84           // 화면 위 ↔ 상단 바 (Hi-Fi 266: 글자 y0 86.5 − 2.5)
    static let iconSize: CGFloat = 98.5          // Hi-Fi 266: 152 ~ 250.5
    static let iconTop: CGFloat = 51             // 상단 바 아래(104) ↔ 아이콘 (Hi-Fi 266: y0 155)
    static let latestVersionTop: CGFloat = 20.5  // 아이콘 ↔ "최신 버전" (253.5 → 275.5, 글자 보정)
    static let currentVersionTop: CGFloat = 3    // ↔ "현재 버전" (286.5 → 294, 측정 보정)
    static let sectionTitleTop: CGFloat = 47     // ↔ "정보 및 지원" (309 → 360)
    static let cardTop: CGFloat = 13             // 섹션 제목 ↔ 카드 (375 → 390)
    static let cardVerticalPadding: CGFloat = 3
    static let dividerLeading: CGFloat = 57      // Hi-Fi 266: 구분선 x 77 (카드 왼쪽 20)
    static let dividerTrailing: CGFloat = 12
}

// MARK: - 이 화면 전용 색상

private extension AppColors {
    static let settingsIconTile = Color(hex: 0x263947)
    static let settingsDivider = Color(hex: 0x3C3E43)
}

#Preview {
    SettingsView(latestVersion: "1.00.3")
}
