// iPhone과 Watch가 공유하는 색상과 최근 고역 크기 그래프입니다.
import SwiftUI

// 색을 한곳에서 관리해 공기음 감지 전후의 화면 의미를 일관되게 유지합니다.
enum PuffinStyle {
    static let blue = Color(red: 0.098, green: 0.42, blue: 0.58)
    static let ink = Color(red: 0.09, green: 0.204, blue: 0.27)
    static let pale = Color(red: 0.929, green: 0.973, blue: 0.996)
    static let mint = Color(red: 0.78, green: 0.937, blue: 0.878)
    static let greenInk = Color(red: 0.082, green: 0.361, blue: 0.278)
    static let night = Color(red: 0.063, green: 0.102, blue: 0.137)
}
// 최근 31개 고역 크기를 막대로 표시합니다. 원본 음성 파형이나 공기량은 아닙니다.
struct SoundEnvelope: View {
    var levels: [Float]
    var color: Color
    var body: some View {
        Canvas { context, size in
            let values = Array(levels.suffix(31)), count = 31
            for index in 0..<count {
                let offset = index-(count-values.count)
                let value = offset >= 0 ? CGFloat(values[offset]) : 0
                let height = max(4, min(1,value)*size.height)
                let rect = CGRect(x: CGFloat(index)*size.width/CGFloat(count), y: (size.height-height)/2, width: max(2,size.width/CGFloat(count)*0.38), height: height)
                context.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(color))
            }
        }.accessibilityHidden(true)
    }
}
