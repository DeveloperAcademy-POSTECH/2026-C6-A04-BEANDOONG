import SwiftUI

/// 아이폰 + 워치 일러스트 (ONB-01 · WCH-01 전파 점등)
///
/// 아이폰에서 워치 쪽으로 나가는 전파 3개가 안쪽부터 하나씩 켜지고, 다 켜진 채 잠시 있다가 한꺼번에 꺼져요.
/// 화면이 열리면 전파가 모두 꺼진 상태에서 시작해요 (애니메이션 벤치와 같아요).
///
///     0.00s  (전파 없음) 첫 번째 전파 켜짐 (0.15초)
///     0.25s  두 번째
///     0.50s  세 번째 → 다 켜진 채 0.6초 유지 (= Hi-Fi)
///     1.25s  꺼짐 (0.2초)
///     1.80s  다시 처음으로 (한 바퀴 1.8초, 꺼진 채 0.35초 쉼)
///
///     ┌ 베이스: 아이폰 + 워치 (전파만 뺀 이미지, IllustPhoneWatchBase)
///     └ 전파 3개: 원본 일러스트에서 그대로 떼어 낸 이미지 (IllustPhoneWatchWave1~3)
///
/// - 전파 이미지는 원본에서 떼어 낸 것이라, 다 켜진 모습이 Hi-Fi와 픽셀까지 같아요.
/// - 동작 줄이기(Reduce Motion)가 켜져 있으면 다 켜진 Hi-Fi 정지 화면으로 멈춰 있어요.
/// - 온보딩 1/4(WatchIntroPage)와 애플 워치 연결 안내(WatchSetupView)가 같이 써요.
struct PhoneWatchIllustration: View {
    private let timing = RadioRevealTiming.phoneWatch

    var body: some View {
        ZStack {
            image("IllustPhoneWatchBase")

            LoopTimeline(period: timing.period, restProgress: timing.restProgress) { progress in
                let time = progress * timing.period
                ZStack {
                    ForEach(Spec.waveImages.indices, id: \.self) { index in
                        image(Spec.waveImages[index])
                            // 꺼진 동안도 0 대신 0.001로 둬요. 0이면 그리기를 건너뛰어, 스플래시 · 이웃 쪽으로 미리 만들 때
                            // 이미지가 준비되지 않고 처음 켜지는 순간(애니메이션 시작)에 디코딩이 몰려 버벅여요. 0.001은 눈에 보이지 않아요.
                            .opacity(max(timing.opacity(index: index, time: time), RadioRevealTiming.hiddenOpacity))
                    }
                }
            }
        }
        .accessibilityHidden(true)
    }

    private func image(_ name: String) -> some View {
        AssetImageView(name: name, width: Spec.frameSize.width, height: Spec.frameSize.height)
    }
}

// MARK: - 사양

private enum Spec {
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
