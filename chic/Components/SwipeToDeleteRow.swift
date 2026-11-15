import SwiftUI
import UIKit

// MARK: - 왼쪽으로 밀어 삭제

/// 카드를 왼쪽으로 밀면 오른쪽에 삭제 버튼이 나오는 줄.
///
/// 밀린 카드는 목록 왼쪽 끝 밖으로 나가는데, 잘린 쪽도 카드 모서리와 같은 둥근 모서리로 오려 그린다.
/// 그래서 각지게 잘리지 않고 둥근 끝을 유지한 채 밀려 나간다.
/// 모서리 반경은 카드 폭처럼 화면 폭 비율로 바꿔 받으므로, 기기가 달라도 카드와 모서리의 비율이 같다.
///
/// 삭제 버튼의 모양·위치는 이전에 쓰던 시스템 `swipeActions` 버튼을 iPhone 17에서 재서 맞췄다.
struct SwipeToDeleteRow<Content: View>: View {
    @Binding var isOpen: Bool
    let width: CGFloat
    /// 삭제 버튼을 열었을 때 카드가 밀리는 거리
    let revealWidth: CGFloat
    let cornerRadius: CGFloat
    /// 카드 배경색. 남은 폭만큼의 둥근 사각형으로 직접 칠한다
    let cardColor: Color
    let onDelete: () -> Void
    @ViewBuilder let content: () -> Content

    /// 손가락으로 끄는 중의 이동량 (왼쪽이 −). 끄는 중이 아니면 nil
    @State private var dragTranslation: CGFloat?

    /// 지금 카드가 왼쪽으로 밀린 거리 (0이면 닫힘)
    private var offset: CGFloat {
        let base = isOpen ? revealWidth : 0
        guard let dragTranslation else { return base }
        let raw = base - dragTranslation
        if raw <= 0 { return 0 }
        // 열린 거리보다 더 끌면 고무줄처럼 덜 따라온다
        if raw > revealWidth { return revealWidth + (raw - revealWidth) * Layout.overdragResistance }
        return raw
    }

    /// 삭제 버튼이 드러난 정도 (0 ~ 1)
    private var progress: CGFloat { min(1, offset / revealWidth) }

    var body: some View {
        ZStack(alignment: .trailing) {
            deleteButton
                .frame(width: revealWidth)
                .opacity(progress)
                .scaleEffect(Layout.buttonStartScale + (1 - Layout.buttonStartScale) * progress)
                .allowsHitTesting(isOpen && dragTranslation == nil)

            content()
                // 밀기와 둥글게 오리기를 한 값으로 매 프레임 함께 계산해, 애니메이션 중에도 잘린 끝이 둥글게 따라간다
                .modifier(SwipedCardClip(offset: offset, cornerRadius: cornerRadius, cardColor: cardColor))
                .gesture(
                    HorizontalPanGesture(
                        allowsRightward: isOpen,
                        onChanged: { dragTranslation = $0 },
                        onEnded: { translation, velocity in
                            let base = isOpen ? revealWidth : 0
                            // 손을 뗀 속도까지 더해 반 넘게 열릴 것 같으면 연다
                            let projected = base - translation - velocity * Layout.velocityProjection
                            withAnimation(Layout.settle) {
                                isOpen = projected > revealWidth / 2
                                dragTranslation = nil
                            }
                        }
                    )
                )
        }
        .frame(width: width)
        .animation(Layout.settle, value: isOpen)
        .accessibilityAction(named: String(localized: "삭제"), onDelete)
    }

    private var deleteButton: some View {
        Button(action: onDelete) {
            VStack(spacing: Layout.labelGap) {
                Image(systemName: "trash")
                    .font(.system(size: Layout.iconSize, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .frame(width: Layout.circleSize, height: Layout.circleSize)
                    .background(Circle().fill(AppColors.swipeDeleteRed))
                Text(String(localized: "삭제"))
                    .font(.system(size: Layout.labelSize, weight: .regular))
                    .foregroundStyle(Color(uiColor: .secondaryLabel))
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: "삭제"))
    }
}

/// 카드를 왼쪽으로 `offset`만큼 민다.
/// - 카드 겉모양(배경)은 옮기지 않고, 목록 안에 남은 폭만큼의 둥근 사각형으로 그 자리에 다시 그린다.
///   옮긴 사각형을 오려 내면 이동과 오리기가 화면에 한 프레임씩 어긋나 끝이 각져 보이는데, 도형 하나로 그리면 그럴 일이 없다.
/// - 글자·링·화살표만 옮기고 같은 모양으로 오린다.
/// - 남은 폭이 모서리 두 개보다 좁으면 알약 모양이 된다.
/// - `Animatable`이라 제자리로 돌아가는 애니메이션 중에도 배경과 내용이 같은 값으로 그려진다.
private struct SwipedCardClip: ViewModifier, Animatable {
    var offset: CGFloat
    let cornerRadius: CGFloat
    let cardColor: Color

    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }

    func body(content: Content) -> some View {
        let shape = VisibleCardShape(hiddenWidth: offset, cornerRadius: cornerRadius)
        content
            .offset(x: -offset)
            .clipShape(shape)
            .background(shape.fill(cardColor))
            // 보간은 이 수정자가 매 프레임 하므로, 안쪽 이동이 같은 애니메이션을 한 번 더 받아 뒤처지지 않게 한다
            .transaction(value: offset) { $0.animation = nil }
    }
}

/// 카드에서 왼쪽으로 밀려 나간 폭(`hiddenWidth`)을 뺀 나머지를 둥근 사각형으로 오리는 모양.
/// 모서리 반경은 남은 폭·높이의 절반을 넘지 않아, 좁아지면 알약 모양이 된다.
private struct VisibleCardShape: Shape {
    let hiddenWidth: CGFloat
    let cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        let visibleWidth = max(0, rect.width - hiddenWidth)
        let radius = min(cornerRadius, visibleWidth / 2, rect.height / 2)
        return RoundedRectangle(cornerRadius: radius, style: .continuous)
            .path(in: CGRect(x: rect.minX, y: rect.minY, width: visibleWidth, height: rect.height))
    }
}

/// 가로로 끄는 것만 받는 팬 제스처. 위아래로 끄면 시작하지 않아 목록 스크롤을 막지 않는다.
/// 닫힌 카드를 오른쪽으로 끌어도 시작해서(카드는 움직이지 않음) 손을 뗄 때 카드 탭으로 처리되지 않게 한다.
/// 단, 화면 왼쪽 가장자리에서 시작한 오른쪽 끌기는 뒤로가기 스와이프에 양보한다.
private struct HorizontalPanGesture: UIGestureRecognizerRepresentable {
    var allowsRightward: Bool
    var onChanged: (CGFloat) -> Void
    /// (이동량, 손을 뗄 때 속도 pt/s). 둘 다 왼쪽이 −
    var onEnded: (CGFloat, CGFloat) -> Void

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
        Coordinator()
    }

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let recognizer = UIPanGestureRecognizer()
        recognizer.delegate = context.coordinator
        return recognizer
    }

    func updateUIGestureRecognizer(_ recognizer: UIPanGestureRecognizer, context: Context) {
        context.coordinator.allowsRightward = allowsRightward
    }

    func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context: Context) {
        let translation = recognizer.translation(in: recognizer.view).x
        switch recognizer.state {
        case .began, .changed:
            onChanged(translation)
        case .ended, .cancelled, .failed:
            onEnded(translation, recognizer.state == .ended ? recognizer.velocity(in: recognizer.view).x : 0)
        default:
            break
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var allowsRightward = false

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return false }
            let velocity = pan.velocity(in: pan.view)
            guard abs(velocity.x) > abs(velocity.y) else { return false }
            if velocity.x < 0 || allowsRightward { return true }
            // 닫힌 카드를 오른쪽으로: 끌기 시작한 곳이 화면 왼쪽 가장자리면 뒤로가기에 양보
            let startX = pan.location(in: nil).x - pan.translation(in: nil).x
            return startX > Layout.backSwipeEdgeWidth
        }
    }
}

// MARK: - Layout

/// 밀어서 삭제 수치 (iPhone 17에서 시스템 `swipeActions` 버튼을 잰 값, pt)
private enum Layout {
    static let circleSize: CGFloat = 54.5   // 빨간 원 지름 (x 308.3 ~ 363, y 311.7 ~ 366.3)
    static let iconSize: CGFloat = 20       // 휴지통 아이콘 (19 x 22)
    static let labelSize: CGFloat = 15      // "삭제" 글자 (글자 높이 12)
    static let labelGap: CGFloat = 3        // 원 아래 366.3 → 글줄 위 약 369.5
    static let buttonStartScale: CGFloat = 0.6 // 밀기 시작할 때 버튼 크기 (드러날수록 1로)
    static let overdragResistance: CGFloat = 0.25
    static let backSwipeEdgeWidth: CGFloat = 24 // 이 폭 안에서 시작한 오른쪽 끌기는 뒤로가기 스와이프 몫 (`PracticePrepGuideView`와 같은 값)
    static let velocityProjection: CGFloat = 0.15 // 손을 뗀 속도 × 이 시간(초)만큼 더 간다고 보고 열지 정함
    static let settle = Animation.spring(duration: 0.35, bounce: 0)
}

// MARK: - 이 컴포넌트 전용 색상

private extension AppColors {
    /// 밀어서 삭제 버튼의 빨간 원 (시스템 스와이프 삭제 버튼 측정값)
    static let swipeDeleteRed = Color(hex: 0xFF4245)
}
