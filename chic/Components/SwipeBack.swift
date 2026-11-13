import SwiftUI
import UIKit

// MARK: - 화면 왼쪽 가장자리 스와이프로 이전 화면 돌아가기

/// 상단 바를 `.toolbar(.hidden, for: .navigationBar)`로 숨기면 시스템의 "왼쪽 가장자리에서 밀어 뒤로가기"도 같이 꺼져요.
/// 이 확장이 모든 `NavigationStack`에서 그 제스처를 다시 켭니다. (쌓인 화면이 2개 이상일 때만 동작해서, 홈에서는 아무 일도 없어요)
///
/// 화면마다 막고 싶으면 `.swipeBackDisabled(_:)`를 써요.
/// 가장자리보다 넓은 왼쪽 띠에서도 뒤로 가게 하려면 `.swipeBackZone(width:)`를 써요 (시스템의 화면 전체 뒤로가기 제스처를 그 띠 안에서만 켜요).
extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    /// 시스템이 제스처의 델리게이트를 화면이 올라온 뒤에 다시 바꿔 놓을 수 있어서, 레이아웃 때마다 우리 것으로 맞춰 둔다.
    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let gesture = interactivePopGestureRecognizer, gesture.delegate !== self {
            gesture.delegate = self
        }
        if let gesture = interactiveContentPopGestureRecognizer, gesture.delegate !== self {
            gesture.delegate = self
        }
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard viewControllers.count > 1 else { return false }
        guard gestureRecognizer === interactiveContentPopGestureRecognizer else { return true }
        // 화면 전체 뒤로가기: `.swipeBackZone(width:)`을 둔 화면에서만, 그 띠 안에서 오른쪽으로 끌기 시작했을 때만
        guard let width = SwipeBackZone.width(for: self),
              let pan = gestureRecognizer as? UIPanGestureRecognizer else { return false }
        let startX = pan.location(in: view).x - pan.translation(in: view).x
        return startX <= width && pan.velocity(in: view).x > 0
    }
}

/// 지금 보이는 화면이 정한 "뒤로가기 띠" 폭 (내비게이션 컨트롤러마다 하나)
private enum SwipeBackZone {
    @MainActor private static var widths: [ObjectIdentifier: CGFloat] = [:]

    @MainActor static func width(for controller: UINavigationController) -> CGFloat? {
        widths[ObjectIdentifier(controller)]
    }

    @MainActor static func set(_ width: CGFloat?, for controller: UINavigationController) {
        widths[ObjectIdentifier(controller)] = width
    }
}

extension View {
    /// 이 화면에서는 스와이프로 뒤로가기를 막아요. (삭제 확인 팝업이 떠 있을 때, 권한 요청 중처럼 실수로 나가면 안 되는 때)
    /// `isDisabled`가 false가 되면 다시 켜져요.
    func swipeBackDisabled(_ isDisabled: Bool = true) -> some View {
        background(SwipeBackGate(isDisabled: isDisabled))
    }
}

extension View {
    /// 이 화면에서는 왼쪽 `width` 띠 어디서 오른쪽으로 끌어도 시스템 뒤로가기가 손가락을 따라 시작돼요.
    /// 화면 안에 좌우로 미는 내용(캐러셀 등)이 있으면, 그 제스처는 이 띠를 빼고 받게 해 주세요.
    func swipeBackZone(width: CGFloat) -> some View {
        background(SwipeBackZoneGate(width: width))
    }
}

/// 화면 뒤에 깔려서, 이 화면이 보이는 동안만 뒤로가기 띠 폭을 내비게이션 컨트롤러에 알려 줍니다.
private struct SwipeBackZoneGate: UIViewControllerRepresentable {
    let width: CGFloat

    func makeUIViewController(context: Context) -> ZoneController {
        ZoneController(width: width)
    }

    func updateUIViewController(_ controller: ZoneController, context: Context) {
        controller.width = width
    }

    final class ZoneController: UIViewController {
        var width: CGFloat

        init(width: CGFloat) {
            self.width = width
            super.init(nibName: nil, bundle: nil)
            view.isUserInteractionEnabled = false
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            guard let navigationController else { return }
            SwipeBackZone.set(width, for: navigationController)
            navigationController.interactiveContentPopGestureRecognizer?.isEnabled = true
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            guard let navigationController else { return }
            SwipeBackZone.set(nil, for: navigationController)
        }
    }
}

/// 화면 뒤에 눈에 안 보이게 깔려서, 이 화면이 보이는 동안 제스처를 켜고 끕니다.
private struct SwipeBackGate: UIViewControllerRepresentable {
    let isDisabled: Bool

    func makeUIViewController(context: Context) -> GateController {
        GateController(isDisabled: isDisabled)
    }

    func updateUIViewController(_ controller: GateController, context: Context) {
        controller.isDisabled = isDisabled
        controller.apply()
    }

    final class GateController: UIViewController {
        var isDisabled: Bool

        init(isDisabled: Bool) {
            self.isDisabled = isDisabled
            super.init(nibName: nil, bundle: nil)
            view.isUserInteractionEnabled = false
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            apply()
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            // 이 화면을 떠날 때는 다음 화면이 정하도록 다시 켜 둔다
            navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        }

        func apply() {
            navigationController?.interactivePopGestureRecognizer?.isEnabled = !isDisabled
        }
    }
}
