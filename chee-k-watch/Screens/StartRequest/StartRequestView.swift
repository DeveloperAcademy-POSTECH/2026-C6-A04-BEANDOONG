//
//  StartRequestView.swift
//
//  워치 앱을 열면 처음 보이는 화면입니다.
//  색상과 진동으로 스티밍 상태를 확인할 수 있다고 안내합니다.
//

import SwiftUI

/// 시작 요청 화면
/// - 디자인: hifi/Intro.png
///
///     ┌ 안내 문구
struct StartRequestView: View {
    var body: some View {
        WatchFullScreenStack {
            // MARK: 안내 문구
            Text("색상과 진동으로 스티밍 상태를 확인해 보세요.")
                .font(.watchScaled(17))
                .multilineTextAlignment(.center)
                .lineSpacing(WatchDesignSize.scaled(Metrics.guideMessageLineSpacing))
                // 두 줄 안에 들어가지 않는 경우에만 최대 80%까지 줄입니다.
                .minimumScaleFactor(0.8)
                .padding(.horizontal, WatchDesignSize.scaled(Metrics.guideMessageScreenEdgeInset))
                .watchCenterY(Metrics.guideMessageCenterY)
        }
        .foregroundStyle(.white)
        .background(AppColors.watchDarkScreenBackground)
    }
}

// MARK: - Metrics

/// Hi-Fi(46mm, 248pt 높이) 기준 수치입니다.
/// - ~CenterY: 요소 중심의 세로 위치 (화면 맨 위 = 0, 맨 아래 = 1)
/// - 그 외 pt 수치: 사용할 때 `WatchDesignSize.scaled(_:)`로 기기 크기에 맞춥니다.
private enum Metrics {
    static let guideMessageCenterY: CGFloat = 0.306       // 안내 문구(두 줄 전체) 중심
    static let guideMessageScreenEdgeInset: CGFloat = 15  // 화면 좌우 끝 ↔ 안내 문구 사이 여백
    static let guideMessageLineSpacing: CGFloat = 4       // 안내 문구 줄 사이 간격
}

#Preview {
    StartRequestView()
}
