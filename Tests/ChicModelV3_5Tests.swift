import AVFAudio
import CoreML
import Foundation

/// 제공된 PCM과 예상 출력으로 두 단계 판정 및 입력 변환을 검증합니다.
@main enum ChicModelV3_5Tests {
    struct Expected: Decodable { let gate, state: String; let sputter: Double?; let display: String? }
    struct EndExpected: Decodable { let extraSilentSamples: Int; let probabilities: [[Double]]; let times: [Double] }

    /// 롤링 우세·동률과 공기주입 0.5 초과 경계, 문턱 미달 시 롤링 전환을 확인합니다.
    static func checkAirRolling() {
        precondition(ChicModelV3_5.airState(air: 0.2, sputter: 0.3, rolling: 0.5) == .other)
        precondition(ChicModelV3_5.airState(air: 0.4, sputter: 0.2, rolling: 0.4) == .other)
        precondition(ChicModelV3_5.airState(air: 0, sputter: 0.5, rolling: 0.5) == .other)
        precondition(ChicModelV3_5.airState(air: 0.6, sputter: 0.1, rolling: 0.3) == .air)
        precondition(ChicModelV3_5.airState(air: 0.2, sputter: 0.5, rolling: 0.3) == .sputter)
        precondition(ChicModelV3_5.airState(air: 0.35, sputter: 0.4, rolling: 0.25) == .other)
        precondition(ChicModelV3_5.airState(air: 0.4, sputter: 0.35, rolling: 0.25) == .other)
        precondition(ChicModelV3_5.airState(air: 0.5, sputter: 0.2, rolling: 0.3) == .other)
        precondition(ChicModelV3_5.airState(air: 0.500001, sputter: 0.2, rolling: 0.299999) == .air)
        precondition(ChicModelV3_5.airState(air: 0.499999, sputter: 0.2, rolling: 0.300001) == .other)
        precondition(ChicModelV3_5.airState(air: 0.5, sputter: 0.5, rolling: 0) == .sputter)
        var display = ChicDisplayFilter()
        for _ in 0..<10 { _ = display.consume(.air) }
        var result: ChicModelV3_5.State?
        let belowThreshold = ChicModelV3_5.airState(air: 0.4, sputter: 0.35, rolling: 0.25)
        for _ in 0..<10 { result = display.consume(belowThreshold) }
        precondition(result == .air)
        for _ in 0..<10 { result = display.consume(belowThreshold) }
        precondition(result == .other)
        for _ in 0..<10 { result = display.consume(ChicModelV3_5.airState(air: 0.2, sputter: 0.3, rolling: 0.5)) }
        precondition(result == .other)
        print("PASS air >0.5 boundary, fallback to rolling, ties, warning threshold and rolling display transition")
    }

    /// 고정 특징 벡터에서 독립 학습 모델과 Core ML 분류 점수를 비교합니다.
    static func checkEndClassifier(fixture: URL, compiled: URL) throws {
        let expected = try JSONDecoder().decode([[Double]].self, from: Data(contentsOf: fixture.appendingPathComponent("expected-end-classifier.json")))
        let config = MLModelConfiguration(); config.computeUnits = .cpuOnly
        let model = try MLModel(contentsOf: compiled.appendingPathComponent("ChicEndV3_5.mlmodelc"), configuration: config)
        let input = try MLMultiArray(shape: [1845], dataType: .double)
        let provider = try MLDictionaryFeatureProvider(dictionary: ["features": input])
        var error = 0.0
        for row in expected.indices {
            for i in 0..<1845 {
                let value = row == 0 ? 0 : Double((i * 17 + row * 31) % 101 - 50) / 50 * [0.01, 0.1, 1.0, 10.0][row % 4]
                input[i] = NSNumber(value: value)
            }
            let result = try model.prediction(from: provider)
            precondition(expected[row].count == 8)
            for (head, name) in ["activityProbabilities", "probabilities"].enumerated() {
                guard let probabilities = result.featureValue(for: name)?.multiArrayValue else { preconditionFailure("분류 확률 누락") }
                precondition(probabilities.count == 4)
                for i in 0..<4 { error = max(error, abs(probabilities[i].doubleValue - expected[row][head * 4 + i])) }
            }
        }
        precondition(error < 0.0001)
        print("PASS end classifier: \(expected.count) vectors, maximum error \(error)")
    }

    /// 시작 전 오종료 방지, 작업 점수 20회 연속, 우선순위와 한 번만 종료하는 조건을 확인합니다.
    static func checkEndRule() {
        var rule = ChicEndRule()
        for _ in 0..<30 { precondition(rule.consume(work: 0, end: 1, purge: 1, dropDB: 3) == nil) }
        rule.activate()
        for _ in 0..<19 { precondition(rule.consume(work: 0.299, end: 0, purge: 0, dropDB: 3) == nil) }
        precondition(rule.consume(work: 0.3, end: 0, purge: 0, dropDB: 3) == nil)
        for _ in 0..<19 { precondition(rule.consume(work: 0.299, end: 0, purge: 0, dropDB: 3) == nil) }
        precondition(rule.consume(work: 0.299, end: 0, purge: 0, dropDB: 3) == .disappearance)
        rule.activate()
        precondition(rule.consume(work: 0, end: 1, purge: 1, dropDB: 3) == nil)
        var end = ChicEndRule(); end.activate()
        precondition(end.consume(work: 0.1, end: 0.849999, purge: 0, dropDB: 3) == nil)
        precondition(end.consume(work: 0.1, end: 0.85, purge: 0, dropDB: 2.999) == nil)
        precondition(end.consume(work: 0.1, end: 0.85, purge: 0, dropDB: 3) == .endSound)
        var purge = ChicEndRule(); purge.activate()
        for _ in 0..<4 { precondition(purge.consume(work: 0.1, end: 0, purge: 0.5, dropDB: 0) == nil) }
        precondition(purge.consume(work: 0.1, end: 0, purge: 0.499, dropDB: 0) == nil)
        for _ in 0..<4 { precondition(purge.consume(work: 0.1, end: 0, purge: 0.5, dropDB: 0) == nil) }
        precondition(purge.consume(work: 0.1, end: 0, purge: 0.5, dropDB: 0) == .cleaning)
        var priority = ChicEndRule(); priority.activate()
        for _ in 0..<19 { precondition(priority.consume(work: 0, end: 0, purge: 0, dropDB: 3) == nil) }
        precondition(priority.consume(work: 0, end: 0, purge: 1, dropDB: 3) == .disappearance)
        var activeWork = ChicEndRule(); activeWork.activate()
        for work in [0.3, 0.778, 1.0] {
            for _ in 0..<60 { precondition(activeWork.consume(work: work, end: 0, purge: 0, dropDB: 20) == nil) }
        }
        var alternating = ChicEndRule(); alternating.activate()
        for i in 0..<60 { precondition(alternating.consume(work: i % 2 == 0 ? 0 : 1, end: 0, purge: 0, dropDB: 0) == nil) }
        print("PASS work >=0.3 suppresses disappearance for 60 updates; nonconsecutive low work does not finish")
        print("PASS first-feedback activation, strict <0.3 x20, reset at 0.3, priority and single completion")
    }

    /// 실제 PCM 뒤 무음을 붙인 독립 Python 점수와 두 버퍼 방식의 출력이 일치하는지 확인합니다.
    static func checkEndDetector(_ pcm: [Float], fixture: URL, compiled: URL, gain: Float = 1, referenceName: String = "expected-end.json") throws {
        let expected = try JSONDecoder().decode(EndExpected.self, from: Data(contentsOf: fixture.appendingPathComponent(referenceName)))
        let samples = pcm.map { $0 * gain } + [Float](repeating: 0, count: expected.extraSilentSamples)
        for chunks in [[4800], [1, 127, 513, 1024, 4097]] {
            let detector = try ChicEndDetector(modelURL: compiled.appendingPathComponent("ChicAudioFeatures.mlmodelc"), classifierURL: compiled.appendingPathComponent("ChicEndV3_5.mlmodelc"))
            let spectrum = try ChicV2FeatureExtractor()
            var offset = 0, chunk = 0, index = 0
            var error = 0.0
            var energyHistory: [Double] = []
            var actualRule = ChicEndRule(), referenceRule = ChicEndRule()
            actualRule.activate(); referenceRule.activate()
            let began = Date()
            while offset < samples.count {
                let stop = min(samples.count, offset + chunks[chunk % chunks.count])
                let block = Array(samples[offset..<stop])
                try detector.append(block)
                try spectrum.consume(block, sampleRate: 48000) { _, power in
                    guard let scores = try detector.consume(spectrum: power) else { return }
                    precondition(index < expected.probabilities.count)
                    let actual = [scores.other, scores.work, scores.end, scores.purge]
                    for (a, b) in zip(actual, expected.probabilities[index]) { error = max(error, abs(a-b)) }
                    let sampleEnd = Int((expected.times[index] * 48000).rounded())
                    let sampleStart = max(0, sampleEnd - 5120)
                    let energy = samples[sampleStart..<sampleEnd].reduce(0.0) { $0 + Double($1) * Double($1) } / Double(sampleEnd - sampleStart)
                    precondition(abs(scores.rmsDBFS - 10 * log10(max(energy, 1e-16))) < 1e-8)
                    let referenceEnergy = energyHistory.isEmpty ? energy : energyHistory.reduce(0, +) / Double(energyHistory.count)
                    let expectedDrop = 10 * log10(max(referenceEnergy, 1e-16)) - scores.rmsDBFS
                    precondition(abs(scores.dropDB - expectedDrop) < 1e-8)
                    energyHistory.append(energy)
                    if energyHistory.count > 10 { energyHistory.removeFirst() }
                    let reference = expected.probabilities[index]
                    precondition(actualRule.consume(work: actual[1], end: actual[2], purge: actual[3], dropDB: 3) == referenceRule.consume(work: reference[1], end: reference[2], purge: reference[3], dropDB: 3), "종료 시점 불일치: \(index)")
                    index += 1
                }
                offset = stop; chunk += 1
            }
            FileHandle.standardError.write(Data("End parity: \(index) outputs, max error \(error), chunks \(chunks), seconds \(Date().timeIntervalSince(began))\n".utf8))
            precondition(index == expected.probabilities.count && error < 0.002)
        }
    }
    /// 집계 경계·동률·연속 판정 중단과 새 연습의 초기 상태를 확인합니다.
    static func checkDisplayFilter() {
        typealias State = ChicModelV3_5.State
        func check(_ candidates: [State], _ expected: [State?]) {
            precondition(candidates.count == expected.count)
            var filter = ChicDisplayFilter()
            for (candidate, result) in zip(candidates, expected) {
                for _ in 0..<9 { precondition(filter.consume(candidate) == nil) }
                precondition(filter.consume(candidate) == result)
            }
        }
        check([.other, .other, .air, .other, .air, .air], [nil, nil, .air, .air, .air, .air])
        check([.air, .air, .other, .air, .other, .other], [.air, .air, .air, .air, .air, .other])
        check([.air, .air, .metallic, .metallic, .air, .metallic, .metallic, .metallic],
              [.air, .air, .air, .air, .air, .air, .air, .metallic])
        check([.air, .air, .sputter, .sputter, .metallic, .sputter, .sputter, .sputter],
              [.air, .air, .air, .air, .air, .air, .air, .sputter])
        check([.metallic, .metallic, .metallic, .sputter, .sputter, .sputter, .air, .air],
              [nil, nil, .metallic, .metallic, .metallic, .sputter, .air, .air])
        check([.air, .sputter, .air, .sputter], [.air, .air, .air, .air])
        check([.air, .other, .other, .air], [.air, .air, .other, .air])

        var filter = ChicDisplayFilter()
        let majority = Array(repeating: State.air, count: 6) + Array(repeating: State.metallic, count: 4)
        for state in majority.dropLast() { precondition(filter.consume(state) == nil) }
        precondition(filter.consume(majority.last!) == .air)
        let tied: [State] = [.air, .metallic, .air, .metallic, .metallic, .metallic, .air, .air, .sputter, .other]
        for state in tied.dropLast() { precondition(filter.consume(state) == nil) }
        precondition(filter.consume(tied.last!) == .air)
        var fresh = ChicDisplayFilter()
        for _ in 0..<9 { precondition(fresh.consume(.air) == nil) }
        precondition(fresh.consume(.air) == .air)
        print("PASS 10-frame mode, ties, strict consecutive runs and fresh session")
    }
    /// 같은 소리를 서로 다른 버퍼 크기로 나눠도 결과가 같은지 확인합니다.
    static func main() throws {
        checkAirRolling()
        checkDisplayFilter()
        checkEndRule()
        let args = CommandLine.arguments
        let dir = URL(fileURLWithPath: args[1])
        let compiled = URL(fileURLWithPath: args[2])
        let expected = try JSONDecoder().decode([Expected].self, from: Data(contentsOf: dir.appendingPathComponent("expected.json")))
        let file = try AVAudioFile(forReading: dir.appendingPathComponent("fixture.wav"))
        let buf = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: UInt32(file.length))!
        try file.read(into: buf)
        let x = Array(UnsafeBufferPointer(start: buf.floatChannelData![0], count: Int(buf.frameLength)))
        try checkEndClassifier(fixture: dir, compiled: compiled)
        try checkEndDetector(x, fixture: dir, compiled: compiled)
        try checkEndDetector(x, fixture: dir, compiled: compiled, gain: Float(pow(10.0, -24.0 / 20)), referenceName: "expected-end-low-gain.json")
        for chunks in [[4800], [1, 127, 513, 1024, 4097]] {
            let stream = try ChicModelV3_5(gateURL: compiled.appendingPathComponent("ChicModelV3_5Gate.mlmodelc"),
                                         airURL: compiled.appendingPathComponent("ChicModelV3_5Air.mlmodelc"),
                                         rollingURL: compiled.appendingPathComponent("ChicModelV3_5Metallic.mlmodelc"))
            var displayFilter = ChicDisplayFilter()
            var i=0, start=0, chunk=0
            while start<x.count {
                let end = min(x.count,start+chunks[chunk % chunks.count])
                try stream.consume(Array(x[start..<end]),sampleRate:48000) { frame in
                    precondition(i<expected.count)
                    let e=expected[i]
                    precondition(frame.state.rawValue==e.state && frame.gateLabel==e.gate,"frame \(i) expected \(e.gate)/\(e.state) got \(frame.gateLabel)/\(frame.state.rawValue)")
                    precondition(displayFilter.consume(frame.state)?.rawValue == e.display, "display at frame \(i)")
                    if let s=e.sputter {
                        precondition(abs(s-frame.sputterScore!)<1e-6,"air head score at \(i)")
                    } else { precondition(frame.sputterScore==nil) }
                    i+=1
                }
                chunk+=1; start=end
            }
            precondition(i==expected.count)
            print("\(i) frames match, chunks \(chunks)")
        }
        for rate in [44100,48000,96000] {
            let converter=ChicV2Input48k()
            let wave=(0..<rate).map { Float(sin(2 * .pi * 1000 * Double($0) / Double(rate))) }
            var result=[Float]()
            for block in stride(from:0,to:rate,by:rate/10) { result += try converter.convert(Array(wave[block..<block+rate/10]),sampleRate:Double(rate)) }
            let crossings=zip(result.dropFirst(4800),result.dropFirst(4801)).filter { $0 <= 0 && $1 > 0 }.count
            FileHandle.standardError.write(Data("rate \(rate) samples \(result.count) crossings \(crossings)\n".utf8))
            precondition(abs(result.count-48000)<150 && (894...903).contains(crossings),"resampling timebase at \(rate)")
            if rate==48000 { precondition(result==wave) }
            print("\(rate) Hz input → \(result.count) samples, tone OK")
        }
    }
}
