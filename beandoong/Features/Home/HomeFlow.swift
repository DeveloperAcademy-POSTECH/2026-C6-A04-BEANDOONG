import SwiftUI

struct HomeFlow: View {
    @State private var path: [HomeRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            HomeView { path.append($0) }
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: HomeRoute.self) { route in
                    // 실제 기능 화면은 이 연결부에서 교체합니다.
                    PlaceholderView(title: route.title) { path.removeAll() }
                }
        }
    }
}

#Preview {
    HomeFlow()
}
