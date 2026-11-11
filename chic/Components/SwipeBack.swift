import SwiftUI
import UIKit

// MARK: - 화면 왼쪽 가장자리 스와이프로 이전 화면 돌아가기

/// 상단 바를 `.toolbar(.hidden, for: .navigationBar)`로 숨기면 시스템의 "왼쪽 가장자리에서 밀어 뒤로가기"도 같이 꺼져요.
/// 이 확장이 모든 `NavigationStack`에서 그 제스처를 다시 켭니다. (쌓인 화면이 2개 이상일 때만 동작해서, 홈에서는 아무 일도 없어요)
///
/// 화면마다 막고 싶으면 `.swipeBackDisabled(_:)`를 써요.
extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    /// 시스템이 제스처의 델리게이트를 화면이 올라온 뒤에 다시 바꿔 놓을 수 있어서, 레이아웃 때마다 우리 것으로 맞춰 둔다.
    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let gesture = interactivePopGestureRecognizer, gesture.delegate !== self else { return }
        gesture.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        viewControllers.count > 1
    }
}

extension View {
    /// 이 화면에서는 스와이프로 뒤로가기를 막아요. (삭제 확인 팝업이 떠 있을 때, 권한 요청 중처럼 실수로 나가면 안 되는 때)
    /// `isDisabled`가 false가 되면 다시 켜져요.
    func swipeBackDisabled(_ isDisabled: Bool = true) -> some View {
        background(SwipeBackGate(isDisabled: isDisabled))
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
