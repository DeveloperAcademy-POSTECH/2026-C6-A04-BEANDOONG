import SwiftUI

/// 스플래시 chic 로고 등장 애니메이션 (SPL-01 로고 블러 스태거)
///
/// 로고를 조각 7개로 나눠, 음파 3개 → c → h·i 기둥 → c → i 점 순서로 하나씩
/// 아래에서 살짝 떠오르며 나타나고, 흐림이 걷혀요.
///
///     ((( c h i c        조각마다 0.065초씩 늦게 출발 (i 점만 0.06초 더 늦게)
///     ↑ 떠오름: 0.9초, ease-out-expo — 글자가 먼저 자리를 잡고
///     ◌ 흐림:   0.85초, ease-out-quad — 흐림이 조금 더 남았다가 걷혀요
///
/// - 조각은 원본 로고 이미지(`ChicLogo`)를 조각 영역으로 잘라서 그려요. 그래서 다 나타난 모습이 원본 로고와 똑같아요.
/// - 동작 줄이기(Reduce Motion)가 켜져 있으면 처음부터 다 나타난 로고를 보여 줘요.
struct SplashLogoReveal: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// 조각마다 떠오름이 끝났는지 / 흐림이 걷혔는지
    @State private var risen: Set<LogoPart> = []
    @State private var focused: Set<LogoPart> = []

    var body: some View {
        ZStack {
            ForEach(LogoPart.allCases, id: \.self) { part in
                Image("ChicLogo")
                    .resizable()
                    .mask(LogoPartShape(part: part))
                    // 잘라 낸 뒤에 흐리게 해서, 흐림이 조각 바깥으로 자연스럽게 번져요.
                    .blur(radius: focused.contains(part) ? 0 : RevealMotion.startBlur)
                    .offset(y: risen.contains(part) ? 0 : RevealMotion.riseDistance)
                    .opacity(risen.contains(part) ? 1 : 0)
            }
        }
        .frame(width: LogoGeometry.size.width, height: LogoGeometry.size.height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("chic")
        .onAppear(perform: showAllIfReduceMotion)
        // 앱을 켠 직후 첫 프레임은 아래 화면(홈·온보딩)까지 한꺼번에 만드느라 늦게 그려져요.
        // 그사이 애니메이션 앞부분이 건너뛰어지지 않도록, 첫 프레임이 그려진 뒤에 출발해요. (그전에는 배경만 보여서 런치 화면과 같아요)
        .task {
            guard !reduceMotion else { return }
            await FrameClock.nextFrame()
            reveal()
        }
    }

    /// 동작 줄이기: 첫 프레임부터 다 나타난 로고
    private func showAllIfReduceMotion() {
        guard reduceMotion else { return }
        risen = Set(LogoPart.allCases)
        focused = Set(LogoPart.allCases)
    }

    /// 마지막 조각(i 점)까지 다 나타나는 데 걸리는 시간(초)
    static var revealDuration: TimeInterval { RevealMotion.totalDuration }

    private func reveal() {
        for part in LogoPart.allCases {
            withAnimation(RevealMotion.rise(part)) { _ = risen.insert(part) }
            withAnimation(RevealMotion.focus(part)) { _ = focused.insert(part) }
        }
    }
}

// MARK: - 타이밍

private enum RevealMotion {
    /// 조각 사이 출발 간격(초)
    static let stagger: TimeInterval = 0.065
    /// i 점만 더 늦게 출발하는 시간(초)
    static let dotExtraDelay: TimeInterval = 0.06

    static let riseDuration: TimeInterval = 0.9
    /// 로고 높이의 9% 아래에서 떠오름
    static let riseDistance: CGFloat = LogoGeometry.size.height * 0.09

    static let focusDuration: TimeInterval = 0.85
    /// 처음 흐림 반지름 (화면 폭 402pt 의 2.2%)
    static let startBlur: CGFloat = 8.8

    /// 마지막 조각(i 점)이 출발한 뒤 떠오름·흐림이 모두 끝나는 시간 = 전체 길이 (1.35초)
    static var totalDuration: TimeInterval {
        delay(of: .dot) + max(riseDuration, focusDuration)
    }

    static func delay(of part: LogoPart) -> TimeInterval {
        let order = Double(LogoPart.allCases.firstIndex(of: part) ?? 0)
        return stagger * order + (part == .dot ? dotExtraDelay : 0)
    }

    static func rise(_ part: LogoPart) -> Animation {
        Animation.timingCurve(MotionCurve.easeOutExpo, duration: riseDuration).delay(delay(of: part))
    }

    static func focus(_ part: LogoPart) -> Animation {
        Animation.timingCurve(MotionCurve.easeOutQuad, duration: focusDuration).delay(delay(of: part))
    }
}

// MARK: - 로고 조각

/// 로고 조각 (나타나는 순서대로)
private enum LogoPart: CaseIterable {
    /// 음파 3개 (가장 왼쪽부터)
    case wave1, wave2, wave3
    /// 첫 번째 c
    case firstC
    /// h 와 i 기둥
    case hi
    /// 마지막 c
    case lastC
    /// i 점
    case dot
}

/// 원본 로고 이미지(`ChicLogo`, 446×153px)에서 조각이 차지하는 영역
///
/// 조각끼리 떨어져 있는 틈 한가운데를 경계로 잡아서, 영역이 겹치거나 비는 곳 없이 로고 전체를 나눠요.
/// i 점은 i 기둥 바로 위에 있어서, 기둥 영역에서 점 영역(위쪽 사각형)만 빼요.
private enum LogoGeometry {
    /// 화면에 그리는 로고 크기 (원본 3배 이미지 446×153px)
    static let size = CGSize(width: 446.0 / 3, height: 153.0 / 3)
    /// 원본 이미지 픽셀 크기
    static let pixelSize = CGSize(width: 446, height: 153)

    /// 조각 사이 세로 경계 (원본 픽셀 x)
    static let wave1End: CGFloat = 13.5
    static let wave2End: CGFloat = 36
    static let wave3End: CGFloat = 75
    static let firstCEnd: CGFloat = 185
    static let hiEnd: CGFloat = 344.5
    /// i 점 영역 (원본 픽셀): x 300 ~ 344.5, y 0 ~ 47 (점 아래 끝 y 39 ↔ i 기둥 위 끝 y 54 사이)
    static let dotRect = CGRect(x: 300, y: 0, width: hiEnd - 300, height: 47)

    /// 조각 영역들 (원본 픽셀 좌표)
    static func pixelRects(of part: LogoPart) -> [CGRect] {
        let fullHeight = pixelSize.height
        func column(_ minX: CGFloat, _ maxX: CGFloat) -> CGRect {
            CGRect(x: minX, y: 0, width: maxX - minX, height: fullHeight)
        }
        switch part {
        case .wave1: return [column(0, wave1End)]
        case .wave2: return [column(wave1End, wave2End)]
        case .wave3: return [column(wave2End, wave3End)]
        case .firstC: return [column(wave3End, firstCEnd)]
        case .hi:
            return [
                column(firstCEnd, dotRect.minX),
                CGRect(x: dotRect.minX, y: dotRect.maxY, width: dotRect.width, height: fullHeight - dotRect.maxY),
            ]
        case .lastC: return [column(hiEnd, pixelSize.width)]
        case .dot: return [dotRect]
        }
    }
}

/// 로고 조각 하나의 영역 (마스크용). 원본 픽셀 좌표를 그리는 크기에 맞춰 늘려요.
private struct LogoPartShape: Shape {
    let part: LogoPart

    func path(in rect: CGRect) -> Path {
        let scaleX = rect.width / LogoGeometry.pixelSize.width
        let scaleY = rect.height / LogoGeometry.pixelSize.height
        var path = Path()
        for pixelRect in LogoGeometry.pixelRects(of: part) {
            path.addRect(CGRect(
                x: rect.minX + pixelRect.minX * scaleX,
                y: rect.minY + pixelRect.minY * scaleY,
                width: pixelRect.width * scaleX,
                height: pixelRect.height * scaleY
            ))
        }
        return path
    }
}

#Preview {
    SplashLogoReveal()
        .padding(60)
        .background(AppColors.darkBackground)
}
