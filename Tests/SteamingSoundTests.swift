import CoreML
import Foundation

/// 기기 없이 특징 계산·모델 추론·화면 상태 매핑을 검증합니다.
@main
struct SteamingSoundTests {
    static func main() throws {
        precondition(SteamingSound.air.phase == .aeration)
        precondition(SteamingSound.metallic.phase == .sharpSound)
        precondition(SteamingSound.sputter.phase == .bubble)
        precondition(SteamingSound.other.phase == .milkFlow)

        let modelURL = URL(fileURLWithPath: CommandLine.arguments[1])
        let compiled = try MLModel.compileModel(at: modelURL)
        let classifier = try SteamingSoundClassifier(modelURL: compiled)
        let samples = (0..<12000).map { Float(sin(Double($0) * 0.17) * 0.1) }
        let whole = try extract(samples, chunkSize: samples.count)
        let chunked = try extract(samples, chunkSize: 333)
        precondition(whole == chunked && !whole.isEmpty)
        for row in whole {
            precondition(row.count == 273 && row.allSatisfy(\.isFinite))
            _ = try classifier.predict(row)
        }
        for row in try extract([Float](repeating: 0, count: 4096), chunkSize: 1024) {
            precondition(row.allSatisfy(\.isFinite))
            _ = try classifier.predict(row)
        }
        do {
            _ = try classifier.predict([0])
            preconditionFailure("특징 개수가 다르면 거부해야 합니다.")
        } catch {}
        do {
            let extractor = try SteamingFeatureExtractor()
            try extractor.consume([0], sampleRate: 16000) { _ in }
            preconditionFailure("지원하지 않는 샘플레이트는 거부해야 합니다.")
        } catch {}

        // 학습 PCM과 캐시가 있으면 첫 2초의 모든 특징이 동일한지도 검증합니다.
        if CommandLine.arguments.count == 4 {
            let pcm = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[2]))
            let samples = pcm.withUnsafeBytes { Array($0.bindMemory(to: Float.self).prefix(96000)) }
            let cache = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[3]))
            let expected = cache.withUnsafeBytes { Array($0.bindMemory(to: Double.self)) }
            let rows = try extract(samples, chunkSize: 1024)
            var maximumDifference = 0.0
            for (index, row) in rows.enumerated() {
                for (column, value) in row.enumerated() {
                    maximumDifference = max(maximumDifference, abs(value - expected[index * 273 + column]))
                }
                _ = try classifier.predict(row)
            }
            precondition(maximumDifference < 1e-5)
            print("Training feature parity passed:", rows.count, "frames; max difference:", maximumDifference)
        }
        print("SteamingSoundTests passed")
    }

    /// 오디오 콜백의 청크 크기와 무관하게 동일한 특징이 나오는지 비교합니다.
    private static func extract(_ samples: [Float], chunkSize: Int) throws -> [[Double]] {
        let extractor = try SteamingFeatureExtractor()
        var result: [[Double]] = []
        for offset in stride(from: 0, to: samples.count, by: chunkSize) {
            try extractor.consume(Array(samples[offset..<min(offset + chunkSize, samples.count)]), sampleRate: 48000) {
                result.append($0)
            }
        }
        return result
    }
}
