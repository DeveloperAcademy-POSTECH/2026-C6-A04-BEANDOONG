//
//  SteamingFeedback.swift
//
//  실시간 피드백 화면(SteamingFeedbackView)에 표시할 피드백 종류입니다.
//  피드백 종류마다 안내 문구 · 소리 상태 · 일러스트 · 배경 색상이 정해져 있습니다.
//
//  [이름 규칙]
//  case 이름은 Shared/PracticeState.swift 의 PracticePhase 연습 단계 이름과 같게 맞췄습니다.
//  색상도 iPhone 앱의 피드백 색상 규칙(AppColors)을 따릅니다.
//  (공기 주입 = 파랑, 큰 기포 = 주황, 공기 추가 = 보라, 우유 흐름 = 초록)
//

import SwiftUI

enum SteamingFeedback: CaseIterable {
    /// 파랑 · 공기가 알맞게 들어가는 소리 → 지금 위치 유지
    case aeration
    /// 주황 · 스팀 노즐이 너무 높은 소리 → 피처 내리기
    case bubble
    /// 보라 · 공기가 부족한 소리 → 피처 살짝 내리기
    case moreAir
    /// 초록 · 우유가 회전(롤링)하는 소리 → 우유가 도는지 확인
    case milkFlow

    // MARK: 문구

    /// 화면 위쪽에 크게 보이는 문구: 사용자가 지금 해야 할 동작
    var actionTitle: String {
        switch self {
        case .aeration: "지금 위치를 유지해요"
        case .bubble: "피처를 내려 주세요"
        case .moreAir: "피처를 살짝 내려 주세요"
        case .milkFlow: "우유가 도는지 확인해요"
        }
    }

    /// 안내 문구 아래에 작게 보이는 문구: 앱이 인식한 현재 소리 상태
    var soundStatusText: String {
        switch self {
        case .aeration: "공기 주입 소리"
        case .bubble: "노즐 높음"
        case .moreAir: "공기 부족"
        case .milkFlow: "롤링 소리"
        }
    }

    // MARK: 일러스트

    /// 화면 아래쪽 일러스트의 에셋 이름 (chic-watch/Assets.xcassets)
    var illustrationAssetName: String {
        switch self {
        case .aeration: "WatchIllustAeration"
        case .bubble: "WatchIllustBubble"
        case .moreAir: "WatchIllustMoreAir"
        case .milkFlow: "WatchIllustMilkFlow"
        }
    }

    /// 일러스트 중심의 세로 위치 (화면 맨 위 = 0, 맨 아래 = 1)
    /// - 일러스트마다 모양과 크기가 달라 Hi-Fi에서 각각 측정했습니다.
    var illustrationCenterY: CGFloat {
        switch self {
        case .aeration: 0.608
        case .bubble: 0.62
        case .moreAir: 0.638
        case .milkFlow: 0.643
        }
    }

    // MARK: 배경

    /// 화면 전체 배경 그라데이션 (위 → 아래)
    /// - 색상은 Hi-Fi 원본 이미지의 픽셀에서 추출했습니다.
    /// - 각 배열의 색상 5개는 순서대로 backgroundGradientStopLocations 의 위치에 놓입니다.
    var backgroundGradient: Gradient {
        let topToBottomColors: [UInt32] = switch self {
        case .aeration: [0x052FA9, 0x1D4FCD, 0x2E66E4, 0x3A6EE7, 0x86A6EF]
        case .bubble: [0xFF6A11, 0xFE7E1D, 0xE4A727, 0xE9C353, 0xF0DC8B]
        case .moreAir: [0x5904A5, 0x6101A7, 0x7C1BC7, 0x913EDA, 0xC194EF]
        case .milkFlow: [0x1F9A0A, 0x258302, 0x25B539, 0x36D25D, 0x86EFA5]
        }
        return Gradient(stops: zip(topToBottomColors, Self.backgroundGradientStopLocations).map { hex, location in
            Gradient.Stop(color: Color(hex: hex), location: location)
        })
    }

    /// 피드백이 공통으로 쓰는 그라데이션 색상 위치 (화면 맨 위 = 0, 맨 아래 = 1)
    /// - 0 ~ 0.81: 위에서 아래로 조금씩 밝아짐
    /// - 0.89 ~ 1: 화면 아래 끝에서 빛이 번지듯 밝아짐
    private static let backgroundGradientStopLocations: [CGFloat] = [0, 0.5, 0.81, 0.89, 1]
}
