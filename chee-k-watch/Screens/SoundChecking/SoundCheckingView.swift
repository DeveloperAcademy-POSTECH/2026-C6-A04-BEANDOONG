//
//  SoundCheckingView.swift
//
//  연습 중 실시간 피드백을 보여주기 전, 앱이 아직 소리를 판단하지 못했을 때 보이는 대기 화면입니다.
//  - 소리 확인 중: 연습을 시작한 직후 소리를 분석하는 동안
//  - 구분 어려움: 주변 소음 등으로 스티밍 소리를 구분하기 어려울 때
//
//  화면만 그리며, 연습 종료는 iPhone에서 처리합니다.
//

import SwiftUI

/// 소리 확인 대기 화면
/// - 디자인: hifi/watch11.png (소리 확인 중), hifi/watch11-1.png (구분 어려움)
///
///     ┌ 상태 문구
///     └ 로딩 인디케이터 (화면 정중앙)
struct SoundCheckingView: View {
    /// 대기 상태 종류
    /// - case 이름은 Shared/PracticeState.swift 의 PracticePhase 연습 단계 이름과 같게 맞췄습니다.
    enum CheckingStatus {
        /// 소리를 분석하는 중 (PracticePhase.listening)
        case listening
        /// 소음 등으로 스티밍 소리를 구분하기 어려움 (PracticePhase.noiseWarning)
        case noiseWarning

        /// 화면 위쪽에 보이는 상태 문구
        var statusText: String {
            switch self {
            case .listening: "소리를 확인하고 있어요"
            case .noiseWarning: "소리 구분이 어려워요"
            }
        }
    }

    /// 화면에 보여줄 대기 상태
    let checkingStatus: CheckingStatus

    var body: some View {
        WatchFullScreenStack {
            // MARK: 상태 문구
            Text(checkingStatus.statusText)
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
        SoundCheckingView(checkingStatus: .listening)
    }
}

#Preview("구분 어려움") {
    NavigationStack {
        SoundCheckingView(checkingStatus: .noiseWarning)
    }
}
