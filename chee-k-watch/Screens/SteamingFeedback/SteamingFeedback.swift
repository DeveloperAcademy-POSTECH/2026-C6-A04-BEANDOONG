//
//  SteamingFeedback.swift
//
//  실시간 피드백 화면(SteamingFeedbackView)에 표시할 피드백 종류입니다.
//  피드백 종류마다 안내 문구 · 소리 상태 문구가 정해져 있습니다.
//
//  [이름 규칙]
//  case 이름은 Shared/PracticeState.swift 의 PracticePhase 연습 단계 이름과 같게 맞췄습니다.
//  색상도 iPhone 앱의 피드백 색상 규칙(AppColors)을 따릅니다.
//  (공기 주입 = 파랑, 날카로운 소리 = 분홍, 큰 기포 = 주황, 공기 추가 = 보라, 우유 흐름 = 초록)
//

import SwiftUI

enum SteamingFeedback: CaseIterable {
    /// 파랑 · 공기가 알맞게 들어가는 소리 → 지금 위치 유지
    case aeration
    /// 분홍 · 공기가 너무 많이 들어가는 소리 → 공기 주입 줄이기
    case sharpSound
    /// 주황 · 스팀 노즐이 너무 높은 소리 → 피처 내리기
    case bubble
    /// 보라 · 공기가 부족한 소리 → 피처 올리기
    case moreAir
    /// 초록 · 우유가 회전(롤링)하는 소리 → 우유가 도는지 확인
    case milkFlow

    // MARK: 문구

    /// 화면 위쪽에 크게 보이는 문구: 사용자가 지금 해야 할 동작
    var actionTitle: String {
        switch self {
        case .aeration: "지금 위치를 유지해요"
        case .sharpSound: "공기 주입을 줄여 주세요"
        case .bubble: "피처를 내려 주세요"
        case .moreAir: "피처를 올려주세요"
        case .milkFlow: "우유가 도는지 확인해요"
        }
    }

    /// 안내 문구 아래에 작게 보이는 문구: 앱이 인식한 현재 소리 상태
    var soundStatusText: String {
        switch self {
        case .aeration: "공기 주입 소리"
        case .sharpSound: "공기 과다"
        case .bubble: "노즐 높음"
        case .moreAir: "공기 부족"
        case .milkFlow: "롤링 소리"
        }
    }
}
