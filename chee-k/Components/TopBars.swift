import SwiftUI

// MARK: - 상단 네비게이션 바

/// `<` 뒤로가기 + 가운데 제목 형태의 상단 바 (높이 20, 좌우 여백 27)
///
///     [ <          제목          ]
struct TopNavigationHeader: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    /// true: 흰색 아이콘/제목 (다크 화면), false: 검정 아이콘/제목 (라이트 화면)
    var isDark: Bool = false

    private var foregroundColor: Color {
        isDark ? Color.white : AppColors.lightHeaderText
    }

    var body: some View {
        ZStack {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(foregroundColor)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("뒤로가기")
                Spacer()
            }
            Text(title)
                .font(.pretendard(.medium, size: 16))
                .foregroundStyle(foregroundColor)
        }
        .frame(height: 20)
        .padding(.horizontal, 27)
    }
}

// MARK: - 스티밍 연습 상단 바

/// 스티밍 진행 중 화면의 상단 바: 좌측 제목 + 우측 닫기(X)
///
///     [ 스티밍 연습              X ]
struct SteamingPracticeTopBar: View {
    var title: String = "스티밍 연습"
    var onClose: () -> Void = {}

    var body: some View {
        HStack {
            Text(title)
                .font(.pretendard(.medium, size: 16))
                .foregroundStyle(Color.white)
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(Color.white)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("연습 종료")
        }
        .frame(height: 20)
        .padding(.leading, 20)
        .padding(.trailing, 25)
    }
}

// MARK: - 온보딩 상단 바

/// 온보딩 화면의 상단 바: 우측 "건너뛰기" 텍스트만 존재
///
///     [                   건너뛰기 ]
struct OnboardingSkipTopBar: View {
    var action: () -> Void = {}

    var body: some View {
        HStack {
            Spacer()
            Button(action: action) {
                Text("건너뛰기")
                    .font(.pretendard(.medium, size: 16))
                    .foregroundStyle(AppColors.onboardingSkipText)
            }
            .buttonStyle(.plain)
        }
        .frame(height: 20)
        .padding(.trailing, 22)
    }
}
