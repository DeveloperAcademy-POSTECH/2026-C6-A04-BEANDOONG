import SwiftUI

/// 아이폰 + 워치 일러스트 (ONB-01 · WCH-01 전파 점등)
///
/// 아이폰에서 워치 쪽으로 나가는 전파 3개가 안쪽부터 하나씩 켜지고, 다 켜진 채 잠시 있다가 한꺼번에 꺼져요.
///
///     0.00s  ))) 다 켜진 상태로 시작 (= Hi-Fi)
///     0.25s  꺼짐 (0.2초)
///     0.80s  )   첫 번째 전파 켜짐 (0.15초)
///     1.05s  ))  두 번째
///     1.30s  ))) 세 번째 → 다시 처음으로 (한 바퀴 1.8초)
///
///     ┌ 베이스: 아이폰 + 워치 (전파만 뺀 이미지, IllustPhoneWatchBase)
///     └ 전파 3개: 원본 일러스트에서 그대로 떼어 낸 이미지 (IllustPhoneWatchWave1~3)
///
/// - 전파 이미지는 원본에서 떼어 낸 것이라, 다 켜진 모습이 Hi-Fi와 픽셀까지 같아요.
/// - 동작 줄이기(Reduce Motion)가 켜져 있으면 다 켜진 Hi-Fi 정지 화면으로 멈춰 있어요.
/// - 온보딩 1/3(WatchIntroPage)과 애플 워치 연결 안내(WatchSetupView)가 같이 써요.
struct PhoneWatchIllustration: View {
    var body: some View {
        ZStack {
            image("IllustPhoneWatchBase")

            LoopTimeline(period: Spec.period) { progress in
                let time = cycleTime(progress: progress)
                ZStack {
                    ForEach(Spec.waveImages.indices, id: \.self) { index in
                        image(Spec.waveImages[index])
                            .opacity(waveOpacity(index: index, time: time))
                    }
                }
            }
        }
        .accessibilityHidden(true)
    }

    private func image(_ name: String) -> some View {
        AssetImageView(name: name, width: Spec.frameSize.width, height: Spec.frameSize.height)
    }

    /// 한 주기 안의 시간(초). 다 켜진 순간(Hi-Fi)에서 시작하도록 앞당겨요.
    private func cycleTime(progress: Double) -> TimeInterval {
        (progress * Spec.period + Spec.startTime).truncatingRemainder(dividingBy: Spec.period)
    }

    /// `index`번째 전파(0 = 가장 안쪽)의 투명도
    private func waveOpacity(index: Int, time: TimeInterval) -> Double {
        let turnOn = clamp01((time - Spec.stepInterval * Double(index)) / Spec.fadeInDuration)
        let turnOff = 1 - clamp01((time - Spec.allOffTime) / Spec.fadeOutDuration)
        return turnOn * turnOff
    }

    private func clamp01(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}

// MARK: - 사양

/// 전파 점등 타이밍 (애니메이션 벤치 사양, 초)
/// - 전파 사이 간격 0.25초: 하나씩 켜지는 순서가 읽히는 가장 짧은 간격
/// - 켜짐 0.15초 · 꺼짐 0.2초: 사라지는 쪽을 조금 길게
/// - 다 켜진 채 0.6초 유지 → 꺼진 채 0.35초 쉬고 반복
private enum Spec {
    static let period: TimeInterval = 1.8
    static let stepInterval: TimeInterval = 0.25
    static let fadeInDuration: TimeInterval = 0.15
    static let allOffTime: TimeInterval = 1.25
    static let fadeOutDuration: TimeInterval = 0.2
    /// 화면이 나타날 때 시작하는 시점: 세 전파가 다 켜져 있는 구간(Hi-Fi 정지 화면)
    static let startTime: TimeInterval = 1.0

    /// 화면에 놓이는 크기(pt) — 기존 일러스트와 같아요
    static let frameSize = CGSize(width: 230, height: 193)
    /// 안쪽 전파부터
    static let waveImages = ["IllustPhoneWatchWave1", "IllustPhoneWatchWave2", "IllustPhoneWatchWave3"]
}

#Preview {
    PhoneWatchIllustration()
        .padding(40)
        .background(AppColors.darkBackground)
}
