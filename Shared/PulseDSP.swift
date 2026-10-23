// 마이크 PCM을 받아 공기 주입 소리의 특징과 상태를 계산하는 공통 분석기입니다.
// iPhone과 Watch가 각각 이 파일을 사용하므로, 여기에는 화면이나 진동 코드가 없습니다.
import Foundation
import Accelerate

// Steam Pulse v3 웹 프로토타입과 같은 주파수 대역과 전환 규칙을 사용한다.
// 한 분석 창의 측정값과 판정 결과. active는 화면의 공기음 표시,
// suppressed는 전환 감지로 인한 표시 차단, pulse는 이번 창에서 진동을 요청할지 뜻합니다.
struct PulseResult {
    var time: Double
    var db, highDB, ratio, flatness, lowerDB, upperDB: Double
    var active = false, suppressed = false, pulse = false
    var upperDrop = 0.0, tiltDrop = 0.0
    #if os(iOS)
    var appliedHighDB = -48.0, appliedRatio = 0.12, appliedFlatness = 0.12
    var smoothedLowerDB = -160.0
    var hasReference = false
    var candidateSeconds = 0.0, releaseSeconds = 0.0, transitionSeconds = 0.0
    #endif
}
final class PulseDSP {
    // 48kHz 입력 기준 약 43ms를 살펴보고 약 11ms마다 다음 결과를 냅니다.
    private let n = 2048, hop = 512
    private let setup = vDSP_DFT_zop_CreateSetupD(nil, 2048, .FORWARD)!
    private let window = (0..<2048).map { 0.5 - 0.5 * cos(2 * Double.pi * Double($0) / 2047) }
    private var pending: [Float] = [], rate = 0.0, samples = 0
    private var on = 0.0, off = 0.0, transition = 0.0, recovery = 0.0, quiet = 0.0
    private var active = false, suppressed = false
    private var smooth: (upper: Double, lower: Double)?
    private var history: [(time: Double, upper: Double, tilt: Double)] = []
    private var reference: (upper: Double, tilt: Double)?
    private var envelope = 0.0, lastPulse = -Double.infinity
    var minimumHighDB = -48.0
    var minimumRatio = 0.12
    var minimumFlatness = 0.12
    deinit { vDSP_DFT_DestroySetupD(setup) }

    // 오디오 탭에서 받은 조각을 이어 붙여 일정한 크기의 분석 창으로 만듭니다.
    // 입력 조각 길이가 달라도 같은 연속 음성이라면 판정 결과가 같아야 합니다.
    func consume(_ input: [Float], sampleRate: Double) throws -> [PulseResult] {
        guard sampleRate.isFinite, (32000...192000).contains(sampleRate), input.allSatisfy(\.isFinite), rate == 0 || rate == sampleRate else {
            throw NSError(domain: "Puffin", code: 1, userInfo: [NSLocalizedDescriptionKey: "32kHz 이상의 고정된 마이크 입력이 필요합니다. 입력 장치를 확인해 주세요."])
        }
        rate = sampleRate; pending += input
        var output: [PulseResult] = [], cursor = 0
        while pending.count - cursor >= n {
            samples += hop
            let frame = pending[cursor..<(cursor+n)].map(Double.init)
            // 창 함수를 적용한 뒤 FFT로 시간에 따른 진동을 주파수별 에너지로 바꿉니다.
            let real = zip(frame, window).map(*), imaginary = [Double](repeating: 0, count: n)
            var re = imaginary, im = imaginary
            vDSP_DFT_ExecuteD(setup, real, imaginary, &re, &im)
            // total은 고역 비율의 분모, high는 공기음 후보의 주된 대역입니다.
            // lower/upper는 이후 '상단 대역 감소'를 비교하는 데 사용합니다.
            var total = 0.0, high = 0.0, lower = 0.0, upper = 0.0, sum = 0.0, logSum = 0.0, count = 0.0
            for k in 1..<(n/2) {
                let hz = Double(k)*rate/Double(n), p = re[k]*re[k]+im[k]*im[k]
                if hz >= 200 && hz < 16000 { total += p }
                if hz >= 4000 && hz < 12000 { high += p }
                if hz >= 4000 && hz < 8000 { lower += p }
                if hz >= 12000 && hz < 16000 { upper += p }
                if hz >= 2000 && hz < 12000 { sum += p; logSum += log(max(p, 1e-30)); count += 1 }
            }
            let normalization = 2 / (Double(n)*window.reduce(0) { $0+$1*$1 })
            func db(_ power: Double) -> Double { 10*log10(max(power*normalization, 1e-16)) }
            // dBFS는 디지털 입력 크기이며 실제 공간의 소음계 dB SPL은 아닙니다.
            // ratio는 고역 비중, flatness는 에너지가 여러 주파수에 퍼진 정도입니다.
            var r = PulseResult(time: Double(samples+n-hop)/rate,
                db: 10*log10(max(frame.reduce(0) { $0+$1*$1 }/Double(n), 1e-16)),
                highDB: db(high), ratio: high/max(total, 1e-30), flatness: sum > 1e-25 ? exp(logSum/count)/(sum/count) : 0,
                lowerDB: db(lower), upperDB: db(upper))
            update(&r, dt: Double(hop)/rate); output.append(r); cursor += hop
        }
        if cursor > 0 { pending.removeFirst(cursor) }
        return output
    }

    // 숫자 한 번으로 바로 켜거나 끄지 않고, 지속 시간과 직전 소리의 변화를 반영합니다.
    private func update(_ r: inout PulseResult, dt: Double) {
        // 사용자가 조절하는 세 입력 조건은 모두 충족해야 합니다.
        let base = r.highDB >= minimumHighDB && r.ratio >= minimumRatio && r.flatness >= minimumFlatness
        let alpha = 1-exp(-dt/0.05)
        // 고·저 대역의 순간 튐을 줄이고, 최근 1.2초를 전환 비교 기준으로 보관합니다.
        if smooth == nil { smooth = (r.upperDB, r.lowerDB) }
        smooth!.upper += alpha*(r.upperDB-smooth!.upper); smooth!.lower += alpha*(r.lowerDB-smooth!.lower)
        let upper = smooth!.upper, lower = smooth!.lower, tilt = upper-lower
        quiet = r.highDB < minimumHighDB-12 ? quiet+dt : 0
        if quiet >= 0.6 { suppressed = false; reference = nil; history = []; transition = 0; recovery = 0 }
        history.removeAll { r.time-$0.time > 1.2 }
        var ref = suppressed ? reference : nil
        if !suppressed && !history.isEmpty { ref = (history.reduce(0) { $0+$1.upper }/Double(history.count), history.reduce(0) { $0+$1.tilt }/Double(history.count)) }
        r.upperDrop = ref.map { $0.upper-upper } ?? 0; r.tiltDrop = ref.map { $0.tilt-tilt } ?? 0
        // shortcut: 녹음 9·18에 맞춘 기준으로, 다른 마이크 적용 전 정답 녹음으로 검증해야 한다.
        // 상단 주파수가 기준보다 충분히 줄면 공기음 표시를 잠시 차단합니다.
        let dropping = ref != nil && r.upperDrop >= 10 && r.tiltDrop >= 6 && lower >= -55
        transition = dropping ? transition+dt : 0
        if !suppressed && transition >= 0.12 { suppressed = true; reference = ref; active = false; on = 0 }
        let returning = suppressed && base && upper >= reference!.upper-6 && tilt >= reference!.tilt-6
        recovery = returning ? recovery+dt : 0
        if suppressed && recovery >= 0.12 { suppressed = false; history = []; transition = 0; recovery = 0 }
        if !suppressed && base && upper >= -60 { history.append((r.time, upper, tilt)) }
        // 진입 120ms, 해제 220ms: 짧은 잡음이나 끊김에 화면 상태가 흔들리지 않게 합니다.
        let hit = base && !suppressed, previous = active
        on = hit ? on+dt : 0; off = hit ? 0 : off+dt
        if !active && on >= 0.12 { active = true }; if active && off >= 0.22 { active = false }
        let amp = pow(10, r.highDB/20), peak = amp > envelope*1.28 && amp > pow(10, minimumHighDB/20)
        envelope = 0.86*envelope+0.14*amp
        // 진동 요청은 active가 처음 켜질 때 또는 고역 크기가 다시 상승할 때만 냅니다.
        // 최소 350ms 간격은 과도한 연속 진동을 막습니다.
        r.pulse = active && r.time-lastPulse >= 0.35 && (!previous || peak)
        if r.pulse { lastPulse = r.time }
        r.active = active; r.suppressed = suppressed
        #if os(iOS)
        // 아래 값은 iPhone의 진단 패널에 보여 주기 위한 내부 상태입니다.
        r.appliedHighDB = minimumHighDB; r.appliedRatio = minimumRatio; r.appliedFlatness = minimumFlatness
        r.smoothedLowerDB = lower; r.hasReference = ref != nil
        r.candidateSeconds = on; r.releaseSeconds = off; r.transitionSeconds = transition
        #endif
    }
}
