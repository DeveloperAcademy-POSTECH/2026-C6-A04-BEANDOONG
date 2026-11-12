//
//  PracticeGuide.swift
//
//  연습 결과 · 기록 상세의 "연습 가이드" 카드에 띄울 안내를 고릅니다.
//  기준은 연습 중 비커의 두 점선과 같아요: 공기 주입(파랑) 소리가 2~4초면 기준 시간 안이에요.
//  가이드의 비커도 연습 중처럼, 이번 연습에서 공기 주입한 만큼 우유가 차 있어요 (`GuideMilkLevel`).
//

import Foundation

/// 연습 가이드 카드 안내 (Hi-Fi: 연습 가이드 3종)
enum PracticeGuide: Equatable {
    /// ✓ 공기 주입 시간이 기준 안
    case onTarget
    /// (!) 공기 주입 시간이 기준보다 길어요
    case aerationTooLong
    /// (!) 공기 주입 시간이 기준보다 짧아요
    case aerationTooShort

    /// 기준 시간 (초). 연습 중 비커의 아래 점선 · 위 점선과 같은 값이에요.
    static var aerationRange: ClosedRange<Int> {
        Int(MilkLevel.lowerLineSeconds)...Int(MilkLevel.upperLineSeconds)
    }

    /// 화면에 보이는 공기 주입 시간(한 번에 보기 · 상태별 감지시간의 "공기 주입" 초)으로 판단해요.
    /// 숫자와 안내가 서로 어긋나 보이지 않게 같은 값을 써요.
    init(result: PracticeResult) {
        self.init(aerationSeconds: result.detectedSeconds(of: .normalAeration))
    }

    init(aerationSeconds: Int) {
        if aerationSeconds < Self.aerationRange.lowerBound {
            self = .aerationTooShort
        } else if aerationSeconds > Self.aerationRange.upperBound {
            self = .aerationTooLong
        } else {
            self = .onTarget
        }
    }

    var title: String {
        switch self {
        case .onTarget: "기준 시간에 맞춰 연습했어요"
        case .aerationTooLong: "공기 주입 소리가 기준보다 오래 감지 됐어요"
        case .aerationTooShort: "공기 주입 소리가 기준보다 짧게 감지됐어요"
        }
    }

    var message: String {
        switch self {
        case .onTarget:
            "공기 주입과 롤링 소리가 모두 기준 시간 범위에서 감지됐어요\n완성된 우유의 거품과 질감도 함께 확인해 보세요"
        case .aerationTooLong:
            "필요한 거품이 만들어졌다면 노즐을 더 깊게 넣어 롤링으로 전환해 보세요."
        case .aerationTooShort:
            "우유에 공기가 충분히 들어갔는지 확인하고 필요한 경우 노즐을 우유 표면 가까이에 두어 공기를 조금 더 주입해 보세요"
        }
    }

    /// 연습 직후 결과(`PracticeResultView`) 히어로 타이틀 (Hi-Fi 연습가이드 공기 적정 · 과도 · 부족)
    var resultHeadline: String {
        switch self {
        case .onTarget: "좋은 흐름으로\n스티밍 했어요"
        case .aerationTooLong: "공기 주입량이\n많았어요"
        case .aerationTooShort: "공기 주입량이\n부족했어요"
        }
    }

    /// 기록 상세(`HistoryDetailView`) 히어로 타이틀 (Hi-Fi 같은 이름 -1. 부족만 문구가 조금 달라요)
    var historyHeadline: String {
        switch self {
        case .onTarget: "좋은 흐름으로\n스티밍 했어요"
        case .aerationTooLong: "공기 주입량이\n많았어요"
        case .aerationTooShort: "공기 주입이\n부족했어요"
        }
    }

    /// 왼쪽 아이콘 (SF Symbol)
    var systemImage: String {
        switch self {
        case .onTarget: "checkmark"
        case .aerationTooLong, .aerationTooShort: "exclamationmark.circle"
        }
    }
}

/// 연습 가이드 비커(`IllustPracticeGuidePitcher`, 289.7×217pt)의 우유 윗면 y (pt, 그림 위쪽 기준).
/// 연습 중 비커 수위(`MilkLevel`)를 두 점선이 서로 겹치도록 옮겨 써요. 그래서 2초면 아래 점선, 4초면 위 점선이에요.
enum GuideMilkLevel {
    /// 위 점선 (Hi-Fi 260: 화면 y 1145.75 − 그림 위 1045.8)
    static let upperLine: CGFloat = 100
    /// 아래 점선 (Hi-Fi 260: 1166.75 − 1045.8)
    static let lowerLine: CGFloat = 120.9
    /// 우유 바닥 (Hi-Fi 260: 1258.5 − 1045.8)
    static let bottom: CGFloat = 212.7

    static func top(forAeration seconds: TimeInterval) -> CGFloat {
        let scale = (lowerLine - upperLine) / (MilkLevel.lowerLine - MilkLevel.upperLine)
        let mapped = upperLine + (MilkLevel.top(forAeration: seconds) - MilkLevel.upperLine) * scale
        return min(bottom - 1, mapped)
    }
}
