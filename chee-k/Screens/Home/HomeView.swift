import SwiftUI

/// 홈 화면
/// - 디자인: Hi-Fi/iPhone 17 - 120.png
///
///     ┌ chic 로고
///     ├ 헤드라인 "다음 한잔을 / 위한 작은 연습" + 설명
///     ├ 메인 히어로 카드 (피처 이미지)
///     └ 하단 2열 카드: [연습 가이드] [최근 연습]
struct HomeView: View {
    @State private var path: [Destination] = []

    private enum Destination: Hashable {
        case microphone
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
                        case .watchSetup:
                            WatchSetupView()
                        case .history:
                            HistoryView()
                        }
                    }
                    .toolbar(.hidden, for: .navigationBar)
                }
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

            // MARK: 메인 히어로 카드 (362 x 262)
            Button {
                path.append(MicrophonePermission.isGranted ? .watchSetup : .microphone)
            } label: {
                AssetImageView(name: "HeroPitcherCard", width: 362, height: 262)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("스티밍 연습하기")
            .padding(.top, Layout.heroCardTop)

            // MARK: 하단 2열 카드 (연습 가이드 / 최근 연습)
            HStack(spacing: 14) {
                HomeSubCard(title: "연습 가이드", colors: AppColors.homeGuideCardGradient)
                Button {
                    path.append(.history)
                } label: {
                    HomeSubCard(title: "최근 연습", colors: AppColors.homeRecentCardGradient)
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

/// 우측 상단 ↗ 화살표 + 좌측 하단 제목이 있는 그라데이션 카드 (174 x 171)
private struct HomeSubCard: View {
    let title: String
    /// 위 → 아래 그라데이션 색상
    let colors: [Color]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 우측 상단 화살표
            HStack {
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.white)
            }
            .padding(.top, 20)
            .padding(.trailing, 20)

            Spacer()

            // 좌측 하단 제목
            Text(title)
                .font(.pretendard(.bold, size: 20))
                .foregroundStyle(Color.white)
                .padding(.leading, 16)
                .padding(.bottom, 18)
        }
        .frame(width: 174, height: 171)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: colors,
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
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
    static let homeGuideCardGradient: [Color] = [Color(hex: 0x476480), Color(hex: 0x5B7895)]
    static let homeRecentCardGradient: [Color] = [Color(hex: 0x163248), Color(hex: 0x163248)]
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
