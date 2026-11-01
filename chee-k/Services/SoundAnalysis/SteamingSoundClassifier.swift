import CoreML
import Foundation

/// 모델의 네 분류를 기존 연습 화면 상태로 연결합니다.
nonisolated enum SteamingSound: String, CaseIterable {
    case air, metallic, sputter, other

    var phase: PracticePhase {
        switch self {
        case .air: .aeration
        case .metallic: .sharpSound
        case .sputter: .bubble
        case .other: .milkFlow
        }
    }
}

/// 특징값을 Core ML 모델에 넣고 가장 높은 확률의 소리를 반환합니다.
nonisolated final class SteamingSoundClassifier {
    private let model: MLModel
    private let probabilityName: String
    private let columns = (0..<273).map { String(format: "f%03d", $0) }

    init(modelURL: URL) throws {
        let configuration = MLModelConfiguration()
        configuration.computeUnits = .cpuOnly
        model = try MLModel(contentsOf: modelURL, configuration: configuration)
        guard Set(model.modelDescription.inputDescriptionsByName.keys) == Set(columns),
              let name = model.modelDescription.predictedProbabilitiesName else { throw Self.invalidModel() }
        probabilityName = name
    }

    /// 손상된 입력이나 모델 출력은 롤링으로 숨기지 않고 오류로 전달합니다.
    func predict(_ features: [Double]) throws -> SteamingSound {
        guard features.count == columns.count, features.allSatisfy(\.isFinite) else { throw Self.invalidModel() }
        let input = try MLDictionaryFeatureProvider(dictionary: Dictionary(uniqueKeysWithValues: zip(columns, features)))
        let result = try model.prediction(from: input)
        guard let probabilities = result.featureValue(for: probabilityName)?.dictionaryValue,
              Set(probabilities.keys.map { String(describing: $0) }) == Set(SteamingSound.allCases.map(\.rawValue)),
              probabilities.values.allSatisfy({ $0.doubleValue.isFinite && (0...1).contains($0.doubleValue) }),
              let winner = probabilities.max(by: { $0.value.doubleValue < $1.value.doubleValue }),
              let sound = SteamingSound(rawValue: String(describing: winner.key)) else { throw Self.invalidModel() }
        return sound
    }

    /// 모델과 입력 계약이 맞지 않을 때 보여줄 오류입니다.
    private static func invalidModel() -> NSError {
        NSError(domain: "SteamingAnalysis", code: 3,
                userInfo: [NSLocalizedDescriptionKey: "스티밍 분석 모델의 입력 또는 출력이 올바르지 않아요."])
    }
}
