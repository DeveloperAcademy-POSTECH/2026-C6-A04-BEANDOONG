import SwiftUI

/// 본문을 스크롤하면 상단의 단계 표시가 차례로 채워지는 액팅 가이드.
struct SteamingGuideView: View {
    @Environment(\.designScale) private var scale
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var currentStep = 1
    @State private var hasEntered = false
    @State private var isCompletionVisible = false

    private var showsCompletion: Bool { currentStep == 4 && isCompletionVisible }

    var body: some View {
        ScrollViewReader { scroll in
            VStack(spacing: 0) {
                TopNavigationHeader(title: String(localized: "스티밍 액팅 가이드"), isDark: true)
                    .padding(.top, Layout.headerTop.v(scale))

                GuideStepProgress(currentStep: hasEntered ? currentStep : 0)
                    .padding(.horizontal, Layout.horizontalPadding.h(scale))
                    .padding(.top, Layout.progressTop.v(scale))

                GeometryReader { viewport in
                    ScrollView {
                        VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                            preparation.guideSection(1)
                            positioning.guideSection(2)
                            steaming.guideSection(3)
                            finishing
                                // 마지막 단계도 첫 단계와 같은 높이까지 올릴 수 있게 여백을 둬요.
                                .frame(minHeight: max(0, viewport.size.height - Layout.contentTop - Layout.footerSpace), alignment: .top)
                                .guideSection(4)
                        }
                        .padding(.horizontal, Layout.horizontalPadding.h(scale))
                        .padding(.top, Layout.contentTop)
                        .padding(.bottom, Layout.footerSpace)
                        .id(Layout.topAnchor)
                    }
                    .coordinateSpace(name: Layout.scrollSpace)
                    .scrollIndicators(.hidden)
                    .onPreferenceChange(GuideSectionOffsets.self) { offsets in
                        // 다음 제목이 본문 상단에 닿을 때 해당 단계를 활성화해요.
                        currentStep = offsets.filter { $0.value <= Layout.contentTop + 1 }.keys.max() ?? 1
                    }
                }
                .clipped()
            }
            .overlay(alignment: .bottom) {
                if showsCompletion {
                    DarkPrimaryButton(
                        title: String(localized: "처음부터 다시보기"),
                        width: CGFloat(364).h(scale),
                        height: 56
                    ) {
                        withAnimation(reduceMotion ? nil : .timingCurve(MotionCurve.easeInOutReveal, duration: 0.8)) {
                            scroll.scrollTo(Layout.topAnchor, anchor: .top)
                        }
                    }
                    .padding(.bottom, 34)
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .offset(y: 12)))
                }
            }
        }
        .ignoresSafeArea()
        .background(AppColors.darkBackground.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .toolbar(.hidden, for: .navigationBar)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.3), value: showsCompletion)
        .task {
            await FrameClock.nextFrame()
            hasEntered = true
        }
    }

    private var preparation: some View {
        VStack(alignment: .leading, spacing: 13) {
            stepHeader(1, title: String(localized: "우유와 스팀 완드를 준비해요"))
            guideDescription(String(localized: "차가운 우유를 피처에 담아주세요.\n스팀 완드를 물받이 쪽으로 향하게 해 잠깐 스팀을 내보낸 뒤 꺼주세요."))
                .padding(16)
                .guideCard()
        }
    }

    private var positioning: some View {
        VStack(alignment: .leading, spacing: 13) {
            stepHeader(2, title: String(localized: "노즐과 피처의 위치를 잡아요"))
            VStack(spacing: 49) {
                ActingPositionIllustration()
                guideDescription(String(localized: "손잡이를 안정되게 잡고 조금 기울여요.\n중앙에서 살짝 옆, 표면 바로 아래에\n팁을 잠기게 두고 스팀을 준비해요"))
            }
            .padding(.horizontal, 14)
            .padding(.top, 48)
            .padding(.bottom, 19)
            .guideCard()
        }
    }

    private var steaming: some View {
        VStack(alignment: .leading, spacing: 13) {
            stepHeader(3, title: String(localized: "공기 주입에서 롤링으로 이어가요"))
            VStack(spacing: 18) {
                steamingCard(
                    image: "IllustActingAeration",
                    title: String(localized: "공기주입"),
                    description: String(localized: "스팀을 켜고 피처를 조금 내려\n노즐을 우유 표면 가까이에 유지해 주세요\n공기가 들어가면서 우유의 부피가 서서히 늘어나요")
                )
                steamingCard(
                    image: "IllustActingRolling",
                    title: String(localized: "롤링"),
                    description: String(localized: "필요한 공기가 다 들어갔다면\n피처를 살짝 올려 노즐을 더 넣어 주세요\n우유가 한 방향으로 부드럽게 회전하도록 위치를 유지해 주세요")
                )
            }
        }
    }

    private var finishing: some View {
        VStack(alignment: .leading, spacing: 13) {
            stepHeader(4, title: String(localized: "마무리"))
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(String(localized: "스팀을 끈 뒤 노즐을 빼주세요"))
                        .font(.pretendard(.bold, size: 16))
                        .foregroundStyle(AppColors.guideText)
                    guideDescription(String(localized: "목표 온도에 도달하면 스팀을 끄고 노즐을 빼주세요.\n완드를 닦고 짧게 스팀을 내보낸 뒤, 피처를 가볍게 두드리고 돌려 거품을 정리해요."))
                }
                .padding(16)
                .guideCard()

                VStack(alignment: .leading, spacing: 16) {
                    GuideCompletionCheck(isVisible: showsCompletion)
                    Text(String(localized: "4단계 안내를\n모두 살펴봤어요"))
                        .font(.pretendard(.bold, size: 26))
                        .lineSpacing(10)
                        .foregroundStyle(AppColors.guideText)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(minHeight: 80, alignment: .leading)
                    guideDescription(String(localized: "4단계 가이드를 모두 살펴봤어요\n안내받은 동작을 떠올리며\n이제 스티밍을 시작해 볼까요?"), lineSpacing: 5)
                        .frame(minHeight: 72, alignment: .leading)
                }
                .padding(20)
                .guideCard()
                .onScrollVisibilityChange(threshold: 0.8) { isCompletionVisible = $0 }
            }
        }
    }

    private func stepHeader(_ step: Int, title: String) -> some View {
        VStack(alignment: .leading, spacing: 25) {
            Text(String(format: "STEP %02d", step))
                .font(.pretendard(.bold, size: 16))
                .foregroundStyle(AppColors.darkBackground)
                .frame(width: 81, height: 26)
                .background(AppColors.guideStepNumber, in: Capsule())
            Text(title)
                .font(.pretendard(.semibold, size: 20))
                .foregroundStyle(AppColors.guideText)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
        }
    }

    private func guideDescription(_ text: String, lineSpacing: CGFloat = 3) -> some View {
        Text(text)
            .font(.pretendard(.regular, size: 16))
            .lineSpacing(lineSpacing)
            .foregroundStyle(AppColors.darkSubtitle)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func steamingCard(image: String, title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 42) {
            ActingSteamingIllustration(image: image)
                .frame(maxWidth: .infinity)
            VStack(alignment: .leading, spacing: 7) {
                Text(title)
                    .font(.pretendard(.bold, size: 16))
                    .foregroundStyle(AppColors.guideText)
                guideDescription(description)
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 15)
        .padding(.bottom, 11)
        .frame(minHeight: 370, alignment: .top)
        .guideCard()
    }
}

// MARK: - 스크롤 위치

private struct GuideSectionOffsets: PreferenceKey {
    static let defaultValue: [Int: CGFloat] = [:]

    static func reduce(value: inout [Int: CGFloat], nextValue: () -> [Int: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

private extension View {
    func guideSection(_ number: Int) -> some View {
        background {
            GeometryReader { geometry in
                Color.clear.preference(key: GuideSectionOffsets.self, value: [number: geometry.frame(in: .named(Layout.scrollSpace)).minY])
            }
        }
        .id(number)
    }

    func guideCard() -> some View {
        frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.darkCard, in: RoundedRectangle(cornerRadius: 12))
    }
}

private enum Layout {
    static let headerTop: CGFloat = 84
    static let progressTop: CGFloat = 35
    static let horizontalPadding: CGFloat = 20
    static let contentTop: CGFloat = 52
    static let sectionSpacing: CGFloat = 50
    static let footerSpace: CGFloat = 124
    static let scrollSpace = "steamingGuide"
    static let topAnchor = "steamingGuideTop"
}

private extension AppColors {
    static let guideText = Color(hex: 0xF5FAFF)
}

#Preview {
    SteamingGuideView()
}
