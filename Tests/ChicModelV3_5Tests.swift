import AVFAudio
import Foundation

/// 제공된 PCM과 예상 출력으로 두 단계 판정 및 입력 변환을 검증합니다.
@main enum ChicModelV3_5Tests {
    struct Expected: Decodable { let gate, state: String; let sputter: Double?; let display: String? }
    struct EndExpected: Decodable { let extraSilentSamples: Int; let probabilities: [[Double]]; let times: [Double] }

    /// 시작 전 오종료 방지, 엄격한 20회 연속, 우선순위와 한 번만 종료하는 조건을 확인합니다.
    static func checkEndRule() {
        var rule = ChicEndRule()
        for _ in 0..<30 { precondition(rule.consume(work: 0, end: 1, purge: 1) == nil) }
        rule.activate()
        for _ in 0..<19 { precondition(rule.consume(work: 0.299, end: 0, purge: 0) == nil) }
        precondition(rule.consume(work: 0.3, end: 0, purge: 0) == nil)
        for _ in 0..<19 { precondition(rule.consume(work: 0.299, end: 0, purge: 0) == nil) }
        precondition(rule.consume(work: 0.299, end: 0, purge: 0) == .disappearance)
        rule.activate()
        precondition(rule.consume(work: 0, end: 1, purge: 1) == nil)
        var end = ChicEndRule(); end.activate()
        precondition(end.consume(work: 0, end: 0.995, purge: 1) == .endSound)
        var purge = ChicEndRule(); purge.activate()
        precondition(purge.consume(work: 0.8, end: 0, purge: 0.994) == nil)
        precondition(purge.consume(work: 0.8, end: 0, purge: 0.995) == .cleaning)
        var priority = ChicEndRule(); priority.activate()
        for _ in 0..<19 { precondition(priority.consume(work: 0, end: 0, purge: 0) == nil) }
        precondition(priority.consume(work: 0, end: 0, purge: 1) == .disappearance)
        print("PASS first-feedback activation, strict <0.3 x20, reset at 0.3, priority and single completion")
    }

    /// 실제 PCM 뒤 무음을 붙인 독립 Python 점수와 두 버퍼 방식의 출력이 일치하는지 확인합니다.
    static func checkEndDetector(_ pcm: [Float], fixture: URL, compiled: URL, weights: URL) throws {
        let expected = try JSONDecoder().decode(EndExpected.self, from: Data(contentsOf: fixture.appendingPathComponent("expected-end.json")))
        let samples = pcm + [Float](repeating: 0, count: expected.extraSilentSamples)
        for chunks in [[4800], [1, 127, 513, 1024, 4097]] {
            let detector = try ChicEndDetector(modelURL: compiled.appendingPathComponent("ChicAudioFeatures.mlmodelc"), weightsURL: weights)
            let spectrum = try ChicV2FeatureExtractor()
            var offset = 0, chunk = 0, index = 0
            var error = 0.0
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
        try checkEndDetector(x, fixture: dir, compiled: compiled, weights: URL(fileURLWithPath: args[3]))
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
