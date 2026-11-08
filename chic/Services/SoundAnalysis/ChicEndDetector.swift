import Accelerate
import CoreML
import Foundation

/// 같은 원음의 10프레임 묶음마다 작업·종료·청소 점수를 계산합니다.
nonisolated final class ChicEndDetector {
    struct Scores {
        let other, work, end, purge: Double
    }
    private struct Weights: Decodable {
        let coefficients: [[Double]]
        let intercept: [Double]
        let classes: [Int]
        let inputDimension: Int
        let resamplingCoefficients: [Double]
    }
    private let extractor: MLModel
    private let weights: Weights
    private let audioInput: MLMultiArray
    private let provider: MLDictionaryFeatureProvider
    private var filterHistory = [Double](repeating: 0, count: 61)
    private var filterCursor = 0
    private var samplesReceived = 0
    private var samples16: [Float] = []
    private var sampleBase16 = 0
    private var rawFrameCount = 0
    private var powerSum = [Float](repeating: 0, count: 1023)
    private var embeddings: [[Float]] = []
    private var bandHistory: [[Double]] = []
    private let bands: [Int]
    private let powerScale: Double

    /// 플랫폼 소리 특징 모델과 재학습된 선형 분류 계수를 불러옵니다.
    convenience init(bundle: Bundle = .main) throws {
        guard let model = bundle.url(forResource: "ChicAudioFeatures", withExtension: "mlmodelc"),
              let weights = bundle.url(forResource: "ChicEndV3_5Weights", withExtension: "json") else {
            throw ChicModelV3_5.Failure.resource("ChicEndV3_5")
        }
        try self.init(modelURL: model, weightsURL: weights)
    }

    /// 오프라인 재생도 앱과 동일한 특징 추출기와 계수를 사용합니다.
    init(modelURL: URL, weightsURL: URL) throws {
        weights = try JSONDecoder().decode(Weights.self, from: Data(contentsOf: weightsURL))
        guard weights.classes == [0, 1, 2, 3], weights.inputDimension == 1845,
              weights.coefficients.count == 4, weights.intercept.count == 4,
              weights.coefficients.allSatisfy({ $0.count == 1845 && $0.allSatisfy(\.isFinite) }),
              weights.intercept.allSatisfy(\.isFinite), weights.resamplingCoefficients.count == 61,
              weights.resamplingCoefficients.allSatisfy(\.isFinite) else { throw ChicModelV3_5.Failure.schema }
        let config = MLModelConfiguration()
        config.computeUnits = .all
        extractor = try MLModel(contentsOf: modelURL, configuration: config)
        guard extractor.modelDescription.inputDescriptionsByName["audioSamples"]?.type == .multiArray,
              extractor.modelDescription.outputDescriptionsByName["features"]?.type == .multiArray else {
            throw ChicModelV3_5.Failure.schema
        }
        audioInput = try MLMultiArray(shape: [15600], dataType: .float32)
        provider = try MLDictionaryFeatureProvider(dictionary: ["audioSamples": audioInput])
        let edges = [0.0] + (0..<49).map { 100 * pow(160, Double($0) / 48) } + [24001]
        bands = (1...1023).map { k in
            let hz = Double(k) * 48000 / 2048
            return (0..<50).first { edges[$0] <= hz && hz < edges[$0 + 1] }!
        }
        let windowEnergy = (0..<2048).reduce(0.0) { sum, i in
            let w = 0.5 - 0.5 * cos(2 * Double.pi * Double(i) / 2047)
            return sum + w * w
        }
        powerScale = 2 / (48000 * windowEnergy)
    }

    /// 학습의 61탭 인과적 FIR과 같은 위상으로 48 kHz 입력을 16 kHz로 줄입니다.
    func append(_ mono: [Float]) throws {
        guard mono.allSatisfy(\.isFinite) else { throw ChicModelV3_5.Failure.input }
        for value in mono {
            filterHistory[filterCursor] = Double(value)
            if samplesReceived % 3 == 0 {
                var sample = 0.0
                for j in 0..<61 {
                    sample += weights.resamplingCoefficients[j] * filterHistory[(filterCursor - j + 61) % 61]
                }
                samples16.append(Float(sample))
            }
            filterCursor = (filterCursor + 1) % 61
            samplesReceived += 1
        }
    }

    /// 작업 분류에서 계산한 스펙트럼을 재사용하여 묶음 끝 시각에 맞춰 추론합니다.
    func consume(spectrum: [Double]) throws -> Scores? {
        guard spectrum.count == 1025, spectrum.allSatisfy({ $0.isFinite && $0 >= 0 }) else {
            throw ChicModelV3_5.Failure.input
        }
        for i in 0..<1023 { powerSum[i] += Float(spectrum[i + 1] * powerScale) }
        rawFrameCount += 1
        guard rawFrameCount % 10 == 0 else { return nil }
        var current = [Double](repeating: 0, count: 50)
        for i in 0..<1023 { current[bands[i]] += Double(powerSum[i] / 10) }
        powerSum = [Float](repeating: 0, count: 1023)
        let end16 = (2048 + (rawFrameCount - 1) * 512) / 3
        guard end16 <= sampleBase16 + samples16.count else { throw ChicModelV3_5.Failure.alignment }
        let input = audioInput.dataPointer.assumingMemoryBound(to: Float.self)
        for i in 0..<15600 {
            let index = end16 - 15600 + i
            if index < 0 { input[i] = 0 }
            else {
                guard index >= sampleBase16 else { throw ChicModelV3_5.Failure.alignment }
                input[i] = samples16[index - sampleBase16]
            }
        }
        let result = try extractor.prediction(from: provider)
        guard let array = result.featureValue(for: "features")?.multiArrayValue, array.count == 512 else {
            throw ChicModelV3_5.Failure.schema
        }
        var embedding = (0..<512).map { array[$0].floatValue }
        let norm = max(sqrt(embedding.reduce(Float(0)) { $0 + $1 * $1 }), 1e-6)
        embedding = embedding.map { $0 / norm }
        var features = embedding.map(Double.init)
        for count in [5, 15] {
            let history = embeddings.suffix(count)
            for i in 0..<512 {
                let mean = history.isEmpty ? Double(embedding[i]) : history.reduce(0.0) { $0 + Double($1[i]) } / Double(history.count)
                features.append(Double(Float(Double(embedding[i]) - mean)))
            }
        }
        features += spectralChanges(current)
        guard features.count == 1845, features.allSatisfy(\.isFinite) else { throw ChicModelV3_5.Failure.input }
        var logits = weights.intercept
        for i in 0..<4 {
            var dot = 0.0
            vDSP_dotprD(features, 1, weights.coefficients[i], 1, &dot, vDSP_Length(features.count))
            logits[i] += dot
        }
        let maximum = logits.max()!
        let values = logits.map { exp($0 - maximum) }
        let total = values.reduce(0, +)
        let p = values.map { $0 / total }
        guard p.allSatisfy({ $0.isFinite && (0...1).contains($0) }) else { throw ChicModelV3_5.Failure.schema }
        embeddings.append(embedding)
        if embeddings.count > 15 { embeddings.removeFirst() }
        bandHistory.append(current)
        if bandHistory.count > 30 { bandHistory.removeFirst() }
        let discard = max(0, end16 - 15600 - sampleBase16)
        samples16.removeFirst(discard)
        sampleBase16 += discard
        return Scores(other: p[0], work: p[1], end: p[2], purge: p[3])
    }

    /// 직전 3·10·30묶음의 주파수 변화와 변동성을 학습 순서대로 계산합니다.
    private func spectralChanges(_ current: [Double]) -> [Double] {
        var features: [Double] = []
        for count in [3, 10, 30] {
            let history = bandHistory.suffix(count)
            var reference = current
            var deviations = [Double](repeating: 0, count: 50)
            if !history.isEmpty {
                for i in 0..<50 {
                    reference[i] = history.reduce(0) { $0 + $1[i] } / Double(history.count)
                    let logs = history.map { 10 * log10(max($0[i], 1e-30)) }
                    let mean = logs.reduce(0, +) / Double(logs.count)
                    deviations[i] = sqrt(max(0, logs.reduce(0) { $0 + $1 * $1 } / Double(logs.count) - mean * mean))
                }
            }
            let delta = zip(current, reference).map { min(60, max(-60, 10 * log10(max($0, 1e-30) / max($1, 1e-30)))) }
            let referenceTotal = max(reference.reduce(0, +), 1e-30)
            let remain = zip(current, reference).reduce(0) { $0 + min($1.0, $1.1) } / referenceTotal
            let added = zip(current, reference).reduce(0) { $0 + max(0, $1.0 - $1.1) } / referenceTotal
            let change = min(60, max(-60, 10 * log10(max(current.reduce(0, +), 1e-30) / referenceTotal)))
            features += (delta + deviations + [min(80, max(0, -10 * log10(max(remain, 1e-8)))), log1p(added), change]).map { Double(Float($0)) }
        }
        return features
    }
}
