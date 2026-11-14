import SwiftUI

/// 홈 화면
/// - 디자인: Hi-Fi iPhone 17 - 217(워치 미연결) · 311(워치 연결됨)
///
///     ┌ 상단 행: chic 로고 · 워치 페어링 배지(연결 상태만 표시, 2026-11-13부터 누를 수 없음) · 설정
///     ├ 헤드라인 "다음 한잔을 / 위한 작은 연습" + 설명
///     ├ 메인 연습 카드 (워치 + 피처 이미지, 좌하단 문구, 우하단 [연습하기 →]) — 누르면 (마이크 권한 →) 연습 준비 가이드 → 연습 시작
///     └ 아래 행: 가이드 카드 (책 아이콘, 아직 가는 곳 없음) · 기록 카드 ("연습 기록 보러가기", 오른쪽 아래 기록 링)
///
/// `animatesEntrance`를 켜면 화면이 나타날 때 로고 → 헤드라인 → 설명 → 메인 카드 → 아래 카드 행 순서로
/// 아래에서 살짝 떠오르며 차례로 나타나요. (온보딩을 마치고 홈으로 넘어올 때)
struct HomeView: View {
    @EnvironmentObject private var practice: PracticeSession
    @EnvironmentObject private var connection: WatchConnection
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.designScale) private var scale
    @State private var path: [Destination] = []
    /// 등장 애니메이션을 할지
    private let animatesEntrance: Bool
    /// 화면이 실제로 보이고 있는지 (기본: 보임). 온보딩 아래에 미리 만들어 둘 때 false 로 두면,
    /// true 가 되는 순간 등장 애니메이션이 출발해요.
    private let isEntranceActive: Bool
    /// 홈 요소가 다 나타났는지 (등장 애니메이션을 하지 않으면 처음부터 true)
    @State private var hasEntered: Bool

    init(animatesEntrance: Bool = false, isEntranceActive: Bool = true) {
        self.animatesEntrance = animatesEntrance
        self.isEntranceActive = isEntranceActive
        _hasEntered = State(initialValue: !animatesEntrance)
    }

    private enum Destination: Hashable {
        case microphone
        case prepGuide      // 연습 준비 가이드 → 바로 연습 시작
        case watchSetup     // 워치 연결 과정 (설정 > 워치 페어링 > 애플 워치 연결에서 진입)
        case history
        case settings
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
                            // 연습하기: 워치 연결 과정 없이 준비 가이드를 보여 주고 바로 연습을 시작합니다.
                            PracticePrepGuideView()
                        case .watchSetup:
                            // 워치 연결이 끝나면(완료) 들어온 설정 화면으로 돌아갑니다.
                            WatchConnectionFlow(onReady: {
                                if path.last == .watchSetup { path.removeLast() }
                            })
                        case .history:
                            HistoryView(onStartPractice: startPractice)
                        case .settings:
                            SettingsView(onWatchPairing: { path.append(.watchSetup) })
                        }
                    }
                    .toolbar(.hidden, for: .navigationBar)
                }
        }
        .onAppear { if isEntranceActive { enter() } }
        .onChange(of: isEntranceActive) { _, isActive in
            if isActive { enter() }
        }
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

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: 상단 행 (로고 · 워치 페어링 배지 · 설정)
            HStack(spacing: 0) {
                AssetImageView(name: "ChicLogo", width: 82, height: 28)
                Spacer(minLength: 0)
                // 워치 연결 상태만 보여 줘요. 연결 과정은 설정 > 워치 페어링에서 시작해요
                WatchPairingBadge(isConnected: connection.isReachable)
                Button {
                    path.append(.settings)
                } label: {
                    Image("IconSettings")
                        .resizable()
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("설정")
                .padding(.leading, Layout.badgeToSettings.h(scale))
            }
            .homeEntrance(order: 0, hasEntered: hasEntered)
            .padding(.top, Layout.logoTop.v(scale))

            // MARK: 헤드라인 + 설명
            headline
                .homeEntrance(order: 1, hasEntered: hasEntered)
                .padding(.top, Layout.headlineTop.v(scale))

            Text("한 잔의 시작, 작은 소리부터 함께해요")
                .font(.pretendard(.regular, size: 16))
                .foregroundStyle(AppColors.darkSubtitle)
                .homeEntrance(order: 2, hasEntered: hasEntered)
                .padding(.top, Layout.subtitleTop.v(scale))

            // MARK: 메인 연습 카드
            practiceCard
                .homeEntrance(order: 3, hasEntered: hasEntered)
                .padding(.top, Layout.heroCardTop.v(scale))

            // MARK: 가이드 카드 · 기록 카드
            HStack(spacing: Layout.bottomCardSpacing.h(scale)) {
                guideCard
                recordCard
            }
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

    /// 워치+피처 이미지 위로, 좌하단 안내 문구와 우하단 연습 버튼을 배치한 홈 카드
    /// - 카드 어디를 눌러도 우하단 [연습하기 →]와 같은 동작을 한다 (카드 전체가 버튼)
    private var practiceCard: some View {
        Button(action: startPractice) { practiceCardContent }
            .buttonStyle(HomeCardPressStyle(reduceMotion: reduceMotion))
            .accessibilityLabel("연습하기")
            .accessibilityHint("애플 워치와 함께 스티밍 연습을 시작해요")
    }

    private var practiceCardContent: some View {
        // 문구 두 줄과 버튼은 세로 가운데를 맞춰요 (Hi-Fi 311)
        HStack(alignment: .center, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("애플 워치와 함께")
                Text("스티밍을 연습해요")
            }
            .font(.pretendard(.semibold, size: 20))
            .foregroundStyle(AppColors.homeCardText)

            Spacer(minLength: 0)

            HomeCardCapsule(title: "연습하기", width: Layout.buttonWidth.h(scale))
        }
        .padding(.leading, Layout.cardTextLeading.h(scale))
        .padding(.trailing, Layout.cardButtonTrailing.h(scale))
        .padding(.bottom, Layout.cardContentBottom.v(scale))
        .frame(width: Layout.cardWidth.h(scale), height: Layout.heroCardHeight.v(scale), alignment: .bottom)
        .background {
            LinearGradient(
                stops: AppColors.homePracticeCardGradient,
                startPoint: .top,
                endPoint: .bottom
            )
            .overlay(alignment: .topLeading) {
                // 이미지는 카드보다 크게 그려 왼쪽(손목)과 위쪽(스팀 노즐)이 카드 밖으로 잘립니다. (Hi-Fi 그대로)
                Image("HomeWatchPractice")
                    .resizable()
                    // 카드 높이는 세로 비율로 줄므로 이미지도 가로·세로 중 작은 비율(fit)로 줄여야 SE처럼 짧은 화면에서 아래 문구를 덮지 않는다
                    .frame(width: HeroImage.size.width * scale.fit, height: HeroImage.size.height * scale.fit)
                    .offset(x: HeroImage.offset.width * scale.fit, y: HeroImage.offset.height * scale.fit)
                    .accessibilityHidden(true)
            }
            .allowsHitTesting(false)
        }
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous))
    }

    /// "가이드" 카드 (오른쪽 위에 책 아이콘이 카드 밖으로 잘려 걸쳐 있음)
    /// - 누를 수 있는 버튼만 있고, 가는 곳은 아직 정하지 않았어요.
    private var guideCard: some View {
        Button {
            // TODO: 가이드 화면 연결 (가는 곳이 정해지면)
        } label: {
            bottomCardContent(title: "가이드", width: Layout.guideCardWidth.h(scale)) {
                Image("IllustGuideBook")
                    .resizable()
                    .frame(width: Layout.guideBookSize.width.h(scale), height: Layout.guideBookSize.height.h(scale))
                    .offset(x: Layout.guideBookOffset.width.h(scale), y: Layout.guideBookOffset.height.v(scale))
            }
        }
        .buttonStyle(HomeCardPressStyle(reduceMotion: reduceMotion))
        .accessibilityLabel("가이드")
    }

    /// "연습 기록 보러가기" 카드 (오른쪽 아래에 기록 링 에셋이 카드 밖으로 잘려 걸쳐 있음)
    private var recordCard: some View {
        Button { path.append(.history) } label: {
            bottomCardContent(title: "연습 기록 보러가기", width: recordCardWidth) {
                // 링 에셋을 시계 방향으로 60° 돌려 분홍 호가 12시 ~ 4시 쪽에 오게 해요 (Hi-Fi 311)
                Image("IllustRecordRing")
                    .resizable()
                    .frame(width: Layout.ringSize.h(scale), height: Layout.ringSize.h(scale))
                    .rotationEffect(Layout.ringRotation)
                    .offset(x: Layout.ringOffset.width.h(scale), y: Layout.ringOffset.height.v(scale))
            }
        }
        .buttonStyle(HomeCardPressStyle(reduceMotion: reduceMotion))
        .accessibilityLabel("기록 보기")
        .accessibilityHint("연습 기록을 확인해요")
    }

    /// 기록 카드 폭: 메인 카드 폭에서 가이드 카드와 사이 간격을 뺀 나머지 (오른쪽 끝을 메인 카드와 맞춰요)
    private var recordCardWidth: CGFloat {
        (Layout.cardWidth - Layout.guideCardWidth - Layout.bottomCardSpacing).h(scale)
    }

    /// 아래 행 카드 모양: 밝은 바탕에 왼쪽 아래 제목, 왼쪽 위 기준으로 놓는 그림이 카드 밖으로 잘려요.
    /// - 카드 전체가 버튼이에요.
    private func bottomCardContent<Art: View>(title: String, width: CGFloat, @ViewBuilder art: () -> Art) -> some View {
        Text(title)
            .font(.pretendard(.semibold, size: 20))
            .foregroundStyle(AppColors.homeCardText)
            .padding(.leading, Layout.cardTextLeading.h(scale))
            .padding(.bottom, Layout.bottomCardTextBottom.v(scale))
            .frame(width: width, height: Layout.bottomCardHeight.v(scale), alignment: .bottomLeading)
            .background(alignment: .topLeading) {
                AppColors.homeRecentCard
                    .overlay(alignment: .topLeading) {
                        art().accessibilityHidden(true)
                    }
                    .allowsHitTesting(false)
            }
            .clipShape(RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous))
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
        path = [MicrophonePermission.isGranted ? .prepGuide : .microphone]
    }

    /// "다음 **한잔**을 / 위한 작은 연습" — '한잔'만 강조색
    private var headline: some View {
        VStack(alignment: .leading, spacing: 3.3) { // Hi-Fi 253: 헤드라인 줄 간격 37
            HStack(spacing: 0) {
                Text("다음 ")
                    .foregroundStyle(Color.white)
                Text("한잔")
                    .foregroundStyle(AppColors.darkChipSelected)
                Text("을")
                    .foregroundStyle(Color.white)
            }
            Text("위한 작은 연습")
                .foregroundStyle(Color.white)
        }
        .font(.pretendard(.bold, size: 28))
    }
}

// MARK: - 등장 애니메이션

/// 홈 요소가 차례로 떠오르는 타이밍
/// - 온보딩이 걷히기 시작하고 0.15초 뒤에 첫 요소가 출발하고, 요소 사이는 0.06초씩 늦게 출발해요.
/// - 각 요소는 12pt 아래에서 0.45초 동안 떠오르며 나타나요 (스플래시·온보딩과 같은 ease-out-expo).
private enum HomeEntranceMotion {
    static let startDelay: TimeInterval = 0.15
    static let stagger: TimeInterval = 0.06
    static let duration: TimeInterval = 0.45
    static let riseDistance: CGFloat = 12

    static func animation(order: Int) -> Animation {
        Animation.timingCurve(MotionCurve.easeOutExpo, duration: duration)
            .delay(startDelay + stagger * Double(order))
    }
}

private extension View {
    /// `order`번째로 나타나는 홈 요소: 나타나기 전에는 투명하게 조금 아래에 있다가 제자리로 떠올라요.
    func homeEntrance(order: Int, hasEntered: Bool) -> some View {
        self
            .opacity(hasEntered ? 1 : 0)
            .offset(y: hasEntered ? 0 : HomeEntranceMotion.riseDistance)
            .animation(HomeEntranceMotion.animation(order: order), value: hasEntered)
    }
}

// MARK: - 카드 버튼

/// 메인 카드 우측의 검정 캡슐: "연습하기 →" (136 x 44)
/// - 카드 전체가 버튼이라 캡슐은 모양만 그린다 (따로 누르는 버튼이 아님, 접근성에서도 숨김)
private struct HomeCardCapsule: View {
    let title: String
    var width: CGFloat = 136

    var body: some View {
        HStack(spacing: 4) {
            Text(title)
            Image(systemName: "arrow.right")
                .font(.system(size: 14, weight: .bold))
        }
        .font(.pretendard(.bold, size: 16))
        .foregroundStyle(AppColors.homePracticeButtonText)
        .frame(width: width, height: 44)
        .background(Capsule().fill(AppColors.homePracticeButton))
        .accessibilityHidden(true)
    }
}

/// 홈 카드를 누르는 동안 살짝 눌리는 느낌을 주는 스타일 (눌리면 98%로 줄고 조금 어두워짐)
/// - 동작 줄이기가 켜져 있으면 크기는 그대로 두고 밝기만 바꾼다
private struct HomeCardPressStyle: ButtonStyle {
    let reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - 워치 페어링 배지

/// 상단 행의 "워치 페어링" 알약 (연결됨: 초록 테두리·진초록 채움·✓ / 안 됨: 회색 테두리·회색 ✓)
/// - Hi-Fi 217·311: 91.5 x 27, 테두리 1.5, 아이콘 원 14, 글자 Regular 10
/// - 2026-11-14 시안부터 안 됨도 ✕ 대신 ✓ 이고, 색으로만 상태를 나눠요.
private struct WatchPairingBadge: View {
    let isConnected: Bool

    var body: some View {
        HStack(spacing: 6) {
            ZStack {
                Circle().fill(accent)
                Image(systemName: "checkmark")
                    .font(.system(size: 7, weight: .black))
                    .foregroundStyle(AppColors.darkBackground)
            }
            .frame(width: 14, height: 14)

            Text("워치 페어링")
                .font(.pretendard(.regular, size: 10))
                .foregroundStyle(accent)
        }
        .padding(.leading, 9.5)
        .padding(.trailing, 10)
        .frame(width: 91, height: 27)
        .background(Capsule().fill(isConnected ? AppColors.homeBadgeConnectedFill : Color.clear))
        .overlay(Capsule().strokeBorder(accent, lineWidth: 1.5))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isConnected ? "워치 페어링됨" : "워치 페어링 안 됨")
    }

    private var accent: Color {
        isConnected ? AppColors.soundRolling : AppColors.homeBadgeDisconnected
    }
}

// MARK: - Layout (iPhone 17 시안 측정값, pt)

private enum Layout {
    static let horizontalPadding: CGFloat = 20
    static let logoTop: CGFloat = 80           // 화면 위 ↔ 로고 (Hi-Fi 311: 로고 y0 80)
    static let badgeToSettings: CGFloat = 14   // 배지 오른쪽 ↔ 설정 아이콘 (343.8 → 358)
    static let headlineTop: CGFloat = 51.5     // 로고 아래(108.5) ↔ 헤드라인 (Hi-Fi 311: 글자 위 163.7, 예전 248·253보다 8pt 아래)
    static let subtitleTop: CGFloat = 10.5     // 헤드라인 ↔ 설명 (Hi-Fi 311: 설명 글자 위 243.3)
    static let heroCardTop: CGFloat = 43       // 설명 ↔ 메인 카드 (Hi-Fi 311: 메인 카드 위 303)
    static let cardWidth: CGFloat = 362        // Hi-Fi 311: 메인 카드 x 20 ~ 382
    static let heroCardHeight: CGFloat = 341   // Hi-Fi 311: 303 ~ 644
    static let cardCornerRadius: CGFloat = 12
    static let cardTextLeading: CGFloat = 15.5 // 카드 왼쪽 ↔ 글자 (Hi-Fi 311: 글자 x 35.7)
    static let cardButtonTrailing: CGFloat = 23 // 연습하기 버튼 ↔ 카드 오른쪽 (Hi-Fi 311: 버튼 359 → 382)
    // 문구 두 줄(약 52)이 버튼(44)보다 높아 여백은 문구 아래에 붙어요. 버튼 아래는 4pt 더 떠서 Hi-Fi 311의 619 → 644(25)가 돼요.
    static let cardContentBottom: CGFloat = 21
    static let buttonWidth: CGFloat = 136

    // 아래 행: 가이드 카드 · 기록 카드 (Hi-Fi 311: y 660 ~ 767)
    static let bottomRowTop: CGFloat = 16      // 메인 카드 ↔ 아래 행 (644 → 660)
    static let bottomCardHeight: CGFloat = 107
    static let bottomCardSpacing: CGFloat = 16 // 가이드 카드 ↔ 기록 카드 (115 → 131)
    // 가이드 카드 폭 (Hi-Fi 311: x 20 ~ 115). 기록 카드는 나머지 251이에요.
    // 시안의 기록 카드는 252(오른쪽 끝 383)로 메인 카드보다 1pt 더 나가 있어서, 오른쪽 끝을 메인 카드에 맞췄어요.
    static let guideCardWidth: CGFloat = 95
    static let bottomCardTextBottom: CGFloat = 15.5 // 제목 ↔ 카드 아래 (Hi-Fi 311: 글자 아래 748.3 → 767)
    static let guideBookSize = CGSize(width: 191.0 / 3, height: 174.0 / 3) // `IllustGuideBook` @3x 191×174
    static let guideBookOffset = CGSize(width: 43, height: 13)              // 가이드 카드 왼쪽 위 기준 (Hi-Fi 311: 책 x 63, y 673)
    static let ringSize: CGFloat = 155                 // `IllustRecordRing` 크기
    static let ringRotation = Angle.degrees(60)        // 분홍 호: 에셋 -161° ~ -42° → 시안 -101° ~ 16°
    static let ringOffset = CGSize(width: 90, height: 9.25) // 기록 카드 왼쪽 위 기준 (Hi-Fi 311: 링 중심 298.5, 746.75)
}

/// 메인 카드 사진: 원본(@3x) 크기 그대로, 카드 왼쪽 위에서 밀어 배치
private enum HeroImage {
    static let size = CGSize(width: 469, height: 284)
    static let offset = CGSize(width: -42, height: -30)
}

// MARK: - 이 화면 전용 색상

private extension AppColors {
    // Hi-Fi 253 배경 측정 (311에서도 같음): y 5 `01030C` → y 600 `101521` → y 850 `080B16`
    static let homeBackgroundTop = Color(hex: 0x01030C)
    static let homeBackgroundMiddle = Color(hex: 0x101521)
    static let homeBackgroundBottom = Color(hex: 0x080B16)
    /// 메인 카드 바탕: 위 절반 가까이는 하늘색 그대로, 그 아래부터 밝아져요 (Hi-Fi 311 측정)
    static let homePracticeCardGradient: [Gradient.Stop] = [
        .init(color: Color(hex: 0xA6DDF7), location: 0),
        .init(color: Color(hex: 0xA6DDF7), location: 0.45),
        .init(color: Color(hex: 0xF5FAFF), location: 1)
    ]
    static let homePracticeButton = Color(hex: 0x01030C)
    static let homePracticeButtonText = Color(hex: 0xF5FAFF)
    static let homeRecentCard = Color(hex: 0xF5FAFF)
    /// 밝은 카드 위 글자·화살표 색
    static let homeCardText = Color(hex: 0x01030C)
    /// 워치 페어링 배지 — 연결됨 채움 / 안 됨 테두리·글자·아이콘 (Hi-Fi 311·217 측정)
    static let homeBadgeConnectedFill = Color(hex: 0x0A3A1B)
    static let homeBadgeDisconnected = Color(hex: 0xCCCCCC)
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        let connection = WatchConnection()
        HomeView()
            .environmentObject(PracticeSession(connection: connection))
            .environmentObject(connection)
    }
}
