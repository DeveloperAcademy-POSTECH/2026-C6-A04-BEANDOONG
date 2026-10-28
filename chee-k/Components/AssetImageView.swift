import SwiftUI

/// Assets.xcassets 의 일러스트를 고정 크기 박스 안에 비율 유지(scaledToFit)로 그립니다.
struct AssetImageView: View {
    let name: String
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .frame(width: width, height: height)
    }
}
