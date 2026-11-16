import CoreMotion
import SwiftUI

/// Icon Composer의 조명 없는 원본 SVG에 기울기에 반응하는 테두리 조명과 작은 움직임을 더해요.
/// SettingsAppIconArtwork 에셋은 AppIcon.icon/Assets/기본.svg를 직접 참조해요.
struct SettingsAppIcon: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.loopAnimationsPaused) private var isPaused
    @State private var tilt = CGPoint.zero

    private var tracksMotion: Bool {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-uiTestStill") { return false }
        #endif
        return scenePhase == .active && !reduceMotion && !isPaused
    }

    var body: some View {
        SettingsAppIconSurface(tilt: tilt)
            .accessibilityHidden(true)
            .allowsHitTesting(false)
            .task(id: tracksMotion) {
                guard tracksMotion else {
                    tilt = .zero
                    return
                }
                await trackMotion()
            }
    }

    @MainActor
    private func trackMotion() async {
        // 화면의 task가 취소되면 센서도 함께 멈춰요. 재진입 시 현재 자세를 새 기준으로 잡아요.
        tilt = .zero
        let manager = CMMotionManager()
        guard manager.isDeviceMotionAvailable, !Task.isCancelled else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 60.0
        manager.startDeviceMotionUpdates()
        defer { manager.stopDeviceMotionUpdates() }

        var origin: CMAcceleration?
        while !Task.isCancelled {
            if let gravity = manager.deviceMotion?.gravity {
                if origin == nil { origin = gravity }
                if let origin {
                    // 중력 성분을 쓰면 흔들림보다 기울기에 반응하고, 각도의 경계에서도 튀지 않아요.
                    let x = tanh((gravity.x - origin.x) / 0.45)
                    // 폰을 세워 들고 앞뒤로 기울일 때도 반응하도록 y/z 평면의 각도를 써요.
                    let pitch = atan2(gravity.z, -gravity.y) - atan2(origin.z, -origin.y)
                    let y = tanh(atan2(sin(pitch), cos(pitch)) / 0.55)
                    tilt = CGPoint(
                        x: tilt.x + (x - tilt.x) * 0.14,
                        y: tilt.y + (y - tilt.y) * 0.14
                    )
                }
            }
            do {
                try await Task.sleep(for: .milliseconds(16))
            } catch {
                break
            }
        }
    }
}

/// 센서와 분리해 여러 기울기의 조명·자세를 같은 조건에서 확인할 수 있어요.
struct SettingsAppIconSurface: View {
    var tilt: CGPoint

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)

        ZStack {
            Image("SettingsAppIconArtwork")
                .resizable()
                .scaledToFill()

            // 유리 가장자리의 넓고 약한 반사와 얇고 선명한 반사를 겹쳐요.
            // 조명은 stroke 안에만 존재하므로 중앙 로고에는 번지지 않아요.
            shape.strokeBorder(.white, lineWidth: 2.4)
                .colorEffect(rimShader(sharpness: 14))
                .opacity(0.24)
            shape.strokeBorder(.white, lineWidth: 0.85)
                .colorEffect(rimShader(sharpness: 32))
        }
        .frame(width: 98.5, height: 98.5)
        .clipShape(shape)
        .rotation3DEffect(.degrees(-Double(tilt.y) * 5), axis: (x: 1, y: 0, z: 0), perspective: 0.25)
        .rotation3DEffect(.degrees(Double(tilt.x) * 5), axis: (x: 0, y: 1, z: 0), perspective: 0.25)
        .offset(x: tilt.x * 2.5, y: tilt.y * 2.5)
        .shadow(color: .black.opacity(0.22), radius: 10, x: -tilt.x * 2.5, y: 5 - tilt.y * 2.5)
    }

    private func rimShader(sharpness: Float) -> Shader {
        ShaderLibrary.settingsIconRim(
            .float2(98.5, 98.5),
            .float2(Float(tilt.x), Float(tilt.y)),
            .float(sharpness)
        )
    }
}

#Preview("기울기에 따른 반사") {
    HStack(spacing: 24) {
        SettingsAppIconSurface(tilt: CGPoint(x: -0.65, y: -0.35))
        SettingsAppIconSurface(tilt: .zero)
        SettingsAppIconSurface(tilt: CGPoint(x: 0.65, y: 0.35))
    }
    .padding(24)
    .background(AppColors.darkBackground)
}
