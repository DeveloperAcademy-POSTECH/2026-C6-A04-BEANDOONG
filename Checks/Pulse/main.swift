// 앱과 분리해 PulseDSP의 기본 동작을 검사하는 명령행 코드입니다.
// 임의 잡음·무음, 입력 조각 크기, 잘못된 입력, 기준값 변경을 확인합니다.
import Foundation // 파일 데이터와 명령행 인자를 읽습니다.

// 고정 시드로 매번 같은 잡음을 만들어 검사 결과를 재현할 수 있게 합니다.
let dsp = PulseDSP()
var seed: UInt32 = 9
func random() -> Float { seed = 1664525 &* seed &+ 1013904223;return Float(Double(seed)/4294967296*2-1)*0.1 }
let noise = (0..<48000).map { _ in random() }
// 넓은 주파수에 퍼진 잡음에서 후보가 생기고 측정값이 유한한지 확인합니다.
let result = try dsp.consume(noise,sampleRate:48000)
assert(result.contains { $0.active })
assert(result.allSatisfy { $0.db.isFinite && $0.upperDB.isFinite && $0.flatness.isFinite })
let silence = try dsp.consume([Float](repeating:0,count:48000),sampleRate:48000)
// 무음 이후에는 이전 잡음 판정이 계속 남아 있으면 안 됩니다.
assert(silence.last?.active == false)
// 선택적으로 전달한 Float32 PCM 파일은 시간 순서대로 재생해 판정 구간을 확인합니다.
let arguments = CommandLine.arguments.dropFirst()
for path in arguments {
    // 선택 입력은 raw 48kHz mono Float32 PCM이어야 같은 샘플 순서로 읽힙니다.
    let data = try Data(contentsOf:URL(fileURLWithPath:path))
    let samples = data.withUnsafeBytes { Array($0.bindMemory(to:Float.self)) }
    // 일부러 777개씩 잘라 실제 오디오 버퍼 길이가 달라도 처리되게 합니다.
    let detector = PulseDSP();var all: [PulseResult] = []
    for start in stride(from:0,to:samples.count,by:777) { all += try detector.consume(Array(samples[start..<min(start+777,samples.count)]),sampleRate:48000) }
    if path.contains("recording18") {
        // 이 검사에서 기대하는 구간이 감지되고 뒤에는 해제되는지 확인합니다.
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
// NaN·지원하지 않는 샘플레이트는 조용히 잘못 판정하지 않고 오류를 내야 합니다.
do { _ = try PulseDSP().consume([Float.nan],sampleRate:48000);assertionFailure() } catch {}
do { _ = try PulseDSP().consume([0],sampleRate:16000);assertionFailure() } catch {}
print("PASS noise, silence, finite values, chunk independence, invalid input")

// 분석기를 다시 만들지 않고 변경된 기준값이 다음 입력부터 반영되는지 검사한다.
let tuning = PulseDSP()
// 조건을 하나씩 일부러 불가능하게 만들어 즉시 판정이 달라지는지 확인합니다.
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

// 70ms 고역 잡음은 기존 120ms 진입보다 짧아 빠른 경로의 실제 이득을 확인합니다.
let background = (0..<48000).map { _ in random()*0.001 }
let burst = (0..<3360).map { _ in random() }
let shortSound = background + burst + [Float](repeating: 0, count: 24000)
let quick = try PulseDSP().consume(shortSound, sampleRate: 48000)
let old = PulseDSP(); old.enableFastOnset = false
let slow = try old.consume(shortSound, sampleRate: 48000)
assert(quick.contains { $0.active && $0.fastCandidate })
assert(!slow.contains { $0.active })
// 큰 저역 단일음은 소리 크기만으로 공기음이 되지 않아야 합니다.
let tone = (0..<3360).map { Float(0.1*sin(2*Double.pi*1000*Double($0)/48000)) }
let lowSound = background + tone + [Float](repeating: 0, count: 24000)
let lowResult = try PulseDSP().consume(lowSound, sampleRate: 48000)
assert(!lowResult.contains { $0.active })
print("PASS short onset and low tone rejection")
