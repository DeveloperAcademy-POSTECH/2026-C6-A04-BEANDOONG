import SwiftUI

// 여러 줄 문구(\n 포함)에만 가운데 정렬 + 줄간격을 적용합니다.
// 한 줄 문구에 lineSpacing 을 주면 렌더링 위치가 달라지므로, 원래 디자인과 동일하게 적용하지 않습니다.

// MARK: - 다크 화면 타이틀

/// 다크 화면 큰 제목 (Bold 26, 흰색 / 여러 줄이면 가운데 정렬 + 줄간격 3)
struct DarkScreenTitle: View {
    let text: String
    /// 여러 줄일 때의 줄간격 (기본 3, 스티밍 피드백·청취 시안은 줄 높이 36pt라 4.7)
    let lineSpacing: CGFloat

    init(_ text: String, lineSpacing: CGFloat = 3) {
        self.text = text
        self.lineSpacing = lineSpacing
    }

    var body: some View {
        if text.contains("\n") {
            Text(text)
                .font(.pretendard(.bold, size: 26))
                .multilineTextAlignment(.center)
                .lineSpacing(lineSpacing)
                .foregroundStyle(Color.white)
        } else {
            Text(text)
                .font(.pretendard(.bold, size: 26))
                .foregroundStyle(Color.white)
        }
    }
}

// MARK: - 다크 화면 설명 문구

/// 다크 화면 제목 아래 설명 (Regular 16 / 여러 줄이면 가운데 정렬 + 줄간격 3)
struct DarkScreenSubtitle: View {
    let text: String
    /// 기본은 회색(`darkSubtitle`), 스티밍 화면에서는 흰색 계열을 사용
    let color: Color

    init(_ text: String, color: Color = AppColors.darkSubtitle) {
        self.text = text
        self.color = color
    }

    var body: some View {
        if text.contains("\n") {
            Text(text)
                .font(.pretendard(.regular, size: 16))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .foregroundStyle(color)
        } else {
            Text(text)
                .font(.pretendard(.regular, size: 16))
                .foregroundStyle(color)
        }
    }
}
