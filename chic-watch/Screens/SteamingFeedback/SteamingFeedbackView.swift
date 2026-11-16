import SwiftUI

struct SteamingFeedbackView: View {
    let feedback: SteamingFeedback
    var onStop: () -> Void = {}

    var body: some View {
        WatchFullScreenStack {
            Text(feedback.actionTitle)
                .font(.watchScaled(20, weight: .semibold))
                .multilineTextAlignment(.center)
                .lineSpacing(WatchDesignSize.scaled(2))
                .watchCenterY(0.226)

            Image(feedback.illustrationAssetName)
                .resizable()
                .scaledToFit()
                .frame(width: WatchDesignSize.scaled(73), height: WatchDesignSize.scaled(73))
                .accessibilityHidden(true)
                .watchCenterY(0.554)

            Button(action: onStop) {
                Text(String(localized: "종료"))
                    .font(.watchScaled(12, weight: .bold))
                    .foregroundStyle(AppColors.watchDarkScreenBackground)
                    .frame(width: WatchDesignSize.scaled(48), height: WatchDesignSize.scaled(24))
                    .background(Color(hex: 0xF5FAFF), in: Capsule())
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .watchCenterY(0.851)
        }
        .foregroundStyle(.white)
        .background {
            LinearGradient(gradient: feedback.backgroundGradient, startPoint: .top, endPoint: .bottom)
                .overlay {
                    Rectangle()
                        .strokeBorder(.white.opacity(0.15), lineWidth: WatchDesignSize.scaled(10))
                        .blur(radius: WatchDesignSize.scaled(8))
                }
                .ignoresSafeArea()
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview("공기 주입") { NavigationStack { SteamingFeedbackView(feedback: .aeration) } }
#Preview("노즐 높음") { NavigationStack { SteamingFeedbackView(feedback: .bubble) } }
#Preview("공기 부족") { NavigationStack { SteamingFeedbackView(feedback: .moreAir) } }
#Preview("롤링") { NavigationStack { SteamingFeedbackView(feedback: .milkFlow) } }
