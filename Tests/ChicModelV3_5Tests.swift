import AVFAudio
import CoreML
import Foundation

/// 제공된 PCM과 예상 출력으로 두 단계 판정 및 입력 변환을 검증합니다.
@main enum ChicModelV3_5Tests {
    struct Expected: Decodable { let gate, state: String; let sputter: Double?; let display: String? }
    struct EndExpected: Decodable { let extraSilentSamples: Int; let probabilities: [[Double]]; let times: [Double] }

    struct StartExpected: Decodable {
        let audio, startReason: String
        let frames, startFrame: Int
        let startScore, highProbability, lowProbability: Double
        let highFeatures, lowFeatures: [Double]
        let states: [Expected]
    }

    /// 공기주입과 시작음은 서로의 점수나 판정에 의존하지 않는 OR입니다.
    static func checkStartRule() {
        var air = ChicStartRule()
        for _ in 0..<9 { precondition(air.consume(0, state: .air) == nil) }
        precondition(air.consume(0, state: .air) == .air)
        precondition(air.isStarted && air.meanScore == 0)
        for _ in 0..<100 { precondition(air.consume(1, state: .other) == nil) }
        var sound = ChicStartRule()
        for _ in 0..<9 { precondition(sound.consume(0.86, state: .other) == nil) }
        precondition(sound.consume(0.86, state: .other) == .startSound)
        var average = ChicStartRule()
        for _ in 0..<9 { precondition(average.consume(0.9, state: .other) == nil) }
        precondition(average.consume(0, state: .other) == nil)
        for _ in 0..<9 { precondition(average.consume(0.86, state: .other) == nil) }
        precondition(average.consume(0.86, state: .other) == .startSound)
        for state in [ChicModelV3_5.State.other, .sputter, .metallic] {
            var idle = ChicStartRule()
            for _ in 0..<40 { precondition(idle.consume(0, state: state) == nil) }
            precondition(!idle.isStarted)
        }
        var simultaneous = ChicStartRule()
        for _ in 0..<9 { precondition(simultaneous.consume(1, state: .air) == nil) }
        precondition(simultaneous.consume(1, state: .air) == .air)
        var tied = ChicStartRule()
        for _ in 0..<5 { precondition(tied.consume(0, state: .other) == nil) }
        for _ in 0..<4 { precondition(tied.consume(0, state: .air) == nil) }
        precondition(tied.consume(0, state: .air) == .air)
        var reverse = ChicStartRule()
        for _ in 0..<5 { precondition(reverse.consume(0, state: .air) == nil) }
        for _ in 0..<5 { precondition(reverse.consume(0, state: .other) == nil) }
        precondition(!reverse.isStarted)
        print("PASS independent air OR start sound, mean, tie, no other-state start and one shot")
    }

    /// 실제 모델에서도 어느 경로로 시작했든 추론을 다시 호출하지 않습니다.
    static func checkStartModel(_ expected: StartExpected, url: URL) throws {
        precondition(expected.highProbability > ChicStartRule.threshold)
        precondition(expected.lowProbability < ChicStartRule.threshold)
        for (features, state, reason) in [(expected.highFeatures, ChicModelV3_5.State.other, ChicStartRule.Reason.startSound),
                                         (expected.lowFeatures, .air, .air)] {
            let gate = try ChicStartGate(url: url)
            for _ in 0..<9 { let result = try gate.consume(features, state: state); precondition(result == nil) }
            let result = try gate.consume(features, state: state)
            precondition(result == reason && gate.isStarted)
            let probability = reason == .air ? expected.lowProbability : expected.highProbability
            precondition(abs(gate.meanScore! - probability) < 1e-8)
            // 빈 특징은 추론 시 오류여야 하므로 양 경로 모두 호출 중단을 검증합니다.
            for _ in 0..<100 { let repeated = try gate.consume([], state: .other); precondition(repeated == nil) }
        }
        let idle = try ChicStartGate(url: url)
        for _ in 0..<30 { let result = try idle.consume(expected.lowFeatures, state: .other); precondition(result == nil) }
        precondition(!idle.isStarted)
        print("PASS real start sound and low-score air both stop further model calls")
    }

    /// 실제 공기주입 누락 회귀와 일정·불규칙 버퍼의 OR·분류·종료 시간축을 확인합니다.
    static func checkStartPipeline(fixture: URL, compiled: URL) throws {
        let url = compiled.appendingPathComponent("ChicStartSoundV1.mlmodelc")
        for name in ["start-reference.json", "air-start-reference.json", "sound-start-reference.json"] {
            let expected = try JSONDecoder().decode(StartExpected.self, from: Data(contentsOf: fixture.appendingPathComponent(name)))
            if name == "sound-start-reference.json" { try checkStartModel(expected, url: url) }
            let file = try AVAudioFile(forReading: fixture.appendingPathComponent(expected.audio))
            let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: UInt32(file.length))!
            try file.read(into: buffer)
            let samples = Array(UnsafeBufferPointer(start: buffer.floatChannelData![0], count: Int(buffer.frameLength)))
            for chunks in [[4800], [1, 127, 513, 1024, 4097]] {
                let stream = try ChicModelV3_5(gateURL: compiled.appendingPathComponent("ChicModelV3_5Gate.mlmodelc"),
                    airURL: compiled.appendingPathComponent("ChicModelV3_5Air.mlmodelc"),
                    rollingURL: compiled.appendingPathComponent("ChicModelV3_5Metallic.mlmodelc"), startURL: url)
                let end = try ChicEndDetector(modelURL: compiled.appendingPathComponent("ChicAudioFeatures.mlmodelc"), classifierURL: compiled.appendingPathComponent("ChicEndV3_5.mlmodelc"))
                var display = ChicDisplayFilter(), endRule = ChicEndRule()
                var offset = 0, chunk = 0, spectra = 0, frames = 0, starts = 0, endScores = 0
                while offset < samples.count {
                    let stop = min(samples.count, offset + chunks[chunk % chunks.count])
                    let block = Array(samples[offset..<stop])
                    try end.append(block)
                    try stream.consume(block, sampleRate: 48000, onSpectrum: { power in
                        spectra += 1
                        if let score = try end.consume(spectrum: power) {
                            endScores += 1
                            if starts == 0 { precondition(!endRule.isActive) }
                            _ = endRule.consume(work: score.work, end: score.end, purge: score.purge)
                        }
                    }) { frame in
                        if let reason = frame.startReason {
                            precondition(starts == 0 && frames == expected.startFrame)
                            precondition(reason.rawValue == expected.startReason)
                            precondition(abs(stream.startProbability! - expected.startScore) < 1e-8)
                            starts += 1
                            display.activate()
                            endRule.activate()
                        }
                        precondition(stream.isStarted == (expected.startFrame >= 0 && frames >= expected.startFrame))
                        let reference = expected.states[frames]
                        precondition(frame.state.rawValue == reference.state && frame.gateLabel == reference.gate)
                        let actual = display.consume(frame.state)
                        precondition((stream.isStarted ? actual?.rawValue : nil) == reference.display)
                        if let score = reference.sputter { precondition(abs(score - frame.sputterScore!) < 1e-6) }
                        frames += 1
                    }
                    offset = stop; chunk += 1
                }
                precondition(spectra == expected.frames && frames == expected.frames && starts == (expected.startFrame >= 0 ? 1 : 0))
                precondition(endScores == expected.frames / 10)
                print("PASS OR pipeline: \(name), \(spectra) frames, start=\(expected.startReason) @\(expected.startFrame), chunks \(chunks)")
            }
        }
    }

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

    /// 시작 전 오알림 방지, 작업 점수 20회 연속, 우선순위, 그리고 종료음 · 청소음 · 소리 끊김 모두 끝내지 않고 한 번만 묻는 조건을 확인합니다.
    static func checkEndRule() {
        var rule = ChicEndRule()
        for _ in 0..<30 { precondition(rule.consume(work: 0, end: 1, purge: 1) == nil) }
        rule.activate()
        for _ in 0..<19 { precondition(rule.consume(work: 0.299, end: 0, purge: 0) == nil) }
        precondition(rule.consume(work: 0.3, end: 0, purge: 0) == nil)
        for _ in 0..<19 { precondition(rule.consume(work: 0.299, end: 0, purge: 0) == nil) }
        precondition(rule.consume(work: 0.299, end: 0, purge: 0) == .disappearance)
        // 소리 끊김은 끝내지 않고 한 번만 알림: 계속 조용해도, 종료음 · 청소음이 와도 다시 알리지 않음
        precondition(rule.isAsking && rule.isActive)
        for _ in 0..<60 { precondition(rule.consume(work: 0, end: 1, purge: 1) == nil) }
        // 작업 점수가 2번만 이어지면 아직 묻는 중 → 다시 20번 낮아도 알리지 않음
        for _ in 0..<2 { precondition(rule.consume(work: 0.3, end: 0, purge: 0) == nil) }
        for _ in 0..<20 { precondition(rule.consume(work: 0, end: 0, purge: 0) == nil) }
        precondition(rule.isAsking)
        // 3번 이어지면 소리가 다시 이어진 것 → 다음 끊김을 다시 알림
        for _ in 0..<3 { precondition(rule.consume(work: 0.5, end: 0, purge: 0) == nil) }
        precondition(!rule.isAsking)
        for _ in 0..<19 { precondition(rule.consume(work: 0, end: 0, purge: 0) == nil) }
        precondition(rule.consume(work: 0, end: 0, purge: 0) == .disappearance)

        // 종료음: 0.6 이상 한 번이면 묻고, 끝내지 않음. 스티밍이 이어지면(작업 점수 3번) 다시 물을 수 있음
        var end = ChicEndRule(); end.activate()
        precondition(end.consume(work: 0.8, end: 0.599999, purge: 0) == nil)
        precondition(end.consume(work: 0.8, end: 0.6, purge: 0) == .endSound)
        precondition(end.isAsking && end.isActive)
        for _ in 0..<2 { precondition(end.consume(work: 0.8, end: 0.9, purge: 0) == nil) }
        precondition(end.consume(work: 0.8, end: 0.9, purge: 0) == .endSound)

        // 청소음: 0.5 이상 3번 연속이면 묻고, 끝내지 않음. 다시 이어진 뒤에는 처음부터 3번을 셈
        var purge = ChicEndRule(); purge.activate()
        for _ in 0..<6 { precondition(purge.consume(work: 0.8, end: 0, purge: 0.499999) == nil) }
        for _ in 0..<2 { precondition(purge.consume(work: 0.8, end: 0, purge: 0.5) == nil) }
        precondition(purge.consume(work: 0.8, end: 0, purge: 0.499999) == nil)
        for _ in 0..<2 { precondition(purge.consume(work: 0.8, end: 0, purge: 0.5) == nil) }
        precondition(purge.consume(work: 0.8, end: 0, purge: 0.5) == .cleaning && purge.isAsking)
        for _ in 0..<3 { precondition(purge.consume(work: 0.8, end: 0, purge: 0) == nil) }
        precondition(!purge.isAsking)
        for _ in 0..<2 { precondition(purge.consume(work: 0.8, end: 0, purge: 0.5) == nil) }
        precondition(purge.consume(work: 0.8, end: 0, purge: 0.5) == .cleaning)

        // 끝난 것으로 볼 시각: 종료음은 지금, 소리 끊김은 20번 전, 청소음은 3번 전
        precondition(ChicEndRule.Reason.endSound.lookbackCount == 0)
        precondition(ChicEndRule.Reason.disappearance.lookbackCount == ChicEndRule.silenceCount)
        precondition(ChicEndRule.Reason.cleaning.lookbackCount == ChicEndRule.cleaningCount)

        var priority = ChicEndRule(); priority.activate()
        for _ in 0..<19 { precondition(priority.consume(work: 0, end: 0, purge: 0) == nil) }
        precondition(priority.consume(work: 0, end: 0, purge: 1) == .disappearance)
        var activeWork = ChicEndRule(); activeWork.activate()
        for work in [0.3, 0.778, 1.0] {
            for _ in 0..<60 { precondition(activeWork.consume(work: work, end: 0, purge: 0) == nil) }
        }
        var alternating = ChicEndRule(); alternating.activate()
        for i in 0..<60 { precondition(alternating.consume(work: i % 2 == 0 ? 0 : 1, end: 0, purge: 0) == nil) }
        print("PASS work >=0.3 suppresses disappearance for 60 updates; nonconsecutive low work does not ask")
        print("PASS first-feedback activation, strict <0.3 x20, reset at 0.3, priority")
        print("PASS end sound / cleaning / silence never finish: each asks once, re-armed after 3 working updates")
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
                    precondition(actualRule.consume(work: actual[1], end: actual[2], purge: actual[3]) == referenceRule.consume(work: reference[1], end: reference[2], purge: reference[3]), "종료 시점 불일치: \(index)")
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
              [.air, .air, .air, .sputter, .sputter, .sputter, .sputter, .sputter])
        check([.metallic, .metallic, .metallic, .sputter, .sputter, .sputter, .air, .air],
              [nil, nil, .metallic, .metallic, .sputter, .sputter, .air, .air])
        check([.air, .sputter, .air, .sputter], [.air, .air, .air, .air])
        check([.air, .sputter, .other, .sputter, .sputter], [.air, .air, .air, .air, .sputter])
        check([.sputter, .sputter], [nil, .sputter])
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
        checkStartRule()
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
        try checkStartPipeline(fixture: dir, compiled: compiled)
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
