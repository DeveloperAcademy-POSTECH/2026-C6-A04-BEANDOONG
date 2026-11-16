import Foundation

/// 한 번의 연습에서 시작·진행·종료 분석에 사용할 모델을 정합니다.
nonisolated enum ChicModelSelection: String {
    case standard
    #if DEVELOP
    case home
    static let storageKey = "steamingModelSelection"
    #endif

    static var selected: Self {
        #if DEVELOP
        return UserDefaults.standard.string(forKey: storageKey).flatMap(Self.init(rawValue:)) ?? .standard
        #else
        return .standard
        #endif
    }

    /// 비커의 아래·위 점선에 해당하는 누적 정상 공기 주입 시간입니다.
    var aerationRange: ClosedRange<TimeInterval> {
        switch self {
        case .standard: 2...4
        #if DEVELOP
        case .home: 8...10
        #endif
        }
    }
}
