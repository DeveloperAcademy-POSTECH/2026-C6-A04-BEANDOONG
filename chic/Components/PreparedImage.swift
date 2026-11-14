import SwiftUI
import UIKit

/// 큰 이미지 에셋을 화면에 올리기 전에 백그라운드에서 미리 디코딩해 두는 곳
///
/// 에셋 이미지(`Image("이름")`)는 처음 화면에 그려지는 순간 압축을 풀고(디코딩) GPU로 올려요.
/// 큰 사진(예: 홈 연습 카드의 `HomeWatchPractice`, 1408×853)은 이 일이 길어서, 다른 애니메이션이 도는 중에 처음 그려지면
/// 그 프레임이 늦게 나와 화면이 잠깐 멈춰요. (온보딩 마지막 쪽에서 홈을 미리 만들 때 그래프가 멈칫하던 원인)
///
/// - `prepare`로 앱이 켜질 때 백그라운드에서 디코딩해 두고, 화면은 `image(named:)`로 디코딩된 이미지를 써요.
/// - 아직 준비되지 않았으면 nil 이라, 부르는 쪽은 전처럼 `Image("이름")`을 쓰면 돼요. 모습은 같아요.
@MainActor
enum PreparedImage {
    private static var images: [String: UIImage] = [:]
    private static var requested: Set<String> = []

    /// 디코딩해 둔 이미지 (아직이면 nil)
    static func image(named name: String) -> UIImage? {
        images[name]
    }

    /// 이름의 에셋을 백그라운드에서 디코딩해 둬요. 같은 이름은 한 번만 해요.
    static func prepare(_ names: [String]) {
        for name in names where !requested.contains(name) {
            requested.insert(name)
            Task.detached(priority: .utility) {
                guard let decoded = await UIImage(named: name)?.byPreparingForDisplay() else { return }
                await MainActor.run { images[name] = decoded }
            }
        }
    }
}

extension Image {
    /// 미리 디코딩해 둔 이미지가 있으면 그것으로, 없으면 에셋 이름으로 만들어요. 화면에 그려지는 모습은 같아요.
    static func prepared(_ name: String) -> Image {
        if let image = PreparedImage.image(named: name) {
            return Image(uiImage: image)
        }
        return Image(name)
    }
}
