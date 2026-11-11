import SwiftUI

//
//  ReportReveal.swift
//
//  연습 결과 · 기록 상세 리포트(`PracticeReportScreen`)의 등장 애니메이션 (애니메이션 벤치 RES-01).
//
//  - 위 도넛: 화면이 열리면 분홍 호(주의 소리)가 시계 방향으로 1초 동안 차올라 멈춰요.
//  - 탭: 누르면 선택 표시가 0.32초 동안 미끄러지고, 새 내용이 0.18초 동안 나타나요.
//  - 막대(한 번에 보기 · 타임라인): 줄마다 왼쪽에서 오른쪽으로 0.65초 동안 드러나요 (줄 사이 0.08초 간격).
//  - 원(상태별 감지 시간): 시계 방향으로 1초 동안 차올라요. 호 끝의 아이콘은 호가 지나가면서 나타나요.
//  - 막대와 원은 탭을 눌렀을 때 55% 이상 보이는 것은 바로, 아래쪽에 있는 것은 스크롤해서 처음 보이는 순간 나와요.
//    한번 나온 것은 스크롤로 다시 나오지 않고, 탭을 누르거나 화면을 새로 열 때만 다시 나와요 (같은 탭을 다시 눌러도 다시 나와요).
//  - 동작 줄이기(Reduce Motion)가 켜져 있으면 막대·원·링이 처음부터 다 나온 상태예요 (탭 내용이 나타나는 효과도 없어요).
//

// MARK: - 사양

enum ReportMotion {
    /// 링 · 원이 차오르는 시간(초). 빠르게 출발해 끝에서 부드럽게 멈춰요 (ease-out-quart)
    static let ringDuration: TimeInterval = 1.0
    /// 막대 한 줄이 나타나는 시간(초) (ease-out-cubic)
    static let barDuration: TimeInterval = 0.65
    /// 함께 나타나는 줄 사이 간격(초). 위에서부터 차례로 나와요
    static let stagger: TimeInterval = 0.08
    /// 이만큼(55%) 보이면 나타나기 시작해요
    static let visibleThreshold: Double = 0.55
    /// 호 끝 아이콘이 나타나는 동안 호가 지나가는 각도(도)
    static let iconFadeDegrees: Double = 24
    /// 호 끝 아이콘은 호가 끝나기 이만큼(도) 전부터 나타나기 시작해요
    static let iconLeadDegrees: Double = 16

    /// 탭 선택 표시가 미끄러지는 곡선 · 시간 (ease-out-quint)
    static let tabSlide = Animation.timingCurve(MotionCurve.easeOutQuint, duration: 0.32)
    /// 새 탭 내용이 나타나는 시간(초)
    static let contentFade = Animation.easeOut(duration: 0.18)

    static func easeOutCubic(_ t: Double) -> Double { 1 - pow(1 - t, 3) }
    static func easeOutQuart(_ t: Double) -> Double { 1 - pow(1 - t, 4) }
    static func smoothstep(_ t: Double) -> Double {
        let v = min(max(t, 0), 1)
        return v * v * (3 - 2 * v)
    }
}

// MARK: - 진행 모델

/// 리포트 안에서 따로 나타나는 구역들의 진행 상태를 들고 있어요. `PracticeReportScreen`이 하나 만들어 환경으로 내려 줘요.
@Observable
final class ReportReveal {
    /// 따로 나타나는 구역
    enum Section: Hashable {
        /// 위 도넛 (화면이 열리면 바로)
        case heroRing
        /// 막대 한 줄 (탭, 위에서부터의 순서)
        case bar(PracticeReportTab, Int)
        /// 상태별 감지 시간 원 (위에서부터의 순서)
        case donut(Int)

        var duration: TimeInterval {
            switch self {
            case .heroRing, .donut: ReportMotion.ringDuration
            case .bar: ReportMotion.barDuration
            }
        }

        /// 탭 안의 구역들 (위에서부터 차례로)
        static func sections(of tab: PracticeReportTab) -> [Section] {
            switch tab {
            case .overview: (0..<4).map { .bar(.overview, $0) }
            case .timeline: (0..<2).map { .bar(.timeline, $0) }
            case .durations: (0..<2).map { .donut($0) }
            }
        }
    }

    struct Run: Equatable {
        let start: Date
        let delay: TimeInterval
        let duration: TimeInterval
    }

    enum Phase {
        case idle
        case running(Run)
        case done

        var isRunning: Bool {
            if case .running = self { true } else { false }
        }

        /// `date` 시점의 진행률 (0 → 1). 나오기 전에는 0, 다 나온 뒤에는 1이에요.
        func progress(at date: Date) -> Double {
            switch self {
            case .idle: 0
            case .done: 1
            case .running(let run):
                min(max((date.timeIntervalSince(run.start) - run.delay) / run.duration, 0), 1)
            }
        }
    }

    /// 동작 줄이기가 켜져 있으면 처음부터 다 나온 상태로 둬요
    var reduceMotion = false

    /// 화면이 실제로 보이고 있는지. 보이기 전에 미리 만들어 둔 화면(연습 결과 로딩 중 아래)에서는 꺼 두었다가,
    /// 보이는 순간 `activate()`로 켜요. 꺼져 있는 동안에는 막대·원·링이 출발하지 않아요.
    @ObservationIgnored private(set) var isActive: Bool

    private var runs: [Section: Run] = [:]
    private var finished: Set<Section> = []
    private var visible: Set<Section> = []
    @ObservationIgnored private var activeTab: PracticeReportTab
    @ObservationIgnored private var checkScheduled = false

    init(initialTab: PracticeReportTab, isActive: Bool = true) {
        activeTab = initialTab
        self.isActive = isActive
    }

    /// DEBUG 빌드에서 `-uiTestStill`을 주면 다 나온 정지 화면이에요 (Hi-Fi 대조용)
    private var isStill: Bool {
        #if DEBUG
        return reduceMotion || ProcessInfo.processInfo.arguments.contains("-uiTestStill")
        #else
        return reduceMotion
        #endif
    }

    func phase(of section: Section) -> Phase {
        if isStill || finished.contains(section) { return .done }
        if let run = runs[section] { return .running(run) }
        return .idle
    }

    // MARK: 시작

    /// 화면이 열릴 때: 위 도넛을 차오르게 해요.
    func startHero() {
        guard isActive, runs[.heroRing] == nil else { return }
        start(.heroRing, delay: 0)
    }

    /// 미리 만들어 둔 화면이 보이기 시작할 때: 화면이 열릴 때와 똑같이 위 도넛과 지금 보이는 막대·원을 출발시켜요.
    func activate() {
        guard !isActive else { return }
        isActive = true
        startHero()
        scheduleCheck()
    }

    /// 탭을 눌렀을 때: 그 탭의 막대·원을 처음 상태로 되돌리고, 지금 보이는 것부터 다시 나오게 해요.
    func select(_ tab: PracticeReportTab) {
        activeTab = tab
        for section in Section.sections(of: tab) {
            runs[section] = nil
            finished.remove(section)
        }
        scheduleCheck()
    }

    /// 스크롤로 구역이 55% 이상 보이게 되거나(true) 가려졌을 때(false)
    func setVisible(_ section: Section, _ isVisible: Bool) {
        if isVisible { visible.insert(section) } else { visible.remove(section) }
        if isVisible { scheduleCheck() }
    }

    // MARK: 내부

    /// 같은 순간에 보이게 된 구역들이 모이도록 잠깐 기다렸다가 한꺼번에 시작해요 (위에서부터 차례로 0.08초씩 늦게).
    private func scheduleCheck() {
        guard !checkScheduled else { return }
        checkScheduled = true
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(30))
            self?.checkVisible()
        }
    }

    private func checkVisible() {
        checkScheduled = false
        guard isActive else { return }
        var order = 0
        for section in Section.sections(of: activeTab) {
            guard case .idle = phase(of: section), visible.contains(section) else { continue }
            start(section, delay: ReportMotion.stagger * Double(order))
            order += 1
        }
    }

    private func start(_ section: Section, delay: TimeInterval) {
        let run = Run(start: .now, delay: delay, duration: section.duration)
        runs[section] = run
        finished.remove(section)
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(run.delay + run.duration + 0.05))
            guard let self, self.runs[section] == run else { return }
            self.finished.insert(section)
        }
    }
}

// MARK: - 환경

private struct ReportRevealKey: EnvironmentKey {
    static let defaultValue: ReportReveal? = nil
}

extension EnvironmentValues {
    /// 리포트의 등장 애니메이션 진행. 없으면(긴 화면 캡처 등) 모든 것이 다 나온 상태로 그려요.
    var reportReveal: ReportReveal? {
        get { self[ReportRevealKey.self] }
        set { self[ReportRevealKey.self] = newValue }
    }
}

// MARK: - 구역 그리기 도우미

/// 구역 하나의 진행률(0 → 1)을 받아 그려 줘요. 나오기 전에는 0, 다 나온 뒤에는 1이에요.
/// 진행 모델이 없으면(긴 화면 캡처 등) 항상 1이에요.
struct ReportRevealProgress<Content: View>: View {
    @Environment(\.reportReveal) private var reveal
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let section: ReportReveal.Section
    @ViewBuilder let content: (_ progress: Double) -> Content

    var body: some View {
        // 동작 줄이기: 첫 프레임부터 다 나온 상태로 그려요 (화면이 열린 뒤에야 켜지는 깜빡임이 없도록 환경 값을 직접 봐요)
        // 나오기 전 · 나오는 중 · 다 나온 뒤 모두 같은 TimelineView 로 그려요. 단계마다 다른 뷰로 바꿔 끼우면
        // 출발하는 순간 안쪽 뷰(막대 · 원 · 아이콘)를 통째로 새로 만들어 그 프레임이 늦어지고 깜빡일 수 있어요.
        // 나오는 중일 때만 시계가 흐르고, 나머지는 멈춰 있어요.
        if let reveal, !reduceMotion {
            let phase = reveal.phase(of: section)
            TimelineView(.animation(minimumInterval: nil, paused: !phase.isRunning)) { context in
                content(phase.progress(at: context.date))
            }
        } else {
            content(1)
        }
    }
}

extension View {
    /// 스크롤해서 이 구역이 55% 이상 보이게 되면 진행 모델에 알려요 (막대 · 원에 붙여요).
    @ViewBuilder
    func revealsWhenVisible(_ section: ReportReveal.Section, in reveal: ReportReveal?) -> some View {
        if let reveal {
            onScrollVisibilityChange(threshold: ReportMotion.visibleThreshold) { reveal.setVisible(section, $0) }
        } else {
            self
        }
    }
}
