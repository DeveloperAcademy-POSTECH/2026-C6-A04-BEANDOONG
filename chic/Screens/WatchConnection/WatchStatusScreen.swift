import SwiftUI

/// 워치 연결 · 마이크 권한 화면이 같이 쓰는 틀: 상단 바 → 일러스트 → 타이틀 → 설명 → (아래쪽 버튼)
///
/// 세로 위치는 모두 바로 위 요소 기준 간격이에요. 기본값은 워치 상태 화면 4곳(연결 확인 중 · 못 찾음 · 앱 설치 · 준비 완료)이 같이 쓰는
/// `ScreenMetrics.WatchStatus` 예요. 같은 골격이지만 값이 다른 화면(애플 워치 연결 안내 · 마이크 권한)은 그 값을 넘겨요.
///
///     WatchStatusScreen(
///         title: String(localized: "Apple Watch 를\n찾지 못했어요"),
///         subtitle: String(localized: "…")
///     ) {
///         AssetImageView(name: "IllustWatchDisconnect", size: ScreenMetrics.WatchStatus.illustrationSize)
///     } footer: {
///         BottomPrimaryButton(title: String(localized: "다시 연결 확인하기"), action: onCheck)
///     }
struct WatchStatusScreen<Illustration: View, Footer: View>: View {
    /// 상단 바 제목 (기본: "애플 워치 연결")
    var headerTitle = String(localized: "애플 워치 연결")
    /// 상단 바 제목 굵기 (기본 medium. Hi-Fi 113 앱 설치 화면만 semibold)
    var headerTitleWeight: PretendardWeight = .medium
    /// 일러스트가 화면에 놓이는 크기 (iPhone 17 기준 pt, 다른 기기는 `designScaled` 가 키워요)
    var illustrationSize = ScreenMetrics.WatchStatus.illustrationSize
    /// 상단 바 ↔ 일러스트
    var illustrationTop = ScreenMetrics.WatchStatus.illustrationTop
    /// 일러스트 ↔ 타이틀
    var titleTop = ScreenMetrics.WatchStatus.titleTop
    /// 타이틀 ↔ 설명
    var subtitleTop = ScreenMetrics.WatchStatus.subtitleTop
    let title: String
    let subtitle: String
    @ViewBuilder let illustration: () -> Illustration
    /// 화면 맨 아래 버튼 (`BottomPrimaryButton`). 버튼이 없는 화면은 `EmptyView`
    @ViewBuilder let footer: () -> Footer

    @Environment(\.designScale) private var scale

    var body: some View {
        VStack(spacing: 0) {
            // MARK: 상단 네비게이션 바
            TopNavigationHeader(title: headerTitle, isDark: true, titleWeight: headerTitleWeight)
                .padding(.top, ScreenMetrics.topBarTop.v(scale))

            // MARK: 일러스트
            illustration()
                .designScaled(size: illustrationSize, scale)
                .padding(.top, illustrationTop.v(scale))

            // MARK: 타이틀 + 설명
            DarkScreenTitle(title)
                .padding(.top, titleTop.v(scale))

            DarkScreenSubtitle(subtitle)
                .padding(.top, subtitleTop.v(scale))

            Spacer(minLength: 0)

            // MARK: 하단 버튼
            footer()
        }
        .ignoresSafeArea()
        .darkScreenBackgroundWithTopGlow()
    }
}

extension WatchStatusScreen where Footer == EmptyView {
    /// 하단 버튼이 없는 화면
    init(
        headerTitle: String = String(localized: "애플 워치 연결"),
        headerTitleWeight: PretendardWeight = .medium,
        illustrationSize: CGSize = ScreenMetrics.WatchStatus.illustrationSize,
        illustrationTop: CGFloat = ScreenMetrics.WatchStatus.illustrationTop,
        titleTop: CGFloat = ScreenMetrics.WatchStatus.titleTop,
        subtitleTop: CGFloat = ScreenMetrics.WatchStatus.subtitleTop,
        title: String,
        subtitle: String,
        @ViewBuilder illustration: @escaping () -> Illustration
    ) {
        self.init(
            headerTitle: headerTitle, headerTitleWeight: headerTitleWeight, illustrationSize: illustrationSize,
            illustrationTop: illustrationTop, titleTop: titleTop, subtitleTop: subtitleTop,
            title: title, subtitle: subtitle, illustration: illustration, footer: { EmptyView() }
        )
    }
}
