import CoreML
import Foundation

/// 한 번의 연습에서 유지하며 직렬 분석 큐에서 두 단계 모델을 실행합니다.
nonisolated final class ChicModelV2 {
    enum State: String { case air, sputter, metallic, other }
    struct Frame {
        let state: State
        let gateLabel: String
        let sputterScore: Double?
    }
    enum Failure: LocalizedError {
        case resource(String), schema, input, alignment

        var errorDescription: String? {
            switch self {
            case .resource: "스티밍 분석 모델을 찾을 수 없어요."
            case .schema: "스티밍 분석 모델의 입력 또는 출력이 올바르지 않아요."
            case .input: "마이크 입력 형식이 올바르지 않아요."
            case .alignment: "소리 분석 프레임을 맞출 수 없어요."
            }
        }
    }
    static let sputterThreshold = 0.7543236034777003
    private static let columns = (0..<273).map { String(format: "f%03d", $0) }
    private let gate, air, rolling: Classifier
    private let rawExtractor: ChicV2FeatureExtractor
    private let boostedExtractor: ChicV2FeatureExtractor
    private let filter = ChicV2Filter()

    private struct Classifier {
        let model: MLModel
        let output: String
        let labels: [String]
        /// 모델 입력 열과 확률 출력이 예상한 형태인지 확인합니다.
        init(url: URL, labels: [String]) throws {
            let config = MLModelConfiguration()
            config.computeUnits = .cpuOnly
            model = try MLModel(contentsOf: url, configuration: config)
            let description = model.modelDescription
            guard let name = description.predictedProbabilitiesName,
                  Set(description.inputDescriptionsByName.keys) == Set(columns),
                  description.inputDescriptionsByName.values.allSatisfy({ $0.type == .double }) else { throw Failure.schema }
            output = name
            self.labels = labels
        }
        /// 특징 273개를 추론해 지정한 라벨 순서로 확률을 반환합니다.
        func scores(_ x: [Double]) throws -> [Double] {
            guard x.count == columns.count, x.allSatisfy(\.isFinite) else { throw Failure.input }
            let input = try MLDictionaryFeatureProvider(dictionary: Dictionary(uniqueKeysWithValues: zip(columns, x)))
            let result = try model.prediction(from: input)
            guard let values = result.featureValue(for: output)?.dictionaryValue, values.count == labels.count else { throw Failure.schema }
            return try labels.map { key in
                guard let p = values[key]?.doubleValue, (0...1).contains(p) else { throw Failure.schema }
                return p
            }
        }
        /// 가장 높은 확률의 라벨을 반환합니다.
        func winner(_ x: [Double]) throws -> String {
            let p = try scores(x)
            var best = 0
            for i in p.indices.dropFirst() where p[i] > p[best] { best = i }
            return labels[best]
        }
    }
    /// 앱 번들에 컴파일된 세 모델을 불러옵니다.
    convenience init(bundle: Bundle = .main) throws {
        func url(_ name: String) throws -> URL {
            guard let u = bundle.url(forResource: name, withExtension: "mlmodelc") else { throw Failure.resource(name) }
            return u
        }
        try self.init(gateURL: url("ChicModelV2Gate"), airURL: url("ChicModelV2Air"), rollingURL: url("ChicModelV2Metallic"))
    }
    /// 테스트 또는 앱 번들에서 받은 세 모델로 연습별 분석 상태를 만듭니다.
    init(gateURL: URL, airURL: URL, rollingURL: URL) throws {
        gate = try Classifier(url: gateURL, labels: ["air","metallic","sputter","other","breath_whistle"])
        air = try Classifier(url: airURL, labels: ["air","sputter"])
        rolling = try Classifier(url: rollingURL, labels: ["air","metallic","sputter","other"])
        rawExtractor = try ChicV2FeatureExtractor()
        boostedExtractor = try ChicV2FeatureExtractor()
    }

    /// 같은 버퍼의 강조음과 원음으로 두 단계 판정을 완료합니다.
    func consume(_ mono: [Float], sampleRate: Double, onFrame: (Frame) throws -> Void) throws {
        guard sampleRate == 48_000, mono.allSatisfy(\.isFinite) else { throw Failure.input }
        var gates = [String]()
        try boostedExtractor.consume(filter.process(mono), sampleRate: sampleRate) { gates.append(try gate.winner($0)) }
        var i = 0
        try rawExtractor.consume(mono, sampleRate: sampleRate) { x in
            guard i < gates.count else { throw Failure.alignment }
            let label = gates[i]
            i += 1
            let state: State
            var score: Double?
            switch label {
            case "air", "sputter":
                let p = try air.scores(x)[1]
                score = p
                state = p >= Self.sputterThreshold ? .sputter : .air
            case "breath_whistle": state = .other
            case "metallic", "other": state = try rolling.winner(x) == "metallic" ? .metallic : .other
            default: throw Failure.schema
            }
            try onFrame(Frame(state: state, gateLabel: label, sputterScore: score))
        }
        guard i == gates.count else { throw Failure.alignment }
    }
}
