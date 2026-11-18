import SwiftUI

/// 홈 화면
/// - 디자인: Hi-Fi iPhone 17 - 217(워치 미연결) · 311(워치 연결됨)
///
///     ┌ 상단 행: chic 로고 · 워치 페어링 배지(연결 상태만 표시, 2026-11-13부터 누를 수 없음) · 설정
///     ├ 헤드라인 "다음 한 잔을 / 위한 작은 시작" + 설명
///     ├ 메인 연습 카드 (워치 + 피처 이미지, 좌하단 문구, 우하단 [시작하기 →]) — 누르면 (마이크 권한 →) 연습 준비 가이드 → 연습 시작
///     └ 아래 행: 가이드 카드 (스티밍 액팅 가이드) · 기록 카드 ("기록", 오른쪽 아래 기록 링)
///
/// `animatesEntrance`를 켜면 화면이 나타날 때 로고 → 헤드라인 → 설명 → 메인 카드 → 아래 카드 행 순서로
/// 아래에서 살짝 떠오르며 차례로 나타나요. (온보딩을 마치고 홈으로 넘어올 때)
struct HomeView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.designScale) private var scale
    @State private var path: [Destination] = []
    /// 저장하지 않아서 앱을 다시 실행하면 실제 연습 모드로 시작합니다.
    @State private var isPresentationMode = false
    @State private var startsPresentationFromWatch = false
    /// 등장 애니메이션을 할지
    private let animatesEntrance: Bool
    /// 화면이 실제로 보이고 있는지 (기본: 보임). 온보딩 아래에 미리 만들어 둘 때 false 로 두면,
    /// true 가 되는 순간 등장 애니메이션이 출발해요.
    private let isEntranceActive: Bool
    private let onResetOnboarding: () -> Void
    /// 홈 요소가 다 나타났는지 (등장 애니메이션을 하지 않으면 처음부터 true)
    @State private var hasEntered: Bool

    init(animatesEntrance: Bool = false, isEntranceActive: Bool = true,
         onResetOnboarding: @escaping () -> Void = {}) {
        self.animatesEntrance = animatesEntrance
        self.isEntranceActive = isEntranceActive
        self.onResetOnboarding = onResetOnboarding
        _hasEntered = State(initialValue: !animatesEntrance)
    }

    private enum Destination: Hashable {
        case microphone
        case prepGuide      // 연습 준비 가이드 → 바로 연습 시작
        case steamingGuide
        case watchSetup     // 워치 연결 과정 (설정 > 워치 페어링 > 애플 워치 연결에서 진입)
        case history
        case settings
        case presentationPractice
    }

    var body: some View {
        NavigationStack(path: $path) {
            content
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: Destination.self) { destination in
                    Group {
                        switch destination {
                        case .microphone:
                            MicrophoneAlertView {
                                guard path.last == .microphone else { return }
                                // 완료한 권한 화면은 뒤로가기 경로에 남기지 않습니다.
                                path[path.count - 1] = .prepGuide
                            }
                        case .prepGuide:
                            // 시작하기: 워치 연결 과정 없이 준비 가이드를 보여 주고 바로 연습을 시작합니다.
                            PracticePrepGuideView()
                        case .steamingGuide:
                            SteamingGuideView()
                        case .watchSetup:
                            // 워치 연결이 끝나면(완료) 들어온 설정 화면으로 돌아갑니다.
                            WatchConnectionFlow(onReady: {
                                if path.last == .watchSetup { path.removeLast() }
                            })
                        case .history:
                            HistoryView(onStartPractice: startPractice)
                        case .settings:
                            SettingsView(onWatchPairing: { path.append(.watchSetup) },
                                         onResetOnboarding: onResetOnboarding,
                                         isPresentationMode: $isPresentationMode)
                        case .presentationPractice:
                            PresentationPracticeView(startsFromWatch: $startsPresentationFromWatch)
                        }
                    }
                    .toolbar(.hidden, for: .navigationBar)
                }
        }
        .onAppear { if isEntranceActive { enter() } }
        .onChange(of: isEntranceActive) { _, isActive in
            if isActive { enter() }
        }
        .modifier(PresentationWatchStart(isEnabled: $isPresentationMode) {
            startsPresentationFromWatch = true
            path = [.presentationPractice]
        })
        .clearsPathWhenPracticeFinishes($path)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: 상단 행 (로고 · 워치 페어링 배지 · 설정)
            HStack(spacing: 0) {
                AssetImageView(name: "ChicLogo", width: 82, height: 28)
                Spacer(minLength: 0)
                // 워치 연결 상태만 보여 줘요. 연결 과정은 설정 > 워치 페어링에서 시작해요
                WatchPairingBadge()
                Button {
                    path.append(.settings)
                } label: {
                    Image("IconSettings")
                        .resizable()
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "설정"))
                .padding(.leading, Layout.badgeToSettings.h(scale))
            }
            .homeEntrance(order: 0, hasEntered: hasEntered)
            .padding(.top, Layout.logoTop.v(scale))

            // MARK: 헤드라인 + 설명
            headline
                .homeEntrance(order: 1, hasEntered: hasEntered)
                .padding(.top, Layout.headlineTop.v(scale))

            Text(String(localized: "한 잔의 시작, 작은 소리부터 함께해요"))
                .font(.pretendard(.regular, size: 16))
                .foregroundStyle(AppColors.darkSubtitle)
                .homeEntrance(order: 2, hasEntered: hasEntered)
                .padding(.top, Layout.subtitleTop.v(scale))

            // MARK: 메인 연습 카드
            HomePracticeCard(action: startPractice)
                .homeEntrance(order: 3, hasEntered: hasEntered)
                .padding(.top, Layout.heroCardTop.v(scale))

            // MARK: 가이드 카드 · 기록 카드
            HomeBottomCards(onShowGuide: { path.append(.steamingGuide) }, onShowHistory: { path.append(.history) })
                .homeEntrance(order: 4, hasEntered: hasEntered)
                .padding(.top, Layout.bottomRowTop.v(scale))

            Spacer(minLength: 0)
        }
        .padding(.horizontal, Layout.horizontalPadding.h(scale))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .ignoresSafeArea()
        .background(
            LinearGradient(
                stops: [
                    .init(color: AppColors.homeBackgroundTop, location: 0),
                    .init(color: AppColors.homeBackgroundMiddle, location: 0.68),
                    .init(color: AppColors.homeBackgroundBottom, location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .preferredColorScheme(.dark)
    }

    /// 홈 요소를 나타나게 해요. 동작 줄이기가 켜져 있으면 떠오르는 움직임 없이 바로 보여 줘요.
    private func enter() {
        guard !hasEntered else { return }
        guard !reduceMotion else {
            var instant = Transaction()
            instant.disablesAnimations = true
            withTransaction(instant) { hasEntered = true }
            return
        }
        hasEntered = true
    }

    private func startPractice() {
        if isPresentationMode {
            path = [.presentationPractice]
            return
        }
        path = [MicrophonePermission.isGranted ? .prepGuide : .microphone]
    }

    /// "다음 **한 잔**을 / 위한 작은 시작" — '한 잔'만 강조색
    private var headline: some View {
        Text("다음 \(Text("한 잔").foregroundStyle(AppColors.darkChipSelected))을\n위한 작은 시작")
            .foregroundStyle(Color.white)
            .lineSpacing(3.3)
            .font(.pretendard(.bold, size: 28))
    }
}

// MARK: - 연습이 끝나면 경로 비우기

/// 연습이 끝나는 순간(`.finished`) 홈의 이동 경로를 비워서, 결과 화면을 닫으면 홈이 보이게 해요.
///
/// 연습 상태(`PracticeSession`)는 연습 중 계속 바뀌어요 (워치로 보내는 상태가 약 1초마다 바뀜). 홈 본체가 직접 관찰하면
/// 연습 화면 뒤에 숨어 있는 홈 전체가 그때마다 다시 계산돼요. 그래서 관찰은 이 수정자만 하고, 홈 본체는 건드리지 않아요.
private struct ClearsPathWhenPracticeFinishes<Destination>: ViewModifier {
    @EnvironmentObject private var practice: PracticeSession
    @Binding var path: [Destination]

    func body(content: Content) -> some View {
        content
            .onChange(of: practice.state.phase) { previous, current in
                // 연습이 끝나면 홈으로 돌아올 수 있게 경로를 비웁니다. (결과 화면을 닫으면 홈이 보여요)
                // 결과 화면을 닫은 뒤에 비우면 아래에 있던 준비 화면이 잠깐 보였다가 밀려 나가므로,
                // 결과(로딩) 화면이 화면 전체를 덮고 있는 종료 순간에 애니메이션 없이 비워 둡니다.
                guard previous != .finished, current == .finished else { return }
                var instant = Transaction()
                instant.disablesAnimations = true
                withTransaction(instant) { path = [] }
            }
    }
}

private extension View {
    func clearsPathWhenPracticeFinishes<Destination>(_ path: Binding<[Destination]>) -> some View {
        modifier(ClearsPathWhenPracticeFinishes(path: path))
    }
}

// MARK: - Layout (iPhone 17 시안 측정값, pt)

/// 카드 안쪽 치수는 `HomeCards.swift` 에 있어요.
private enum Layout {
    static let horizontalPadding: CGFloat = 20
    static let logoTop: CGFloat = 80           // 화면 위 ↔ 로고 (Hi-Fi 311: 로고 y0 80)
    static let badgeToSettings: CGFloat = 14   // 배지 오른쪽 ↔ 설정 아이콘 (343.8 → 358)
    static let headlineTop: CGFloat = 51.5     // 로고 아래(108.5) ↔ 헤드라인 (Hi-Fi 311: 글자 위 163.7, 예전 248·253보다 8pt 아래)
    static let subtitleTop: CGFloat = 10.5     // 헤드라인 ↔ 설명 (Hi-Fi 311: 설명 글자 위 243.3)
    static let heroCardTop: CGFloat = 43       // 설명 ↔ 메인 카드 (Hi-Fi 311: 메인 카드 위 303)
    static let bottomRowTop: CGFloat = 16      // 메인 카드 ↔ 아래 행 (644 → 660)
}

// MARK: - 이 화면 전용 색상

private extension AppColors {
    // Hi-Fi 253 배경 측정 (311에서도 같음): y 5 `01030C` → y 600 `101521` → y 850 `080B16`
    static let homeBackgroundTop = Color(hex: 0x01030C)
    static let homeBackgroundMiddle = Color(hex: 0x101521)
    static let homeBackgroundBottom = Color(hex: 0x080B16)
}

#Preview {
    let connection = WatchConnection()
    HomeView()
        .environmentObject(PracticeSession(connection: connection))
        .environmentObject(connection)
}
