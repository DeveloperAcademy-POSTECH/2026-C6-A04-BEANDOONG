import QuartzCore
import SwiftUI

// MARK: - 모션 곡선

/// 화면 애니메이션에서 같이 쓰는 가감속 곡선 (CSS cubic-bezier 와 같은 값)
///
/// 값은 애니메이션 벤치(Animation Bench)에서 정한 사양을 그대로 옮겼어요.
enum MotionCurve {
    /// 빠르게 출발해 끝에서 아주 길게 멈춤 (ease-out-expo)
    /// - 스플래시 로고가 떠오를 때, 온보딩 내용이 들어올 때
    static let easeOutExpo = UnitCurve.bezier(
        startControlPoint: UnitPoint(x: 0.16, y: 1),
        endControlPoint: UnitPoint(x: 0.3, y: 1)
    )

    /// 빠르게 출발해 아주 부드럽게 멈춤 (ease-out-quint)
    /// - 연습 결과 탭 선택 표시가 미끄러질 때
    static let easeOutQuint = UnitCurve.bezier(
        startControlPoint: UnitPoint(x: 0.22, y: 1),
        endControlPoint: UnitPoint(x: 0.36, y: 1)
    )

    /// 빠르게 출발해 부드럽게 멈춤 (ease-out-quart)
    /// - 연습 결과 도넛 링이 차오를 때
    static let easeOutQuart = UnitCurve.bezier(
        startControlPoint: UnitPoint(x: 0.25, y: 1),
        endControlPoint: UnitPoint(x: 0.5, y: 1)
    )

    /// 끝에서 덜 늘어지는 ease-out (ease-out-quad)
    /// - 스플래시 로고의 흐림이 걷힐 때
    static let easeOutQuad = UnitCurve.bezier(
        startControlPoint: UnitPoint(x: 0.5, y: 1),
        endControlPoint: UnitPoint(x: 0.89, y: 1)
    )

    /// 천천히 출발해 점점 빨라짐 (ease-in)
    /// - 온보딩 내용이 밀려 나갈 때
    static let easeIn = UnitCurve.bezier(
        startControlPoint: UnitPoint(x: 0.4, y: 0),
        endControlPoint: UnitPoint(x: 1, y: 1)
    )

    /// 천천히 출발해 천천히 멈춤 (ease-in-out)
    /// - 온보딩 페이지 표시가 다음 자리로 옮겨 갈 때
    static let easeInOut = UnitCurve.bezier(
        startControlPoint: UnitPoint(x: 0.65, y: 0),
        endControlPoint: UnitPoint(x: 0.35, y: 1)
    )
}

// MARK: - 첫 프레임 기다리기

/// 화면이 처음 그려진 뒤에 애니메이션을 시작하게 해 주는 도우미
///
/// 화면이 나타나는 순간(`onAppear`)에는 아직 뷰를 만들고 배치하는 중이라, 첫 프레임이 늦게 그려지면
/// 그동안 흐른 애니메이션 앞부분이 건너뛰어져 "툭" 튀어 보여요.
/// 다음 화면 갱신(디스플레이 링크 한 번)을 기다린 뒤 시작하면 애니메이션이 처음부터 끝까지 다 보여요.
///
///     .task {
///         await FrameClock.nextFrame()
///         withAnimation(...) { ... }
///     }
@MainActor
enum FrameClock {
    static func nextFrame() async {
        await withCheckedContinuation { continuation in
            FrameWaiter(continuation: continuation).start()
        }
    }
}

/// 디스플레이 링크를 한 번만 받고 멈추는 객체 (`FrameClock` 전용)
@MainActor
private final class FrameWaiter: NSObject {
    private var continuation: CheckedContinuation<Void, Never>?
    private var link: CADisplayLink?

    init(continuation: CheckedContinuation<Void, Never>) {
        self.continuation = continuation
    }

    func start() {
        let link = CADisplayLink(target: self, selector: #selector(tick))
        link.add(to: .main, forMode: .common)
        self.link = link // 링크가 이 객체를 붙잡고 있다가 invalidate 할 때 놓아요.
    }

    @objc private func tick() {
        link?.invalidate()
        link = nil
        continuation?.resume()
        continuation = nil
    }
}

// MARK: - 가려진 화면의 반복 애니메이션 멈춤

/// 화면이 다른 것(스플래시, 연습 화면, 아직 넘어오지 않은 쪽)에 가려져 있는 동안 반복 애니메이션을 멈춰 두는 값
///
/// 켜져 있으면 `LoopTimeline` 이 시계를 멈추고 첫 프레임(0)만 그려요. 꺼지는 순간 0부터 다시 시작해서,
/// 화면이 보이기 시작할 때의 모습이 "화면이 나타날 때 0부터" 와 같아요. 기본값은 false 예요.
private struct LoopAnimationsPausedKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var loopAnimationsPaused: Bool {
        get { self[LoopAnimationsPausedKey.self] }
        set { self[LoopAnimationsPausedKey.self] = newValue }
    }
}

// MARK: - 반복 애니메이션 시계

/// 반복 애니메이션용 시계: 화면에 나타난 순간부터 흐른 시간을 한 주기 안의 진행률(0 이상 1 미만)로 넘겨 줘요.
///
/// - 화면에 나타날 때마다 0부터 다시 시작해요. 벤치(Animation Bench)도 화면이 열리는 순간 0초부터 재생해요.
/// - 경과 시간을 주기로 나눈 나머지를 쓰기 때문에 반복할 때 이음새가 튀지 않아요.
/// - 동작 줄이기(Reduce Motion)가 켜져 있으면 시계를 멈추고 `restProgress`(Hi-Fi 정지 화면 지점)만 넘겨요.
/// - DEBUG 빌드에서 `-uiTestStill` 런치 아규먼트를 주면 동작 줄이기와 같이 정지 화면으로 멈춰요 (Hi-Fi 대조용).
///
///     LoopTimeline(period: 1.4) { progress in
///         Spinner(progress: progress)
///     }
struct LoopTimeline<Content: View>: View {
    /// 한 주기 길이(초)
    let period: TimeInterval
    /// 동작 줄이기에서 멈춰 둘 지점 (주기 대비 0 이상 1 미만). Hi-Fi 정지 화면과 같은 지점이에요.
    var restProgress: Double = 0
    @ViewBuilder let content: (_ progress: Double) -> Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.loopAnimationsPaused) private var isPaused
    @State private var startDate = Date.now

    private var isStill: Bool {
        #if DEBUG
        return reduceMotion || ProcessInfo.processInfo.arguments.contains("-uiTestStill")
        #else
        return reduceMotion
        #endif
    }

    var body: some View {
        if isStill {
            content(restProgress)
        } else {
            // 멈춰 있을 때도 같은 TimelineView 를 써서, 다시 움직일 때 안쪽 뷰를 새로 만들지 않아요.
            TimelineView(.animation(minimumInterval: nil, paused: isPaused)) { context in
                content(progress(at: context.date))
            }
            .onAppear { startDate = .now }
            .onChange(of: isPaused) { _, paused in
                if !paused { startDate = .now }
            }
        }
    }

    private func progress(at date: Date) -> Double {
        if isPaused { return 0 }
        let elapsed = max(0, date.timeIntervalSince(startDate))
        return elapsed.truncatingRemainder(dividingBy: period) / period
    }
}

// MARK: - 전파 점등 타이밍

/// 전파를 안쪽부터 하나씩 켰다가 다 켜지면 한꺼번에 끄고 반복하는 타이밍 (아이폰·워치 전파, 스팀 머신 옆 전파)
///
///     0.00s  전파 1 켜짐 (fade 동안)
///     0.25s  전파 2 켜짐 (step 간격)
///     ...    다 켜진 채 유지
///     offAt  전부 한꺼번에 꺼짐 (offLen 동안)
///     나머지  꺼진 채 쉬고 반복
///
/// 값은 애니메이션 벤치의 `RADIO_MS` 와 같아요 (Material 3 duration 토큰: short 50–200ms · medium 250–400ms).
struct RadioRevealTiming {
    /// 한 주기 길이(초)
    let period: TimeInterval
    /// 전파 사이 켜지는 간격: 하나씩 켜지는 순서가 읽히는 가장 짧은 간격
    let step: TimeInterval
    /// 한 전파가 켜지는 데 걸리는 시간
    let fade: TimeInterval
    /// 전부 꺼지기 시작하는 시점
    let offAt: TimeInterval
    /// 꺼지는 데 걸리는 시간 (사라지는 쪽을 조금 길게)
    let offLen: TimeInterval

    /// 아이폰 + 워치 (ONB-01 · WCH-01): 다 켜진 채 0.6초 유지 → 꺼진 채 0.35초 쉬고 반복
    static let phoneWatch = RadioRevealTiming(period: 1.8, step: 0.25, fade: 0.15, offAt: 1.25, offLen: 0.2)
    /// 스팀 머신 + 폰 (ONB-02): 전파 3개 뒤 네 번째 박자(0.75초)에 폰 위 신호 선 3개가 함께 켜져요. 유지·쉬는 시간은 같아요.
    static let machinePhone = RadioRevealTiming(period: 2.05, step: 0.25, fade: 0.15, offAt: 1.5, offLen: 0.2)

    /// 동작 줄이기에서 멈춰 둘 지점: 모두 켜진 채 꺼지기 직전 (= Hi-Fi 정지 화면)
    var restProgress: Double { offAt / period - 0.001 }

    /// `index`번째(0부터) 요소의 투명도. `time` 은 한 주기 안의 시간(초)이에요.
    func opacity(index: Int, time: TimeInterval) -> Double {
        let turnOn = Self.clamp01((time - step * Double(index)) / fade)
        let turnOff = 1 - Self.clamp01((time - offAt) / offLen)
        return turnOn * turnOff
    }

    private static func clamp01(_ value: Double) -> Double { min(max(value, 0), 1) }
}
