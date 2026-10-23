// iPhone 연습 화면입니다. PulseMonitor가 가진 상태를 읽어 안내·시각 피드백을 그립니다.
// 아래 진단 패널은 기준값을 조절하는 프로토타입 도구이며 판정 계산은 하지 않습니다.
import SwiftUI

// 임시 iPhone 화면으로 분석 상태와 기준값을 확인한다.
struct PulseInputView: View {
    @State private var monitor = PulseMonitor()
    @Environment(\.scenePhase) private var scenePhase
    // 공기음 감지 여부 하나가 배경색·문구·고역 이력 표시를 함께 바꿉니다.
    private var background: Color { monitor.air ? PuffinStyle.mint : Color.white }
    private var ink: Color { monitor.air ? PuffinStyle.greenInk : PuffinStyle.ink }
    private var title: String { monitor.starting ? "마이크 연결 중" : !monitor.running ? "소리를 확인해요" : monitor.air ? "공기 주입 소리" : "공기음 미감지" }
    private var detail: String { !monitor.running ? "시작을 누르고 스티밍해 보세요." : monitor.suppressed ? "상단 대역 감소를 감지했어요." : monitor.air ? "현재 소리의 특징을 표시하고 있어요." : "롤링·종료 여부를 뜻하지 않아요." }
    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:20) {
                HStack {
                    Text("chee-k").font(.system(size:32,weight:.bold)).foregroundStyle(PuffinStyle.blue)
                    Spacer()
                    Text(monitor.previewing ? "화면 시험" : monitor.running ? "● 분석 중" : "입력 대기").font(.caption)
                }
                Text(title).font(.largeTitle.bold()).fixedSize(horizontal:false,vertical:true)
                    .accessibilityAddTraits(.isHeader).accessibilityIdentifier("pulse.status")
                Text(detail).font(.subheadline).fixedSize(horizontal:false,vertical:true)
                HStack(alignment:.center) {
                    Text(String(format:"%02d:%02d",Int(monitor.elapsed)/60,Int(monitor.elapsed)%60))
                        .font(.system(size:44,weight:.bold,design:.rounded)).monospacedDigit()
                    SoundEnvelope(levels:monitor.running ? monitor.levels : [],color:ink).frame(height:48)
                }
                PulseMonitoringPanel(monitor:monitor)
                Text("소리 기반 추정 · 실제 공기량과 우유 온도는 측정하지 않아요.")
                    .font(.caption2).fixedSize(horizontal:false,vertical:true)
            }.padding(24).frame(maxWidth:560).frame(maxWidth:.infinity)
        }.background(background.ignoresSafeArea()).foregroundStyle(ink)
        .safeAreaInset(edge:.bottom) { action.padding(.horizontal,24).padding(.vertical,12).background(.regularMaterial) }
        .preferredColorScheme(.light)
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
            if ProcessInfo.processInfo.arguments.contains("--preview-input") { monitor.preview() }
            #endif
        }
    }
    // 시작/종료 버튼은 화면 상태를 직접 바꾸지 않고 Monitor의 수명주기를 호출합니다.
    private var action: some View {
        Button {
            if monitor.running || monitor.starting {monitor.stop()} else {Task{await monitor.start()}}
        } label: {
            HStack { if monitor.starting {ProgressView()}; Text(monitor.starting ? "취소" : monitor.running ? "연습 종료" : "연습 시작").font(.headline) }
                .frame(maxWidth:.infinity,minHeight:56)
        }.buttonStyle(.plain).foregroundStyle(monitor.running ? PuffinStyle.blue : .white)
            .background(monitor.running ? PuffinStyle.pale : PuffinStyle.blue,in:Capsule())
            .accessibilityIdentifier("pulse.startStop")
    }
}

// 임시 측정 패널: '측정값', '현재 적용된 기준', '전환 차단 상태'를 구분해 보여 줍니다.
// 숫자를 조절하면 PulseMonitor → PulseCapture → PulseDSP 순서로 전달됩니다.
private struct PulseMonitoringPanel: View {
    @Bindable var monitor: PulseMonitor
    private var reading: PulseResult? { monitor.reading }
    private func number(_ value: Double?, unit: String = "dBFS") -> String {
        value.map { String(format:"%.1f",$0)+" "+unit } ?? "—"
    }
    private var settingsApplied: Bool {
        guard let r = reading else{return false}
        return r.appliedHighDB == monitor.thresholds.highDB && r.appliedRatio == monitor.thresholds.ratio && r.appliedFlatness == monitor.thresholds.flatness
    }
    var body: some View {
        VStack(alignment:.leading,spacing:18) {
            Text("입력 모니터링").font(.title2.bold()).accessibilityAddTraits(.isHeader)
            Text(monitor.previewing ? "화면 시험 · 마이크 미사용" : monitor.running ? "현재 측정값 · 약 40ms 간격" : reading == nil ? "측정 대기" : "마지막 측정값 · 입력 중지")
                .font(.caption).foregroundStyle(.secondary)
            Text(monitor.inputDescription).font(.caption).textSelection(.enabled)
            measurement("전체 크기 (RMS)",number(reading?.db))
            Grid(alignment:.leading,horizontalSpacing:12,verticalSpacing:10) {
                GridRow { Text("입력 조건");Text("측정");Text("적용 기준") }.fontWeight(.semibold)
                GridRow { Text("고역 크기");Text(number(reading?.highDB,unit:""));Text(number(reading?.appliedHighDB,unit:"dBFS")) }
                GridRow { Text("고역 비율");Text(number(reading.map{$0.ratio*100},unit:"%"));Text(number(reading.map{$0.appliedRatio*100},unit:"%")) }
                GridRow { Text("광대역성");Text(number(reading.map{$0.flatness*100},unit:"%"));Text(number(reading.map{$0.appliedFlatness*100},unit:"%")) }
            }.font(.caption).monospacedDigit()
            Divider()
            Text("기준값 조절").font(.headline)
            threshold("4–12kHz 에너지",measurement:reading?.highDB,value:$monitor.thresholds.highDB,range:-100...0,step:1,percent:false,applied:reading?.appliedHighDB)
            threshold("고역 비율",measurement:reading.map{$0.ratio*100},value:$monitor.thresholds.ratio,range:0...1,step:0.01,percent:true,applied:reading.map{$0.appliedRatio*100})
            threshold("광대역성 (평탄도)",measurement:reading.map{$0.flatness*100},value:$monitor.thresholds.flatness,range:0...1,step:0.01,percent:true,applied:reading.map{$0.appliedFlatness*100})
            if monitor.running && !monitor.previewing {
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
            measurement("4–8kHz",number(reading?.lowerDB))
            measurement("12–16kHz",number(reading?.upperDB))
            measurement("상단 감소 / 기준 ≥ 10dB",number(reading?.upperDrop,unit:"dB"))
            measurement("대역 대비 감소 / 기준 ≥ 6dB",number(reading?.tiltDrop,unit:"dB"))
            measurement("평활 4–8kHz / 기준 ≥ −55dBFS",number(reading?.smoothedLowerDB))
            Text(reading?.hasReference == true ? "전환 비교 기준 있음" : "전환 비교 기준 없음 · 앞선 후보 소리가 필요해요.").font(.caption)
            measurement("후보 지속 / 진입 120ms",number(reading.map{$0.candidateSeconds*1000},unit:"ms"))
            measurement("조건 미달 지속 / 해제 220ms",number(reading.map{$0.releaseSeconds*1000},unit:"ms"))
            measurement("상단 감소 지속 / 차단 120ms",number(reading.map{$0.transitionSeconds*1000},unit:"ms"))
            Text("세 가지 입력 조건을 모두 만족해야 합니다. 세 조건이 통과해도 추가 해제 조건이 적용 중이면 표시되지 않습니다. 위 해제·복귀 규칙과 시간 조건은 변경하지 않았습니다.")
                .font(.caption).foregroundStyle(.secondary)
        }.padding(18).background(PuffinStyle.pale,in:RoundedRectangle(cornerRadius:20))
    }
    private func measurement(_ name: String,_ value: String) -> some View {
        LabeledContent(name) { Text(value).monospacedDigit().foregroundStyle(PuffinStyle.ink) }.font(.caption)
    }
    // 세 기준값에 공통으로 쓰는 조절 UI. 사용자가 만지는 값과 DSP에 적용된 값을 함께 표시합니다.
    private func threshold(_ title: String,measurement: Double?,value: Binding<Double>,range: ClosedRange<Double>,step: Double,percent: Bool,applied: Double?) -> some View {
        let factor = percent ? 100.0 : 1.0, unit = percent ? "%" : "dBFS"
        return VStack(alignment:.leading,spacing:8) {
            Text(title).font(.headline)
            self.measurement("측정값",number(measurement,unit:unit))
            self.measurement("적용된 기준값",number(applied,unit:unit))
            if let measurement,let applied {
                Text(measurement >= applied ? "✓ 입력 조건 통과" : "× 기준 미달")
                    .font(.caption.weight(.semibold)).foregroundStyle(measurement >= applied ? PuffinStyle.greenInk : Color(red:0.6,green:0.2,blue:0.1))
            }
            Stepper(value:value,in:range,step:step) {
                Text("조절: "+number(value.wrappedValue*factor,unit:unit)).font(.subheadline).monospacedDigit()
            }.accessibilityLabel(title+" 기준값")
            Slider(value:value,in:range,step:step).tint(PuffinStyle.blue).accessibilityLabel(title+" 기준값 슬라이더")
        }
    }
}
