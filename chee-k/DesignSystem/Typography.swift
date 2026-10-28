import CoreText
import SwiftUI

// MARK: - Pretendard 폰트

/// 앱에서 사용하는 Pretendard 굵기 (rawValue = 폰트 PostScript 이름)
enum PretendardWeight: String {
    case regular = "Pretendard-Regular"
    case medium = "Pretendard-Medium"
    case semibold = "Pretendard-SemiBold"
    case bold = "Pretendard-Bold"
}

/// 번들에 포함된 Pretendard 폰트 파일을 런타임에 한 번만 등록합니다.
/// (번들에서 찾지 못하면 프로젝트 폴더 경로로 한 번 더 시도 — 프리뷰 대비)
enum FontRegistrar {
    private static var didRegister = false

    static func registerIfNeeded() {
        guard !didRegister else { return }
        didRegister = true
        let files = [
            ("Pretendard-Regular", "otf"),
            ("Pretendard-Medium", "ttf"),
            ("Pretendard-SemiBold", "otf"),
            ("Pretendard-Bold", "ttf")
        ]
        for (name, ext) in files {
            if let url = Bundle.main.url(forResource: name, withExtension: ext) {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            } else {
                let fallbackURL = URL(fileURLWithPath: "chee-k/Fonts/\(name).\(ext)")
                if FileManager.default.fileExists(atPath: fallbackURL.path) {
                    CTFontManagerRegisterFontsForURL(fallbackURL as CFURL, .process, nil)
                }
            }
        }
    }
}

extension Font {
    /// 사용 예: `.font(.pretendard(.bold, size: 26))`
    static func pretendard(_ weight: PretendardWeight, size: CGFloat) -> Font {
        FontRegistrar.registerIfNeeded()
        return .custom(weight.rawValue, size: size)
    }
}
