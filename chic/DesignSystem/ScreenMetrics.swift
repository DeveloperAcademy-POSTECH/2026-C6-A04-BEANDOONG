import SwiftUI

/// 여러 화면이 같이 쓰는 치수 (iPhone 17 시안 기준 pt)
///
/// 세로 위치 · 간격은 `.v(scale)`, 가로 폭은 `.h(scale)` 로 바꿔 써요 (`DesignScale` 참고).
/// 화면 하나에서만 쓰는 값은 그 화면의 `Layout` 에 두고, 여기에는 **같은 값이 여러 화면에 반복되는 것**만 둬요.
///
/// 치수 묶음 이름 규칙 (파일 안 `private enum`):
/// - `Layout`: 화면 · 컴포넌트의 배치 값 (위치 · 간격 · 폭 · 모서리)
/// - `Spec`: 일러스트의 사양 (크기 · 이미지 이름 · 그림 안 좌표)
/// - `…Motion`: 타이밍 · 곡선 (`BarMotion` · `SpinnerMotion` · `AlertMotion` · `PageTurnMotion`)
enum ScreenMetrics {
    // MARK: 상단 바 · 하단 버튼

    /// 화면 위 ↔ 상단 바 (Hi-Fi 글자 y0 86.5 − 2.5)
    /// - 설정 · 기록 · 결과 리포트 · 온보딩 · 연습 준비 · 마이크 권한 · 워치 연결 화면이 같은 자리에 상단 바를 둬요.
    static let topBarTop: CGFloat = 84
    /// 하단 큰 버튼 폭 (Hi-Fi 버튼 폭). 높이와 아래 간격은 `BottomButton` 이에요.
    static let bottomButtonWidth: CGFloat = 363

    // MARK: 타이틀 · 설명

    /// 타이틀 ↔ 설명 (기본)
    /// - 워치 상태 화면 5곳 · 결과 로딩 · 스티밍 피드백
    static let subtitleTop: CGFloat = 14
    /// 타이틀 ↔ 설명 (간격이 조금 좁은 쪽)
    /// - 온보딩 소개 쪽 4곳(우유 수위 · 워치 · 리뷰 · 소리) · 애플 워치 연결 안내(`WatchSetupView`)
    static let compactSubtitleTop: CGFloat = 11

    // MARK: 워치 상태 화면

    /// 워치 연결 화면(연결 확인 중 · 못 찾음 · 앱 설치 · 준비 완료)이 같이 쓰는 배치:
    /// 상단 바 → 워치 일러스트 → 타이틀 → 설명 (세로 위치는 모두 바로 위 요소 기준 간격이에요)
    ///
    /// 같은 골격이지만 값이 다른 화면: 애플 워치 연결 안내(`WatchSetupView`: 일러스트가 아이폰 + 워치 230×193 이라 143.5 / 68 / 11),
    /// 마이크 권한(`MicrophoneAccessView`: 131 / 75.5 / 15). 이 화면들은 자기 `Layout` 값을 그대로 둬요.
    enum WatchStatus {
        /// 상단 바 ↔ 일러스트 (Hi-Fi 측정 후 보정)
        static let illustrationTop: CGFloat = 130.5
        /// 일러스트 ↔ 타이틀
        static let titleTop: CGFloat = 76
        /// 타이틀 ↔ 설명
        static let subtitleTop: CGFloat = ScreenMetrics.subtitleTop
        /// 워치 일러스트 크기 (`.designScaled(size:_:)` 에 넘겨요)
        static let illustrationSize = CGSize(width: 121, height: 207)
    }
}
