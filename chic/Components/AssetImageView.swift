import SwiftUI

/// Assets.xcassets 의 일러스트를 고정 크기 박스 안에 비율 유지(scaledToFit)로 그립니다.
///
///     AssetImageView(name: "IllustMic", width: 93, height: 165)
///     AssetImageView(name: "IllustSoundBars", size: SoundBarsIllustration.size)
struct AssetImageView: View {
    let name: String
    let width: CGFloat
    let height: CGFloat

    init(name: String, width: CGFloat, height: CGFloat) {
        self.name = name
        self.width = width
        self.height = height
    }

    /// 크기를 `CGSize` 로 한 번에 넘겨요. 일러스트가 공개한 `size` · 사양의 `frameSize` 를 나눠 적을 필요가 없어요.
    init(name: String, size: CGSize) {
        self.init(name: name, width: size.width, height: size.height)
    }

    var body: some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .frame(width: width, height: height)
    }
}
