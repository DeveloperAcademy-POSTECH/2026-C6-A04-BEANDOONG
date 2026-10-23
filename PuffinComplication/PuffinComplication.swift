// 시계 화면에 chee-k 진입점을 표시하는 정적 컴플리케이션입니다.
// 실시간 공기음 상태나 진동을 제공하지 않습니다.
import SwiftUI
import WidgetKit
// WidgetKit이 요청할 때 표시할 시각 정보를 전달합니다. 상태 데이터는 담지 않습니다.
private struct Entry: TimelineEntry { let date: Date }
private struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> Entry { Entry(date:Date()) }
    func getSnapshot(in context: Context,completion: @escaping(Entry)->Void){completion(Entry(date:Date()))}
    func getTimeline(in context: Context,completion: @escaping(Timeline<Entry>)->Void){completion(Timeline(entries:[Entry(date:Date())],policy:.never))}
}
// 임시 컴플리케이션 화면으로 워치 앱 진입점을 표시한다.
private struct ComplicationView: View {
    @Environment(\.widgetFamily) private var family
    var body: some View {
        Group {
            if family == .accessoryInline { Label("chee-k",systemImage:"waveform") }
            else { VStack {Image(systemName:"waveform");Text("chee-k").font(.caption2)} }
        }.containerBackground(.fill.tertiary,for:.widget)
    }
}
@main struct PuffinComplication: Widget {
    // 지원하는 시계 화면 크기와 사용자에게 보이는 이름을 등록합니다.
    var body: some WidgetConfiguration {
        StaticConfiguration(kind:"PuffinInput",provider:Provider()) { _ in
            ComplicationView()
        }.configurationDisplayName("chee-k 입력").description("눌러서 워치 마이크로 스티밍 소리를 확인해요.")
            .supportedFamilies([.accessoryCircular,.accessoryRectangular,.accessoryInline])
    }
}
