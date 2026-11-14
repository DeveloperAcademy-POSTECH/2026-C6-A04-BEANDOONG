import Foundation

/// 정상 공기 주입과 롤링 기록을 먼저 확인한 뒤 피그마 문구표의 안내를 고릅니다.
enum PracticeGuide: Equatable {
    case missingAeration, missingRolling, missingBoth
    case short, shortScratch, shortBubble, shortBoth
    case onTarget, targetScratch, targetBubble, targetBoth
    case long, longScratch, longBubble, longBoth

    init(result: PracticeResult) {
        let air = result.guideDuration(of: .normalAeration)
        let rolling = result.guideDuration(of: .rolling)
        guard air > 0 else {
            self = rolling > 0 ? .missingAeration : .missingBoth
            return
        }
        guard rolling > 0 else {
            self = .missingRolling
            return
        }

        let scratch = result.guideDuration(of: .lackOfAir) > 0
        let bubble = result.guideDuration(of: .overAeration) > 0
        switch (air, scratch, bubble) {
        case (..<MilkLevel.lowerLineSeconds, false, false): self = .short
        case (..<MilkLevel.lowerLineSeconds, true, false): self = .shortScratch
        case (..<MilkLevel.lowerLineSeconds, false, true): self = .shortBubble
        case (..<MilkLevel.lowerLineSeconds, true, true): self = .shortBoth
        case (...MilkLevel.upperLineSeconds, false, false): self = .onTarget
        case (...MilkLevel.upperLineSeconds, true, false): self = .targetScratch
        case (...MilkLevel.upperLineSeconds, false, true): self = .targetBubble
        case (...MilkLevel.upperLineSeconds, true, true): self = .targetBoth
        case (_, false, false): self = .long
        case (_, true, false): self = .longScratch
        case (_, false, true): self = .longBubble
        case (_, true, true): self = .longBoth
        }
    }

    /// 한 조건에 쓰이는 상단 문구, 가이드 제목과 본문입니다.
    private var copy: (headline: String, title: String, message: String) {
        switch self {
        case .missingAeration:
            (String(localized: "이번엔 공기 주입 소리를\n확인하지 못했어요"),
             String(localized: "우유의 거품 상태를 살펴보세요"),
             String(localized: "공기주입 소리를 확인하지 못해 이번 기록만으로 거품 상태를 판단하기 어려워요. 완성된 우유의 거품을 살펴보고 다음에는 고른 공기주입 소리를 찾아보세요."))
        case .missingRolling:
            (String(localized: "다음엔 우유와 거품을\n고르게 섞어볼까요?"),
             String(localized: "우유와 거품이 덜 섞였을 수 있어요"),
             String(localized: "컵에 따를 때 묽은 우유가 먼저 나오고 거품이 피처에 덩어리로 남는다면, 우유와 거품이 덜 섞인 거예요. 다음엔 공기를 넣은 뒤 노즐 끝을 살짝 담가 우유 전체가 돌도록 해 보세요."))
        case .missingBoth:
            (String(localized: "이번 스티밍 상태를\n판단하기 어려워요"),
             String(localized: "소리가 제대로 확인되지 않았어요"),
             String(localized: "핸드폰이 스팀기 근처에 위치해있는지, 외부소리가 너무 큰 것은 아닌지 확인해주세요"))
        case .short:
            (String(localized: "거품이 조금\n얇을 수 있어요"),
             String(localized: "우유 높이가 처음과 비슷한가요?"),
             String(localized: "피처에 처음 담았을 때보다 우유가 얼마나 부풀었는지 보세요. 높이가 거의 그대로이고 거품도 적다면 다음번엔 공기를 조금 더 오래 넣어 보세요."))
        case .shortScratch:
            (String(localized: "공기 주입이\n조금 부족했어요"),
             String(localized: "우유가 부풀고 거품이 생겼나요?"),
             String(localized: "스크레칭이 들렸을 때는 스티밍 전후의 우유 높이와 표면을 함께 보세요. 높이가 거의 그대로이고 거품도 잘 보이지 않는다면 다음엔 초반에 노즐 끝을 표면 가까이에 두세요."))
        case .shortBubble:
            (String(localized: "짧은 순간에\n공기가 들어갔어요"),
             String(localized: "표면에 큰 기포가 남았나요?"),
             String(localized: "피처 안을 들여다봤을 때 낱개로 또렷이 보이는 기포가 있는지 살펴보세요. 큰 기포가 남았다면 다음엔 공기를 넣을 때 노즐 끝이 표면 밖으로 드러나지 않게 해 보세요."))
        case .shortBoth:
            (String(localized: "공기가 조금\n거칠게 들어갔어요"),
             String(localized: "기포 크기와 부피를 따로 보세요"),
             String(localized: "먼저 표면에 큰 기포가 있는지 보고, 우유 높이도 처음과 비교해 보세요. 큰 기포 몇 개가 눈에 띄는 것만으로는 우유 전체가 얼마나 부풀었는지 알기 어려워요."))
        case .onTarget:
            (String(localized: "스티밍 타이밍을\n딱 맞췄어요!"),
             String(localized: "우유 표면에 윤기가 나나요?"),
             String(localized: "피처를 가볍게 돌려 우유 표면을 보세요. 기포 하나하나가 잘 보이지 않고 표면이 매끈하게 빛나면 고운 거품의 특징이에요."))
        case .targetScratch:
            (String(localized: "공기 주입 시간을\n잘 맞췄어요"),
             String(localized: "우유 높이를 처음과 비교해 보세요"),
             String(localized: "스크레칭이 들렸어도 우유가 원하는 만큼 부풀었다면 공기 주입 시간을 늘릴 필요는 없어요. 높이가 거의 그대로이고 거품도 적다면 다음엔 차가운 우유에 공기를 조금 더 넣어 보세요."))
        case .targetBubble:
            (String(localized: "공기가 한꺼번에 들어간\n순간이 있었어요"),
             String(localized: "큰 기포가 눈에 띄나요?"),
             String(localized: "표면이 전반적으로 매끈한지, 그 사이에 큰 기포가 남았는지 보세요. 몇 개만 남았다면 피처 바닥을 작업대에 가볍게 톡톡 두드린 뒤 살짝 돌려 보세요."))
        case .targetBoth:
            (String(localized: "우유 표면에 큰 기포가\n남았을 수 있어요"),
             String(localized: "표면과 따를 때의 모습을 함께 보세요"),
             String(localized: "표면에 큰 기포가 있는지 먼저 살펴보세요. 컵에 따를 때 묽은 우유가 먼저 나오고 거품이 피처에 덩어리로 남는다면 우유와 거품이 고르게 섞이지 않은 상태예요."))
        case .long:
            (String(localized: "공기를 조금\n오래 넣었어요"),
             String(localized: "거품이 원하는 만큼 생겼나요?"),
             String(localized: "컵에 따른 뒤 거품이 원했던 것보다 두껍게 쌓였는지 보세요. 더 얇은 거품을 원한다면 다음엔 공기 주입을 조금 일찍 마쳐 보세요."))
        case .longScratch:
            (String(localized: "거품이 우유와 덜 섞여\n위에 남았을 수 있어요"),
             String(localized: "거품 두께를 직접 살펴보세요"),
             String(localized: "스크레칭이 들렸더라도 컵에 따른 거품이 원하는 두께라면 공기를 더 넣을 필요는 없어요. 묽은 우유부터 나오고 피처에 두꺼운 거품이 남았다면 우유와 거품이 따로 층을 이룬 거예요."))
        case .longBubble:
            (String(localized: "거품 사이에 큰 기포가\n남았을 수 있어요"),
             String(localized: "큰 기포와 거품 두께를 구분해 보세요"),
             String(localized: "피처에서는 표면에 큰 기포가 남았는지, 컵에 따른 뒤 거품이 원하는 두께인지 보세요. 큰 기포가 남았다면 다음엔 공기를 한꺼번에 넣지 않도록 노즐 끝을 표면 바로 아래에 두세요."))
        case .longBoth:
            (String(localized: "큰 기포가 섞인 거품층이\n위에 남았을 수 있어요"),
             String(localized: "마지막에 거품만 남나요?"),
             String(localized: "스티밍을 마친 뒤 피처를 가볍게 돌려 컵에 따라 보세요. 처음에는 묽은 우유만 나오고 끝에 뻣뻣한 거품이 남는다면 우유와 거품이 따로 층을 이룬 상태예요."))
        }
    }

    var resultHeadline: String { copy.headline }
    var historyHeadline: String { copy.headline }
    var title: String { copy.title }
    var message: String { copy.message }
    var systemImage: String { self == .onTarget ? "checkmark" : "exclamationmark.circle" }
}

extension PracticeResult {
    /// 실제 구간 시간을 합산해 1초 미만의 소리도 기록으로 인정합니다.
    func guideDuration(of sound: DetectedSound) -> TimeInterval {
        let seconds = segments.reduce(0.0) { total, segment in
            guard segment.sound == sound, segment.duration.isFinite, segment.duration > 0 else { return total }
            return total + segment.duration
        }
        return seconds > 0 ? seconds : Double(max(0, customDetectedSeconds?[sound] ?? 0))
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
