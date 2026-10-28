import SwiftUI

/// 히스토리 빈 상태 화면 (연습 기록이 하나도 없을 때)
/// - 디자인: Hi-Fi/iPhone 17 - 107.png
///
///     ┌ 상단 네비게이션 바: 히스토리
///     ├ 타이틀 + 설명
///     ├ 스팀 머신 일러스트
///     └ 하단 버튼: [첫 연습 시작하기] (가로 그라데이션)
struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 0) {
            // MARK: 상단 네비게이션 바
            TopNavigationHeader(title: "히스토리", isDark: true)
                .padding(.top, Layout.headerTop)

            // MARK: 타이틀 + 설명
            DarkScreenTitle("첫 연습을 기다리고 있어요.")
                .padding(.top, Layout.titleTop)

            // NOTE: '변호와'는 '변화와'의 오타로 보이지만, 기존 화면 문구를 그대로 유지함
            DarkScreenSubtitle("연습을 마치면 소리의 변호와\n표시된 상태를 다시 볼 수 있어요.", color: Color.white.opacity(0.88))
                .padding(.top, Layout.subtitleTop)

            // MARK: 일러스트
            AssetImageView(name: "IllustMachineWave", width: 254, height: 202)
                .padding(.top, Layout.illustrationTop)

            Spacer(minLength: 0)

            // MARK: 하단 버튼
            StartFirstPracticeButton()
                .padding(.bottom, Layout.buttonBottom)
        }
        .darkScreenBackground()
    }
}

// MARK: - 첫 연습 시작 버튼

/// 좌 → 우 네이비 그라데이션 캡슐 버튼 (363 x 51)
private struct StartFirstPracticeButton: View {
    var body: some View {
        Button(action: {}) {
            Text("첫 연습 시작하기")
                .font(.pretendard(.bold, size: 16))
                .foregroundStyle(Color.white)
                .frame(width: 363, height: 51)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: 0x35536E),
                                    Color(hex: 0x7A9BB8)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Layout

private enum Layout {
    static let headerTop: CGFloat = 22         // 상태바 ↔ 네비게이션 바
    static let titleTop: CGFloat = 65          // 네비게이션 바 ↔ 타이틀
    static let subtitleTop: CGFloat = 16       // 타이틀 ↔ 설명
    static let illustrationTop: CGFloat = 134  // 설명 ↔ 일러스트
    static let buttonBottom: CGFloat = 13      // 버튼 ↔ 화면 하단(안전 영역)
}

struct EmptyHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyHistoryView()
    }
}
