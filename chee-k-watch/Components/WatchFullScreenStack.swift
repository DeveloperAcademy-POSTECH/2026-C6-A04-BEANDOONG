//
//  WatchFullScreenStack.swift
//
//  워치 화면 전체를 기준으로 요소를 배치하는 컨테이너입니다.
//
//  [왜 VStack이 아닌가요?]
//  VStack은 요소 사이 간격으로 위치가 정해져서, 화면 높이가 다른 기기에서는
//  Hi-Fi와 위치가 조금씩 어긋납니다. 이 컨테이너는 "화면 높이의 몇 % 지점"으로 위치를 정하므로
//  40mm ~ Ultra 49mm 어느 기기에서도 Hi-Fi와 같은 위치에 보입니다.
//
//  [사용 방법]
//      WatchFullScreenStack {
//          Text("안내 문구")
//              .watchCenterY(0.3)   // 요소의 세로 중심을 화면 위에서 30% 지점에 둡니다.
//          WatchCapsuleButton(...)
//              .watchCenterY(0.65)  // 요소의 세로 중심을 화면 위에서 65% 지점에 둡니다.
//      }
//
//  - 모든 요소는 가로 가운데에 놓이고, 화면 너비만큼의 공간을 제안받습니다.
//  - 비율 값은 Hi-Fi에서 측정합니다. (요소 중심의 y 좌표 ÷ 화면 높이 248pt)
//  - 시간 표시 영역까지 포함한 "화면 전체"를 기준으로 계산하도록 안전 영역 무시(.ignoresSafeArea)가
//    컨테이너 안에 이미 들어 있습니다. 사용하는 쪽에서 따로 붙이지 않아도 됩니다.
//

import SwiftUI

/// 요소를 화면 높이 대비 비율 위치에 배치하는 전체 화면 컨테이너
struct WatchFullScreenStack<Content: View>: View {
    /// 배치할 요소들. 각 요소에 `.watchCenterY(_:)`로 세로 위치를 지정합니다.
    @ViewBuilder let content: Content

    var body: some View {
        ProportionalPlacement {
            content
        }
        .ignoresSafeArea()
    }
}

extension View {
    /// WatchFullScreenStack 안에서 이 요소의 세로 중심 위치를 정합니다.
    /// - Parameter ratio: 화면 맨 위 = 0, 맨 아래 = 1 기준의 비율 (예: 0.5 = 정중앙)
    func watchCenterY(_ ratio: CGFloat) -> some View {
        layoutValue(key: CenterYRatioKey.self, value: ratio)
    }
}

// MARK: - 배치 계산 (WatchFullScreenStack 내부 구현)

/// 각 요소를 가로 가운데, 세로는 `watchCenterY`로 지정한 비율 지점에 놓는 SwiftUI 레이아웃
private struct ProportionalPlacement: Layout {
    /// 주어진 공간을 모두 차지합니다. (화면 전체를 기준으로 비율을 계산하기 위함)
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        proposal.replacingUnspecifiedDimensions()
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for subview in subviews {
            let centerY = bounds.minY + bounds.height * subview[CenterYRatioKey.self]
            subview.place(at: CGPoint(x: bounds.midX, y: centerY),
                          anchor: .center,
                          // 너비는 화면 너비만큼 제안해서, 버튼처럼 너비를 꽉 채우는 요소도 올바르게 그려지게 합니다.
                          proposal: ProposedViewSize(width: bounds.width, height: nil))
        }
    }
}

/// 요소마다 지정한 세로 중심 비율을 레이아웃에 전달하는 키
/// - 지정하지 않은 요소는 화면 정중앙(0.5)에 놓입니다.
nonisolated private struct CenterYRatioKey: LayoutValueKey {
    static let defaultValue: CGFloat = 0.5
}
