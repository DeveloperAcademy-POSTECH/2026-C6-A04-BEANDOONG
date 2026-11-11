import SwiftUI

/// Hi-Fi 시안 기준 기기(iPhone 17, 402x874pt) 대비 현재 화면의 비율.
/// - 세로 위치·간격은 `.v(scale)`, 가로 여백·폭은 `.h(scale)`로 변환한다.
/// - 글자 크기는 변환하지 않는다.
struct DesignScale: Equatable, Sendable {
    static let baseSize = CGSize(width: 402, height: 874)
    static let identity = DesignScale(x: 1, y: 1)

    let x: CGFloat
    let y: CGFloat

    init(x: CGFloat, y: CGFloat) {
        self.x = x
        self.y = y
    }

    init(screenSize: CGSize) {
        guard screenSize.width > 0, screenSize.height > 0 else {
            self = .identity
            return
        }
        self.init(x: screenSize.width / Self.baseSize.width,
                  y: screenSize.height / Self.baseSize.height)
    }
}

private struct DesignScaleKey: EnvironmentKey {
    static let defaultValue = DesignScale.identity
}

extension EnvironmentValues {
    var designScale: DesignScale {
        get { self[DesignScaleKey.self] }
        set { self[DesignScaleKey.self] = newValue }
    }
}

extension CGFloat {
    /// 세로 위치·간격: 시안 값 × 화면 높이 비율
    func v(_ scale: DesignScale) -> CGFloat { self * scale.y }
    /// 가로 여백·폭: 시안 값 × 화면 폭 비율
    func h(_ scale: DesignScale) -> CGFloat { self * scale.x }
}

extension DesignScale {
    /// 일러스트처럼 가로·세로를 함께 줄여야 하는 요소의 배율. 가로 비율만 쓰면 화면이 짧은 기기(SE 등)에서
    /// 세로 자리(`.v`)보다 크게 그려져 아래 글과 겹치므로, 가로·세로 비율 중 작은 쪽을 쓴다.
    var fit: CGFloat { min(x, y) }

    /// 높이를 변환하지 않는 고정 높이 요소(버튼 52 등)의 위쪽 선을 시안 비율 위치에 맞추기 위한 보정값.
    /// 아래 여백에 더하면 요소 위쪽이 `(화면 아래 거리) × 세로 비율` 자리에 놓인다.
    func fixedHeightAdjustment(_ height: CGFloat) -> CGFloat { height * (y - 1) }
}

extension View {
    /// 앱 루트(AppRootView)에 한 번만 붙인다. 안전 영역을 포함한 전체 화면 크기로 비율을 계산해 하위 뷰에 내려준다.
    func providesDesignScale() -> some View {
        modifier(DesignScaleProvider())
    }
}

private struct DesignScaleProvider: ViewModifier {
    /// 첫 프레임부터 실제 화면 비율로 시작해요. (기준 비율로 한 번 그린 뒤 바로 다시 배치하면,
    /// 앱을 켜는 순간 화면 전체를 두 번 배치하느라 스플래시 애니메이션 앞부분이 버벅여요)
    /// 값은 아래 GeometryReader(안전 영역 포함 전체 화면)가 재는 크기와 같고, 다르면 그쪽 값으로 바로 고쳐져요.
    @State private var scale = DesignScaleProvider.initialScale

    @MainActor
    private static var initialScale: DesignScale {
        let screen = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.screen }
            .first
        return screen.map { DesignScale(screenSize: $0.bounds.size) } ?? .identity
    }

    func body(content: Content) -> some View {
        content
            .environment(\.designScale, scale)
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .onAppear { scale = DesignScale(screenSize: proxy.size) }
                        .onChange(of: proxy.size) { _, newSize in
                            scale = DesignScale(screenSize: newSize)
                        }
                }
                .ignoresSafeArea()
            }
    }
}

extension View {
    /// 고정 크기(width x height pt)로 그려지는 일러스트를 `scale.fit`(가로·세로 비율 중 작은 쪽)으로 키웁니다. 레이아웃 크기도 함께 바뀝니다.
    func designScaled(width: CGFloat, height: CGFloat, _ scale: DesignScale) -> some View {
        self
            .frame(width: width, height: height)
            .scaleEffect(scale.fit)
            .frame(width: width * scale.fit, height: height * scale.fit)
    }
}
