import SwiftUI

/// 상단 행의 "워치 페어링" 알약 (연결됨: 초록 테두리·진초록 채움·✓ / 안 됨: 회색 테두리·회색 ✓)
/// - Hi-Fi 217·311: 91.5 x 27, 테두리 1.5, 아이콘 원 14, 글자 Regular 10
/// - 2026-11-14 시안부터 안 됨도 ✕ 대신 ✓ 이고, 색으로만 상태를 나눠요.
/// - 워치 연결 상태(`WatchConnection.isReachable`)는 이 배지가 직접 읽어요. 홈 본체가 읽으면 연결 상태가 바뀔 때마다
///   홈 전체가 다시 계산되는데, 이렇게 하면 배지만 다시 그려져요.
struct WatchPairingBadge: View {
    @EnvironmentObject private var connection: WatchConnection

    private var isConnected: Bool { connection.isReachable }

    var body: some View {
        HStack(spacing: 6) {
            ZStack {
                Circle().fill(accent)
                Image(systemName: "checkmark")
                    .font(.system(size: 7, weight: .black))
                    .foregroundStyle(AppColors.darkBackground)
            }
            .frame(width: 14, height: 14)

            Text(String(localized: "워치 페어링"))
                .font(.pretendard(.regular, size: 10))
                .foregroundStyle(accent)
        }
        .padding(.leading, 9.5)
        .padding(.trailing, 10)
        .frame(minWidth: 91, minHeight: 27)
        .background(Capsule().fill(isConnected ? AppColors.homeBadgeConnectedFill : Color.clear))
        .overlay(Capsule().strokeBorder(accent, lineWidth: 1.5))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isConnected ? String(localized: "워치 페어링됨") : String(localized: "워치 페어링 안 됨"))
    }

    private var accent: Color {
        isConnected ? AppColors.soundRolling : AppColors.homeBadgeDisconnected
    }
}

// MARK: - 이 화면 전용 색상

private extension AppColors {
    /// 워치 페어링 배지 — 연결됨 채움 / 안 됨 테두리·글자·아이콘 (Hi-Fi 311·217 측정)
    static let homeBadgeConnectedFill = Color(hex: 0x0A3A1B)
    static let homeBadgeDisconnected = Color(hex: 0xCCCCCC)
}
