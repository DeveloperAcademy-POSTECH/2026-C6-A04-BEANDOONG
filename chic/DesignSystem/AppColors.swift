// 이 파일은 iPhone(chee-k) 타깃과 워치(chee-k-watch) 타깃에 함께 포함되어 있습니다.
// 워치에서 빌드되지 않는 iPhone 전용 코드(UIKit 등)는 이 파일에 넣지 마세요.

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

    // MARK: 라이트 테마

    /// 라이트 상단 네비게이션 바의 뒤로가기 아이콘 / 제목 색상
    static let lightHeaderText = Color(hex: 0x111111)

    // MARK: 다크 테마 (대부분의 화면)

    static let darkBackground = Color(hex: 0x01030C)
    /// 다크 화면 위쪽 가운데 글로우의 가장 밝은 색 (가장자리로 갈수록 `darkBackground`로 사라짐)
    static let darkTopGlow = Color(hex: 0x3D4A5D)
    static let darkCard = Color(hex: 0x202228)
    static let darkChipUnselected = Color(hex: 0x202228)
    /// 다크 화면의 강조색 (선택된 칩, 주요 버튼, 강조 텍스트)
    static let darkChipSelected = Color(hex: 0xA6DDF7)
    static let darkChipTextSelected = Color(hex: 0x01030C)
    static let darkChipTextUnselected = Color(hex: 0xF5FAFF)
    static let darkSubtitle = Color(hex: 0xB9B9B9)
    /// 다크 화면 보조 버튼 배경
    static let darkSecondaryButton = Color(hex: 0xF5FAFF)
    /// 안내 단계(①②) 번호 원 색상 — 강조색보다 한 단계 진한 하늘색
    static let guideStepNumber = Color(hex: 0x76CAF2)

    // MARK: 온보딩

    static let onboardingSkipText = Color(hex: 0xB9B9B9)
    static let pageIndicatorActive = Color(hex: 0xA6DDF7)
    static let pageIndicatorInactive = Color(hex: 0x717276)

    // MARK: 스티밍 피드백
    // 배경은 모두 위 → 아래 2색 그라데이션이고, 위쪽 색이 곧 상태 대표색입니다.
    // (정지 버튼 사각형, 연습 준비 화면의 워치 아이콘 화면 색으로도 사용)

    // 위쪽 색은 Hi-Fi 160/188/189/190의 위 끝(y 0)을 잰 값, 아래쪽 색은 디자인 시스템 팔레트(아래 `sound*`)입니다.

    /// 공기 주입 (파랑): 위 `01289F` → 아래 blue1
    static let aerationTop = Color(hex: 0x01289F)
    static let aerationGradient: [Color] = [aerationTop, soundNormalAeration]

    /// 롤링 (초록): 위 `176101` → 아래 green1
    static let milkFlowTop = Color(hex: 0x176101)
    static let milkFlowGradient: [Color] = [milkFlowTop, soundRolling]

    /// 노즐이 높아 큰 기포가 생길 수 있음 (주황): 위 `FE5F0F` → 아래 Yellow1
    static let bubbleTop = Color(hex: 0xFE5F0F)
    static let bubbleGradient: [Color] = [bubbleTop, soundOverAeration]

    /// 공기 주입 부족 (보라): 위 `52009B` → 아래 Purple1
    static let moreAirTop = Color(hex: 0x52009B)
    static let moreAirGradient: [Color] = [moreAirTop, soundLackOfAir]

    // MARK: 결과·히스토리 소리 상태 팔레트 (디자인 시스템 2026-11-10: blue1 / Yellow1 / Purple1 / green1 / red1)
    // 타임라인 막대, 한 번에 보기 막대, 상태별 감지시간 도넛, 주의 소리 링에 쓰는 단색입니다.

    /// 정상 공기 주입 (blue1)
    static let soundNormalAeration = Color(hex: 0x3976FA)
    /// 공기 과다 (Yellow1, 주황)
    static let soundOverAeration = Color(hex: 0xFF9823)
    /// 공기 부족 (Purple1)
    static let soundLackOfAir = Color(hex: 0xA408FF)
    /// 롤링 소리 (green1)
    static let soundRolling = Color(hex: 0x2AC44B)
    /// 주의 소리 (red1)
    static let soundCaution = Color(hex: 0xF2627C)

}
