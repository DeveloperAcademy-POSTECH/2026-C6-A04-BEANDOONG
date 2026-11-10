import SwiftUI

enum SteamingFeedback: CaseIterable {
    case aeration, bubble, moreAir, milkFlow

    var actionTitle: String {
        switch self {
        case .aeration: "지금 위치를\n유지해요"
        case .bubble: "피처를\n내려 주세요"
        case .moreAir: "피처를\n올려 주세요"
        case .milkFlow: "우유가 도는지\n확인해요"
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

    var backgroundGradient: Gradient {
        let colors: [UInt32] = switch self {
        case .aeration: [0x0128A0, 0x1D4FCD, 0x2860DF, 0x2D65E4, 0x376DE5, 0x86A6EF]
        case .bubble: [0xFF5F0F, 0xFF7C19, 0xF68D1C, 0xE69E1E, 0xE7BF4B, 0xF0DC8B]
        case .moreAir: [0x52009C, 0x7B04CE, 0x8808DE, 0x8A15DE, 0x943BE2, 0xC294EF]
        case .milkFlow: [0x2C7200, 0x258201, 0x209510, 0x1EB330, 0x31D359, 0x86EFA6]
        }
        let locations: [CGFloat] = [0, 0.5, 0.7, 0.8, 0.88, 1]
        return Gradient(stops: zip(colors, locations).map { hex, location in
            Gradient.Stop(color: Color(hex: hex), location: location)
        })
    }
}
