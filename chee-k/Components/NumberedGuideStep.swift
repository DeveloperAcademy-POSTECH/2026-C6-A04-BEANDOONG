import SwiftUI

/// 번호 원 + 제목 + 설명 2줄로 이루어진 안내 단계 (스티밍 가이드 / 연습 준비 화면)
///
///     (1)  제목
///          설명 1줄
///          설명 2줄
struct NumberedGuideStep: View {
    let number: Int
    let title: String
    let line1: String
    let line2: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // 번호 원 (25x25)
            ZStack {
                Circle()
                    .fill(AppColors.darkChipSelected)
                    .frame(width: 25, height: 25)
                Text("\(number)")
                    .font(.pretendard(.bold, size: 14))
                    .foregroundStyle(AppColors.darkChipTextSelected)
            }

            // 제목 + 설명
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.pretendard(.medium, size: 18))
                    .foregroundStyle(Color.white)
                    .frame(height: 25, alignment: .leading)

                Text(line1)
                    .font(.pretendard(.regular, size: 12))
                    .foregroundStyle(AppColors.darkSubtitle)
                    .padding(.top, 3)

                Text(line2)
                    .font(.pretendard(.regular, size: 12))
                    .foregroundStyle(AppColors.darkSubtitle)
                    .padding(.top, 3)
            }
        }
    }
}
