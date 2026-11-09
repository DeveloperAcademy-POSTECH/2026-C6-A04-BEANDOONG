import SwiftUI

/// 홈 화면
/// - 디자인: Hi-Fi 변경사항 05
///
///     ┌ chic 로고
///     ├ 헤드라인 "다음 한잔을 / 위한 작은 연습" + 설명
///     ├ 메인 연습 카드 (워치 + 피처 이미지, 좌하단 문구, 우하단 [연습하기 →])
///     └ 하단 2열 카드: [워치 없이 연습] [최근 연습]
///
/// `animatesEntrance`를 켜면 화면이 나타날 때 로고 → 헤드라인 → 설명 → 메인 카드 → 하단 카드 순서로
/// 아래에서 살짝 떠오르며 차례로 나타나요. (온보딩을 마치고 홈으로 넘어올 때)
struct HomeView: View {
    @EnvironmentObject private var practice: PracticeSession
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var path: [Destination] = []
    /// 등장 애니메이션을 할지
    private let animatesEntrance: Bool
    /// 홈 요소가 다 나타났는지 (등장 애니메이션을 하지 않으면 처음부터 true)
    @State private var hasEntered: Bool

    init(animatesEntrance: Bool = false) {
        self.animatesEntrance = animatesEntrance
        _hasEntered = State(initialValue: !animatesEntrance)
    }

    private enum Destination: Hashable {
        case microphone
        case checklist(usesWatch: Bool)
        case watchSetup
        case history
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
                                path[path.count - 1] = .watchSetup
                            }
                        case .checklist(let usesWatch):
                            SessionChecklistView(usesWatch: usesWatch)
                        case .watchSetup:
                            WatchConnectionFlow()
                        case .history:
                            HistoryView(onStartPractice: startPractice)
                        }
                    }
                    .toolbar(.hidden, for: .navigationBar)
                }
        }
        .onAppear(perform: enter)
        .onChange(of: practice.state.phase) { previous, current in
            // 결과 화면의 '다시 연습'으로 종료 상태를 벗어날 때만 준비 화면으로 이동합니다.
            // 최초 연습을 어느 화면에서 시작했든 준비 화면을 목적지로 명시합니다.
            guard previous == .finished, current == .idle else { return }
            path = []
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: 로고
            AssetImageView(name: "ChicLogo", width: 82, height: 28)
                .homeEntrance(order: 0, hasEntered: hasEntered)
                .padding(.top, Layout.logoTop)

            // MARK: 헤드라인 + 설명
            headline
                .homeEntrance(order: 1, hasEntered: hasEntered)
                .padding(.top, Layout.headlineTop)

            Text("한 잔의 시작, 작은 소리부터 함께해요")
                .font(.pretendard(.regular, size: 16))
                .foregroundStyle(AppColors.darkSubtitle)
                .homeEntrance(order: 2, hasEntered: hasEntered)
                .padding(.top, Layout.subtitleTop)

            // MARK: 메인 연습 카드
            practiceCard
                .homeEntrance(order: 3, hasEntered: hasEntered)
                .padding(.top, Layout.heroCardTop)

            // MARK: 하단 2열 카드 (워치 없이 연습 / 최근 연습)
            HStack(spacing: Layout.subCardSpacing) {
                Button {
                    path.append(.checklist(usesWatch: false))
                } label: {
                    HomeSubCard(title: "워치 없이 연습", color: AppColors.homeWithoutWatchCard)
                }
                .buttonStyle(.plain)
                .homeEntrance(order: 4, hasEntered: hasEntered)

                Button {
                    path.append(.history)
                } label: {
                    HomeSubCard(title: "최근 연습", color: AppColors.homeRecentCard)
                }
                .buttonStyle(.plain)
                .homeEntrance(order: 5, hasEntered: hasEntered)
            }
            .padding(.top, Layout.subCardsTop)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, Layout.horizontalPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            LinearGradient(
                colors: AppColors.homeBackgroundGradient,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .preferredColorScheme(.dark)
    }

    /// 워치+피처 이미지 위로, 좌하단 안내 문구와 우하단 연습 버튼을 배치한 홈 카드
    private var practiceCard: some View {
        HStack(alignment: .bottom, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("애플 워치와 함께")
                Text("스티밍을 연습해요")
            }
            .font(.pretendard(.semibold, size: 20))
            .foregroundStyle(AppColors.homeCardText)

            Spacer(minLength: 0)

            HomePracticeButton(action: startPractice)
        }
        .padding(.leading, HeroCard.textLeading)
        .padding(.trailing, HeroCard.buttonTrailing)
        .padding(.bottom, HeroCard.contentBottom)
        .frame(width: HeroCard.width, height: HeroCard.height, alignment: .bottom)
        .background {
            LinearGradient(
                colors: AppColors.homePracticeCardGradient,
                startPoint: .top,
                endPoint: .bottom
            )
            .overlay(alignment: .topLeading) {
                // 이미지는 카드보다 크게 그려 왼쪽(손목)과 위쪽(스팀 노즐)이 카드 밖으로 잘립니다. (Hi-Fi 그대로)
                Image("HomeWatchPractice")
                    .resizable()
                    .frame(width: HeroCard.imageSize.width, height: HeroCard.imageSize.height)
                    .offset(HeroCard.imageOffset)
                    .accessibilityHidden(true)
            }
            .allowsHitTesting(false)
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
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
        path = [MicrophonePermission.isGranted ? .watchSetup : .microphone]
    }

    /// "다음 **한잔**을 / 위한 작은 연습" — '한잔'만 강조색
    private var headline: some View {
        VStack(alignment: .leading, spacing: 5) {
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

// MARK: - 메인 카드 연습 버튼

/// 메인 카드 우측 하단의 검정 캡슐 버튼: "연습하기 →"
private struct HomePracticeButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text("연습하기")
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .bold))
            }
            .font(.pretendard(.bold, size: 16))
            .foregroundStyle(AppColors.homePracticeButtonText)
            .frame(width: 136, height: 44)
            .background(Capsule().fill(AppColors.homePracticeButton))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 하단 서브 카드

/// 우측 상단 화살표와 좌측 하단 제목이 있는 홈 카드 (173 x 107)
private struct HomeSubCard: View {
    let title: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image("HomeArrowUpRight")
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .frame(width: 33, height: 33)
                .foregroundStyle(AppColors.homeCardText)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .accessibilityHidden(true)

            Spacer()

            Text(title)
                .font(.pretendard(.semibold, size: 20))
                .foregroundStyle(AppColors.homeCardText)
        }
        .padding(15)
        .frame(width: 173, height: 107)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(color)
        )
    }
}

// MARK: - Layout

private enum Layout {
    static let horizontalPadding: CGFloat = 20
    static let logoTop: CGFloat = 19      // 상태바 ↔ 로고
    static let headlineTop: CGFloat = 50  // 로고 ↔ 헤드라인
    static let subtitleTop: CGFloat = 10  // 헤드라인 ↔ 설명
    static let heroCardTop: CGFloat = 44  // 설명 ↔ 메인 카드
    static let subCardsTop: CGFloat = 16  // 메인 카드 ↔ 하단 2열 카드
    static let subCardSpacing: CGFloat = 16
}

/// 메인 연습 카드 치수 (Hi-Fi 측정값)
private enum HeroCard {
    static let width: CGFloat = 362
    static let height: CGFloat = 341
    /// 이미지 원본(@3x) 크기 그대로, 카드 왼쪽 위에서 (-42, -30) 만큼 밖으로 밀어 배치 (Hi-Fi와 겹쳐 맞춘 값)
    static let imageSize = CGSize(width: 469, height: 284)
    static let imageOffset = CGSize(width: -42, height: -30)
    static let textLeading: CGFloat = 15     // 카드 왼쪽 ↔ 안내 문구
    static let buttonTrailing: CGFloat = 23  // 연습 버튼 ↔ 카드 오른쪽
    static let contentBottom: CGFloat = 25   // 연습 버튼 ↔ 카드 아래
}

// MARK: - 이 화면 전용 색상

private extension AppColors {
    static let homeBackgroundGradient: [Color] = [
        Color(hex: 0x070B14),
        Color(hex: 0x111721),
        Color(hex: 0x0E131D)
    ]
    static let homePracticeCardGradient: [Color] = [Color(hex: 0xA6DDF7), Color(hex: 0xF3F8FE)]
    static let homePracticeButton = Color(hex: 0x01030C)
    static let homePracticeButtonText = Color(hex: 0xF5FAFF)
    static let homeWithoutWatchCard = Color(hex: 0x76CAF2)
    static let homeRecentCard = Color(hex: 0xF5FAFF)
    /// 밝은 카드 위 글자·화살표 색
    static let homeCardText = Color(hex: 0x01030C)
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        let connection = WatchConnection()
        HomeView()
            .environmentObject(PracticeSession(connection: connection))
            .environmentObject(connection)
    }
}
