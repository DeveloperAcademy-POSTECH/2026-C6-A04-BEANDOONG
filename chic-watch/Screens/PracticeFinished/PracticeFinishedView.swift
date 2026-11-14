//
//  PracticeFinishedView.swift
//
//  연습이 끝난 뒤 보이는 화면입니다. 연습을 마쳤다는 안내와 총 연습 시간을 보여주고,
//  사용자가 [완료] 버튼으로 연습을 마무리할 수 있게 합니다.
//
//  화면만 그립니다. 완료 버튼을 눌렀을 때의 동작은
//  화면을 사용하는 쪽에서 `onDoneTap`으로 전달합니다.
//

import SwiftUI

/// 종료 확인 화면
/// - 디자인: hifi/watch11-2.png
///
///     ┌ 안내 문구 + 총 연습 시간
///     └ 버튼: [완료]
struct PracticeFinishedView: View {
    /// 총 연습 시간 문구 ("분:초" 형식, 예: "00:32")
    /// - PracticeState.durationText 를 그대로 전달하면 됩니다.
    let practiceDurationText: String
    /// [완료] 버튼을 눌렀을 때 실행할 동작
    var onDoneTap: () -> Void = {}

    var body: some View {
        WatchFullScreenStack {
            // MARK: 안내 문구
            Text(String(localized: "연습을 마쳤어요"))
                .font(.watchScaled(16))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .watchCenterY(Metrics.finishedMessageCenterY)

            // MARK: 총 연습 시간
            Text(practiceDurationText)
                .font(.watchScaled(20, weight: .semibold))
                // 숫자 너비를 모두 같게 해서, 시간이 바뀌어도 글자가 좌우로 흔들리지 않게 합니다.
                .monospacedDigit()
                .watchCenterY(Metrics.practiceDurationCenterY)

            // MARK: 하단 버튼
            WatchCapsuleButton(title: String(localized: "완료"), action: onDoneTap)
                .watchCenterY(Metrics.doneButtonCenterY)
        }
        .foregroundStyle(.white)
        .background(AppColors.watchDarkScreenBackground)
    }
}

// MARK: - Metrics

/// Hi-Fi(46mm, 248pt 높이) 기준 수치입니다.
/// - ~CenterY: 요소 중심의 세로 위치 (화면 맨 위 = 0, 맨 아래 = 1)
private enum Metrics {
    static let finishedMessageCenterY: CGFloat = 0.269   // "연습을 마쳤어요" 중심
    static let practiceDurationCenterY: CGFloat = 0.391  // 총 연습 시간 중심
    static let doneButtonCenterY: CGFloat = 0.648        // [완료] 버튼 중심
}

#Preview {
    NavigationStack {
        PracticeFinishedView(practiceDurationText: "00:32")
    }
}
