// 마이크의 시작·종료, DSP 실행, 화면 상태 갱신, 기기별 진동을 연결합니다.
// iPhone과 Watch는 이 파일을 각자 실행하며 서로 분석 결과를 주고받지 않습니다.
import AVFoundation // AVAudioSession/AVAudioEngine로 마이크 입력을 관리합니다.
import Observation // @Observable 상태를 SwiftUI 화면에 자동 반영합니다.
#if os(watchOS)
import WatchKit // Watch 고유 햅틱을 호출합니다.
#else
import UIKit // iPhone 햅틱과 화면 자동 잠금 설정을 사용합니다.
#endif

#if os(iOS)
// iPhone 진단 화면에서 조절하는 세 기준값입니다. 이 기기의 UserDefaults에만 저장됩니다.
struct PulseThresholds: Equatable, Sendable {
    // 기본 기준은 DSP 기본값과 같게 시작합니다.
    var highDB = -48.0
    var ratio = 0.12
    var flatness = 0.12
    // 저장값이 없거나 범위를 벗어나면 안전하게 기본값을 사용합니다.
    static func load() -> Self {
        let defaults = Self()
        func read(_ key: String, fallback: Double, range: ClosedRange<Double>) -> Double {
            // 잘못 저장된 값이나 무한대가 판정을 망치지 않게 걸러냅니다.
            guard let value = UserDefaults.standard.object(forKey: "pulse.threshold."+key) as? Double,
                  value.isFinite, range.contains(value) else { return fallback }
            return value
        }
        // 세 기준을 각각 허용 범위 안에서 복원합니다.
        return Self(highDB: read("highDB",fallback:defaults.highDB,range:-100...0),
                    ratio:read("ratio",fallback:defaults.ratio,range:0...1),flatness:read("flatness",fallback:defaults.flatness,range:0...1))
    }
    // 사용자가 다시 앱을 열어도 iPhone 기준값을 유지하도록 저장합니다.
    func save() {
        UserDefaults.standard.set(highDB,forKey:"pulse.threshold.highDB")
        UserDefaults.standard.set(ratio,forKey:"pulse.threshold.ratio")
        UserDefaults.standard.set(flatness,forKey:"pulse.threshold.flatness")
    }
}
#endif

// 오디오 분석은 직렬 큐에서 처리하고 결과 값만 화면으로 전달한다.
// 오디오 콜백에서는 샘플을 복사해 큐로 넘겨 화면 갱신·FFT가 입력을 막지 않게 합니다.
// @unchecked Sendable은 동시성 안전성을 컴파일러 대신 직접 책임진다는 뜻입니다.
// DSP 변경·분석은 queue에 모으지만, 시작/종료는 별도로 호출되므로 변경 시 주의해야 합니다.
private final class PulseCapture: @unchecked Sendable {
    // AVAudioEngine이 마이크의 PCM 샘플을 공급합니다.
    private let engine = AVAudioEngine()
    // DSP 상태를 한 큐에서만 바꿔 동시 접근으로 인한 오류를 막습니다.
    private let queue = DispatchQueue(label: "puffin.dsp", qos: .userInitiated)
    // 캡처 한 번마다 독립된 판정기를 사용해 이전 연습의 상태가 섞이지 않게 합니다.
    private let dsp = PulseDSP()
    // 화면 갱신을 줄이면서 그 사이 발생한 pulse를 잃지 않기 위한 값입니다.
    private var lastDisplay = 0.0, pendingPulse = false
    // 탭이 설치됐을 때만 제거하도록 현재 설치 여부를 기억합니다.
    private var tapInstalled = false
    // 분석 결과와 오류를 Monitor에 돌려주는 콜백입니다.
    private let result: @Sendable (PulseResult) -> Void
    private let failure: @Sendable (String) -> Void
    init(result: @escaping @Sendable (PulseResult) -> Void, failure: @escaping @Sendable (String) -> Void) {
        self.result = result; self.failure = failure
    }
    #if os(iOS)
    // 슬라이더 변경도 분석 큐에서 적용해 consume()과 값 변경이 겹치지 않게 합니다.
    func apply(_ thresholds: PulseThresholds) {
        queue.async { [self] in
            dsp.minimumHighDB = thresholds.highDB
            dsp.minimumRatio = thresholds.ratio
            dsp.minimumFlatness = thresholds.flatness
        }
    }
    #endif
    func start() throws {
        // measurement 모드에서 각 기기의 마이크를 열고 PCM 입력 탭을 설치합니다.
        let session = AVAudioSession.sharedInstance()
        // 녹음 용도로 오디오 세션을 정하고 시스템의 입력 신호 처리를 줄입니다.
        try session.setCategory(.record, mode: .measurement)
        // 녹음 중에도 햅틱·시스템 소리를 허용해 피드백이 막히지 않게 합니다.
        try session.setAllowHapticsAndSystemSoundsDuringRecording(true)
        // 세션을 활성화한 뒤 실제 입력 형식을 읽습니다.
        try session.setActive(true)
        let input = engine.inputNode, format = input.outputFormat(forBus: 0)
        // 너무 낮은 샘플레이트에는 현재 12–16kHz 비교 대역이 존재하지 않습니다.
        guard format.sampleRate >= 32000, format.channelCount > 0 else { throw NSError(domain:"Puffin",code:1,userInfo:[NSLocalizedDescriptionKey:"32kHz 이상의 마이크 입력이 필요합니다. 블루투스 입력을 해제하고 다시 시도해 주세요."]) }
        // 탭은 들어오는 PCM 조각을 받습니다. bufferSize는 요청값이며 실제 길이를 사용합니다.
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            // Float32 채널 자료가 없으면 해석할 수 없으므로 이 조각을 건너뜁니다.
            guard let self, let channels = buffer.floatChannelData else { return }
            // 매 버퍼의 실제 길이와 샘플레이트를 DSP에 전달합니다.
            let count = Int(buffer.frameLength), rate = buffer.format.sampleRate
            // 여러 마이크 채널이 들어와도 평균하여 한 채널로 분석합니다.
            var values = [Float](repeating:0,count:count)
            for channel in 0..<Int(buffer.format.channelCount) { for i in 0..<count { values[i] += channels[channel][i]/Float(buffer.format.channelCount) } }
            // 실시간 오디오 콜백 밖의 직렬 큐에서 FFT와 판정을 수행합니다.
            self.queue.async { [self, values] in
                do {
                    // 한 버퍼에서 0개 이상의 분석 결과가 나올 수 있습니다.
                    for var r in try self.dsp.consume(values,sampleRate:rate) {
                        // 화면은 약 40ms 간격으로 갱신하되, 그 사이의 진동 요청은 보존합니다.
                        self.pendingPulse = self.pendingPulse || r.pulse
                        // 화면 갱신 시각이 됐거나 진동이 발생하면 즉시 Monitor에 전달합니다.
                        if r.time-self.lastDisplay >= 0.04 || r.pulse {
                            r.pulse = self.pendingPulse; self.pendingPulse = false; self.lastDisplay = r.time; self.result(r)
                        }
                    }
                // DSP 입력 오류를 화면에 알릴 수 있도록 콜백으로 전달합니다.
                } catch { self.failure(error.localizedDescription) }
            }
        }
        // 설치된 탭을 stop()에서 안전하게 해제하기 위한 표식입니다.
        tapInstalled = true
        // 미리 준비한 뒤 실제 마이크 입력 스트림을 시작합니다.
        engine.prepare(); try engine.start()
    }
    // 탭을 먼저 제거하고 이미 큐에 들어온 분석 작업이 끝나기를 기다립니다.
    func stop() { if tapInstalled { engine.inputNode.removeTap(onBus:0); tapInstalled = false }; engine.stop(); queue.sync {} }
}

// SwiftUI가 관찰하는 상태의 주인입니다. 화면에 필요한 값만 MainActor에서 바꿉니다.
// @Observable은 값 변경을 화면에 전달하고, @MainActor는 UI 상태 변경 위치를 제한합니다.
@MainActor @Observable final class PulseMonitor {
    // previewing은 가짜 화면 시험, running은 실제/시험 실행, starting은 권한·마이크 연결 중입니다.
    private(set) var previewing = false
    private(set) var running = false
    private(set) var starting = false
    // 화면 색·문구를 정하는 두 판정 상태입니다.
    private(set) var air = false
    private(set) var suppressed = false
    // 시간과 음량은 화면에 보여 줄 최신 분석 결과입니다.
    private(set) var elapsed = 0.0
    private(set) var db = -160.0
    private(set) var highDB = -160.0
    // 최근 고역 크기만 보관해 짧은 그래프를 그립니다. 원음은 저장하지 않습니다.
    private(set) var levels: [Float] = []
    // 권한·입력 문제를 사용자에게 알리는 문구입니다.
    var error: String?
    // 마이크를 소유하는 객체를 보관해야 분석 중에 해제되지 않습니다.
    private var capture: PulseCapture?
    // 비동기 권한 응답이나 이전 분석 결과가 새 연습 세션을 덮어쓰지 못하게 하는 표식입니다.
    private var generation = UUID()
    // 입력 부재 감시와 Debug 화면 시험을 중지할 때 취소하기 위한 작업 핸들입니다.
    private var watchdog: Task<Void,Never>?
    private var previewTask: Task<Void,Never>?
    // 오디오 변경 알림 등록 토큰은 종료 시 제거해야 중복 호출·누수를 막습니다.
    // @ObservationIgnored는 화면에 표시하지 않는 관리용 값임을 뜻합니다.
    // nonisolated(unsafe)는 이 토큰의 동시성 검사를 완화하므로 접근 방식을 바꿀 때 주의합니다.
    @ObservationIgnored nonisolated(unsafe) private var observers: [NSObjectProtocol] = []
    #if os(iOS)
    // 연습 중 화면 잠금을 껐다가 끝날 때 원래 설정으로 되돌리기 위한 값입니다.
    private var previousIdle: Bool?
    // iPhone 전용 사용자 기준과 진단 패널의 상세 결과입니다.
    var thresholds = PulseThresholds.load()
    private(set) var reading: PulseResult?
    private(set) var inputDescription = "입력 대기"
    func applyThresholds() {
        // 화면의 값을 저장한 뒤, 실행 중이면 다음 분석 입력부터 반영합니다.
        thresholds.save(); capture?.apply(thresholds)
    }

    #endif
    init() {
        // 통화 등으로 녹음이 중단되거나 입력 장치가 바뀌면 이전 분석을 종료합니다.
        for name in [AVAudioSession.interruptionNotification,AVAudioSession.routeChangeNotification,AVAudioSession.mediaServicesWereResetNotification] {
            // 시스템 알림은 들어온 기기가 바뀌거나 오디오 서비스가 리셋될 때도 발생합니다.
            observers.append(NotificationCenter.default.addObserver(forName:name,object:nil,queue:.main) { [weak self] note in
                if name == AVAudioSession.routeChangeNotification {
                    // 연결과 무관한 경로 변경 알림에는 연습을 멈추지 않습니다.
                    let reason = note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt
                    guard reason == AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue || reason == AVAudioSession.RouteChangeReason.newDeviceAvailable.rawValue else { return }
                }
                // 인터럽트가 '시작'된 경우만 중단하고 '끝' 알림은 무시합니다.
                if name == AVAudioSession.interruptionNotification, (note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt) != AVAudioSession.InterruptionType.began.rawValue { return }
                // 화면 상태는 MainActor에서만 바꾸고 사용자에게 재시작 이유를 알립니다.
                Task { @MainActor in guard let self,self.running else{return}; self.stop(); self.error = "오디오 연결이 바뀌었어요. 입력을 확인하고 다시 시작해 주세요." }
            })
        }
    }
    deinit { observers.forEach(NotificationCenter.default.removeObserver) }
    func start() async {
        // 권한 확인 → 새 캡처 생성 → 기준값 적용 → 마이크 시작 → 입력 확인 순서입니다.
        guard !running && !starting else{return}
        // 이전 세션을 정리하면서 generation을 새로 만들고 연결 중 상태를 표시합니다.
        stop(); error = nil; starting = true; let token = generation
        // 비동기 권한 응답을 기다립니다. 이미 허용했다면 곧바로 결과가 돌아옵니다.
        // withCheckedContinuation은 콜백 기반 권한 API를 await로 다루기 위한 연결입니다.
        let allowed = await withCheckedContinuation { continuation in AVAudioApplication.requestRecordPermission { continuation.resume(returning:$0) } }
        // 권한 창을 보는 동안 사용자가 취소했다면 오래된 응답을 버립니다.
        guard token == generation else{return}
        // 권한 거부는 분석을 시작하지 않고 설정 안내를 보여 줍니다.
        guard allowed else{starting = false; error = "마이크 권한이 필요합니다. 기기 설정에서 chee-k의 마이크 접근을 허용해 주세요.";return}
        // 새 연습의 시간·그래프·상태를 초기화합니다.
        elapsed = 0; levels = []; air = false; suppressed = false
        #if os(iOS)
        reading = nil
        #endif
        do {
            // 캡처의 백그라운드 콜백을 MainActor로 보내 화면 상태와 연결합니다.
            // token 비교로 이전 세션에서 늦게 온 결과/오류를 버립니다.
            // weak self는 Monitor가 사라진 뒤 콜백이 객체를 계속 붙잡지 않게 합니다.
            let input = PulseCapture(result: { [weak self] r in Task { @MainActor in
                guard let self,self.generation == token else{return}; self.accept(r)
            } },failure: { [weak self] message in Task { @MainActor in
                guard let self,self.generation == token else{return};self.stop();self.error = message
            } })
            #if os(iOS)
            // 저장된 iPhone 기준값을 실제 분석기에 먼저 적용합니다.
            input.apply(thresholds)
            #endif
            // 캡처를 보관하고 시작에 성공한 뒤에만 running을 켭니다.
            capture = input; try input.start(); starting = false; running = true
            #if os(iOS)
            // 실제 선택된 입력 장치·샘플레이트·모드를 진단 화면에 표시합니다.
            let audio = AVAudioSession.sharedInstance()
            inputDescription = "\(audio.currentRoute.inputs.map(\.portName).joined(separator: ", ")) · \(Int(audio.sampleRate)) Hz · \(audio.mode.rawValue)"
            // 연습 중에는 화면이 자동으로 잠기지 않도록 하되 이전 값을 기억합니다.
            previousIdle = UIApplication.shared.isIdleTimerDisabled; UIApplication.shared.isIdleTimerDisabled = true
            #endif
            // 4초 동안 분석 결과가 없으면 연결만 된 상태로 방치하지 않고 오류를 보여 줍니다.
            watchdog = Task { [weak self] in
                try? await Task.sleep(for:.seconds(4)); guard !Task.isCancelled,let self,self.generation == token,self.levels.isEmpty else{return}
                self.stop(); self.error = "마이크 데이터가 들어오지 않아요. 입력을 확인해 주세요."
            }
        } catch { stop(); self.error = error.localizedDescription }
    }
    // DSP 결과 하나를 화면 수치·최근 고역 이력·햅틱 동작으로 변환합니다.
    private func accept(_ r: PulseResult) {
        #if os(iOS)
        // iPhone 진단 패널은 최신 PulseResult 전체를 보여 줍니다.
        reading = r
        #endif
        // 화면이 자주 읽는 핵심 수치와 판정 상태만 별도 속성으로 옮깁니다.
        elapsed = r.time; db = r.db; highDB = r.highDB; air = r.active; suppressed = r.suppressed
        // 고역 dBFS를 0~1 화면 높이로 바꾸고, 화면에 필요한 최근 31개만 유지합니다.
        levels.append(Float(max(0,min(1,(r.highDB+70)/45))))
        if levels.count > 31 { levels.removeFirst(levels.count-31) }
        if r.pulse {
            // 워치는 자체 햅틱, iPhone은 가벼운 터치 피드백을 사용합니다.
            #if os(watchOS)
            WKInterfaceDevice.current().play(.click)
            #else
            UIImpactFeedbackGenerator(style:.light).impactOccurred()
            #endif
        }
    }
    // 화면을 닫거나 앱이 백그라운드로 갈 때도 같은 정리 경로를 사용합니다.
    func stop() {
        // 기다리는 작업과 이전 세션 콜백을 모두 무효화합니다.
        previewing = false; generation = UUID(); watchdog?.cancel();watchdog = nil;previewTask?.cancel();previewTask = nil
        // 오디오 탭·엔진을 닫고 화면의 실행/감지 상태를 초기화합니다.
        capture?.stop();capture = nil;running = false;starting = false;air = false;suppressed = false
        #if os(iOS)
        if let previousIdle { UIApplication.shared.isIdleTimerDisabled = previousIdle; self.previousIdle = nil }
        #endif
        // 다른 앱이 오디오를 다시 사용할 수 있도록 녹음 세션을 비활성화합니다.
        try? AVAudioSession.sharedInstance().setActive(false,options:.notifyOthersOnDeactivation)
    }
    #if DEBUG
    // 마이크 입력과 정확도 검사에 사용하지 않는 화면 확인용 가짜 데이터입니다.
    func preview() {
        // 실제 캡처를 중지한 뒤 화면만 동작하도록 시험 상태를 켭니다.
        stop();running = true;previewing = true
        previewTask = Task { [weak self] in
            var time = 0.0
            while !Task.isCancelled {
                // 50ms마다 변하는 가짜 고역 값과 4초 주기 감지 상태를 만듭니다.
                guard let self else{return};time += 0.05
                var r = PulseResult(time:time,db:-30,highDB:-55+18*pow(sin(time*17),2),ratio:0.5,flatness:0.3,lowerDB:-34,upperDB:-30)
                r.active = Int(time/4)%2 == 0;r.suppressed = !r.active
                // 실제 결과와 같은 화면 갱신 경로를 사용하되 감지 정확도를 검증하지는 않습니다.
                self.accept(r);try? await Task.sleep(for:.milliseconds(50))
            }
        }
    }
    #endif
}
