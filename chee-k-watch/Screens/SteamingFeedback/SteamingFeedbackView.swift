//
//  SteamingFeedbackView.swift
//
//  연습 중 실시간으로 스티밍 상태를 보여주는 피드백 화면입니다.
//  사용자가 스티밍 중 손목을 잠깐 보는 것만으로 상태를 알 수 있도록,
//  글자를 읽지 않아도 일러스트로 구분되게 디자인되어 있습니다.
//
//  화면만 그립니다. 어떤 피드백을 보여줄지는 화면을 사용하는 쪽에서 `feedback`으로 전달합니다.
//

import SwiftUI

/// 실시간 피드백 화면
/// - 디자인: hifi/Frame 2147236534 ~ 2147236538.png
///
///     ┌ 안내 문구 (해야 할 동작)
///     ├ 소리 상태 문구
///     └ 일러스트
struct SteamingFeedbackView: View {
    /// 화면에 보여줄 피드백 종류 (문구 · 일러스트 · 배경 색상이 함께 바뀝니다)
    let feedback: SteamingFeedback

    var body: some View {
        WatchFullScreenStack {
            // MARK: 안내 문구
            Text(feedback.actionTitle)
                .font(.watchScaled(19, weight: .bold))
                .lineLimit(1)
                // 가장 긴 문구("공기 주입을 줄여 주세요")도 작은 기기에서 한 줄로 보이도록 최대 70%까지 줄입니다.
                .minimumScaleFactor(0.7)
                .padding(.horizontal, WatchDesignSize.scaled(Metrics.actionTitleScreenEdgeInset))
                .watchCenterY(Metrics.actionTitleCenterY)

            // MARK: 소리 상태 문구
            Text(feedback.soundStatusText)
                .font(.watchScaled(14))
                .lineLimit(1)
                .watchCenterY(Metrics.soundStatusTextCenterY)

            // MARK: 일러스트
            // 에셋은 Hi-Fi(46mm) 기준 크기로 넣어 두었으므로, 기기 너비 비율만 곱하면 됩니다.
            Image(feedback.illustrationAssetName)
                .scaleEffect(WatchDesignSize.screenWidthRatio)
                // 장식용 이미지라 VoiceOver가 읽지 않도록 합니다.
                .accessibilityHidden(true)
                .watchCenterY(feedback.illustrationCenterY)
        }
        .foregroundStyle(.white)
        // 피드백 화면은 버튼이 없는 디자인이라 상단 내비게이션 바를 숨깁니다.
        // (시간 표시는 watchOS가 항상 보여주므로 숨길 수 없습니다.)
        .toolbar(.hidden, for: .navigationBar)
    }
}

// MARK: - Metrics

/// Hi-Fi(46mm, 248pt 높이) 기준 수치입니다.
/// - ~CenterY: 요소 중심의 세로 위치 (화면 맨 위 = 0, 맨 아래 = 1)
/// - 그 외 pt 수치: 사용할 때 `WatchDesignSize.scaled(_:)`로 기기 크기에 맞춥니다.
private enum Metrics {
    static let actionTitleCenterY: CGFloat = 0.255       // 안내 문구 중심
    static let soundStatusTextCenterY: CGFloat = 0.343   // 소리 상태 문구 중심
    static let actionTitleScreenEdgeInset: CGFloat = 10  // 화면 좌우 끝 ↔ 안내 문구 사이 최소 여백
}

#Preview("파랑 · 공기 주입 소리") { SteamingFeedbackView(feedback: .aeration) }
#Preview("분홍 · 공기 과다") { SteamingFeedbackView(feedback: .sharpSound) }
#Preview("주황 · 노즐 높음") { SteamingFeedbackView(feedback: .bubble) }
#Preview("보라 · 공기 부족") { SteamingFeedbackView(feedback: .moreAir) }
#Preview("초록 · 롤링 소리") { SteamingFeedbackView(feedback: .milkFlow) }
