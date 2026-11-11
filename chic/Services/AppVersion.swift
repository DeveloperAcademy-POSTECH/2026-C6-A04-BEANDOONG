import Foundation

/// 앱 버전 번호 (예: "1.0.3"). 점으로 나눈 숫자를 앞에서부터 비교해요.
/// - "1.10.0"은 "1.9.0"보다 높아요 (글자가 아니라 숫자로 비교).
/// - 자리 수가 달라도 빈 자리는 0으로 봐요 ("1.2" == "1.2.0").
nonisolated struct AppVersion: Comparable, CustomStringConvertible {
    let components: [Int]

    /// 숫자와 점으로 된 버전만 받아요. 비어 있거나 숫자가 아닌 자리가 있으면 nil.
    init?(_ string: String) {
        let parts = string.trimmingCharacters(in: .whitespaces).split(separator: ".", omittingEmptySubsequences: false)
        let numbers = parts.compactMap { Int($0) }
        guard !parts.isEmpty, numbers.count == parts.count, numbers.allSatisfy({ $0 >= 0 }) else { return nil }
        components = numbers
    }

    /// 지금 설치된 앱의 버전 (Xcode 타깃의 Version = `MARKETING_VERSION`)
    static var current: AppVersion? {
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String).flatMap(AppVersion.init)
    }

    /// 시안 표기: 가운데 자리를 두 자리로 (1.0.3 → 1.00.3, 1.12.0 → 1.12.0)
    var display: String {
        let padded = components + Array(repeating: 0, count: max(0, 3 - components.count))
        return "\(padded[0]).\(String(format: "%02d", padded[1])).\(padded[2])"
    }

    var description: String { components.map(String.init).joined(separator: ".") }

    static func == (lhs: AppVersion, rhs: AppVersion) -> Bool {
        compare(lhs, rhs) == 0
    }

    static func < (lhs: AppVersion, rhs: AppVersion) -> Bool {
        compare(lhs, rhs) < 0
    }

    /// 앞자리부터 비교해 처음 다른 자리에서 결과를 내요. 빈 자리는 0.
    private static func compare(_ lhs: AppVersion, _ rhs: AppVersion) -> Int {
        for index in 0..<max(lhs.components.count, rhs.components.count) {
            let left = index < lhs.components.count ? lhs.components[index] : 0
            let right = index < rhs.components.count ? rhs.components[index] : 0
            if left != right { return left < right ? -1 : 1 }
        }
        return 0
    }
}

/// App Store에 올라간 최신 버전을 확인해요 (Apple iTunes Lookup API, 따로 서버 없음).
nonisolated enum AppStoreVersion {
    /// 출시 앱의 번들 ID. 개발용 빌드(`.develop`)도 출시 앱 버전과 비교해요.
    static let bundleID = "com.beandoong.chic"

    /// App Store 최신 버전. 출시 전이거나 네트워크 오류면 nil (틀린 정보를 보여 주지 않기 위해).
    static func latest(session: URLSession = .shared) async -> AppVersion? {
        var components = URLComponents(string: "https://itunes.apple.com/lookup")!
        components.queryItems = [URLQueryItem(name: "bundleId", value: bundleID)]
        // 앱은 나라별 App Store에 따로 올라가요. 기기 지역의 스토어에서 찾아요.
        if let region = Locale.current.region?.identifier {
            components.queryItems?.append(URLQueryItem(name: "country", value: region.lowercased()))
        }
        guard let url = components.url else { return nil }
        // 같은 날 다시 열어도 Apple 쪽 캐시 대신 새로 확인하도록 캐시를 쓰지 않아요.
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        guard let (data, response) = try? await session.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
        return parse(data)
    }

    /// 조회 결과(JSON)에서 버전을 꺼내요. 결과가 없으면 nil.
    static func parse(_ data: Data) -> AppVersion? {
        struct Response: Decodable {
            struct Result: Decodable { let version: String }
            let results: [Result]
        }
        guard let version = (try? JSONDecoder().decode(Response.self, from: data))?.results.first?.version else { return nil }
        return AppVersion(version)
    }
}
