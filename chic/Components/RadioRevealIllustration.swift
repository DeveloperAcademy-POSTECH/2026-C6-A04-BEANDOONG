import SwiftUI

/// 전파 점등 일러스트 공용 틀 (아이폰 + 워치 · 스팀 머신 + 폰)
///
/// 베이스 이미지 한 장 위에 전파 조각 이미지를 겹쳐 놓고, `RadioRevealTiming` 에 따라 안쪽부터 하나씩 켰다가
/// 다 켜지면 한꺼번에 끄고 반복해요. 어떤 이미지를 쓰고 몇 번째가 언제 켜지는지만 일러스트마다 다르고, 그리는 방식은 같아요.
///
///     ┌ 베이스: 전파를 뺀 이미지 (`base`)
///     └ 전파 조각: 켜지는 순서대로 (`layers`) — 원본 일러스트에서 그대로 떼어 낸 이미지라, 다 켜진 모습이 Hi-Fi와 픽셀까지 같아요.
///
/// - 화면이 열리면 전파가 모두 꺼진 상태에서 시작해요 (애니메이션 벤치와 같아요).
/// - 동작 줄이기(Reduce Motion)가 켜져 있으면 다 켜진 Hi-Fi 정지 화면으로 멈춰 있어요.
/// - `PhoneWatchIllustration` · `MachinePhoneIllustration` 이 이 틀에 이미지와 타이밍만 넘겨요.
struct RadioRevealIllustration: View {
    /// 베이스 이미지 이름 (전파를 뺀 그림)
    let base: String
    /// 전파 조각 이미지 이름: 켜지는 순서대로 (안쪽 → 바깥쪽 …)
    let layers: [String]
    /// 화면에 놓이는 크기(pt). 베이스와 조각 이미지가 모두 같은 크기 캔버스예요.
    let size: CGSize
    let timing: RadioRevealTiming

    var body: some View {
        ZStack {
            image(base)

            LoopTimeline(period: timing.period, restProgress: timing.restProgress) { progress in
                let time = progress * timing.period
                ZStack {
                    ForEach(layers.indices, id: \.self) { index in
                        image(layers[index])
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
        AssetImageView(name: name, size: size)
    }
}
