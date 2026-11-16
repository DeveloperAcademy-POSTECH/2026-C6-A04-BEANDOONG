import SwiftUI

/// 마이크 권한 안내 화면 (권한이 꺼져 있을 때 설정으로 유도)
/// - 디자인: Hi-Fi/iPhone 17 - 115.png
///
///     ┌ 상단 네비게이션 바: 마이크 설정
///     ├ 마이크 일러스트
///     ├ 타이틀 + 설명
///     └ 하단 버튼: [설정 열기]
struct MicrophoneAccessView: View {
    var onOpenSettings: () -> Void = {}

    var body: some View {
        // 워치 연결 화면과 같은 틀이고, 일러스트 크기와 위치 값만 달라요.
        WatchStatusScreen(
            headerTitle: String(localized: "마이크 설정"),
            illustrationSize: Layout.illustrationSize,
            illustrationTop: Layout.illustrationTop,
            titleTop: Layout.titleTop,
            subtitleTop: Layout.subtitleTop,
            title: String(localized: "공기주입 상태를 분석하려면\n마이크 권한이 필요해요"),
            subtitle: String(localized: "기기 설정에서 chic의 마이크 접근을\n허용한 뒤 돌아와 주세요")
        ) {
            AssetImageView(name: "IllustMic", size: Layout.illustrationSize)
        } footer: {
            BottomPrimaryButton(title: String(localized: "설정 열기"), action: onOpenSettings)
        }
    }
}

// MARK: - Layout

private enum Layout {
    static let illustrationSize = CGSize(width: 93, height: 165)
    static let illustrationTop: CGFloat = 131  // 네비게이션 바 ↔ 일러스트 (Hi-Fi 측정 후 보정)
    static let titleTop: CGFloat = 75.5  // 일러스트 ↔ 타이틀
    static let subtitleTop: CGFloat = 15  // 타이틀 ↔ 설명
}

#Preview {
    MicrophoneAccessView()
}
