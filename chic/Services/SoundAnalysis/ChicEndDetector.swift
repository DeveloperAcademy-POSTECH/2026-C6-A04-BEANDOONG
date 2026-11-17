import CoreML
import Foundation

/// 같은 원음의 10프레임 묶음마다 작업·종료·청소 점수를 계산합니다.
nonisolated final class ChicEndDetector {
    struct Scores {
        let other, work, end, purge, rmsDBFS, dropDB: Double
    }
    private let extractor, classifier: MLModel
    private let classificationInput: MLMultiArray
    private let classificationProvider: MLDictionaryFeatureProvider
    // 학습 때와 동일한 리샘플링을 유지하는 고정 FIR 계수입니다.
    private static let resamplingCoefficients: [Double] = [
        -1.0409432268003816e-18, -0.0007854868784156074, -0.0008877975100279239,
        1.333890706987186e-18, 0.0012715969903686053, 0.0015638250611718185,
        -2.184057407101802e-18, -0.00237821843177987, -0.0029135164757142285,
        3.508223087077304e-18, 0.0042786798273629625, 0.005127168104170554,
        -5.176769184152897e-18, -0.007215471842062842, -0.008486915105961517,
        7.02636678090257e-18, 0.0115954804943481, 0.013497257484706869,
        -8.875964377652243e-18, -0.018246470421547003, -0.021255377206899826,
        1.0544510474727835e-17, 0.029253750768818067, 0.034775477812188635,
        -1.1868676154703337e-17, -0.051806348417392414, -0.06626646171666845,
        1.2718842854817952e-17, 0.13663451916773778, 0.27534824914220496,
        0.3337921183067828, 0.27534824914220496, 0.13663451916773778,
        1.2718842854817952e-17, -0.06626646171666845, -0.051806348417392414,
        -1.1868676154703337e-17, 0.03477547781218864, 0.02925375076881807,
        1.0544510474727835e-17, -0.02125537720689983, -0.018246470421547006,
        -8.875964377652243e-18, 0.013497257484706874, 0.011595480494348104,
        7.02636678090257e-18, -0.00848691510596152, -0.007215471842062848,
        -5.176769184152897e-18, 0.0051271681041705555, 0.004278679827362968,
        3.508223087077304e-18, -0.0029135164757142307, -0.0023782184317798732,
        -2.184057407101802e-18, 0.0015638250611718192, 0.0012715969903686058,
        1.333890706987186e-18, -0.0008877975100279239, -0.0007854868784156074,
        -1.0409432268003816e-18,
    ]
    private let audioInput: MLMultiArray
    private let provider: MLDictionaryFeatureProvider
    private var filterHistory = [Double](repeating: 0, count: 61)
    private var filterCursor = 0
    private var samplesReceived = 0
    private var energyHistory: [Double] = []
    private var samples48: [Float] = []
    private var sampleBase48 = 0
    private var samples16: [Float] = []
    private var sampleBase16 = 0
    private var rawFrameCount = 0
    private var powerSum = [Float](repeating: 0, count: 1023)
    private var embeddings: [[Float]] = []
    private var bandHistory: [[Double]] = []
    private let bands: [Int]
    private let powerScale: Double

    /// 플랫폼 소리 특징 모델과 종료 분류 모델을 불러옵니다.
    convenience init(bundle: Bundle = .main) throws {
        guard let model = bundle.url(forResource: "ChicAudioFeatures", withExtension: "mlmodelc"),
              let classifier = bundle.url(forResource: "ChicEndV3_5", withExtension: "mlmodelc") else {
            throw ChicModelV3_5.Failure.resource("ChicEndV3_5")
        }
        try self.init(modelURL: model, classifierURL: classifier)
    }

    /// 오프라인 재생도 앱과 동일한 특징 추출기와 분류 모델을 사용합니다.
    init(modelURL: URL, classifierURL: URL) throws {
        let config = MLModelConfiguration()
        config.computeUnits = .all
        extractor = try MLModel(contentsOf: modelURL, configuration: config)
        guard extractor.modelDescription.inputDescriptionsByName["audioSamples"]?.type == .multiArray,
              extractor.modelDescription.outputDescriptionsByName["features"]?.type == .multiArray else {
            throw ChicModelV3_5.Failure.schema
        }
        let classifierConfig = MLModelConfiguration()
        classifierConfig.computeUnits = .cpuOnly
        classifier = try MLModel(contentsOf: classifierURL, configuration: classifierConfig)
        let description = classifier.modelDescription
        guard let metadata = description.metadata[.creatorDefinedKey] as? [String: String],
              metadata["classOrder"] == "other,work,end,purge",
              let input = description.inputDescriptionsByName["features"]?.multiArrayConstraint,
              input.shape == [1845], input.dataType == .double,
              let output = description.outputDescriptionsByName["probabilities"]?.multiArrayConstraint,
              output.shape == [4], output.dataType == .double,
              let activity = description.outputDescriptionsByName["activityProbabilities"]?.multiArrayConstraint,
              activity.shape == [4], activity.dataType == .double else { throw ChicModelV3_5.Failure.schema }
        classificationInput = try MLMultiArray(shape: [1845], dataType: .double)
        classificationProvider = try MLDictionaryFeatureProvider(dictionary: ["features": classificationInput])
        audioInput = try MLMultiArray(shape: [8000], dataType: .float32)
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
        samples48 += mono
        for value in mono {
            filterHistory[filterCursor] = Double(value)
            if samplesReceived % 3 == 0 {
                var sample = 0.0
                for j in 0..<61 {
                    sample += Self.resamplingCoefficients[j] * filterHistory[(filterCursor - j + 61) % 61]
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
        let end48 = 2048 + (rawFrameCount - 1) * 512
        let start48 = max(0, end48 - 5120)
        guard start48 >= sampleBase48, end48 <= sampleBase48 + samples48.count else { throw ChicModelV3_5.Failure.alignment }
        let energy = samples48[(start48 - sampleBase48)..<(end48 - sampleBase48)].reduce(0.0) { $0 + Double($1) * Double($1) } / Double(end48 - start48)
        let rmsDBFS = 10 * log10(max(energy, 1e-16))
        let referenceEnergy = energyHistory.isEmpty ? energy : energyHistory.reduce(0, +) / Double(energyHistory.count)
        let dropDB = 10 * log10(max(referenceEnergy, 1e-16)) - rmsDBFS
        energyHistory.append(energy)
        if energyHistory.count > 10 { energyHistory.removeFirst() }
        let discard48 = max(0, end48 - 5120 - sampleBase48)
        samples48.removeFirst(discard48)
        sampleBase48 += discard48
        let end16 = end48 / 3
        guard end16 <= sampleBase16 + samples16.count else { throw ChicModelV3_5.Failure.alignment }
        let input = audioInput.dataPointer.assumingMemoryBound(to: Float.self)
        for i in 0..<8000 {
            let index = end16 - 8000 + i
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
        let values = classificationInput.dataPointer.assumingMemoryBound(to: Double.self)
        for i in features.indices { values[i] = features[i] }
        let prediction = try classifier.prediction(from: classificationProvider)
        guard let probabilities = prediction.featureValue(for: "probabilities")?.multiArrayValue,
              probabilities.count == 4,
              let activity = prediction.featureValue(for: "activityProbabilities")?.multiArrayValue,
              activity.count == 4 else { throw ChicModelV3_5.Failure.schema }
        let p = (0..<4).map { probabilities[$0].doubleValue }
        let a = (0..<4).map { activity[$0].doubleValue }
        guard p.allSatisfy({ $0.isFinite && (0...1).contains($0) }),
              a.allSatisfy({ $0.isFinite && (0...1).contains($0) }),
              abs(p.reduce(0, +) - 1) < 1e-5,
              abs(a.reduce(0, +) - 1) < 1e-5 else { throw ChicModelV3_5.Failure.schema }
        embeddings.append(embedding)
        if embeddings.count > 15 { embeddings.removeFirst() }
        bandHistory.append(current)
        if bandHistory.count > 30 { bandHistory.removeFirst() }
        let discard = max(0, end16 - 8000 - sampleBase16)
        samples16.removeFirst(discard)
        sampleBase16 += discard
        // 종료음 재학습이 기존 작업 점수의 소멸 기준까지 바꾸지 않도록 작업 출력을 보존합니다.
        return Scores(other: a[0], work: a[1], end: p[2], purge: p[3], rmsDBFS: rmsDBFS, dropDB: dropDB)
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
