import SwiftUI

/// 3배 PNG 일러스트 위에 겹쳐 그리는 캔버스
///
/// 일러스트를 `AssetImageView`(scaledToFit)로 놓은 자리와 똑같이 맞춰서,
/// 그리는 좌표를 **일러스트 PNG 픽셀 좌표** 그대로 쓸 수 있어요.
/// 그래서 Hi-Fi 에셋에서 잰 값(중심, 반지름, 선 두께 등)을 변환 없이 옮겨 적으면 돼요.
///
///     ZStack {
///         AssetImageView(name: "IllustWatchInstallBase", width: 121, height: 207)
///         IllustrationCanvas(pixelSize: CGSize(width: 363, height: 620),
///                            frameSize: CGSize(width: 121, height: 207)) { context in
///             // 픽셀 좌표로 그리기
///         }
///     }
struct IllustrationCanvas: View {
    /// 일러스트 PNG 크기(px)
    let pixelSize: CGSize
    /// 화면에 놓이는 크기(pt). 같이 쓰는 `AssetImageView`와 같은 값이에요.
    let frameSize: CGSize
    /// 그림이 영역 바깥으로 넘쳐도 잘리지 않도록 캔버스를 사방으로 넓히는 여백(pt).
    /// 레이아웃은 `frameSize`만 차지해요.
    var overflow: CGFloat = 0
    /// 래스터화를 메인 스레드 밖에서 할지. 매 프레임 다시 그리는 반복 애니메이션에서 켜면 메인 스레드가 가벼워져요.
    /// 그려지는 모습은 같아요. (기본: 끔 — 전과 같음)
    var rendersAsynchronously = false
    /// 일러스트 픽셀 좌표로 그리는 내용
    let draw: (inout GraphicsContext) -> Void

    var body: some View {
        Canvas(rendersAsynchronously: rendersAsynchronously) { context, _ in
            context.translateBy(x: overflow + fitOrigin.x, y: overflow + fitOrigin.y)
            context.scaleBy(x: fitScale, y: fitScale)
            draw(&context)
        }
        .frame(width: frameSize.width + overflow * 2, height: frameSize.height + overflow * 2)
        .frame(width: frameSize.width, height: frameSize.height)
        .allowsHitTesting(false)
    }

    /// scaledToFit 과 같은 배율 (px → pt)
    private var fitScale: CGFloat {
        min(frameSize.width / pixelSize.width, frameSize.height / pixelSize.height)
    }

    /// scaledToFit 으로 가운데 놓였을 때 이미지 왼쪽 위 모서리 (pt)
    private var fitOrigin: CGPoint {
        CGPoint(
            x: (frameSize.width - pixelSize.width * fitScale) / 2,
            y: (frameSize.height - pixelSize.height * fitScale) / 2
        )
    }
}
