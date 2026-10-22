import SwiftUI
@main struct PuffinWatchApp: App {
    var body: some Scene { WindowGroup { WatchInputView() } }
}
// 임시 워치 화면으로 독립 마이크 분석과 진동을 확인한다.
private struct WatchInputView: View {
    @State private var monitor = PulseMonitor()
    @Environment(\.scenePhase) private var phase
    private var ink: Color {monitor.air ? PuffinStyle.greenInk : .white}
    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:8) {
                Text("chee-k").font(.caption.bold())
                Text(monitor.starting ? "연결 중" : monitor.air ? "공기 주입 소리" : monitor.running ? "공기음 미감지" : "소리를 확인해요")
                    .font(.system(size:20,weight:.bold)).fixedSize(horizontal:false,vertical:true).accessibilityIdentifier("pulse.status")
                Text(String(format:"%02d:%02d",Int(monitor.elapsed)/60,Int(monitor.elapsed)%60))
                    .font(.system(size:36,weight:.bold,design:.rounded)).monospacedDigit().lineLimit(1).minimumScaleFactor(0.6)
                SoundEnvelope(levels:monitor.levels,color:ink).frame(height:20)
                Text(monitor.previewing ? "화면 시험 · 마이크 미사용" : monitor.suppressed ? "상단 대역 감소 감지" : "워치 마이크 · 소리 기반 추정").font(.system(size:10))
                Button(monitor.starting ? "취소" : monitor.running ? "종료" : "연습 시작") {
                    if monitor.running || monitor.starting {monitor.stop()} else{Task{await monitor.start()}}
                }.buttonStyle(.plain).frame(maxWidth:.infinity,minHeight:40).background(.white,in:Capsule()).foregroundStyle(PuffinStyle.ink).accessibilityIdentifier("pulse.startStop")
            }.frame(maxWidth:.infinity,alignment:.leading).padding(.horizontal,4)
        }.containerBackground(monitor.air ? PuffinStyle.mint : PuffinStyle.night,for:.navigation)
        .background((monitor.air ? PuffinStyle.mint : PuffinStyle.night).ignoresSafeArea()).foregroundStyle(ink)
        .preferredColorScheme(monitor.air ? .light : .dark)
        .alert("입력을 확인해 주세요",isPresented:Binding(get:{monitor.error != nil},set:{if !$0{monitor.error = nil}})){Button("확인"){monitor.error = nil}} message:{Text(monitor.error ?? "")}
        .onChange(of:phase) { _,state in if state == .background {monitor.stop()} }
        .onDisappear{monitor.stop()}
        .task {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--preview-input"){monitor.preview()}
            #endif
        }
    }
}
