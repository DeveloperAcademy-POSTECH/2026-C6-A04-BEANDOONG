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
//                └─ normal / caution → 상단 도넛 차트 · 요약 (첫 감지 전 대기 시간 제외)
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
enum DetectedSound: String, Codable, CaseIterable, Hashable {
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

struct PracticeResult: Hashable {
    /// 연습한 날짜
    let practicedAt: Date
    /// 같은 날 몇 번째 연습인지 (1부터 시작, 제목의 "1차")
    let dailyOrder: Int
    /// 감지 구간 목록 (시간 순서). 화면의 모든 숫자와 그래프는 이 목록에서 계산됩니다.
    let segments: [DetectedSegment]
    /// 소리를 확인 중이던 시간까지 포함한 실제 연습 길이입니다.
    var duration: TimeInterval? = nil
    /// 상태별 감지 시간을 별도로 지정할 때 사용 (nil 이면 segments 합계로 자동 계산)
    var customDetectedSeconds: [DetectedSound: Int]? = nil
    /// 타임라인 눈금 라벨을 별도로 지정할 때 사용 (nil 이면 timelineLength 로 자동 계산)
    var customTickSeconds: [Int]? = nil

    /// 상단 네비게이션 바 제목 (예: "9월 26일 1차")
    var title: String {
        let date = Calendar.current.dateComponents([.month, .day], from: practicedAt)
        return "\(date.month ?? 0)월 \(date.day ?? 0)일 \(dailyOrder)차"
    }

    /// 결과의 0초로 사용할 첫 감지 시점입니다. 감지 구간이 없으면 원래 시간 기준을 유지합니다.
    var timelineStart: TimeInterval {
        segments.map(\.start).min() ?? 0
    }

    /// 첫 감지 전 대기 시간을 제외한 타임라인 길이 (초).
    var timelineLength: TimeInterval {
        max(0, max(duration ?? 0, segments.map(\.end).max() ?? 0) - timelineStart)
    }

    /// 소리 하나가 감지된 시간 (초, 반올림)
    func detectedSeconds(of sound: DetectedSound) -> Int {
        if let override = customDetectedSeconds?[sound] {
            return override
        }
        return roundedDetectedSeconds[sound, default: 0]
    }

    /// 초 단위 반올림의 나머지를 배분해, 짧은 구간이 여러 개여도 합계가 늘어나지 않게 합니다.
    private var roundedDetectedSeconds: [DetectedSound: Int] {
        let durations = DetectedSound.allCases.map { sound in
            segments.filter { $0.sound == sound }.reduce(0) { $0 + $1.duration }
        }
        var seconds = durations.map { Int($0.rounded(.down)) }
        let remainder = Int(durations.reduce(0, +).rounded()) - seconds.reduce(0, +)
        let indices = durations.indices.sorted {
            let left = durations[$0] - Double(seconds[$0])
            let right = durations[$1] - Double(seconds[$1])
            return left == right ? $0 < $1 : left > right
        }
        for index in indices.prefix(remainder) { seconds[index] += 1 }
        return Dictionary(uniqueKeysWithValues: zip(DetectedSound.allCases, seconds))
    }

    /// 상단 요약 "정상소리"
    var normalSeconds: Int {
        DetectedSound.allCases.filter { !$0.needsCaution }.reduce(0) { $0 + detectedSeconds(of: $1) }
    }

    /// 상단 요약 "주의 소리"
    var cautionSeconds: Int {
        DetectedSound.allCases.filter(\.needsCaution).reduce(0) { $0 + detectedSeconds(of: $1) }
    }

    /// 상단 요약 "전체 시간". 첫 감지 이후의 미분류 구간은 포함합니다.
    var totalSeconds: Int { Int(timelineLength.rounded()) }

    /// 도넛 차트 바깥 링(정상소리) 비율 (0.0 ... 1.0)
    var normalRatio: Double {
        guard totalSeconds > 0 else { return 0 }
        return min(max(Double(normalSeconds) / Double(totalSeconds), 0), 1)
    }

    /// 도넛 차트 안쪽 링(주의 소리) 비율 (0.0 ... 1.0)
    var cautionRatio: Double {
        guard totalSeconds > 0 else { return 0 }
        return min(max(Double(cautionSeconds) / Double(totalSeconds), 0), 1)
    }
}

// MARK: - 더미 데이터

extension PracticeResult {
    /// Hi-Fi 디자인과 픽셀 단위로 동일한 24초 연습
    /// - 정상 공기 주입 6초 · 공기과다 2초 · 공기 부족 2초 · 롤링 10초 · 음료 과열 4초 (정상 16초 / 주의 8초 / 전체 24초)
    static let sample = PracticeResult(
        practicedAt: Calendar.current.date(from: DateComponents(year: 2026, month: 9, day: 26)) ?? .now,
        dailyOrder: 1,
        segments: [
            DetectedSegment(sound: .normalAeration, start: 0, end: 3.5),
            DetectedSegment(sound: .rolling, start: 3.5, end: 14.0),
            DetectedSegment(sound: .normalAeration, start: 14.0, end: 17.45),
            DetectedSegment(sound: .overAeration, start: 17.45, end: 20.85),
            DetectedSegment(sound: .lackOfAir, start: 20.85, end: 24.0)
        ],
        customDetectedSeconds: [
            .normalAeration: 6,
            .overAeration: 2,
            .lackOfAir: 2,
            .rolling: 10,
            .overheated: 4
        ],
        customTickSeconds: [0, 8, 12, 16, 20, 24]
    )

    /// 1분이 넘는 긴 연습 — 시간 표기("1분 15초")와 눈금 간격 · 도넛 비율이 동적으로 바뀌는지 확인하는 용도
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
