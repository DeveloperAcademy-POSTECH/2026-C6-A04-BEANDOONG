// 앱과 분리해 PulseDSP의 기본 동작을 검사하는 명령행 코드입니다.
// 임의 잡음·무음, 입력 조각 크기, 잘못된 입력, 기준값 변경을 확인합니다.
import Foundation

let dsp = PulseDSP()
var seed: UInt32 = 9
func random() -> Float { seed = 1664525 &* seed &+ 1013904223;return Float(Double(seed)/4294967296*2-1)*0.1 }
let noise = (0..<48000).map { _ in random() }
let result = try dsp.consume(noise,sampleRate:48000)
assert(result.contains { $0.active })
assert(result.allSatisfy { $0.db.isFinite && $0.upperDB.isFinite && $0.flatness.isFinite })
let silence = try dsp.consume([Float](repeating:0,count:48000),sampleRate:48000)
assert(silence.last?.active == false)
// 선택적으로 전달한 Float32 PCM 파일은 시간 순서대로 재생해 판정 구간을 확인합니다.
let arguments = CommandLine.arguments.dropFirst()
for path in arguments {
    let data = try Data(contentsOf:URL(fileURLWithPath:path))
    let samples = data.withUnsafeBytes { Array($0.bindMemory(to:Float.self)) }
    let detector = PulseDSP();var all: [PulseResult] = []
    for start in stride(from:0,to:samples.count,by:777) { all += try detector.consume(Array(samples[start..<min(start+777,samples.count)]),sampleRate:48000) }
    if path.contains("recording18") {
        assert(all.contains { $0.active && $0.time > 8.5 && $0.time < 9.2 })
        assert(!all.contains { $0.active && $0.time > 9.7 })
        print("Recording 18 last air:",all.last(where: { $0.active })!.time)
    }
    if path.contains("recording9") { assert(all.contains { $0.active && $0.time > 12.8 && $0.time < 13.5 }) }
    print("PASS replay",path,"frames",all.count)
}
let one = PulseDSP(), split = PulseDSP()
// 같은 소리를 한 번에 주거나 잘게 나눠 주어도 결과가 같은지 검사합니다.
let a = try one.consume(noise,sampleRate:48000)
var b: [PulseResult] = []
for i in stride(from:0,to:noise.count,by:113) { b += try split.consume(Array(noise[i..<min(i+113,noise.count)]),sampleRate:48000) }
assert(a.count == b.count)
for (x,y) in zip(a,b) {assert(x.active == y.active && abs(x.upperDB-y.upperDB)<1e-9)}
do { _ = try PulseDSP().consume([Float.nan],sampleRate:48000);assertionFailure() } catch {}
do { _ = try PulseDSP().consume([0],sampleRate:16000);assertionFailure() } catch {}
print("PASS noise, silence, finite values, chunk independence, invalid input")

// 분석기를 다시 만들지 않고 변경된 기준값이 다음 입력부터 반영되는지 검사한다.
let tuning = PulseDSP()
tuning.minimumFlatness = 0.99
assert(!(try! tuning.consume(noise,sampleRate:48000)).contains { $0.active })
tuning.minimumFlatness = 0.12
assert((try! tuning.consume(noise,sampleRate:48000)).contains { $0.active })
tuning.minimumHighDB = 0
assert((try! tuning.consume(noise,sampleRate:48000)).last?.active == false)
tuning.minimumHighDB = -48
tuning.minimumRatio = 1
assert((try! tuning.consume(noise,sampleRate:48000)).last?.active == false)
tuning.minimumRatio = 0.12
assert((try! tuning.consume(noise,sampleRate:48000)).contains { $0.active })
print("PASS live energy, ratio and flatness threshold changes")
