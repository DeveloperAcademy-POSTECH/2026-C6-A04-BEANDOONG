// Watch 앱 진입점과 연습 화면입니다. Watch도 자체 마이크로 PulseMonitor를 실행합니다.
import SwiftUI // Watch 앱 화면과 수명주기 환경값을 사용합니다.
@main struct PuffinWatchApp: App {
    // 앱이 열리면 바로 Watch 전용 연습 화면을 표시합니다.
    var body: some Scene { WindowGroup { WatchInputView() } }
}
// 임시 워치 화면: Monitor의 판정을 읽고 상태·고역 이력을 표시합니다.
// 햅틱을 직접 계산하지 않으며, PulseMonitor.accept()가 DSP의 pulse를 받아 재생합니다.
private struct WatchInputView: View {
    // Watch도 iPhone과 별도의 Monitor/마이크 세션을 가집니다.
    @State private var monitor = PulseMonitor()
    // 앱이 백그라운드로 가면 마이크를 종료하기 위해 관찰합니다.
    @Environment(\.scenePhase) private var phase
    // 감지 중인 배경에서는 어두운 글자, 평상시에는 흰 글자를 사용합니다.
    private var ink: Color {monitor.air ? PuffinStyle.greenInk : .white}
    var body: some View {
        // 작은 화면에서 상태·그래프·버튼을 모두 볼 수 있도록 스크롤합니다.
        ScrollView {
            VStack(alignment:.leading,spacing:8) {
                Text("chee-k").font(.caption.bold())
                // 큰 문구는 연결 중/감지 중/미감지/대기를 구분합니다.
                Text(monitor.starting ? "연결 중" : monitor.air ? "공기 주입 소리" : monitor.running ? "공기음 미감지" : "소리를 확인해요")
                    .font(.system(size:20,weight:.bold)).fixedSize(horizontal:false,vertical:true).accessibilityIdentifier("pulse.status")
                Text(String(format:"%02d:%02d",Int(monitor.elapsed)/60,Int(monitor.elapsed)%60))
                    .font(.system(size:36,weight:.bold,design:.rounded)).monospacedDigit().lineLimit(1).minimumScaleFactor(0.6)
                // 최근 고역 크기 이력이며 원본 음성 파형은 아닙니다.
                SoundEnvelope(levels:monitor.levels,color:ink).frame(height:20)
                // 화면 시험과 전환 차단 여부를 보조 문구로 설명합니다.
                Text(monitor.previewing ? "화면 시험 · 마이크 미사용" : monitor.suppressed ? "상단 대역 감소 감지" : "워치 마이크 · 소리 기반 추정").font(.system(size:10))
                Button(monitor.starting ? "취소" : monitor.running ? "종료" : "연습 시작") {
                    // 같은 버튼이 마이크 연결·취소·종료를 현재 상태에 맞게 호출합니다.
                    if monitor.running || monitor.starting {monitor.stop()} else{Task{await monitor.start()}}
                }.buttonStyle(.plain).frame(maxWidth:.infinity,minHeight:40).background(.white,in:Capsule()).foregroundStyle(PuffinStyle.ink).accessibilityIdentifier("pulse.startStop")
            }.frame(maxWidth:.infinity,alignment:.leading).padding(.horizontal,4)
        }.containerBackground(monitor.air ? PuffinStyle.mint : PuffinStyle.night,for:.navigation)
        // 배경과 글자 대비를 판정 상태에 맞추되 상태는 문구로도 표시합니다.
        .background((monitor.air ? PuffinStyle.mint : PuffinStyle.night).ignoresSafeArea()).foregroundStyle(ink)
        .preferredColorScheme(monitor.air ? .light : .dark)
        .alert("입력을 확인해 주세요",isPresented:Binding(get:{monitor.error != nil},set:{if !$0{monitor.error = nil}})){Button("확인"){monitor.error = nil}} message:{Text(monitor.error ?? "")}
        // 화면이 사라지거나 앱이 백그라운드로 가면 마이크와 분석을 중지합니다.
        .onChange(of:phase) { _,state in if state == .background {monitor.stop()} }
        .onDisappear{monitor.stop()}
        .task {
            #if DEBUG
            // 미리보기 인자는 화면만 시험하며 실제 마이크·감지 결과는 아닙니다.
            if ProcessInfo.processInfo.arguments.contains("--preview-input"){monitor.preview()}
            #endif
        }
    }
}
