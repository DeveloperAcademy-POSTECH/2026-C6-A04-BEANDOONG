import AVFoundation
import Observation
#if os(watchOS)
import WatchKit
#else
import UIKit
#endif

#if os(iOS)
struct PulseThresholds: Equatable, Sendable {
    var highDB = -48.0
    var ratio = 0.12
    var flatness = 0.12
    static func load() -> Self {
        let defaults = Self()
        func read(_ key: String, fallback: Double, range: ClosedRange<Double>) -> Double {
            guard let value = UserDefaults.standard.object(forKey: "pulse.threshold."+key) as? Double,
                  value.isFinite, range.contains(value) else { return fallback }
            return value
        }
        return Self(highDB: read("highDB",fallback:defaults.highDB,range:-100...0),
                    ratio:read("ratio",fallback:defaults.ratio,range:0...1),flatness:read("flatness",fallback:defaults.flatness,range:0...1))
    }
    func save() {
        UserDefaults.standard.set(highDB,forKey:"pulse.threshold.highDB")
        UserDefaults.standard.set(ratio,forKey:"pulse.threshold.ratio")
        UserDefaults.standard.set(flatness,forKey:"pulse.threshold.flatness")
    }
}
#endif

// 오디오 분석은 직렬 큐에서 처리하고 결과 값만 화면으로 전달한다.
private final class PulseCapture: @unchecked Sendable {
    private let engine = AVAudioEngine()
    private let queue = DispatchQueue(label: "puffin.dsp", qos: .userInitiated)
    private let dsp = PulseDSP()
    private var lastDisplay = 0.0, pendingPulse = false
    private var tapInstalled = false
    private let result: @Sendable (PulseResult) -> Void
    private let failure: @Sendable (String) -> Void
    init(result: @escaping @Sendable (PulseResult) -> Void, failure: @escaping @Sendable (String) -> Void) {
        self.result = result; self.failure = failure
    }
    #if os(iOS)
    func apply(_ thresholds: PulseThresholds) {
        queue.async { [self] in
            dsp.minimumHighDB = thresholds.highDB
            dsp.minimumRatio = thresholds.ratio
            dsp.minimumFlatness = thresholds.flatness
        }
    }
    #endif
    func start() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement)
        try session.setAllowHapticsAndSystemSoundsDuringRecording(true)
        try session.setActive(true)
        let input = engine.inputNode, format = input.outputFormat(forBus: 0)
        guard format.sampleRate >= 32000, format.channelCount > 0 else { throw NSError(domain:"Puffin",code:1,userInfo:[NSLocalizedDescriptionKey:"32kHz 이상의 마이크 입력이 필요합니다. 블루투스 입력을 해제하고 다시 시도해 주세요."]) }
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            guard let self, let channels = buffer.floatChannelData else { return }
            let count = Int(buffer.frameLength), rate = buffer.format.sampleRate
            var values = [Float](repeating:0,count:count)
            for channel in 0..<Int(buffer.format.channelCount) { for i in 0..<count { values[i] += channels[channel][i]/Float(buffer.format.channelCount) } }
            self.queue.async { [self, values] in
                do {
                    for var r in try self.dsp.consume(values,sampleRate:rate) {
                        self.pendingPulse = self.pendingPulse || r.pulse
                        if r.time-self.lastDisplay >= 0.04 || r.pulse {
                            r.pulse = self.pendingPulse; self.pendingPulse = false; self.lastDisplay = r.time; self.result(r)
                        }
                    }
                } catch { self.failure(error.localizedDescription) }
            }
        }
        tapInstalled = true
        engine.prepare(); try engine.start()
    }
    func stop() { if tapInstalled { engine.inputNode.removeTap(onBus:0); tapInstalled = false }; engine.stop(); queue.sync {} }
}

@MainActor @Observable final class PulseMonitor {
    private(set) var previewing = false
    private(set) var running = false
    private(set) var starting = false
    private(set) var air = false
    private(set) var suppressed = false
    private(set) var elapsed = 0.0
    private(set) var db = -160.0
    private(set) var highDB = -160.0
    private(set) var levels: [Float] = []
    var error: String?
    private var capture: PulseCapture?
    private var generation = UUID()
    private var watchdog: Task<Void,Never>?
    private var previewTask: Task<Void,Never>?
    @ObservationIgnored nonisolated(unsafe) private var observers: [NSObjectProtocol] = []
    #if os(iOS)
    private var previousIdle: Bool?
    var thresholds = PulseThresholds.load()
    private(set) var reading: PulseResult?
    private(set) var inputDescription = "입력 대기"
    func applyThresholds() {
        thresholds.save(); capture?.apply(thresholds)
    }

    #endif
    init() {
        for name in [AVAudioSession.interruptionNotification,AVAudioSession.routeChangeNotification,AVAudioSession.mediaServicesWereResetNotification] {
            observers.append(NotificationCenter.default.addObserver(forName:name,object:nil,queue:.main) { [weak self] note in
                if name == AVAudioSession.routeChangeNotification {
                    let reason = note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt
                    guard reason == AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue || reason == AVAudioSession.RouteChangeReason.newDeviceAvailable.rawValue else { return }
                }
                if name == AVAudioSession.interruptionNotification, (note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt) != AVAudioSession.InterruptionType.began.rawValue { return }
                Task { @MainActor in guard let self,self.running else{return}; self.stop(); self.error = "오디오 연결이 바뀌었어요. 입력을 확인하고 다시 시작해 주세요." }
            })
        }
    }
    deinit { observers.forEach(NotificationCenter.default.removeObserver) }
    func start() async {
        guard !running && !starting else{return}
        stop(); error = nil; starting = true; let token = generation
        let allowed = await withCheckedContinuation { continuation in AVAudioApplication.requestRecordPermission { continuation.resume(returning:$0) } }
        guard token == generation else{return}
        guard allowed else{starting = false; error = "마이크 권한이 필요합니다. 기기 설정에서 chee-k의 마이크 접근을 허용해 주세요.";return}
        elapsed = 0; levels = []; air = false; suppressed = false
        #if os(iOS)
        reading = nil
        #endif
        do {
            let input = PulseCapture(result: { [weak self] r in Task { @MainActor in
                guard let self,self.generation == token else{return}; self.accept(r)
            } },failure: { [weak self] message in Task { @MainActor in
                guard let self,self.generation == token else{return};self.stop();self.error = message
            } })
            #if os(iOS)
            input.apply(thresholds)
            #endif
            capture = input; try input.start(); starting = false; running = true
            #if os(iOS)
            let audio = AVAudioSession.sharedInstance()
            inputDescription = "\(audio.currentRoute.inputs.map(\.portName).joined(separator: ", ")) · \(Int(audio.sampleRate)) Hz · \(audio.mode.rawValue)"
            previousIdle = UIApplication.shared.isIdleTimerDisabled; UIApplication.shared.isIdleTimerDisabled = true
            #endif
            watchdog = Task { [weak self] in
                try? await Task.sleep(for:.seconds(4)); guard !Task.isCancelled,let self,self.generation == token,self.levels.isEmpty else{return}
                self.stop(); self.error = "마이크 데이터가 들어오지 않아요. 입력을 확인해 주세요."
            }
        } catch { stop(); self.error = error.localizedDescription }
    }
    private func accept(_ r: PulseResult) {
        #if os(iOS)
        reading = r
        #endif
        elapsed = r.time; db = r.db; highDB = r.highDB; air = r.active; suppressed = r.suppressed
        levels.append(Float(max(0,min(1,(r.highDB+70)/45))))
        if levels.count > 31 { levels.removeFirst(levels.count-31) }
        if r.pulse {
            #if os(watchOS)
            WKInterfaceDevice.current().play(.click)
            #else
            UIImpactFeedbackGenerator(style:.light).impactOccurred()
            #endif
        }
    }
    func stop() {
        previewing = false; generation = UUID(); watchdog?.cancel();watchdog = nil;previewTask?.cancel();previewTask = nil
        capture?.stop();capture = nil;running = false;starting = false;air = false;suppressed = false
        #if os(iOS)
        if let previousIdle { UIApplication.shared.isIdleTimerDisabled = previousIdle; self.previousIdle = nil }
        #endif
        try? AVAudioSession.sharedInstance().setActive(false,options:.notifyOthersOnDeactivation)
    }
    #if DEBUG
    // 마이크 입력과 정확도 검사에 사용하지 않는 화면 확인용 데이터다.
    func preview() {
        stop();running = true;previewing = true
        previewTask = Task { [weak self] in
            var time = 0.0
            while !Task.isCancelled {
                guard let self else{return};time += 0.05
                var r = PulseResult(time:time,db:-30,highDB:-55+18*pow(sin(time*17),2),ratio:0.5,flatness:0.3,lowerDB:-34,upperDB:-30)
                r.active = Int(time/4)%2 == 0;r.suppressed = !r.active
                self.accept(r);try? await Task.sleep(for:.milliseconds(50))
            }
        }
    }
    #endif
}
