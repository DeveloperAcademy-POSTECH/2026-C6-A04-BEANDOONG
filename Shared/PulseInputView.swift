// iPhone 연습 화면입니다. PulseMonitor가 가진 상태를 읽어 안내·시각 피드백을 그립니다.
// 아래 진단 패널은 기준값을 조절하는 프로토타입 도구이며 판정 계산은 하지 않습니다.
import SwiftUI // 상태를 화면 선언으로 연결하는 SwiftUI를 사용합니다.

// 임시 iPhone 화면으로 분석 상태와 기준값을 확인한다.
struct PulseInputView: View {
    // View가 살아 있는 동안 같은 Monitor를 유지해야 마이크 분석이 중간에 재시작되지 않습니다.
    @State private var monitor = PulseMonitor()
    // 앱이 백그라운드로 이동할 때 마이크를 멈추기 위해 장면 상태를 관찰합니다.
    @Environment(\.scenePhase) private var scenePhase
    // 공기음 감지 여부 하나가 배경색·문구·고역 이력 표시를 함께 바꿉니다.
    // 색과 문구는 모두 Monitor의 현재 판정에서 파생하며 별도 상태로 중복 저장하지 않습니다.
    private var background: Color { monitor.air ? PuffinStyle.mint : Color.white }
    private var ink: Color { monitor.air ? PuffinStyle.greenInk : PuffinStyle.ink }
    private var title: String { monitor.starting ? "마이크 연결 중" : !monitor.running ? "소리를 확인해요" : monitor.air ? "공기 주입 소리" : "공기음 미감지" }
    private var detail: String { !monitor.running ? "시작을 누르고 스티밍해 보세요." : monitor.suppressed ? "상단 대역 감소를 감지했어요." : monitor.air ? "현재 소리의 특징을 표시하고 있어요." : "롤링·종료 여부를 뜻하지 않아요." }
    var body: some View {
        // 작은 iPhone에서도 진단 내용 전체를 볼 수 있도록 세로 스크롤을 사용합니다.
        ScrollView {
            VStack(alignment:.leading,spacing:20) {
                // 앱 이름과 실행 상태는 분석이 켜졌는지 먼저 알려 줍니다.
                HStack {
                    Text("chee-k").font(.system(size:32,weight:.bold)).foregroundStyle(PuffinStyle.blue)
                    Spacer()
                    Text(monitor.previewing ? "화면 시험" : monitor.running ? "● 분석 중" : "입력 대기").font(.caption)
                }
                // 가장 큰 문구가 현재 공기음 판정이며 VoiceOver 제목으로도 지정합니다.
                Text(title).font(.largeTitle.bold()).fixedSize(horizontal:false,vertical:true)
                    .accessibilityAddTraits(.isHeader).accessibilityIdentifier("pulse.status")
                Text(detail).font(.subheadline).fixedSize(horizontal:false,vertical:true)
                // 경과 시간과 최근 고역 크기 그래프를 같은 줄에 배치합니다.
                HStack(alignment:.center) {
                    Text(String(format:"%02d:%02d",Int(monitor.elapsed)/60,Int(monitor.elapsed)%60))
                        .font(.system(size:44,weight:.bold,design:.rounded)).monospacedDigit()
                    SoundEnvelope(levels:monitor.running ? monitor.levels : [],color:ink).frame(height:48)
                }
                // 개발·현장 조정을 위해 실제 측정값과 적용 기준값을 보여 줍니다.
                PulseMonitoringPanel(monitor:monitor)
                // 소리 기반 결과를 온도·공기량 측정으로 오해하지 않게 범위를 명시합니다.
                Text("소리 기반 추정 · 실제 공기량과 우유 온도는 측정하지 않아요.")
                    .font(.caption2).fixedSize(horizontal:false,vertical:true)
            }.padding(24).frame(maxWidth:560).frame(maxWidth:.infinity)
        // 배경과 글자색은 air 상태를 반영하고, 버튼은 안전 영역 하단에 고정합니다.
        }.background(background.ignoresSafeArea()).foregroundStyle(ink)
        .safeAreaInset(edge:.bottom) { action.padding(.horizontal,24).padding(.vertical,12).background(.regularMaterial) }
        .preferredColorScheme(.light)
        // Monitor.error가 생기면 마이크/권한 오류를 경고창으로 보여 줍니다.
        .alert("입력을 확인해 주세요",isPresented:Binding(get:{monitor.error != nil},set:{if !$0{monitor.error = nil}})) {
            Button("확인"){monitor.error = nil}
        } message:{Text(monitor.error ?? "")}
        // 기준값 변경은 저장하고 실행 중인 분석기에도 적용합니다.
        .onChange(of:monitor.thresholds) { _,_ in monitor.applyThresholds() }
        // 백그라운드에서는 마이크 분석을 유지하지 않습니다.
        .onChange(of:scenePhase) { _,phase in if phase == .background { monitor.stop() } }
        .onDisappear { monitor.stop() }
        .task {
            #if DEBUG
            // --preview-input은 화면 확인 전용 실행 인자이며 실제 마이크를 열지 않습니다.
            if ProcessInfo.processInfo.arguments.contains("--preview-input") { monitor.preview() }
            #endif
        }
    }
    // 시작/종료 버튼은 화면 상태를 직접 바꾸지 않고 Monitor의 수명주기를 호출합니다.
    private var action: some View {
        Button {
            // 연결 중 취소와 실행 중 종료는 모두 같은 stop() 경로를 사용합니다.
            if monitor.running || monitor.starting {monitor.stop()} else {Task{await monitor.start()}}
        } label: {
            // 연결 중에는 진행 표시를 보여 주어 권한 대기와 분석 중을 구분합니다.
            HStack { if monitor.starting {ProgressView()}; Text(monitor.starting ? "취소" : monitor.running ? "연습 종료" : "연습 시작").font(.headline) }
                .frame(maxWidth:.infinity,minHeight:56)
        }.buttonStyle(.plain).foregroundStyle(monitor.running ? PuffinStyle.blue : .white)
            // 시작/종료 버튼을 색으로 구분하되 텍스트도 항상 함께 표시합니다.
            .background(monitor.running ? PuffinStyle.pale : PuffinStyle.blue,in:Capsule())
            .accessibilityIdentifier("pulse.startStop")
    }
}

// 임시 측정 패널: '측정값', '현재 적용된 기준', '전환 차단 상태'를 구분해 보여 줍니다.
// 숫자를 조절하면 PulseMonitor → PulseCapture → PulseDSP 순서로 전달됩니다.
private struct PulseMonitoringPanel: View {
    // @Bindable 덕분에 Stepper/Slider가 Monitor의 기준값을 직접 조절할 수 있습니다.
    @Bindable var monitor: PulseMonitor
    // 아직 첫 오디오 결과가 없으면 측정 항목을 '—'로 표시합니다.
    private var reading: PulseResult? { monitor.reading }
    private func number(_ value: Double?, unit: String = "dBFS") -> String {
        // 숫자 형식을 한곳에서 맞춰 여러 측정 행이 같은 모양으로 보이게 합니다.
        value.map { String(format:"%.1f",$0)+" "+unit } ?? "—"
    }
    private var settingsApplied: Bool {
        guard let r = reading else{return false}
        // 화면 슬라이더의 새 값과 DSP가 이번 결과에 실제 사용한 값을 비교합니다.
        return r.appliedHighDB == monitor.thresholds.highDB && r.appliedRatio == monitor.thresholds.ratio && r.appliedFlatness == monitor.thresholds.flatness
    }
    var body: some View {
        // 측정값 → 조절 가능한 조건 → 고정 전환 조건 순서로 진단 정보를 배치합니다.
        VStack(alignment:.leading,spacing:18) {
            Text("입력 모니터링").font(.title2.bold()).accessibilityAddTraits(.isHeader)
            // 화면 시험/실시간 분석/중지 상태에 따라 측정값의 의미를 바꿔 설명합니다.
            Text(monitor.previewing ? "화면 시험 · 마이크 미사용" : monitor.running ? "현재 측정값 · 약 40ms 간격" : reading == nil ? "측정 대기" : "마지막 측정값 · 입력 중지")
                .font(.caption).foregroundStyle(.secondary)
            Text(monitor.inputDescription).font(.caption).textSelection(.enabled)
            // 전체 RMS는 참고값이고, 실제 공기음 조건은 아래 고역·비율·평탄도입니다.
            measurement("전체 크기 (RMS)",number(reading?.db))
            // 각 열을 나란히 두면 '지금 소리'와 '판정 기준'을 바로 비교할 수 있습니다.
            Grid(alignment:.leading,horizontalSpacing:12,verticalSpacing:10) {
                GridRow { Text("입력 조건");Text("측정");Text("적용 기준") }.fontWeight(.semibold)
                GridRow { Text("고역 크기");Text(number(reading?.highDB,unit:""));Text(number(reading?.appliedHighDB,unit:"dBFS")) }
                GridRow { Text("고역 비율");Text(number(reading.map{$0.ratio*100},unit:"%"));Text(number(reading.map{$0.appliedRatio*100},unit:"%")) }
                GridRow { Text("광대역성");Text(number(reading.map{$0.flatness*100},unit:"%"));Text(number(reading.map{$0.appliedFlatness*100},unit:"%")) }
            }.font(.caption).monospacedDigit()
            Divider()
            Text("기준값 조절").font(.headline)
            // 세 조절 UI는 같은 helper를 써 표시 방식과 변경 단위를 맞춥니다.
            threshold("4–12kHz 에너지",measurement:reading?.highDB,value:$monitor.thresholds.highDB,range:-100...0,step:1,percent:false,applied:reading?.appliedHighDB)
            threshold("고역 비율",measurement:reading.map{$0.ratio*100},value:$monitor.thresholds.ratio,range:0...1,step:0.01,percent:true,applied:reading.map{$0.appliedRatio*100})
            threshold("광대역성 (평탄도)",measurement:reading.map{$0.flatness*100},value:$monitor.thresholds.flatness,range:0...1,step:0.01,percent:true,applied:reading.map{$0.appliedFlatness*100})
            if monitor.running && !monitor.previewing {
                // 값 변경과 오디오 큐 적용 사이 짧은 차이를 사용자가 볼 수 있습니다.
                Text(settingsApplied ? "현재 기준값으로 분석 중" : "새 기준값 적용 대기 · 다음 입력부터 반영")
                    .font(.caption.weight(.semibold)).accessibilityIdentifier("pulse.thresholdStatus")
            }
            Text("광대역성 20%는 계산값 0.20입니다. 변경값은 iPhone에만 저장되고, 분석 중에도 바로 반영됩니다.")
                .font(.caption).foregroundStyle(.secondary)
            Button("기본값 복원 (−48dBFS · 12% · 12%)") { monitor.thresholds = PulseThresholds() }
                .font(.subheadline).frame(minHeight:44).accessibilityIdentifier("pulse.resetThresholds")
            Divider()
            Text("추가 해제 조건 · 기존 고정값").font(.headline)
            // 아래 값은 상단 주파수 감소에 따른 차단 규칙을 설명하는 진단 항목입니다.
            Text(reading == nil ? "측정 대기" : monitor.suppressed ? "상단 대역 감소로 공기음 표시 차단 중" : "상단 감소 차단 없음")
                .font(.subheadline.weight(.semibold))
            // 두 대역 크기와 감소량을 나눠 보여 줘 왜 차단됐는지 추적할 수 있습니다.
            measurement("4–8kHz",number(reading?.lowerDB))
            measurement("12–16kHz",number(reading?.upperDB))
            measurement("상단 감소 / 기준 ≥ 10dB",number(reading?.upperDrop,unit:"dB"))
            measurement("대역 대비 감소 / 기준 ≥ 6dB",number(reading?.tiltDrop,unit:"dB"))
            measurement("평활 4–8kHz / 기준 ≥ −55dBFS",number(reading?.smoothedLowerDB))
            Text(reading?.hasReference == true ? "전환 비교 기준 있음" : "전환 비교 기준 없음 · 앞선 후보 소리가 필요해요.").font(.caption)
            // 순간 기준 통과가 아니라 얼마나 오래 지속됐는지 ms로 보여 줍니다.
            measurement("후보 지속 / 진입 120ms",number(reading.map{$0.candidateSeconds*1000},unit:"ms"))
            measurement("조건 미달 지속 / 해제 220ms",number(reading.map{$0.releaseSeconds*1000},unit:"ms"))
            measurement("상단 감소 지속 / 차단 120ms",number(reading.map{$0.transitionSeconds*1000},unit:"ms"))
            Text("세 가지 입력 조건을 모두 만족해야 합니다. 세 조건이 통과해도 추가 해제 조건이 적용 중이면 표시되지 않습니다. 위 해제·복귀 규칙과 시간 조건은 변경하지 않았습니다.")
                .font(.caption).foregroundStyle(.secondary)
        }.padding(18).background(PuffinStyle.pale,in:RoundedRectangle(cornerRadius:20))
    }
    // 공통 측정 행의 이름·값 정렬을 맡습니다.
    private func measurement(_ name: String,_ value: String) -> some View {
        LabeledContent(name) { Text(value).monospacedDigit().foregroundStyle(PuffinStyle.ink) }.font(.caption)
    }
    // 세 기준값에 공통으로 쓰는 조절 UI. 사용자가 만지는 값과 DSP에 적용된 값을 함께 표시합니다.
    private func threshold(_ title: String,measurement: Double?,value: Binding<Double>,range: ClosedRange<Double>,step: Double,percent: Bool,applied: Double?) -> some View {
        // ratio/flatness는 내부 0~1 값을 사용자에게 익숙한 0~100%로만 표시합니다.
        let factor = percent ? 100.0 : 1.0, unit = percent ? "%" : "dBFS"
        return VStack(alignment:.leading,spacing:8) {
            Text(title).font(.headline)
            self.measurement("측정값",number(measurement,unit:unit))
            self.measurement("적용된 기준값",number(applied,unit:unit))
            if let measurement,let applied {
                // 개별 조건의 통과 표시이며 최종 active는 추가 차단 규칙까지 거칩니다.
                Text(measurement >= applied ? "✓ 입력 조건 통과" : "× 기준 미달")
                    .font(.caption.weight(.semibold)).foregroundStyle(measurement >= applied ? PuffinStyle.greenInk : Color(red:0.6,green:0.2,blue:0.1))
            }
            Stepper(value:value,in:range,step:step) {
                // 접근성이 좋은 단계별 변경 수단입니다.
                Text("조절: "+number(value.wrappedValue*factor,unit:unit)).font(.subheadline).monospacedDigit()
            }.accessibilityLabel(title+" 기준값")
            // 슬라이더는 값을 빠르게 훑어 보며 조절할 때 사용합니다.
            Slider(value:value,in:range,step:step).tint(PuffinStyle.blue).accessibilityLabel(title+" 기준값 슬라이더")
        }
    }
}
