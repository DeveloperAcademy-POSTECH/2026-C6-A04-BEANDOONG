import SwiftUI

/// 홈 화면
/// - 디자인: Hi-Fi/iPhone 17 - 120.png
///
///     ┌ chic 로고
///     ├ 헤드라인 "다음 한잔을 / 위한 작은 연습" + 설명
///     ├ 메인 히어로 카드 (피처 이미지)
///     └ 하단 2열 카드: [연습 가이드] [최근 연습]
struct HomeView: View {
    @EnvironmentObject private var practice: PracticeSession
    @State private var path: [Destination] = []

    private enum Destination: Hashable {
        case microphone
        case checklist
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
                        case .checklist:
                            SessionChecklistView()
                        case .watchSetup:
                            WatchConnectionFlow()
                        case .history:
                            HistoryView()
                        }
                    }
                    .toolbar(.hidden, for: .navigationBar)
                }
        }
        .onChange(of: practice.state.phase) { previous, current in
            // 결과 화면의 '다시 연습'으로 종료 상태를 벗어날 때만 준비 화면으로 이동합니다.
            // 최초 연습을 어느 화면에서 시작했든 준비 화면을 목적지로 명시합니다.
            guard previous == .finished, current == .idle else { return }
            path = [.checklist]
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: 로고
            AssetImageView(name: "ChicLogo", width: 84, height: 31)
                .padding(.top, Layout.logoTop)

            // MARK: 헤드라인 + 설명
            headline
                .padding(.top, Layout.headlineTop)

            Text("한 잔의 시작, 작은 소리부터 함께해요")
                .font(.pretendard(.regular, size: 15))
                .foregroundStyle(AppColors.darkSubtitle)
                .padding(.top, Layout.subtitleTop)

            // MARK: 메인 연습 카드
            practiceCard
                .padding(.top, Layout.heroCardTop)

            // MARK: 하단 2열 카드 (연습 가이드 / 최근 연습)
            HStack(spacing: 15) {
                HomeSubCard(title: "연습 가이드", color: AppColors.homeGuideCard)
                Button {
                    path.append(.history)
                } label: {
                    HomeSubCard(title: "최근 연습", color: AppColors.homeRecentCard, width: 173)
                }
                .buttonStyle(.plain)
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

    /// 피처 이미지와 안내 문구 위에 독립된 연습 버튼을 배치한 홈 카드
    private var practiceCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("실시간 피드백과 함께")
                Text("함께 스티밍을 연습해요")
            }
            .font(.pretendard(.semibold, size: 20))
            .foregroundStyle(Color.white)

            Spacer()

            HomePracticeButton {
                path.append(MicrophonePermission.isGranted ? .watchSetup : .microphone)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 17)
        .frame(width: 362, height: 262)
        .background {
            LinearGradient(
                colors: AppColors.homePracticeCardGradient,
                startPoint: .top,
                endPoint: .bottom
            )
            .overlay(alignment: .trailing) {
                Image("HomePitcher")
                    .resizable()
                    .frame(width: 342, height: 385)
                    .opacity(0.82)
                    .accessibilityHidden(true)
            }
            .allowsHitTesting(false)
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    /// "다음 **한잔**을 / 위한 작은 연습" — '한잔'만 강조색
    private var headline: some View {
        VStack(alignment: .leading, spacing: 6) {
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
        .font(.pretendard(.bold, size: 27))
    }
}

// MARK: - 하단 서브 카드

/// 우측 상단 화살표와 좌측 하단 제목이 있는 홈 카드
private struct HomeSubCard: View {
    let title: String
    let color: Color
    var width: CGFloat = 174

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            AssetImageView(name: "HomeArrowUpRight", width: 33, height: 33)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .accessibilityHidden(true)

            Spacer()

            Text(title)
                .font(.pretendard(.semibold, size: 20))
                .foregroundStyle(Color.white)
        }
        .padding(15)
        .frame(width: width, height: 171)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(color)
        )
    }
}

// MARK: - Layout

private enum Layout {
    static let horizontalPadding: CGFloat = 20
    static let logoTop: CGFloat = 16      // 상태바 ↔ 로고
    static let headlineTop: CGFloat = 54  // 로고 ↔ 헤드라인
    static let subtitleTop: CGFloat = 12  // 헤드라인 ↔ 설명
    static let heroCardTop: CGFloat = 46  // 설명 ↔ 히어로 카드
    static let subCardsTop: CGFloat = 15  // 히어로 카드 ↔ 하단 2열 카드
}

// MARK: - 이 화면 전용 색상

private extension AppColors {
    static let homeBackgroundGradient: [Color] = [
        Color(hex: 0x070B14),
        Color(hex: 0x111721),
        Color(hex: 0x0E131D)
    ]
    static let homePracticeCardGradient: [Color] = [Color(hex: 0xDBECFF), Color(hex: 0x76CAF2)]
    static let homeGuideCard = Color(hex: 0x476480)
    static let homeRecentCard = Color(hex: 0x163248)
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        let connection = WatchConnection()
        HomeView()
            .environmentObject(PracticeSession(connection: connection))
            .environmentObject(connection)
    }
}
