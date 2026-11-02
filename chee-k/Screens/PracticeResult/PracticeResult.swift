//
//  PracticeResult.swift
//
//  연습 결과 화면(PracticeResultView)과 히스토리 상세 화면(HistoryDetailView)에 표시할 데이터입니다.
//
//  [핵심 아이디어]
//  "어떤 소리가 몇 초부터 몇 초까지 감지됐는지"를 담은 구간 목록(segments)을 기본 원본으로 두고,
//  화면에 필요한 숫자와 차트 비율을 모두 계산합니다.
//
//      segments ─┬─ timelineLength    → 전체 타임라인 가로축 길이
//                ├─ detectedSeconds   → 상태별 감지 시간 타일
//                └─ normal / caution / totalSeconds → 상단 도넛 차트 · 3열 요약
//

import SwiftUI

// MARK: - 스티밍 단계

/// 스티밍 단계 = 타임라인의 막대 한 줄 = 상태별 감지 시간의 타일 묶음 하나
enum SteamingStage: CaseIterable {
    /// 우유에 공기를 넣는 단계 (타임라인 위쪽 줄)
    case aeration
    /// 우유를 회전시키는 단계 (타임라인 아래쪽 줄)
    case rolling

    /// 상태별 감지 시간 카드에서 사용하는 단계 제목
    var title: String {
        switch self {
        case .aeration: "공기 주입"
        case .rolling: "롤링"
        }
    }

    /// 전체 타임라인 카드 왼쪽 라벨에서 사용하는 단계 제목
    var timelineTitle: String {
        switch self {
        case .aeration: "공기 주입"
        case .rolling: "롤링 소리"
        }
    }

    /// 이 단계에서 감지될 수 있는 소리 (`DetectedSound` 의 case 순서 그대로)
    var sounds: [DetectedSound] {
        DetectedSound.allCases.filter { $0.stage == self }
    }
}

// MARK: - 감지된 소리

/// 연습 중 감지된 소리 상태
///
/// 소리마다 "어느 단계 줄에 그릴지 · 무슨 색인지 · 주의 소리인지"가 정해져 있습니다.
/// case 순서가 곧 상태별 감지 시간 카드의 타일 순서입니다.
enum DetectedSound: CaseIterable, Hashable {
    /// 파랑 · 공기가 알맞게 들어가는 소리
    case normalAeration
    /// 주황 · 공기가 너무 많이 들어가는 소리
    case overAeration
    /// 보라 · 공기가 부족한 소리
    case lackOfAir
    /// 초록 · 우유가 회전하는 소리
    case rolling
    /// 분홍 · 우유가 너무 뜨거워지는 소리
    case overheated

    var title: String {
        switch self {
        case .normalAeration: "정상 공기 주입"
        case .overAeration: "공기과다"
        case .lackOfAir: "공기 부족"
        case .rolling: "롤링"
        case .overheated: "음료 과열"
        }
    }

    /// 타임라인에서 그려질 줄
    var stage: SteamingStage {
        switch self {
        case .normalAeration, .overAeration, .lackOfAir: .aeration
        case .rolling, .overheated: .rolling
        }
    }

    /// 상단 요약에서 "주의 소리"로 더할지 여부 (false 면 "정상소리"로 더합니다)
    var needsCaution: Bool {
        switch self {
        case .normalAeration, .rolling: false
        case .overAeration, .lackOfAir, .overheated: true
        }
    }

    /// 타임라인 막대 색상 (Hi-Fi 원본 픽셀에서 추출)
    var timelineColor: Color {
        switch self {
        case .normalAeration: Color(hex: 0x1BA7E9)
        case .overAeration: Color(hex: 0xFFA615)
        case .lackOfAir: Color(hex: 0xA480EB)
        case .rolling: Color(hex: 0x1ABC37)
        case .overheated: Color(hex: 0xF2627C)
        }
    }

    /// 상태별 감지 시간 타일의 소리 이름 색상
    var labelColor: Color {
        timelineColor
    }
}

// MARK: - 감지 구간

/// 한 소리가 끊기지 않고 연속으로 감지된 구간
/// - 시간은 연습을 시작한 순간을 0초로 둔 경과 시간(초)입니다.
struct DetectedSegment: Identifiable, Hashable {
    let id = UUID()
    let sound: DetectedSound
    /// 구간 시작 (초)
    let start: TimeInterval
    /// 구간 끝 (초)
    let end: TimeInterval

    var duration: TimeInterval { end - start }
}

// MARK: - 연습 결과

struct PracticeResult {
    /// 연습한 날짜
    let practicedAt: Date
    /// 같은 날 몇 번째 연습인지 (1부터 시작, 제목의 "1차")
    let dailyOrder: Int
    /// 감지 구간 목록 (시간 순서). 화면의 모든 숫자와 그래프는 이 목록에서 계산됩니다.
    let segments: [DetectedSegment]

    /// 상단 네비게이션 바 제목 (예: "9월 26일 1차")
    var title: String {
        let date = Calendar.current.dateComponents([.month, .day], from: practicedAt)
        return "\(date.month ?? 0)월 \(date.day ?? 0)일 \(dailyOrder)차"
    }

    /// 타임라인 가로축 전체 길이 (초) = 마지막 구간이 끝난 시점
    /// - 구간이 하나도 없으면 0 이고, 이때 타임라인은 빈 막대로 그려집니다.
    var timelineLength: TimeInterval {
        segments.map(\.end).max() ?? 0
    }

    /// 소리 하나가 감지된 시간 (초, 반올림)
    ///
    /// 0.5초 미만으로 잠깐 감지된 소리는 "0초"로 표시됩니다.
    /// (타임라인에는 얇은 선으로 보이지만, 숫자는 초 단위라 0초가 됩니다.)
    ///
    /// 소리별로 먼저 반올림한 뒤 아래 합계들을 이 값으로 더합니다.
    /// 합계를 먼저 구하고 반올림하면 "정상 16초 + 주의 8초 = 전체 25초"처럼
    /// 화면의 숫자끼리 안 맞는 경우가 생길 수 있어서입니다.
    func detectedSeconds(of sound: DetectedSound) -> Int {
        let total = segments
            .filter { $0.sound == sound }
            .reduce(0) { $0 + $1.duration }
        return Int(total.rounded())
    }

    /// 상단 요약 "정상소리"
    var normalSeconds: Int {
        DetectedSound.allCases.filter { !$0.needsCaution }.reduce(0) { $0 + detectedSeconds(of: $1) }
    }

    /// 상단 요약 "주의 소리"
    var cautionSeconds: Int {
        DetectedSound.allCases.filter(\.needsCaution).reduce(0) { $0 + detectedSeconds(of: $1) }
    }

    /// 상단 요약 "전체 시간" = 정상소리 + 주의 소리
    /// - 소리가 감지되지 않은 시간(소리 확인 중 · 잡음)은 포함하지 않습니다.
    var totalSeconds: Int { normalSeconds + cautionSeconds }
}

// MARK: - 더미 데이터

// TODO: 연습 기록에 감지 구간이 저장되면 화면에는 실제 기록을 넘기고, 아래 더미는 미리보기용으로만 남깁니다.
extension PracticeResult {
    /// Hi-Fi 디자인과 같은 24초 연습
    /// - 정상 공기 주입 6초 · 공기과다 2초 · 공기 부족 2초 · 롤링 10초 · 음료 과열 4초
    static let sample = PracticeResult(
        practicedAt: Calendar.current.date(from: DateComponents(year: 2026, month: 9, day: 26)) ?? .now,
        dailyOrder: 1,
        segments: [
            DetectedSegment(sound: .normalAeration, start: 0, end: 3),
            DetectedSegment(sound: .rolling, start: 3, end: 13),
            DetectedSegment(sound: .normalAeration, start: 13, end: 16),
            DetectedSegment(sound: .overAeration, start: 16, end: 18),
            DetectedSegment(sound: .lackOfAir, start: 18, end: 20),
            DetectedSegment(sound: .overheated, start: 20, end: 24)
        ]
    )

    /// 1분이 넘는 긴 연습 — 시간 표기("1분 15초")와 눈금 간격이 바뀌는지 확인하는 용도
    /// - 중간중간 소리가 감지되지 않은 빈 시간과, 0.3초짜리 아주 짧은 구간도 들어 있습니다.
    static let longSample = PracticeResult(
        practicedAt: .now,
        dailyOrder: 3,
        segments: [
            DetectedSegment(sound: .lackOfAir, start: 0, end: 6),
            DetectedSegment(sound: .normalAeration, start: 6, end: 20),
            DetectedSegment(sound: .overAeration, start: 20, end: 20.3),
            DetectedSegment(sound: .normalAeration, start: 20.3, end: 28),
            DetectedSegment(sound: .rolling, start: 31, end: 62),
            DetectedSegment(sound: .overheated, start: 62, end: 75)
        ]
    )

    /// 감지된 소리가 하나도 없는 연습 — 빈 화면이 깨지지 않는지 확인하는 용도
    static let empty = PracticeResult(practicedAt: .now, dailyOrder: 1, segments: [])
}

// MARK: - 시간 문구

extension Int {
    /// 초를 화면용 문구로 바꿉니다. (24 → "24초", 60 → "1분", 64 → "1분 4초")
    var practiceSecondsText: String {
        let minutes = self / 60
        let seconds = self % 60
        if minutes == 0 { return "\(seconds)초" }
        if seconds == 0 { return "\(minutes)분" }
        return "\(minutes)분 \(seconds)초"
    }
}
