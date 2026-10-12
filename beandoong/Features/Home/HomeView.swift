import SwiftUI

struct HomeView: View {
    @ScaledMetric(relativeTo: .title3) private var bodySize = 20
    @ScaledMetric(relativeTo: .title2) private var titleSize = 24
    @ScaledMetric(relativeTo: .caption) private var captionSize = 12

    let onSelect: (HomeRoute) -> Void

    // shortcut: 목업 전용 수치와 시스템 폰트이며, 최종 디자인 적용 시 이 뷰를 교체합니다.
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("앱 이름")
                    .font(.system(size: bodySize))
                    .padding(.top, 24)
                    .padding(.bottom, 74)

                hero

                Button { onSelect(.history) } label: {
                    Text("히스토리 보러가기 →")
                        .font(.system(size: bodySize))
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .padding(.top, 24)
                .padding(.bottom, 37)

                Rectangle()
                    .fill(.black)
                    .frame(height: 1)
                    .accessibilityHidden(true)

                Text("잠시 쉬어볼까요?")
                    .font(.system(size: bodySize))
                    .padding(.top, 25)
                    .padding(.bottom, 20)

                activities
            }
            .padding(.horizontal, 46)
            .padding(.bottom, 24)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.black)
        .background(.white)
        .environment(\.colorScheme, .light)
    }

    private var hero: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 40)
            Text("한 걸음 떨어져 보기")
                .font(.system(size: titleSize, weight: .bold))
                .multilineTextAlignment(.center)
            Spacer(minLength: 40)
            Button { onSelect(.takeAStepBack) } label: {
                Text("시작하기")
                    .font(.system(size: bodySize))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .background(Color(white: 48.0 / 255))
            }
        }
        .padding(.horizontal, 33)
        .padding(.bottom, 30)
        .frame(minHeight: 380)
        .background(Color(white: 217.0 / 255))
    }

    private var activities: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 12) {
                ForEach(HomeActivity.allCases) { activity in
                    Button { onSelect(.activity(activity)) } label: {
                        VStack(alignment: .leading) {
                            Text("활동 아이콘")
                            Spacer(minLength: 90)
                            Text("활동 이름")
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .font(.system(size: captionSize))
                        .padding(8)
                        .frame(width: 115)
                        .frame(minHeight: 147)
                        .background(Color(white: 217.0 / 255))
                    }
                    .accessibilityLabel("\(activity.title) 시작하기")
                }
            }
            .scrollTargetLayout()
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.viewAligned)
        .contentMargins(.trailing, 46)
        .padding(.trailing, -46)
    }
}

#Preview {
    HomeView { _ in }
}
