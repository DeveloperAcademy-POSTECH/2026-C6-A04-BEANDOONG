import AVFAudio
import Foundation

/// 제공된 PCM과 예상 출력으로 두 단계 판정 및 입력 변환을 검증합니다.
@main enum ChicModelV3Tests {
    struct Expected: Decodable { let gate, state: String; let sputter: Double?; let display: String? }
    /// 집계 경계·동률·연속 판정 중단과 새 연습의 초기 상태를 확인합니다.
    static func checkDisplayFilter() {
        typealias State = ChicModelV3.State
        func check(_ candidates: [State], _ expected: [State?]) {
            precondition(candidates.count == expected.count)
            var filter = ChicDisplayFilter()
            for (candidate, result) in zip(candidates, expected) {
                for _ in 0..<9 { precondition(filter.consume(candidate) == nil) }
                precondition(filter.consume(candidate) == result)
            }
        }
        check([.other, .other, .air, .other, .air, .air], [nil, nil, nil, nil, nil, .air])
        check([.air, .air, .other, .air, .other, .other], [nil, .air, .air, .air, .air, .other])
        check([.air, .air, .metallic, .metallic, .air, .metallic, .metallic, .metallic],
              [nil, .air, .air, .air, .air, .air, .air, .metallic])
        check([.air, .air, .sputter, .sputter, .metallic, .sputter, .sputter, .sputter],
              [nil, .air, .air, .air, .air, .air, .air, .sputter])
        check([.metallic, .metallic, .metallic, .sputter, .sputter, .sputter, .air, .air],
              [nil, nil, .metallic, .metallic, .metallic, .sputter, .sputter, .air])
        check([.air, .sputter, .air, .sputter], [nil, nil, nil, nil])

        var filter = ChicDisplayFilter()
        let majority = Array(repeating: State.air, count: 6) + Array(repeating: State.metallic, count: 4)
        for state in majority { precondition(filter.consume(state) == nil) }
        let tied: [State] = [.air, .metallic, .air, .metallic, .metallic, .metallic, .air, .air, .sputter, .other]
        for state in tied.dropLast() { precondition(filter.consume(state) == nil) }
        precondition(filter.consume(tied.last!) == .air)
        var fresh = ChicDisplayFilter()
        for _ in 0..<19 { precondition(fresh.consume(.air) == nil) }
        precondition(fresh.consume(.air) == .air)
        print("PASS 10-frame mode, ties, strict consecutive runs and fresh session")
    }
    /// 같은 소리를 서로 다른 버퍼 크기로 나눠도 결과가 같은지 확인합니다.
    static func main() throws {
        checkDisplayFilter()
        let args = CommandLine.arguments
        let dir = URL(fileURLWithPath: args[1])
        let compiled = URL(fileURLWithPath: args[2])
        let expected = try JSONDecoder().decode([Expected].self, from: Data(contentsOf: dir.appendingPathComponent("expected.json")))
        let file = try AVAudioFile(forReading: dir.appendingPathComponent("fixture.wav"))
        let buf = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: UInt32(file.length))!
        try file.read(into: buf)
        let x = Array(UnsafeBufferPointer(start: buf.floatChannelData![0], count: Int(buf.frameLength)))
        for chunks in [[4800], [1, 127, 513, 1024, 4097]] {
            let stream = try ChicModelV3(gateURL: compiled.appendingPathComponent("ChicModelV3Gate.mlmodelc"),
                                         airURL: compiled.appendingPathComponent("ChicModelV3Air.mlmodelc"),
                                         rollingURL: compiled.appendingPathComponent("ChicModelV3Metallic.mlmodelc"))
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
