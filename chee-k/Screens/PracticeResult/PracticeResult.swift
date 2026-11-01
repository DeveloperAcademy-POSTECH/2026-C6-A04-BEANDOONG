//
//  PracticeResult.swift
//
//  연습 결과 화면(PracticeResultView)에 표시할 데이터입니다.
//
//  [핵심 아이디어]
//  "어떤 소리가 몇 초부터 몇 초까지 감지됐는지"를 담은 구간 목록(segments) 하나만 원본으로 두고,
//  화면에 필요한 숫자는 모두 여기서 계산합니다.
//
//      segments ─┬─ timelineLength    → 전체 타임라인 가로축 길이
//                ├─ detectedSeconds   → 상태별 감지 시간 타일
//                └─ normal / caution / totalSeconds → 상단 요약 카드
//
//  [실제 데이터 연결 시 참고]
//  지금은 연습 중 상태 변화가 저장되지 않아 아래 더미 데이터(`.sample` 등)를 사용합니다.
//  실제 기록을 연결할 때는 연습 기록에서 `PracticeResult` 를 만들어 화면에 넘겨주기만 하면 되고,
//  화면 코드는 고칠 필요가 없습니다. 연결 전에 확인할 것:
//    1. 연습 중 상태가 바뀔 때마다 "어떤 소리, 몇 초"를 기록해 두는 곳이 아직 없습니다.
//    2. `PracticePhase` → `DetectedSound` 변환 규칙이 정해지지 않았습니다. (`DetectedSound` 주석 참고)
//    3. "N차"(같은 날 몇 번째 연습인지)를 세는 기준이 정해지지 않았습니다.
//    4. 구간 목록을 `PracticeRecord` 에 넣으면 워치로 보내는 기록(watchSnapshot)도 커지니,
//       워치 전송에서는 빼 주세요.
//

import SwiftUI

// MARK: - 스티밍 단계

/// 스티밍 단계 = 타임라인의 막대 한 줄 = 상태별 감지 시간의 타일 묶음 하나
enum SteamingStage: CaseIterable {
    /// 우유에 공기를 넣는 단계 (타임라인 위쪽 줄)
    case aeration
    /// 우유를 회전시키는 단계 (타임라인 아래쪽 줄)
    case rolling

    var title: String {
        switch self {
        case .aeration: "공기 주입"
        case .rolling: "롤링"
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
///
/// - Note: 아직 `PracticePhase`(Shared/PracticeState.swift)와 연결하지 않았습니다.
///   색만 보면 아래처럼 짝지어지지만, 워치 화면과 이 화면의 소리 이름이 서로 달라서
///   실제 연결 전에 기획 확인이 필요합니다.
///
///       이 화면              PracticePhase   워치 화면 표기
///       정상 공기 주입 (파랑)  .aeration       공기 주입 소리
///       공기과다     (주황)   .bubble         노즐 높음      ← 이름 다름
///       공기 부족    (보라)   .moreAir        공기 부족
///       롤링        (초록)   .milkFlow       롤링 소리
///       음료 과열    (분홍)   .sharpSound     공기 과다      ← 이름 다름
enum DetectedSound: CaseIterable {
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
    /// - 워치 피드백 화면 색(AppColors)과 비슷하지만 이 화면 디자인은 살짝 다른 색이라 따로 둡니다.
    var timelineColor: Color {
        switch self {
        case .normalAeration: Color(hex: 0x5D83FF)
        case .overAeration: Color(hex: 0xFFAB40)
        case .lackOfAir: Color(hex: 0xA178F5)
        case .rolling: Color(hex: 0x20C98A)
        case .overheated: Color(hex: 0xF45D98)
        }
    }

    /// 상태별 감지 시간 타일의 소리 이름 색상
    /// - 디자인에서 공기 부족만 막대보다 진한 보라를 씁니다. 나머지는 막대 색상과 같습니다.
    var labelColor: Color {
        switch self {
        case .lackOfAir: AppColors.moreAirPurple
        default: timelineColor
        }
    }
}

// MARK: - 감지 구간

/// 한 소리가 끊기지 않고 연속으로 감지된 구간
/// - 시간은 연습을 시작한 순간을 0초로 둔 경과 시간(초)입니다.
/// - 같은 소리가 여러 번 나오면 구간도 여러 개가 됩니다. (예: 정상 공기 주입 0~3초, 13~16초)
struct DetectedSegment: Identifiable {
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
