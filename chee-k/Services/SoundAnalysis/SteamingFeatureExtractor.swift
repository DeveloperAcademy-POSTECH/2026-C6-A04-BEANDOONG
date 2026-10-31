import Accelerate
import Foundation

/// 학습 당시 특징 계산에 필요한 주파수 대역별 측정값입니다.
nonisolated struct SteamingSpectralReading {
    let db, highDB, ratio, flatness, lowerDB, upperDB: Double
}

/// 학습과 동일한 2048 샘플 창·512 샘플 간격으로 특징을 추출합니다.
nonisolated final class SteamingFeatureExtractor {
    private let n = 2048, hop = 512
    private let setup: vDSP_DFT_SetupD
    private let window = (0..<2048).map { 0.5 - 0.5 * cos(2 * Double.pi * Double($0) / 2047) }
    private let spectral = SteamingSpectralFeatures()
    private var pending: [Float] = []
    private var rate = 0.0

    init() throws {
        guard let setup = vDSP_DFT_zop_CreateSetupD(nil, 2048, .FORWARD) else {
            throw NSError(domain: "SteamingAnalysis", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "소리 분석을 준비할 수 없어요."])
        }
        self.setup = setup
    }

    deinit { vDSP_DFT_DestroySetupD(setup) }

    /// 고정 샘플레이트의 모노 PCM을 받아 완성된 프레임마다 특징을 전달합니다.
    func consume(_ input: [Float], sampleRate: Double, onFeatures: ([Double]) throws -> Void) throws {
        guard sampleRate.isFinite, (32000...192000).contains(sampleRate),
              input.allSatisfy(\.isFinite), rate == 0 || rate == sampleRate else {
            throw NSError(domain: "SteamingAnalysis", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "32kHz 이상의 고정된 마이크 입력이 필요해요. 입력 장치를 확인해 주세요."])
        }
        rate = sampleRate
        pending += input
        var cursor = 0
        while pending.count - cursor >= n {
            let frame = pending[cursor..<(cursor + n)].map(Double.init)
            let real = zip(frame, window).map(*)
            let imaginary = [Double](repeating: 0, count: n)
            var re = imaginary, im = imaginary
            vDSP_DFT_ExecuteD(setup, real, imaginary, &re, &im)
            var total = 0.0, high = 0.0, lower = 0.0, upper = 0.0
            var sum = 0.0, logSum = 0.0, count = 0.0
            var power = [Double](repeating: 0, count: n / 2 + 1)
            for k in 1..<(n / 2) {
                let hz = Double(k) * rate / Double(n), p = re[k] * re[k] + im[k] * im[k]
                power[k] = p
                if hz >= 200 && hz < 16000 { total += p }
                if hz >= 4000 && hz < 12000 { high += p }
                if hz >= 4000 && hz < 8000 { lower += p }
                if hz >= 12000 && hz < 16000 { upper += p }
                if hz >= 2000 && hz < 12000 { sum += p; logSum += log(max(p, 1e-30)); count += 1 }
            }
            let normalization = 2 / (Double(n) * window.reduce(0) { $0 + $1 * $1 })
            func db(_ power: Double) -> Double { 10 * log10(max(power * normalization, 1e-16)) }
            let reading = SteamingSpectralReading(
                db: 10 * log10(max(frame.reduce(0) { $0 + $1 * $1 } / Double(n), 1e-16)),
                highDB: db(high), ratio: high / max(total, 1e-30),
                flatness: sum > 1e-25 ? exp(logSum / count) / (sum / count) : 0,
                lowerDB: db(lower), upperDB: db(upper)
            )
            try onFeatures(spectral.consume(frame: frame, power: power, sampleRate: rate, reading: reading))
            cursor += hop
        }
        pending.removeFirst(cursor)
    }
}
