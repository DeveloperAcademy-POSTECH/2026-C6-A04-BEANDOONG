import SwiftUI

/// 디자인의 번호 원과 연결선. 원의 배경만 12시부터 시계방향으로 채워요.
struct GuideStepProgress: View {
    let currentStep: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 0) {
            ForEach(1...4, id: \.self) { step in
                ZStack {
                    ClockwiseFill(progress: step <= currentStep ? 1 : 0)
                        .fill(AppColors.guideStepNumber)
                    Circle()
                        .strokeBorder(step <= currentStep ? AppColors.guideStepNumber : Self.inactive, lineWidth: 2)
                    Text("\(step)")
                        .font(.pretendard(.bold, size: 12))
                        .foregroundStyle(step <= currentStep ? AppColors.darkBackground : Self.inactive)
                }
                .frame(width: 28, height: 28)
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.55), value: step <= currentStep)

                if step < 4 {
                    Rectangle()
                        .fill(Self.inactive)
                        .overlay(alignment: .leading) {
                            GeometryReader { geometry in
                                Rectangle()
                                    .fill(AppColors.guideStepNumber)
                                    .frame(width: step < currentStep ? geometry.size.width : 0)
                            }
                        }
                        .frame(height: 2)
                        .animation(reduceMotion ? nil : .easeInOut(duration: 0.4), value: step < currentStep)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "가이드 진행 단계"))
        .accessibilityValue(String(localized: "4단계 중 \(max(1, currentStep))단계"))
    }

    private static let inactive = AppColors.darkSubtitle.opacity(0.52)
}

private struct ClockwiseFill: Shape {
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        Path { path in
            guard progress > 0 else { return }
            let center = CGPoint(x: rect.midX, y: rect.midY)
            path.move(to: center)
            path.addArc(center: center, radius: min(rect.width, rect.height) / 2,
                        startAngle: .degrees(-90), endAngle: .degrees(-90 + 360 * progress), clockwise: false)
            path.closeSubpath()
        }
    }
}

/// 원이 부드럽게 떠오른 뒤 원본 체크가 왼쪽에서 오른쪽으로 나타나요.
struct GuideCompletionCheck: View {
    let isVisible: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Circle()
            .fill(AppColors.darkChipSelected)
            .overlay {
                Image("IconActingGuideCheck")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 25.33, height: 18.6)
                    .mask(alignment: .leading) {
                        Rectangle().frame(width: isVisible ? 25.33 : 0)
                    }
                    .animation(reduceMotion ? nil : .easeOut(duration: 0.3).delay(0.15), value: isVisible)
            }
            .frame(width: 44, height: 44)
            .scaleEffect(isVisible || reduceMotion ? 1 : 0.85)
            .opacity(isVisible ? 1 : 0)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.35), value: isVisible)
            .accessibilityHidden(true)
    }
}
