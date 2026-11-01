import AVFAudio
import Foundation

/// 마이크 PCM 분석을 별도 큐에서 실행하고 결과만 연습 관리자에게 전달합니다.
// 엔진 시작·종료는 메인 액터에서, 특징·모델·종료 플래그 접근은 분석 큐에서 직렬화합니다.
nonisolated final class SteamingAudioAnalyzer: @unchecked Sendable {
    private let engine = AVAudioEngine()
    private let queue = DispatchQueue(label: "com.beandoong.cheek.sound-analysis")
    private let pendingBuffer = DispatchSemaphore(value: 8)
    private let extractor: SteamingFeatureExtractor
    private let classifier: SteamingSoundClassifier
    private var isStopped = false
    private var hasTap = false

    @MainActor
    init() throws {
        guard let url = Bundle.main.url(forResource: "CheekModelV1", withExtension: "mlmodelc") else {
            throw NSError(domain: "SteamingAnalysis", code: 4,
                          userInfo: [NSLocalizedDescriptionKey: "스티밍 분석 모델을 찾을 수 없어요."])
        }
        classifier = try SteamingSoundClassifier(modelURL: url)
        extractor = try SteamingFeatureExtractor()
    }

    /// 오디오 세션은 연습 관리자가 활성화한 뒤 호출합니다.
    @MainActor
    func start(onResult: @escaping @Sendable (PracticePhase) -> Void,
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
                    try self.extractor.consume(samples, sampleRate: rate) { features in
                        phase = try self.classifier.predict(features).phase
                    }
                    if let phase { onResult(phase) }
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
