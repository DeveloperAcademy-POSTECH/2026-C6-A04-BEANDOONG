import Foundation

enum HomeActivity: String, CaseIterable, Identifiable {
    case first, second, third

    var id: Self { self }

    var title: String {
        switch self {
        case .first: "활동 1"
        case .second: "활동 2"
        case .third: "활동 3"
        }
    }
}

enum HomeRoute: Hashable {
    case takeAStepBack
    case history
    case activity(HomeActivity)

    var title: String {
        switch self {
        case .takeAStepBack: "한 걸음 떨어져 보기"
        case .history: "히스토리"
        case .activity(let activity): activity.title
        }
    }
}
