//
//  SoundCheckingView.swift
//
//  연습 중 실시간 피드백을 보여주기 전, 앱이 아직 소리를 판단하지 못했을 때 보이는 대기 화면입니다.
//  - 소리 확인 중: 연습을 시작한 직후 소리를 분석하는 동안
//  - 구분 어려움: 주변 소음 등으로 스티밍 소리를 구분하기 어려울 때
//
//  화면만 그립니다.
//

import SwiftUI

/// 소리 확인 대기 화면
/// - 디자인: hifi/watch11.png (소리 확인 중), hifi/watch11-1.png (구분 어려움)
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
            case .listening: "소리 확인 중"
            case .noiseWarning: "구분 어려움"
            }
        }
    }

    /// 화면에 보여줄 대기 상태
    let checkingStatus: CheckingStatus

    var body: some View {
        Text(checkingStatus.statusText)
    }
}

#Preview("소리 확인 중") {
    SoundCheckingView(checkingStatus: .listening)
}

#Preview("구분 어려움") {
    SoundCheckingView(checkingStatus: .noiseWarning)
}
