import Foundation

/// 버전 비교 · 시안 표기 · App Store 조회 결과 해석을 검증합니다. (네트워크는 쓰지 않습니다)
@main
struct AppVersionTests {
    static func main() {
        func v(_ string: String) -> AppVersion { AppVersion(string)! }

        // 비교: 숫자 단위, 빈 자리는 0
        precondition(v("1.0.0") < v("1.0.3"))
        precondition(v("1.9.0") < v("1.10.0"))
        precondition(v("1.0.9") < v("1.1.0"))
        precondition(v("2.0.0") > v("1.99.99"))
        precondition(v("1.2") == v("1.2.0"))
        precondition(!(v("1.0.0") < v("1.0.0")))

        // 버전이 아닌 값은 받지 않음
        precondition(AppVersion("") == nil)
        precondition(AppVersion("1.0.a") == nil)
        precondition(AppVersion("1..0") == nil)
        precondition(AppVersion("-1.0.0") == nil)

        // 화면 표기: n.n.n, 빈 자리는 0
        precondition(v("1.0.0").display == "1.0.0")
        precondition(v("1.0.3").display == "1.0.3")
        precondition(v("1.12.4").display == "1.12.4")
        precondition(v("1.2.3.4").display == "1.2.3.4")
        precondition(v("2").display == "2.0.0")
        precondition(v("1.0.3").description == "1.0.3")

        // App Store 조회 결과 해석
        let found = Data(#"{"resultCount":1,"results":[{"version":"1.0.3","trackName":"chic"}]}"#.utf8)
        precondition(AppStoreVersion.parse(found) == v("1.0.3"))
        let notReleased = Data(#"{"resultCount":0,"results":[]}"#.utf8)
        precondition(AppStoreVersion.parse(notReleased) == nil)
        precondition(AppStoreVersion.parse(Data("not json".utf8)) == nil)

        print("AppVersionTests passed (compare, display, App Store lookup parsing)")
    }
}
