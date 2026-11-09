import AVFAudio
import Foundation
import OSLog

/// 마이크 PCM 분석을 별도 큐에서 실행하고 결과만 연습 관리자에게 전달합니다.
// 엔진 시작·종료는 메인 액터에서, 특징·모델·종료 플래그 접근은 분석 큐에서 직렬화합니다.
nonisolated final class SteamingAudioAnalyzer: @unchecked Sendable {
    private let logger = Logger(subsystem: "com.beandoong.cheek", category: "SteamingEnd")
    private let engine = AVAudioEngine()
    private let queue = DispatchQueue(label: "com.beandoong.cheek.sound-analysis")
    private let pendingBuffer = DispatchSemaphore(value: 8)
    private let input48k = ChicV2Input48k()
    private var displayFilter = ChicDisplayFilter()
    private let classifier: ChicModelV3_5
    private let endDetector: ChicEndDetector
    private var endRule = ChicEndRule()
    private var isStopped = false
    private var hasTap = false

    @MainActor
    init() throws {
        classifier = try ChicModelV3_5()
        endDetector = try ChicEndDetector()
    }

    /// 오디오 세션은 연습 관리자가 활성화한 뒤 호출합니다.
    @MainActor
    func start(onResult: @escaping @Sendable (PracticePhase) -> Void,
               onFinish: @escaping @Sendable () -> Void,
               onError: @escaping @Sendable (String) -> Void) throws {
        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        guard format.channelCount > 0, format.commonFormat == .pcmFormatFloat32,
              !format.isInterleaved, (32000...192000).contains(format.sampleRate) else {
            throw NSError(domain: "SteamingAnalysis", code: 5,
                          userInfo: [NSLocalizedDescriptionKey: "소리를 분석할 수 있는 마이크 입력이 없어요."])
        }
        try input.installAudioTap(onBus: 0, bufferSize: AVAudioFrameCount(format.sampleRate / 10), format: format) { [weak self] buffer, _ in
            guard let self else { return }
            // 분석이 입력을 따라가지 못하면 샘플을 누락시키지 않고 오류로 종료합니다.
            guard self.pendingBuffer.wait(timeout: .now()) == .success else {
                onError("실시간 소리 분석이 지연되어 연습을 종료했어요. 다시 시작해 주세요.")
                return
            }
            let samples: [Float]? = buffer.withUnsafeAudioBufferList { list in
                guard let data = list.pointee.mBuffers.mData else { return nil }
                return Array(UnsafeBufferPointer(start: data.assumingMemoryBound(to: Float.self), count: buffer.frameLength))
            }
            guard let samples else {
                self.pendingBuffer.signal()
                onError("마이크의 오디오 형식을 읽을 수 없어요.")
                return
            }
            let rate = buffer.format.sampleRate
            self.queue.async {
                defer { self.pendingBuffer.signal() }
                guard !self.isStopped else { return }
                do {
                    var phase: PracticePhase?
                    var finished = false
                    let pcm48 = try self.input48k.convert(samples, sampleRate: rate)
                    try self.endDetector.append(pcm48)
                    try self.classifier.consume(pcm48, sampleRate: 48_000) { frame in
                        guard !self.isStopped else { return }
                        let display = self.displayFilter.consume(frame.state)
                        guard let scores = try self.endDetector.consume(spectrum: frame.spectrum) else { return }
                        #if DEBUG
                        self.logger.debug("종료 분석 active=\(self.endRule.isActive) work=\(scores.work) end=\(scores.end) purge=\(scores.purge) dBFS=\(scores.rmsDBFS) dropDB=\(scores.dropDB)")
                        #endif
                        if let reason = self.endRule.consume(work: scores.work, end: scores.end, purge: scores.purge) {
                            self.logger.notice("자동 종료 reason=\(String(describing: reason), privacy: .public) work=\(scores.work) end=\(scores.end) purge=\(scores.purge) dBFS=\(scores.rmsDBFS) dropDB=\(scores.dropDB)")
                            self.isStopped = true
                            finished = true
                            return
                        }
                        if let display {
                            switch display {
                            case .air: phase = .aeration
                            case .sputter: phase = .bubble
                            case .metallic: phase = .moreAir
                            case .other: phase = .milkFlow
                            }
                            // 첫 피드백과 같은 시점에 시작하며, 그 이전 낮은 작업 점수는 세지 않습니다.
                            self.endRule.activate()
                        }
                    }
                    if finished { onFinish() }
                    else if let phase { onResult(phase) }
                } catch {
                    self.isStopped = true
                    onError(error.localizedDescription)
                }
            }
        }
        hasTap = true
        do { try engine.start() }
        catch { stop(); throw error }
    }

    /// 입력을 중지하고 큐에 남은 분석 결과를 폐기합니다.
    @MainActor
    func stop() {
        engine.stop()
        if hasTap { engine.inputNode.removeTap(onBus: 0); hasTap = false }
        queue.sync { isStopped = true }
    }
}
