import CoreML
import Foundation

/// 한 번의 연습에서 유지하며 직렬 분석 큐에서 선택된 작업음 모델을 실행합니다.
nonisolated final class ChicModelV3_5 {
    enum State: String { case air, sputter, metallic, other }
    struct Output {
        let labels: [String]
        let values: [Double]

        var winner: Int {
            var best = 0
            for i in values.indices.dropFirst() where values[i] > values[best] { best = i }
            return best
        }
    }

    struct WorkScores {
        let primary: Output
        var secondary: (name: String, output: Output)?
    }

    struct Frame {
        let state: State
        let gateLabel: String
        let sputterScore: Double?
        let scores: WorkScores
        let spectrum: [Double]
        let audioTime: TimeInterval
        let newStartMean: Double?
        let startReason: ChicStartRule.Reason?
    }
    enum Failure: LocalizedError {
        case resource(String), schema, input, alignment

        var errorDescription: String? {
            switch self {
            case .resource: String(localized: "스티밍 분석 모델을 찾을 수 없어요.")
            case .schema: String(localized: "스티밍 분석 모델의 입력 또는 출력이 올바르지 않아요.")
            case .input: String(localized: "마이크 입력 형식이 올바르지 않아요.")
            case .alignment: String(localized: "소리 분석 프레임을 맞출 수 없어요.")
            }
        }
    }
    static let sputterThreshold = 0.5
    static let metallicThreshold = 0.65
    private static let columns = (0..<273).map { String(format: "f%03d", $0) }
    private enum WorkModel {
        case standard(gate: Classifier, air: Classifier, rolling: Classifier)
        #if DEVELOP
        case home(work: Classifier, metal: Classifier, air: Classifier)
        #endif
    }
    private let workModel: WorkModel
    private let startGate: ChicStartGate?
    var startProbability: Double? { startGate?.meanScore }
    var isStarted: Bool { startGate?.isStarted ?? true }
    private var frameCount = 0
    private let rawExtractor: ChicV2FeatureExtractor

    struct Classifier {
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
        /// 판정과 로그에서 같은 추론 결과를 사용합니다.
        func prediction(_ x: [Double]) throws -> Output {
            try Output(labels: labels, values: scores(x))
        }
    }
    /// 이번 연습에서 선택한 시작음 모델과 작업 분류 모델을 불러옵니다.
    convenience init(selection: ChicModelSelection = .standard, bundle: Bundle = .main) throws {
        #if DEVELOP
        if selection == .home {
            let work = try Classifier(url: selection.url(for: "ChicModelV3_5Gate", in: bundle),
                                      labels: ["air", "metallic", "sputter", "other", "non_steam"])
            let metal = try Classifier(url: selection.url(for: "ChicModelV3_5Metallic", in: bundle),
                                       labels: ["metallic", "other"])
            let air = try Classifier(url: selection.url(for: "ChicModelV3_5Air", in: bundle),
                                     labels: ["air", "sputter", "other"])
            try self.init(workModel: .home(work: work, metal: metal, air: air), startURL: selection.url(for: "ChicStartSoundV1", in: bundle), delayStartSound: true)
            return
        }
        #endif
        try self.init(gateURL: selection.url(for: "ChicModelV3_5Gate", in: bundle),
                      airURL: selection.url(for: "ChicModelV3_5Air", in: bundle),
                      rollingURL: selection.url(for: "ChicModelV3_5Metallic", in: bundle),
                      startURL: selection.url(for: "ChicStartSoundV1", in: bundle))
    }
    /// 테스트 또는 앱 번들에서 받은 세 모델로 연습별 분석 상태를 만듭니다.
    convenience init(gateURL: URL, airURL: URL, rollingURL: URL, startURL: URL? = nil) throws {
        let gate = try Classifier(url: gateURL, labels: ["air","metallic","sputter","other","breath_whistle"])
        let air = try Classifier(url: airURL, labels: ["air","sputter","rolling"])
        let rolling = try Classifier(url: rollingURL, labels: ["air","metallic","sputter","other"])
        try self.init(workModel: .standard(gate: gate, air: air, rolling: rolling), startURL: startURL)
    }

    /// 한 연습에서 사용할 작업음 모델과 시작 감지 상태를 준비합니다.
    private init(workModel: WorkModel, startURL: URL?, delayStartSound: Bool = false) throws {
        self.workModel = workModel
        startGate = try startURL.map { try ChicStartGate(url: $0, delayStartSound: delayStartSound) }
        rawExtractor = try ChicV2FeatureExtractor()
    }

    /// 롤링 우세를 우선하며 공기주입은 0.5 초과, 두 문턱 미달은 롤링으로 판정합니다.
    static func airState(air: Double, sputter: Double, rolling: Double) -> State {
        if rolling >= air && rolling >= sputter { return .other }
        if sputter >= sputterThreshold { return .sputter }
        return air > 0.5 ? .air : .other
    }

    #if DEVELOP
    /// 드롱기의 2차 판정을 우선하고, 보류된 경우 1차 작업음에도 같은 문턱을 적용합니다.
    static func homeWorkState(primary: State, primaryScore: Double, secondary: State, secondaryScore: Double) -> State {
        if secondaryScore >= (secondary == .other ? 0.65 : 0.75) { return secondary }
        return primaryScore >= 0.75 ? primary : .other
    }
    #endif

    /// 선택한 모델의 분류기로 작업음 한 프레임을 판정합니다.
    private func classifyWork(_ x: [Double]) throws -> (State, String, Double?, WorkScores) {
        switch workModel {
        #if DEVELOP
        case let .home(work, metal, air):
            let primary = try work.prediction(x)
            let scores = primary.values
            let index = primary.winner
            let best = scores[index]
            let label = work.labels[index]
            if label == "non_steam" { return (.other, label, scores[2], WorkScores(primary: primary)) }
            guard let first = State(rawValue: label) else { throw Failure.schema }
            var candidate = first
            if first == .other {
                // 기타가 앞서도 작업음과의 차이가 작으면 해당 2차 모델에서 다시 확인합니다.
                let foreground = scores.prefix(3)
                guard let next = foreground.max(), let runner = foreground.firstIndex(of: next),
                      let label = State(rawValue: work.labels[runner]) else { throw Failure.schema }
                guard best - next <= 0.35 else { return (first, first.rawValue, scores[2], WorkScores(primary: primary)) }
                candidate = label
            }
            let expert = candidate == .metallic ? metal : air
            let refined = try expert.prediction(x)
            let winner = refined.winner
            guard let state = State(rawValue: expert.labels[winner]) else { throw Failure.schema }
            let output = WorkScores(primary: primary, secondary: (candidate == .metallic ? "Metal" : "Air", refined))
            let final = Self.homeWorkState(primary: first, primaryScore: best, secondary: state, secondaryScore: refined.values[winner])
            return (final, first.rawValue, scores[2], output)
        #endif
        case let .standard(gate, air, rolling):
            let primary = try gate.prediction(x)
            let label = gate.labels[primary.winner]
            var output = WorkScores(primary: primary)
            let state: State
            var score: Double?
            switch label {
            case "air", "sputter":
                let prediction = try air.prediction(x)
                output.secondary = ("Air", prediction)
                let p = prediction.values
                score = p[1]
                state = Self.airState(air: p[0], sputter: p[1], rolling: p[2])
            case "breath_whistle": state = .other
            case "metallic", "other":
                let prediction = try rolling.prediction(x)
                output.secondary = ("Metal", prediction)
                let p = prediction.values
                state = p[1] > p[0] && p[1] >= p[2] && p[1] >= p[3] && p[1] >= Self.metallicThreshold ? .metallic : .other
            default: throw Failure.schema
            }
            return (state, label, score, output)
        }
    }

    /// 재학습과 동일한 원음 특징을 작업음 분류와 종료 분석에 공유합니다.
    func consume(_ mono: [Float], sampleRate: Double, onSpectrum: (([Double]) throws -> Void)? = nil, onFrame: (Frame) throws -> Void) throws {
        guard sampleRate == 48_000, mono.allSatisfy(\.isFinite) else { throw Failure.input }
        try rawExtractor.consume(mono, sampleRate: sampleRate) { x, spectrum in
            // 대기 중에도 공기주입을 독립 분류하고 종료 이력을 같은 FFT로 유지합니다.
            try onSpectrum?(spectrum)
            let (state, label, score, scores) = try classifyWork(x)
            frameCount += 1
            let updatesStartMean = frameCount.isMultiple(of: 10) && startGate?.isScoring == true
            let startReason = try startGate?.consume(x, state: label == "non_steam" ? nil : state)
            let audioTime = Double(2048 + (frameCount - 1) * 512) / sampleRate
            try onFrame(Frame(state: state, gateLabel: label, sputterScore: score, scores: scores, spectrum: spectrum,
                              audioTime: audioTime, newStartMean: updatesStartMean ? startProbability : nil, startReason: startReason))
        }
    }
}

nonisolated extension ChicModelSelection {
    /// 드롱기에서 청소음이 확인된 묶음은 작업음 피드백을 기본 상태로 표시합니다.
    func feedback(_ state: ChicModelV3_5.State, purge: Double) -> ChicModelV3_5.State {
        #if DEVELOP
        if self == .home && purge >= 0.5 { return .other }
        #endif
        return state
    }

    /// 선택한 모델의 컴파일된 파일을 앱 번들에서 찾습니다.
    func url(for name: String, in bundle: Bundle) throws -> URL {
        let resource: String
        switch self {
        case .standard: resource = name
        #if DEVELOP
        case .home where name == "ChicStartSoundV1": resource = "DelonghiChicStartSound"
        case .home where name == "ChicEndV3_5": resource = "DelonghiChicEndSound"
        case .home: resource = "Delonghi" + name
        #endif
        }
        guard let url = bundle.url(forResource: resource, withExtension: "mlmodelc") else {
            throw ChicModelV3_5.Failure.resource(resource)
        }
        return url
    }
}
