import SwiftUI

/// 발표용 스팀 준비 화면. 실제 연습 세션을 시작하지 않습니다.
struct PresentationPrepGuideView: View {
    @Environment(\.designScale) private var scale
    @MotionStill private var isStill: Bool
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @Environment(\.loopAnimationsPaused) private var loopsPaused
    let onStart: () -> Void
    /// 캐러셀이 가운데에 보여 주는 칸 (손가락을 따라 소수로 움직이고, 한 바퀴 돌 때마다 4씩 커지거나 작아진다)
    @State private var position: Double = 0
    /// 드래그를 시작할 때의 캐러셀 위치
    @State private var dragStart: Double?
    /// 자동 넘김 카운트다운을 처음부터 다시 세게 하는 번호 (넘길 때 · 손을 뗄 때 바뀐다)
    @State private var autoCycle = 0

    /// 한 칸을 보여 주는 시간 (넘어가는 움직임 포함)
    private static let autoAdvanceInterval: Duration = .seconds(2.5)

    var body: some View {
        VStack(spacing: 0) {
            // MARK: 상단 바
            TopNavigationHeader(title: String(localized: "스팀 준비"), isDark: true)
                .padding(.top, ScreenMetrics.topBarTop.v(scale))

            // MARK: 워치 캐러셀 (원형)
            PrepWatchCarousel(position: position)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            // 왼쪽 띠는 뒤로가기(`swipeBackZone`) 몫이라 캐러셀 제스처 영역에서 뺀다
            .contentShape(LeftEdgeExcludedShape(edgeWidth: Layout.backSwipeZoneWidth))
            .gesture(swipe)

            // MARK: 버튼
            BottomPrimaryButton(title: String(localized: "바로 시작할 수 있어요"), action: onStart)
        }
        .ignoresSafeArea()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // 배경: 평평한 어두운 색 (워치 캐러셀 시안 #01030C)
        .background(AppColors.darkBackground.ignoresSafeArea())
        // 자동 넘김: 한 칸을 보여 준 뒤 다음 칸으로. 넘기거나 손을 뗄 때마다 처음부터 다시 센다.
        .task(id: [autoCycle, autoAdvances ? 1 : 0]) {
            guard autoAdvances else { return }
            try? await Task.sleep(for: Self.autoAdvanceInterval)
            // 손가락으로 끄는 중이면 넘기지 않는다 (손을 떼면 다시 센다)
            guard !Task.isCancelled, dragStart == nil else { return }
            showNext()
        }
        .swipeBackZone(width: Layout.backSwipeZoneWidth)
        .preferredColorScheme(.dark)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: 동작

    /// 동작 줄이기 · UI 테스트 정지 화면(`-uiTestStill`, 둘 다 `isStill`) · VoiceOver · 다른 화면에 가려졌을 때는 자동으로 넘기지 않는다
    private var autoAdvances: Bool {
        !isStill && !voiceOverEnabled && !loopsPaused
    }

    /// 가장 가까운 칸 자리 (바퀴 수를 포함한 정수, 예: 둘째 바퀴의 과다 = 5)
    private var nearestSlot: Int { Int(position.rounded()) }

    /// 손가락을 떼면 캐러셀이 자리를 찾아가는 움직임 (ease-out-quint)
    private static let settle = Animation.timingCurve(MotionCurve.easeOutQuint, duration: 0.4)

    private func moveCarousel(to slot: Int) {
        withAnimation(Self.settle) { position = Double(slot) }
    }

    /// 다음 칸: 정상 → 과다 → 부족 → 롤링 → 정상 … (원형이라 끝에서도 같은 움직임)
    private func showNext() {
        moveCarousel(to: nearestSlot + 1)
        autoCycle += 1
    }

    /// 좌우 스와이프. 손가락을 따라 캐러셀이 움직이다가 놓으면 한 칸 넘어간다 (양끝 없이 원형).
    private var swipe: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                let start = dragStart ?? position
                if dragStart == nil { dragStart = start }
                // 세로로 더 움직인 제스처는 캐러셀을 움직이지 않는다
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                let raw = start - Double(value.translation.width) / Layout.carouselPitch
                var noAnimation = Transaction()
                noAnimation.disablesAnimations = true
                withTransaction(noAnimation) { position = raw }
            }
            .onEnded { value in
                let startPosition = dragStart ?? position
                dragStart = nil
                let dx = Double(value.translation.width)
                guard abs(dx) > abs(Double(value.translation.height)) else {
                    moveCarousel(to: nearestSlot)
                    autoCycle += 1
                    return
                }
                let predicted = Double(value.predictedEndTranslation.width)
                let threshold = Layout.carouselPitch * 0.18
                let step = (dx < -threshold || predicted < -Layout.carouselPitch * 0.5) ? 1
                    : (dx > threshold || predicted > Layout.carouselPitch * 0.5) ? -1 : 0
                moveCarousel(to: Int(startPosition.rounded()) + step)
                autoCycle += 1
            }
    }
}

// MARK: - Layout (iPhone 17 시안 측정값, pt)

private enum Layout {
    static let carouselPitch: Double = 196          // 캐러셀 한 칸 이동에 필요한 손가락 거리 (칸 사이 거리와 같다)
    static let backSwipeZoneWidth: CGFloat = 50     // 밀어서 뒤로가기를 받는 왼쪽 띠 폭 (요청 이미지: 빨간 영역 100px @2x)
}

/// 화면 전체에서 왼쪽 가장자리 `edgeWidth`만 뺀 터치 영역
private struct LeftEdgeExcludedShape: Shape {
    let edgeWidth: CGFloat

    func path(in rect: CGRect) -> Path {
        Path(CGRect(x: rect.minX + edgeWidth, y: rect.minY, width: max(0, rect.width - edgeWidth), height: rect.height))
    }
}

