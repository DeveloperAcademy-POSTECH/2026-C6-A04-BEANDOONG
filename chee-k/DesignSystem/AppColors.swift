import SwiftUI

// MARK: - Hex 색상 초기화

extension Color {
    /// `Color(hex: 0xRRGGBB)` 형태로 Hi-Fi 디자인의 sRGB 색상을 그대로 옮겨 쓰기 위한 초기화.
    init(hex: UInt32, opacity: Double = 1.0) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}

// MARK: - 앱 공통 색상 팔레트

/// 두 개 이상의 화면에서 함께 쓰는 색상 모음.
/// 한 화면에서만 쓰는 색상은 해당 화면 파일 하단의 `private extension AppColors`에 둡니다.
enum AppColors {

    // MARK: 라이트 테마 (연습 기록 / 연습 상세 화면)

    static let darkTitle = Color(hex: 0x0F2938)
    static let pureBlackTitle = Color(hex: 0x0B151D)
    static let subtitleGray = Color(hex: 0x5E7482)
    static let axisGray = Color(hex: 0x6B808E)
    static let captionGray = Color(hex: 0x7A8E9B)
    static let cardBackground = Color(hex: 0xEEF8FD)
    static let primaryButton = Color(hex: 0x42BAF8)
    static let secondaryButton = Color(hex: 0xE8F6FE)
    static let greenAccent = Color(hex: 0x0C5B47)
    static let badgeBlueText = Color(hex: 0x0F6B8F)
    /// 라이트 상단 네비게이션 바의 뒤로가기 아이콘 / 제목 색상
    static let lightHeaderText = Color(hex: 0x111111)

    // MARK: 스펙트로그램 하단 상태 색상 바

    static let statusMint = Color(hex: 0xBCEAD9)
    static let statusYellow = Color(hex: 0xFFE29D)
    static let statusGray = Color(hex: 0xE5EDF4)

    /// 스펙트로그램 히트맵 5단계 색상 (0: 가장 진함 → 4: 가장 옅음, Hi-Fi 원본 sRGB 픽셀에서 추출)
    static let heatmapPalette: [Color] = [
        Color(hex: 0x267A9B),
        Color(hex: 0x56ADCE),
        Color(hex: 0x8FD3EE),
        Color(hex: 0xC2E6F7),
        Color(hex: 0xE5F4FB)
    ]

    // MARK: 다크 테마 (대부분의 화면)

    static let darkBackground = Color(hex: 0x02040D)
    static let darkCard = Color(hex: 0x151D34)
    static let darkChipUnselected = Color(hex: 0x151D34)
    /// 다크 화면의 강조색 (선택된 칩, 주요 버튼, 강조 텍스트)
    static let darkChipSelected = Color(hex: 0x99BDE3)
    static let darkChipTextSelected = Color(hex: 0x0A111D)
    static let darkChipTextUnselected = Color(hex: 0xCFD6E2)
    static let darkSubtitle = Color(hex: 0x8F98A8)
    /// 다크 화면 보조 버튼 배경
    static let darkSecondaryButton = Color(hex: 0xE8F7FF)

    // MARK: 온보딩

    static let onboardingSkipText = Color(hex: 0x9EA6B4)
    static let pageIndicatorActive = Color(hex: 0x48637E)
    static let pageIndicatorInactive = Color(hex: 0xA5ACB8)

    // MARK: 스티밍 피드백 (공기 주입 = 파랑, 날카로운 소리 = 분홍, 큰 기포 = 주황, 공기 추가 = 보라, 우유 흐름 = 초록)

    static let aerationBlue = Color(hex: 0x5A82FC)
    static let aerationGradient: [Color] = [
        aerationBlue,
        Color(hex: 0x4371FC),
        aerationBlue
    ]
    static let aerationStopSquare = Color(hex: 0x4C77FC)

    static let sharpSoundPink = Color(hex: 0xFF5B79)
    static let sharpSoundGradient: [Color] = [
        sharpSoundPink,
        Color(hex: 0xFF385E),
        Color(hex: 0xFF5978)
    ]
    static let sharpSoundStopSquare = Color(hex: 0xFF4F70)

    static let bubbleWarningOrange = Color(hex: 0xFFA615)
    static let moreAirPurple = Color(hex: 0x784AD6)
    static let milkFlowGreen = Color(hex: 0x1ABC6B)
}
