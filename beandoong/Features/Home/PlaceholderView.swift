import SwiftUI

struct PlaceholderView: View {
    let title: String
    let onReturnHome: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text(title)
                .font(.title2.bold())
            Text("아직 구현되지 않은 기능입니다.")
                .foregroundStyle(.secondary)
            Button("메인 화면으로 돌아가기", action: onReturnHome)
                .buttonStyle(.borderedProminent)
        }
        .multilineTextAlignment(.center)
        .padding()
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }
}
