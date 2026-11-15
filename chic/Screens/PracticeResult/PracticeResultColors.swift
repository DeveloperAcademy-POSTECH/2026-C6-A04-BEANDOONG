import SwiftUI

/// 연습 결과 · 히스토리 상세 화면에서 공통으로 쓰는 색상 (Hi-Fi 원본 픽셀에서 추출)
enum PracticeResultColors {
    /// 카드 배경 · 도넛 차트 트랙 배경
    static let cardBackground = Color(hex: 0x202228)
    /// 카드 안쪽 배경 (타임라인 빈 막대 바탕 · 소리 타일 바탕)
    static let innerBackground = Color(hex: 0x16181F)
    /// 제목 · 큰 숫자
    static let primaryText = Color(hex: 0xDBECFF)
    /// 설명 · 작은 라벨 · 눈금 숫자
    static let secondaryText = Color(hex: 0x919296)
    /// 도넛 바깥 링 · 요약 "정상소리" 숫자
    static let normalSound = Color(hex: 0x76CAF2)
    /// 도넛 안쪽 링 · 요약 "주의 소리" 숫자
    static let cautionSound = Color(hex: 0xF2627C)
    /// 상단 요약 바 세로 구분선
    static let summaryDivider = Color(hex: 0x798494)
    /// 상단 히어로 요약 컨테이너 하단 가장자리 그라데이션 색상
    static let heroGradientEdgeBottom = Color(hex: 0x141A27) // Hi-Fi 연습가이드: 아래 가장자리 x 8 → 0x151B28
    /// 상단 히어로 요약 컨테이너 하단 중앙 글로우 색상
    static let heroGradientCenterBottom = Color(hex: 0x2C3546) // Hi-Fi 연습가이드: 아래 가운데 0x212938 (글로우 60%와 섞인 값)
    /// 타임라인 눈금 선
    static let tickLine = Color(hex: 0x78797B)
    /// 하단 안내 문구
    static let footnote = Color(hex: 0x98A2B3)
    /// 연습 가이드 비커의 우유 (Hi-Fi 260)
    static let guideMilk = Color(hex: 0x686E79)
    /// 연습 가이드 카드 설명 (Hi-Fi 연습 가이드: 182,184,188)
    static let guideMessage = Color(hex: 0xB6B8BC)
}
