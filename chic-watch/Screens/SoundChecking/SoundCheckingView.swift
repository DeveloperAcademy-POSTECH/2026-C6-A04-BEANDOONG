//
//  SoundCheckingView.swift
//
//  연습 중 실시간 피드백을 보여주기 전, 앱이 아직 소리를 판단하지 못했을 때 보이는 대기 화면입니다.
//
//  화면만 그립니다. X 버튼은 전달받은 `onCloseTap`으로 연습 종료를 요청합니다.
//

import SwiftUI

/// 소리 확인 대기 화면
/// - 디자인: hifi/watch11.png (소리 확인 중)
///
///     ┌ 좌측 상단 닫기(X) 버튼 · 상태 문구
///     └ 로딩 인디케이터 (화면 정중앙)
struct SoundCheckingView: View {
    /// 뷰 작업자가 추가할 X 버튼에서 호출할 연습 종료 동작
    var onCloseTap: () -> Void = {}

    var body: some View {
        WatchFullScreenStack {
            // MARK: 상태 문구
            Text("소리를 확인하고 있어요")
                .font(.watchScaled(18))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .watchCenterY(Metrics.statusTextCenterY)

            // MARK: 로딩 인디케이터
            // watchOS 기본 로딩 인디케이터는 Hi-Fi보다 작아서, 지름이 약 31pt가 되도록 키웁니다.
            ProgressView()
                .tint(.white)
                .scaleEffect(WatchDesignSize.scaled(Metrics.loadingIndicatorScale))
                .watchCenterY(Metrics.loadingIndicatorCenterY)
        }
        .foregroundStyle(.white)
        .background(AppColors.watchSoundCheckingBackground)
        .watchCloseButton(onClose: onCloseTap)
    }
}

// MARK: - Metrics

/// Hi-Fi(46mm, 248pt 높이) 기준 수치입니다.
/// - ~CenterY: 요소 중심의 세로 위치 (화면 맨 위 = 0, 맨 아래 = 1)
private enum Metrics {
    static let statusTextCenterY: CGFloat = 0.269       // 상태 문구 중심
    static let loadingIndicatorCenterY: CGFloat = 0.5   // 로딩 인디케이터 중심 (화면 정중앙)
    static let loadingIndicatorScale: CGFloat = 1.9     // 로딩 인디케이터 확대 배율 (watchOS 기본 크기 = 1)
}

// MARK: - Colors

private extension AppColors {
    /// 소리 확인 대기 화면 배경 (회색)
    /// - Hi-Fi 파일에는 반투명 검정으로 저장되어 있어, 화면에 보이는 색상 기준으로 정했습니다. 디자이너 확인 필요.
    static let watchSoundCheckingBackground = Color(hex: 0x6E6E6E)
}

#Preview("소리 확인 중") {
    NavigationStack {
        SoundCheckingView()
    }
}
