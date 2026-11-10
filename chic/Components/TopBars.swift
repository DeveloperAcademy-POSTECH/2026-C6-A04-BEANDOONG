import SwiftUI

// MARK: - 상단 네비게이션 바

/// `<` 뒤로가기 + 가운데 제목 형태의 상단 바 (높이 20, 좌우 여백 27)
///
///     [ <          제목          ]
struct TopNavigationHeader: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.designScale) private var scale

    let title: String
    /// true: 흰색 아이콘/제목 (다크 화면), false: 검정 아이콘/제목 (라이트 화면)
    var isDark: Bool = false
    /// 제목 굵기. 기본은 medium이고, Hi-Fi 113(워치 앱 설치 화면)만 semibold로 그려져 있어 그 화면에서 넘긴다
    var titleWeight: PretendardWeight = .medium
    var onBack: (() -> Void)? = nil
    /// 오른쪽 텍스트 버튼 (예: "건너뛰기"). nil이면 없음
    var trailingTitle: String? = nil
    var onTrailing: () -> Void = {}
    /// 오른쪽 아이콘 버튼 (SF Symbol 이름, 예: "trash"). nil이면 없음
    var trailingSystemImage: String? = nil
    var onTrailingIcon: () -> Void = {}

    private var foregroundColor: Color {
        isDark ? Color.white : AppColors.lightHeaderText
    }

    var body: some View {
        // 뒤로가기 · 오른쪽 버튼은 한 줄 HStack에 나란히 두고, 제목은 위에 겹치되 터치를 받지 않는다.
        // (예전에는 오른쪽 버튼용 HStack이 전체 폭을 덮어 뒤로가기 터치를 가로챘다)
        HStack(spacing: 0) {
            Button {
                if let onBack { onBack() } else { dismiss() }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(foregroundColor)
                    .tapArea()
            }
            .buttonStyle(.plain)
            .accessibilityLabel("뒤로가기")

            Spacer(minLength: 0)

            if let trailingSystemImage {
                Button(action: onTrailingIcon) {
                    Image(systemName: trailingSystemImage)
                        .font(.system(size: 22, weight: .light))
                        .foregroundStyle(AppColors.settingsChevron)
                        .tapArea()
                }
                .buttonStyle(.plain)
                .accessibilityLabel("삭제")
            }
            if let trailingTitle {
                Button(action: onTrailing) {
                    Text(trailingTitle)
                        .font(.pretendard(.medium, size: 16))
                        .foregroundStyle(AppColors.onboardingSkipText)
                        .tapArea()
                }
                .buttonStyle(.plain)
            }
        }
        .overlay {
            Text(title)
                .font(.pretendard(titleWeight, size: 16))
                .foregroundStyle(foregroundColor)
                .allowsHitTesting(false)
        }
        .frame(height: 20)
        .padding(.leading, CGFloat(27).h(scale))
        .padding(.trailing, CGFloat(trailingTitle != nil ? 22 : (trailingSystemImage != nil ? 24 : 27)).h(scale))
    }
}

private extension View {
    /// 보이는 크기는 그대로 두고 터치 영역만 사방 12pt 넓힌다 (상단 바 버튼이 작아 눌리지 않던 문제)
    func tapArea() -> some View {
        self
            .padding(12)
            .contentShape(Rectangle())
            .padding(-12)
    }
}

// MARK: - 스티밍 연습 상단 바

/// 스티밍 진행 중 화면의 상단 바: 좌측 제목
///
///     [ 스티밍 연습                ]
struct SteamingPracticeTopBar: View {
    @Environment(\.designScale) private var scale
    var title: String = "스티밍 연습"

    var body: some View {
        Text(title)
            .font(.pretendard(.medium, size: 16))
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 20)
            .padding(.leading, CGFloat(20).h(scale))
            .padding(.trailing, CGFloat(25).h(scale))
    }
}

// MARK: - 온보딩 상단 바

/// 온보딩 화면의 상단 바: 우측 "건너뛰기" 텍스트만 존재
///
///     [                   건너뛰기 ]
struct OnboardingSkipTopBar: View {
    @Environment(\.designScale) private var scale
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
        .padding(.trailing, CGFloat(22).h(scale))
    }
}
