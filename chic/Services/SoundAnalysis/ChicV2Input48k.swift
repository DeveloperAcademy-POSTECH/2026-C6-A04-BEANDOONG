import AVFAudio
import Foundation

/// 연습 중 입력 샘플레이트를 48 kHz로 변환하고 버퍼 사이 변환 상태를 유지합니다.
nonisolated final class ChicV2Input48k {
    private var rate: Double?
    private var converter: AVAudioConverter?
    private final class Supply: @unchecked Sendable {
        let samples: [Float]
        let format: AVAudioFormat
        var offset = 0
        var allocationFailed = false
        init(_ samples: [Float], _ format: AVAudioFormat) { self.samples = samples; self.format = format }
        /// 변환기가 요청한 만큼 현재 입력 버퍼의 PCM을 공급합니다.
        func next(_ requested: AVAudioPacketCount, _ status: UnsafeMutablePointer<AVAudioConverterInputStatus>) -> AVAudioBuffer? {
            let n = min(Int(requested), samples.count - offset)
            guard n > 0 else { status.pointee = .noDataNow; return nil }
            guard let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: UInt32(n)), let data = buf.floatChannelData?[0] else {
                allocationFailed = true; status.pointee = .noDataNow; return nil
            }
            buf.frameLength = UInt32(n)
            samples.withUnsafeBufferPointer { data.update(from: $0.baseAddress!.advanced(by: offset), count: n) }
            offset += n
            status.pointee = .haveData
            return buf
        }
    }
    /// 고정된 마이크 입력률을 유지하며 48 kHz PCM으로 변환합니다.
    func convert(_ samples: [Float], sampleRate: Double) throws -> [Float] {
        guard sampleRate.isFinite, (32000...192000).contains(sampleRate),
              rate == nil || rate == sampleRate, samples.allSatisfy(\.isFinite) else { throw ChicModelV3_5.Failure.input }
        rate = sampleRate
        if sampleRate == 48000 || samples.isEmpty { return samples }
        if converter == nil {
            guard let input = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
                  let output = AVAudioFormat(standardFormatWithSampleRate: 48000, channels: 1),
                  let new = AVAudioConverter(from: input, to: output) else { throw ChicModelV3_5.Failure.input }
            new.primeMethod = .none
            converter = new
        }
        guard let c = converter, let dst = AVAudioPCMBuffer(pcmFormat: c.outputFormat, frameCapacity: 1024) else { throw ChicModelV3_5.Failure.input }
        let supply = Supply(samples, c.inputFormat)
        var result = [Float]()
        while true {
            dst.frameLength = 0
            var error: NSError?
            let status = c.convert(to: dst, error: &error) { count, flag in supply.next(count, flag) }
            if let error { throw error }
            guard !supply.allocationFailed, let data = dst.floatChannelData?[0] else { throw ChicModelV3_5.Failure.input }
            result.append(contentsOf: UnsafeBufferPointer(start: data, count: Int(dst.frameLength)))
            if status == .inputRanDry && supply.offset == samples.count { return result }
            guard status == .haveData, dst.frameLength > 0 else { throw ChicModelV3_5.Failure.input }
        }
    }
}
