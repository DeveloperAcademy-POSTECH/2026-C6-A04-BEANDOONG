import SwiftUI

/// 스팀 머신 + 휴대폰 일러스트 (ONB-02 전파 점등)
///
/// 폰에서 머신 쪽으로 나가는 전파 3개가 안쪽부터 하나씩 켜지고, 네 번째 박자에 폰 위 신호 선 3개가 함께 켜져요.
/// 다 켜진 채 잠시 있다가 전부 한꺼번에 꺼지고, 쉬었다가 반복해요. 화면이 열리면 모두 꺼진 상태에서 시작해요.
///
///     0.00s  (전파 없음) 첫 번째 전파 켜짐 (0.15초)
///     0.25s  두 번째
///     0.50s  세 번째
///     0.75s  폰 위 신호 선 3개 (한꺼번에) → 다 켜진 채 0.6초 유지 (= Hi-Fi)
///     1.50s  전부 꺼짐 (0.2초)
///     2.05s  다시 처음으로 (한 바퀴 2.05초, 꺼진 채 0.35초 쉼)
///
///     ┌ 베이스: 머신 + 컵 + 폰 (전파·신호 선만 뺀 이미지, IllustMachinePhoneBase)
///     └ 전파 3개 + 신호 선: 원본 일러스트에서 그대로 떼어 낸 이미지 (IllustMachinePhoneWave1~3 · IllustMachinePhoneSignal)
///
/// - 조각 이미지는 Hi-Fi의 머신·폰 일러스트 한 장을 같은 크기 캔버스에서 나눈 것이라,
///   전부 겹쳐 놓은 다 켜진 모습이 Hi-Fi와 픽셀까지 같아요.
/// - 동작 줄이기(Reduce Motion)가 켜져 있으면 다 켜진 Hi-Fi 정지 화면으로 멈춰 있어요.
struct MachinePhoneIllustration: View {
    private let timing = RadioRevealTiming.machinePhone

    var body: some View {
        ZStack {
            image("IllustMachinePhoneBase")

            LoopTimeline(period: timing.period, restProgress: timing.restProgress) { progress in
                let time = progress * timing.period
                ZStack {
                    ForEach(Spec.revealImages.indices, id: \.self) { index in
                        image(Spec.revealImages[index])
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
    /// 화면에 놓이는 크기(pt) — Hi-Fi 일러스트 크기와 같아요
    static let frameSize = CGSize(width: 304, height: 199)
    /// 켜지는 순서: 전파 안쪽 → 바깥쪽, 그다음 폰 위 신호 선 3개
    static let revealImages = ["IllustMachinePhoneWave1", "IllustMachinePhoneWave2", "IllustMachinePhoneWave3", "IllustMachinePhoneSignal"]
}

#Preview {
    MachinePhoneIllustration()
        .padding(40)
        .background(AppColors.darkBackground)
}
