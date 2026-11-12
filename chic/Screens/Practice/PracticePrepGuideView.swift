import SwiftUI

/// 연습 준비 가이드 — 연습을 시작하기 전에 워치 화면 색 의미를 안내한다
/// - 새 시안 4장 — 워치 화면 4종(정상·과다·부족·롤링)을 좌우로 넘겨 보는 캐러셀 (`PrepWatchCarousel`)
/// - 2026-11-13: "휴대폰은 머신 가까이" 쪽(머신+휴대폰, Hi-Fi 249)은 사용자 결정으로 삭제
///
///     ┌ 상단 바: < 연습 준비
///     ├ 워치 캐러셀 + 점 4개
///     ├ 타이틀 + 설명
///     └ 버튼 "연습 시작하기" (어느 칸에서든 바로 소리 인식 대기로)
///
/// 4칸(정상 → 과다 → 부족 → 롤링)이 일정 시간마다 한 칸씩 옆으로 넘어가고, 롤링 다음에는 다시 정상으로 돌아간다.
/// 칸은 원형으로 이어져 있어서 롤링 → 정상도 다른 칸과 같은 캐러셀 움직임이다 (2026-11-13: 쪽 넘김이 어색해 바꿈).
/// 좌우 스와이프로도 양쪽 방향 모두 끝없이 넘길 수 있고, 손을 대면 자동 넘김은 손을 뗀 때부터 다시 센다.
/// 왼쪽 50pt 띠에서 오른쪽으로 밀면 이전 화면으로 돌아가고(시스템 뒤로가기), 그 밖에서는 캐러셀이 넘어간다.
struct PracticePrepGuideView: View {
    @Environment(\.designScale) private var scale
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @Environment(\.loopAnimationsPaused) private var loopsPaused
    @EnvironmentObject private var practice: PracticeSession
    /// 진입 경로에서 정한 워치 사용 여부
    var usesWatch = true
    /// 캐러셀이 가운데에 보여 주는 칸 (손가락을 따라 소수로 움직이고, 한 바퀴 돌 때마다 4씩 커지거나 작아진다)
    @State private var position: Double
    /// 드래그를 시작할 때의 캐러셀 위치
    @State private var dragStart: Double?
    /// 자동 넘김 카운트다운을 처음부터 다시 세게 하는 번호 (넘길 때 · 손을 뗄 때 바뀐다)
    @State private var autoCycle = 0

    /// `state`: 처음 보여 줄 칸 0...3 (정상 · 과다 · 부족 · 롤링, UI 테스트용 시작 위치)
    init(usesWatch: Bool = true, state: Int = 0) {
        self.usesWatch = usesWatch
        _position = State(initialValue: Double(min(max(state, 0), PrepWatchState.allCases.count - 1)))
    }

    /// 한 칸을 보여 주는 시간 (넘어가는 움직임 포함)
    private static let autoAdvanceInterval: Duration = .seconds(2.5)

    var body: some View {
        VStack(spacing: 0) {
            // MARK: 상단 바
            TopNavigationHeader(title: "연습 준비", isDark: true)
                .padding(.top, Layout.topBarTop.v(scale))

            // MARK: 워치 캐러셀 (원형)
            PrepWatchCarousel(position: position)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            // 왼쪽 띠는 뒤로가기(`swipeBackZone`) 몫이라 캐러셀 제스처 영역에서 뺀다
            .contentShape(LeftEdgeExcludedShape(edgeWidth: Layout.backSwipeZoneWidth))
            .gesture(swipe)

            // MARK: 버튼
            DarkPrimaryButton(
                title: "연습 시작하기",
                width: Layout.buttonWidth.h(scale),
                height: BottomButton.height,
                action: startPractice
            )
            .padding(.bottom, BottomButton.bottomGap.v(scale) + scale.fixedHeightAdjustment(BottomButton.height))
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

    /// 동작 줄이기 · VoiceOver · UI 테스트 정지 화면 · 다른 화면에 가려졌을 때는 자동으로 넘기지 않는다
    private var autoAdvances: Bool {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-uiTestStill") { return false }
        #endif
        return !reduceMotion && !voiceOverEnabled && !loopsPaused
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

    /// "연습 시작하기": 어느 칸에서든 안내를 마치고 바로 소리 인식(연습)을 시작한다
    private func startPractice() {
        Task { await practice.start(usingWatch: usesWatch) }
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
    static let topBarTop: CGFloat = 84              // 화면 위 ↔ 상단 바 (Hi-Fi 249: 글자 y0 86.5 − 2.5)
    static let carouselPitch: Double = 196          // 캐러셀 한 칸 이동에 필요한 손가락 거리 (칸 사이 거리와 같다)
    static let buttonWidth: CGFloat = 363
    static let backSwipeZoneWidth: CGFloat = 50     // 밀어서 뒤로가기를 받는 왼쪽 띠 폭 (요청 이미지: 빨간 영역 100px @2x)
}

/// 화면 전체에서 왼쪽 가장자리 `edgeWidth`만 뺀 터치 영역
private struct LeftEdgeExcludedShape: Shape {
    let edgeWidth: CGFloat

    func path(in rect: CGRect) -> Path {
        Path(CGRect(x: rect.minX + edgeWidth, y: rect.minY, width: max(0, rect.width - edgeWidth), height: rect.height))
    }
}

#Preview {
    let connection = WatchConnection()
    PracticePrepGuideView()
        .environmentObject(PracticeSession(connection: connection))
}
