import SwiftUI

// 홈의 카드들: 메인 연습 카드 · 아래 행(가이드 · 기록) 카드와 카드를 누르는 동안의 스타일.
// 홈 본체(`HomeView`)는 이동 경로 · 등장 애니메이션만 맡고, 카드 모양은 여기서 그려요.

// MARK: - 메인 연습 카드

/// 워치+피처 이미지 위로, 좌하단 안내 문구와 우하단 연습 버튼을 배치한 홈 카드
/// - 카드 어디를 눌러도 우하단 [연습하기 →]와 같은 동작을 한다 (카드 전체가 버튼)
struct HomePracticeCard: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.designScale) private var scale
    /// 카드를 눌렀을 때 (마이크 권한 확인 → 연습 준비 가이드)
    let action: () -> Void

    var body: some View {
        Button(action: action) { content }
            .buttonStyle(HomeCardPressStyle(reduceMotion: reduceMotion))
            .accessibilityLabel(String(localized: "연습하기"))
            .accessibilityHint(String(localized: "애플 워치와 함께 스티밍 연습을 시작해요"))
    }

    private var content: some View {
        // 문구 두 줄과 버튼은 세로 가운데를 맞춰요 (Hi-Fi 311)
        HStack(alignment: .center, spacing: 0) {
            Text(String(localized: "애플 워치와 함께\n스티밍을 연습해요"))
                .lineSpacing(4)
                .font(.pretendard(.semibold, size: 20))
                .foregroundStyle(AppColors.homeCardText)

            Spacer(minLength: 0)

            HomeCardCapsule(title: String(localized: "연습하기"), width: Layout.buttonWidth.h(scale))
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
                // 큰 사진이라 앱이 켜질 때 백그라운드에서 미리 디코딩해 둔 것을 써요 (처음 그려질 때 멈칫하지 않게).
                Image.prepared(HomeHeroImage.assetName)
                    .resizable()
                    // 카드 높이는 세로 비율로 줄므로 이미지도 가로·세로 중 작은 비율(fit)로 줄여야 SE처럼 짧은 화면에서 아래 문구를 덮지 않는다
                    .frame(width: HomeHeroImage.size.width * scale.fit, height: HomeHeroImage.size.height * scale.fit)
                    .offset(x: HomeHeroImage.offset.width * scale.fit, y: HomeHeroImage.offset.height * scale.fit)
                    .accessibilityHidden(true)
            }
            .allowsHitTesting(false)
        }
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous))
    }
}

/// 메인 카드 사진: 원본(@3x) 크기 그대로, 카드 왼쪽 위에서 밀어 배치
enum HomeHeroImage {
    /// 쓰는 언어의 사진 에셋 이름. 카드가 그릴 사진과 앱이 켜질 때 미리 디코딩할 사진이 같은 이름을 쓰도록 한 곳에서 정해요.
    /// (`String(localized:)` 호출이 하나라 번역 카탈로그의 키 · 기본값 · 설명도 하나예요)
    static let assetName = String(localized: "home.practice.image", defaultValue: "HomeWatchPractice", comment: "Asset name for the home photo. Use HomeWatchPracticeEnglish for English.")

    static let size = CGSize(width: 469, height: 284)
    static let offset = CGSize(width: -42, height: -30)
}

// MARK: - 아래 행: 가이드 카드 · 기록 카드

/// 메인 카드 아래 한 줄: "가이드" 카드와 "연습 기록 보러가기" 카드
struct HomeBottomCards: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.designScale) private var scale
    /// 기록 카드를 눌렀을 때 (기록 화면으로)
    let onShowHistory: () -> Void

    var body: some View {
        HStack(spacing: Layout.bottomCardSpacing.h(scale)) {
            guideCard
            recordCard
        }
    }

    /// "가이드" 카드 (오른쪽 위에 책 아이콘이 카드 밖으로 잘려 걸쳐 있음)
    /// - 누를 수 있는 버튼만 있고, 가는 곳은 아직 정하지 않았어요.
    private var guideCard: some View {
        Button {
            // TODO: 가이드 화면 연결 (가는 곳이 정해지면)
        } label: {
            bottomCardContent(title: String(localized: "가이드"), width: Layout.guideCardWidth.h(scale)) {
                Image("IllustGuideBook")
                    .resizable()
                    .frame(width: Layout.guideBookSize.width.h(scale), height: Layout.guideBookSize.height.h(scale))
                    .offset(x: Layout.guideBookOffset.width.h(scale), y: Layout.guideBookOffset.height.v(scale))
            }
        }
        .buttonStyle(HomeCardPressStyle(reduceMotion: reduceMotion))
        .accessibilityLabel(String(localized: "가이드"))
    }

    /// "연습 기록 보러가기" 카드 (오른쪽 아래에 기록 링 에셋이 카드 밖으로 잘려 걸쳐 있음)
    private var recordCard: some View {
        Button(action: onShowHistory) {
            bottomCardContent(title: String(localized: "연습 기록 보러가기"), width: recordCardWidth) {
                // 링 에셋을 시계 방향으로 60° 돌려 분홍 호가 12시 ~ 4시 쪽에 오게 해요 (Hi-Fi 311)
                Image("IllustRecordRing")
                    .resizable()
                    .frame(width: Layout.ringSize.h(scale), height: Layout.ringSize.h(scale))
                    .rotationEffect(Layout.ringRotation)
                    .offset(x: Layout.ringOffset.width.h(scale), y: Layout.ringOffset.height.v(scale))
            }
        }
        .buttonStyle(HomeCardPressStyle(reduceMotion: reduceMotion))
        .accessibilityLabel(String(localized: "기록 보기"))
        .accessibilityHint(String(localized: "연습 기록을 확인해요"))
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

// MARK: - Layout (iPhone 17 시안 측정값, pt)

private enum Layout {
    static let cardWidth: CGFloat = 362        // Hi-Fi 311: 메인 카드 x 20 ~ 382
    static let heroCardHeight: CGFloat = 341   // Hi-Fi 311: 303 ~ 644
    static let cardCornerRadius: CGFloat = 12
    static let cardTextLeading: CGFloat = 15.5 // 카드 왼쪽 ↔ 글자 (Hi-Fi 311: 글자 x 35.7)
    static let cardButtonTrailing: CGFloat = 23 // 연습하기 버튼 ↔ 카드 오른쪽 (Hi-Fi 311: 버튼 359 → 382)
    // 문구 두 줄(약 52)이 버튼(44)보다 높아 여백은 문구 아래에 붙어요. 버튼 아래는 4pt 더 떠서 Hi-Fi 311의 619 → 644(25)가 돼요.
    static let cardContentBottom: CGFloat = 21
    static let buttonWidth: CGFloat = 136

    // 아래 행: 가이드 카드 · 기록 카드 (Hi-Fi 311: y 660 ~ 767)
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

// MARK: - 이 화면 전용 색상

private extension AppColors {
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
}
