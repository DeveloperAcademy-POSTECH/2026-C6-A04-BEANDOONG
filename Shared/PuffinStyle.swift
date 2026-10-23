// 두 기기가 공유하는 색상과 iPhone의 최근 고역 크기 그래프입니다.
import SwiftUI // 화면 색상과 Canvas 그래프에 필요한 형식을 제공합니다.

// 색을 한곳에서 관리해 공기음 감지 전후의 화면 의미를 일관되게 유지합니다.
enum PuffinStyle {
    // 브랜드·기본 글자·비활성 배경·감지 배경·Watch 야간 배경을 한곳에서 정의합니다.
    static let blue = Color(red: 0.098, green: 0.42, blue: 0.58)
    static let ink = Color(red: 0.09, green: 0.204, blue: 0.27)
    static let pale = Color(red: 0.929, green: 0.973, blue: 0.996)
    static let mint = Color(red: 0.78, green: 0.937, blue: 0.878)
    static let greenInk = Color(red: 0.082, green: 0.361, blue: 0.278)
    static let night = Color(red: 0.063, green: 0.102, blue: 0.137)
}
// 최근 31개 고역 크기를 막대로 표시합니다. 원본 음성 파형이나 공기량은 아닙니다.
struct SoundEnvelope: View {
    // PulseMonitor가 만든 0~1 크기 이력과 현재 화면에 맞는 막대 색입니다.
    var levels: [Float]
    var color: Color
    var body: some View {
        // Canvas는 31개 작은 막대를 효율적으로 한 번에 그립니다.
        Canvas { context, size in
            // 최신 31개만 그려 화면 크기와 표시 시간을 일정하게 유지합니다.
            let values = Array(levels.suffix(31)), count = 31
            for index in 0..<count {
                // 실제 값이 31개보다 적을 때 앞쪽 빈 칸을 0으로 채웁니다.
                let offset = index-(count-values.count)
                let value = offset >= 0 ? CGFloat(values[offset]) : 0
                // 0이어도 최소 4pt를 남겨 그래프 위치를 알아볼 수 있게 합니다.
                let height = max(4, min(1,value)*size.height)
                // 각 칸의 x 위치와 크기를 Canvas 너비에 맞춰 계산합니다.
                let rect = CGRect(x: CGFloat(index)*size.width/CGFloat(count), y: (size.height-height)/2, width: max(2,size.width/CGFloat(count)*0.38), height: height)
                // 그래프는 장식용이며 의미 있는 상태는 별도 텍스트로 전달합니다.
                context.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(color))
            }
        }.accessibilityHidden(true)
    }
}
