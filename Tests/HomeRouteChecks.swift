// Run: swiftc beandoong/Features/Home/HomeRoute.swift Tests/HomeRouteChecks.swift -o /tmp/home-route-checks && /tmp/home-route-checks
import Foundation

@main
struct HomeRouteChecks {
    static func main() {
        let activities = HomeActivity.allCases
        assert(activities.count == 3)
        assert(Set(activities.map(\.id)).count == 3)
        let routes: [HomeRoute] = [.takeAStepBack, .history]
            + activities.map { .activity($0) }
        assert(Set(routes).count == 5)
        assert(routes.map(\.title) == ["한 걸음 떨어져 보기", "히스토리", "활동 1", "활동 2", "활동 3"])
        print("Home route checks passed")
    }
}
