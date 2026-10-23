// 시계 화면에 chee-k 진입점을 표시하는 정적 컴플리케이션입니다.
// 실시간 공기음 상태나 진동을 제공하지 않습니다.
import SwiftUI // 시계 화면에 표시할 작은 View를 그립니다.
import WidgetKit // 컴플리케이션의 타임라인과 등록 형식을 제공합니다.
// WidgetKit이 요청할 때 표시할 시각 정보를 전달합니다. 상태 데이터는 담지 않습니다.
// WidgetKit 타임라인에는 현재 날짜만 넣고 분석 상태는 넣지 않습니다.
private struct Entry: TimelineEntry { let date: Date }
private struct Provider: TimelineProvider {
    // 편집 화면에서 보일 임시 항목을 제공합니다.
    func placeholder(in context: Context) -> Entry { Entry(date:Date()) }
    // 미리보기 한 장을 요청받았을 때 현재 시각 항목을 보냅니다.
    func getSnapshot(in context: Context,completion: @escaping(Entry)->Void){completion(Entry(date:Date()))}
    // 내용이 정적이므로 자동 갱신 일정을 추가하지 않습니다.
    func getTimeline(in context: Context,completion: @escaping(Timeline<Entry>)->Void){completion(Timeline(entries:[Entry(date:Date())],policy:.never))}
}
// 임시 컴플리케이션 화면으로 워치 앱 진입점을 표시한다.
private struct ComplicationView: View {
    // 시계 화면의 배치 종류에 맞춰 작은/가로형 표시를 바꿉니다.
    @Environment(\.widgetFamily) private var family
    var body: some View {
        Group {
            // 한 줄 공간에는 텍스트와 아이콘만 간결하게 표시합니다.
            if family == .accessoryInline { Label("chee-k",systemImage:"waveform") }
            // 나머지 크기에는 아이콘 위에 앱 이름을 놓습니다.
            else { VStack {Image(systemName:"waveform");Text("chee-k").font(.caption2)} }
        }.containerBackground(.fill.tertiary,for:.widget)
    }
}
@main struct PuffinComplication: Widget {
    // 지원하는 시계 화면 크기와 사용자에게 보이는 이름을 등록합니다.
    var body: some WidgetConfiguration {
        // StaticConfiguration은 마이크 분석 결과를 실시간으로 반영하지 않습니다.
        StaticConfiguration(kind:"PuffinInput",provider:Provider()) { _ in
            ComplicationView()
        }.configurationDisplayName("chee-k 입력").description("눌러서 워치 마이크로 스티밍 소리를 확인해요.")
            .supportedFamilies([.accessoryCircular,.accessoryRectangular,.accessoryInline])
    }
}
