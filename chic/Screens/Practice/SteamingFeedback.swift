import SwiftUI

// MARK: - 피드백 종류

/// case 이름은 `PracticePhase`(워치와 공유)와 맞춰 두고, 화면 문구만 Hi-Fi에 맞춥니다.
enum SteamingFeedback: CaseIterable {
    /// 공기가 고르게 들어가는 중 (파랑)
    case aeration
    /// 노즐이 높아 큰 기포가 생길 수 있음 (주황)
    case bubble
    /// 공기 주입이 부족함 (보라)
    case moreAir
    /// 롤링이 안정적으로 진행되는 중 (초록)
    case milkFlow

    var gradientColors: [Color] {
        switch self {
        case .aeration: AppColors.aerationGradient
        case .bubble: AppColors.bubbleGradient
        case .moreAir: AppColors.moreAirGradient
        case .milkFlow: AppColors.milkFlowGradient
        }
    }

    /// 보라·주황은 해야 할 동작이 타이틀, 상태가 설명이에요.
    var title: String {
        switch self {
        case .aeration: String(localized: "공기가 고르게\n들어가고 있어요")
        case .bubble: String(localized: "피처를 살짝 올려\n노즐을 더 담가 주세요")
        case .moreAir: String(localized: "피처를 살짝\n내려 주세요")
        case .milkFlow: String(localized: "롤링이 안정적으로\n진행되고 있어요")
        }
    }

    /// 파랑·초록은 설명이 없어요.
    var subtitle: String? {
        switch self {
        case .aeration, .milkFlow: nil
        case .bubble: String(localized: "큰 기포가 생길 수 있어요")
        case .moreAir: String(localized: "공기 주입이 부족해요")
        }
    }

    /// 타이틀 뒤 반투명 큰 기호. 크기는 3x 에셋 그대로, 가운데 점은 Hi-Fi에서 잰 위치 (pt)
    var symbol: (name: String, size: CGSize, center: CGPoint) {
        switch self {
        case .moreAir: ("IllustFeedbackArrowDown", CGSize(width: 340, height: 236), CGPoint(x: 201.2, y: 220))
        case .bubble: ("IllustFeedbackArrowUp", CGSize(width: 340, height: 236), CGPoint(x: 199.3, y: 237))
        case .aeration: ("IllustFeedbackCheck", CGSize(width: 255, height: 188), CGPoint(x: 206.5, y: 246))
        case .milkFlow: ("IllustFeedbackSwirl", CGSize(width: 248, height: 212), CGPoint(x: 198, y: 263))
        }
    }

    /// 비커 위 장식 (보라: 물방울, 주황: 기포). 위치는 비커 그림 왼쪽 위 기준 (pt)
    var decoration: (name: String, size: CGSize, origin: CGPoint)? {
        switch self {
        case .moreAir: ("IllustFeedbackDrops", CGSize(width: 79, height: 69), CGPoint(x: 73.5, y: 22.3))
        case .bubble: ("IllustFeedbackBubbleRings", CGSize(width: 104, height: 78), CGPoint(x: 36, y: 1))
        case .aeration, .milkFlow: nil
        }
    }

    /// 점선 색 (Hi-Fi 에셋에서 잰 값)
    var lineColor: Color {
        switch self {
        case .aeration: AppColors.steamingLineAeration
        case .bubble: AppColors.steamingLineBubble
        case .moreAir: AppColors.steamingLineMoreAir
        case .milkFlow: AppColors.steamingLineMilkFlow
        }
    }

    /// 두 점선 사이 적정 구간 색 (Hi-Fi 에셋의 겹친 색에서 거꾸로 계산한 색·불투명도)
    var bandColor: Color {
        switch self {
        case .aeration: AppColors.steamingBandAeration
        case .bubble: AppColors.steamingBandBubble
        case .moreAir: AppColors.steamingBandMoreAir
        case .milkFlow: AppColors.steamingBandMilkFlow
        }
    }

    /// 종료하기 버튼 사각형 색 = 상태 팔레트 색 (배경 그라데이션의 아래쪽 색)
    var stopSquareColor: Color {
        switch self {
        case .aeration: AppColors.soundNormalAeration
        case .bubble: AppColors.soundOverAeration
        case .moreAir: AppColors.soundLackOfAir
        case .milkFlow: AppColors.soundRolling
        }
    }
}

// MARK: - 그림 미리 디코딩

extension SteamingFeedback {
    /// 연습 화면이 그리는 그림 이름 전부: 비커 · 배경 기호 4종 · 비커 위 장식 2종
    ///
    /// 큰 그림(비커 966×882px 등)은 처음 그려지는 순간 디코딩돼서, 하필 상태가 바뀌며 색이 섞이는 순간에 걸리면 그 프레임이 늦어요.
    /// 그래서 한 화면 앞인 소리 확인 화면(`ListeningView`)이 뜰 때 `PreparedImage.prepare`로 미리 디코딩해 두고,
    /// 연습 화면은 `Image.prepared` 로 그려요 (모습은 같아요).
    static let imageNames: [String] = {
        var names = [SteamingPitcher.imageName]
        for feedback in allCases {
            names.append(feedback.symbol.name)
            if let decoration = feedback.decoration { names.append(decoration.name) }
        }
        return names
    }()
}

// MARK: - 화면 전용 색 (새 연습 중 Hi-Fi 3x 에셋에서 잰 값)

private extension AppColors {
    static let steamingLineAeration = Color(hex: 0x80A5FE)
    static let steamingLineBubble = Color(hex: 0xFFC17A)
    static let steamingLineMoreAir = Color(hex: 0xD799FF)
    static let steamingLineMilkFlow = Color(hex: 0x5FF46B)

    static let steamingBandAeration = Color(hex: 0x6184E0).opacity(0.39)
    static let steamingBandBubble = Color(hex: 0xFF9726).opacity(0.152)
    static let steamingBandMoreAir = Color(hex: 0x7F07D1).opacity(0.152)
    static let steamingBandMilkFlow = Color(hex: 0x209D2C).opacity(0.408)
}
