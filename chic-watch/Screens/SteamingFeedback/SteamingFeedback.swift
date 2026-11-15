import SwiftUI

enum SteamingFeedback: CaseIterable {
    case aeration, bubble, moreAir, milkFlow

    var actionTitle: String {
        switch self {
        case .aeration: String(localized: "지금 위치를\n유지해요")
        case .bubble: String(localized: "피처를\n내려 주세요")
        case .moreAir: String(localized: "피처를\n올려 주세요")
        case .milkFlow: String(localized: "우유가 도는지\n확인해요")
        }
    }

    var illustrationAssetName: String {
        switch self {
        case .aeration: "WatchFeedbackAeration"
        case .bubble: "WatchFeedbackBubble"
        case .moreAir: "WatchFeedbackMoreAir"
        case .milkFlow: "WatchFeedbackMilkFlow"
        }
    }

    /// 상태별 배경 그라데이션 (위 → 아래 6단)
    /// 상태마다 한 번만 만들어 두고 돌려줘요. 연습 화면은 연습 시간이 바뀔 때마다 body를 다시 계산하는데,
    /// 그때마다 같은 그라데이션을 새로 만들 필요가 없어요.
    var backgroundGradient: Gradient {
        switch self {
        case .aeration: Self.aerationGradient
        case .bubble: Self.bubbleGradient
        case .moreAir: Self.moreAirGradient
        case .milkFlow: Self.milkFlowGradient
        }
    }

    // MARK: - 배경 그라데이션 표

    /// 6단의 위치 (모든 상태가 같아요)
    private static let gradientLocations: [CGFloat] = [0, 0.5, 0.7, 0.8, 0.88, 1]

    private static let aerationGradient = makeGradient(colors: [0x0128A0, 0x1D4FCD, 0x2860DF, 0x2D65E4, 0x376DE5, 0x86A6EF])
    private static let bubbleGradient = makeGradient(colors: [0xFF5F0F, 0xFF7C19, 0xF68D1C, 0xE69E1E, 0xE7BF4B, 0xF0DC8B])
    private static let moreAirGradient = makeGradient(colors: [0x52009C, 0x7B04CE, 0x8808DE, 0x8A15DE, 0x943BE2, 0xC294EF])
    private static let milkFlowGradient = makeGradient(colors: [0x2C7200, 0x258201, 0x209510, 0x1EB330, 0x31D359, 0x86EFA6])

    /// 색 6개를 `gradientLocations` 위치에 하나씩 놓은 그라데이션을 만들어요.
    private static func makeGradient(colors: [UInt32]) -> Gradient {
        Gradient(stops: zip(colors, gradientLocations).map { hex, location in
            Gradient.Stop(color: Color(hex: hex), location: location)
        })
    }
}
