import SwiftUI
import WidgetKit
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
    var body: some WidgetConfiguration {
        StaticConfiguration(kind:"PuffinInput",provider:Provider()) { _ in
            ComplicationView()
        }.configurationDisplayName("chee-k 입력").description("눌러서 워치 마이크로 스티밍 소리를 확인해요.")
            .supportedFamilies([.accessoryCircular,.accessoryRectangular,.accessoryInline])
    }
}
