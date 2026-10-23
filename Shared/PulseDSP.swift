// 마이크 PCM을 받아 공기 주입 소리의 특징과 상태를 계산하는 공통 분석기입니다.
// iPhone에서 분석하고 판정만 Watch에 전송하므로, 여기에는 화면이나 진동 코드가 없습니다.
import Foundation // 수학 함수·오류 객체를 사용합니다.
import Accelerate // Apple의 최적화된 FFT(vDSP)로 주파수 에너지를 계산합니다.

// Steam Pulse v3 웹 프로토타입과 같은 주파수 대역과 전환 규칙을 사용한다.
// 한 분석 창의 측정값과 판정 결과. active는 화면의 공기음 표시,
// suppressed는 전환 감지로 인한 표시 차단, pulse는 이번 창에서 진동을 요청할지 뜻합니다.
struct PulseResult {
    // 녹음 시작부터 이 분석 결과까지의 시간입니다. 그래프와 지속 시간 계산에 사용합니다.
    var time: Double
    // 전체 음량, 고역 음량, 고역 비율, 평탄도, 비교용 두 대역의 측정값입니다.
    var db, highDB, ratio, flatness, lowerDB, upperDB: Double
    // 감지 상태·전환 차단 상태·이번 결과의 진동 요청을 따로 보관합니다.
    var active = false, suppressed = false, pulse = false
    // 직전 소리보다 상단 대역과 대역 간 기울기가 얼마나 줄었는지입니다.
    var upperDrop = 0.0, tiltDrop = 0.0
    #if os(iOS)
    // iPhone 진단 화면에 실제 적용 기준을 보여 주어 슬라이더 값과 비교합니다.
    var appliedHighDB = -48.0, appliedRatio = 0.12, appliedFlatness = 0.12
    // 순간값보다 안정적인 하단 대역 크기를 진단 화면에 노출합니다.
    var smoothedLowerDB = -160.0
    // 이전 후보 소리와 비교할 기준이 만들어졌는지 표시합니다.
    var hasReference = false
    // 진입·해제·전환 조건이 각각 얼마나 오래 이어졌는지 보여 줍니다.
    var candidateSeconds = 0.0, releaseSeconds = 0.0, transitionSeconds = 0.0
    #endif
}
final class PulseDSP {
    // 48kHz 입력 기준 약 43ms를 살펴보고 약 11ms마다 다음 결과를 냅니다.
    private let n = 2048, hop = 512
    // FFT 준비 객체는 창마다 만들면 느리므로 분석기 생애 동안 재사용합니다.
    // 2048은 지원되는 길이라 생성 성공을 가정하며, !는 실패 시 즉시 중단하게 합니다.
    private let setup = vDSP_DFT_zop_CreateSetupD(nil, 2048, .FORWARD)!
    // Hann 창은 프레임 양끝을 부드럽게 해 주파수 누출을 줄입니다.
    private let window = (0..<2048).map { 0.5 - 0.5 * cos(2 * Double.pi * Double($0) / 2047) }
    // pending은 아직 분석하지 못한 샘플, rate는 고정 입력률, samples는 시간축입니다.
    private var pending: [Float] = [], rate = 0.0, samples = 0
    // 각 조건의 연속 지속 시간을 누적해 순간적인 소리에 흔들리지 않게 합니다.
    private var on = 0.0, off = 0.0, transition = 0.0, recovery = 0.0, quiet = 0.0
    // active와 suppressed는 다음 프레임에도 이어지는 판정 상태입니다.
    private var active = false, suppressed = false
    // 상단·하단 대역을 평활화해 순간 튐보다 지속적인 변화를 봅니다.
    private var smooth: (upper: Double, lower: Double)?
    // 최근 후보 소리를 보관해 새 소리와 비교할 기준을 만듭니다.
    private var history: [(time: Double, upper: Double, tilt: Double)] = []
    // 차단 중에는 직전 기준을 고정해 복귀 시점을 판단합니다.
    private var reference: (upper: Double, tilt: Double)?
    // 진동은 고역 크기의 상승과 마지막 진동 시각을 함께 보고 제한합니다.
    // -무한대는 첫 진동의 350ms 간격 검사를 통과시키기 위한 초기값입니다.
    private var envelope = 0.0, lastPulse = -Double.infinity
    // 아래 세 값은 공기음 후보가 되기 위한 최소 조건이며 iPhone에서 조절할 수 있습니다.
    var minimumHighDB = -48.0
    var minimumRatio = 0.12
    var minimumFlatness = 0.12
    // Accelerate가 할당한 FFT 준비 객체를 사용 종료 시 반납합니다.
    deinit { vDSP_DFT_DestroySetupD(setup) }

    // 오디오 탭에서 받은 조각을 이어 붙여 일정한 크기의 분석 창으로 만듭니다.
    // 입력 조각 길이가 달라도 같은 연속 음성이라면 판정 결과가 같아야 합니다.
    func consume(_ input: [Float], sampleRate: Double) throws -> [PulseResult] {
        // 잘못된 값이나 중간에 바뀐 샘플레이트는 주파수 계산을 깨뜨리므로 거부합니다.
        guard sampleRate.isFinite, (32000...192000).contains(sampleRate), input.allSatisfy(\.isFinite), rate == 0 || rate == sampleRate else {
            throw NSError(domain: "Puffin", code: 1, userInfo: [NSLocalizedDescriptionKey: "32kHz 이상의 고정된 마이크 입력이 필요합니다. 입력 장치를 확인해 주세요."])
        }
        // 새 샘플을 앞선 미처리 샘플 뒤에 붙여 창 경계의 소리를 잃지 않습니다.
        rate = sampleRate; pending += input
        // 한 번의 입력 호출에서 여러 분석 창이 완성될 수 있어 결과를 배열로 모읍니다.
        var output: [PulseResult] = [], cursor = 0
        while pending.count - cursor >= n {
            // 창은 hop만큼 이동하므로 분석 시각도 이 간격으로 전진합니다.
            samples += hop
            // FFT 계산은 Double 배열을 사용하므로 Float PCM을 변환합니다.
            let frame = pending[cursor..<(cursor+n)].map(Double.init)
            // 창 함수를 적용한 뒤 FFT로 시간에 따른 진동을 주파수별 에너지로 바꿉니다.
            let real = zip(frame, window).map(*), imaginary = [Double](repeating: 0, count: n)
            // 입력/출력 배열을 구분해 실수 신호의 복소 FFT 결과를 받습니다.
            var re = imaginary, im = imaginary
            vDSP_DFT_ExecuteD(setup, real, imaginary, &re, &im)
            // total은 고역 비율의 분모, high는 공기음 후보의 주된 대역입니다.
            // lower/upper는 이후 '상단 대역 감소'를 비교하는 데 사용합니다.
            var total = 0.0, high = 0.0, lower = 0.0, upper = 0.0, sum = 0.0, logSum = 0.0, count = 0.0
            for k in 1..<(n/2) {
                // FFT 칸 번호를 Hz로 바꾸고 복소 성분 제곱합을 에너지로 사용합니다.
                let hz = Double(k)*rate/Double(n), p = re[k]*re[k]+im[k]*im[k]
                // 전체 기준 대역은 고역 비율의 분모입니다.
                if hz >= 200 && hz < 16000 { total += p }
                // 4–12kHz는 공기음 후보의 주 대역입니다.
                if hz >= 4000 && hz < 12000 { high += p }
                // 4–8kHz는 상단 주파수 감소를 비교할 때의 하단 기준입니다.
                if hz >= 4000 && hz < 8000 { lower += p }
                // 12–16kHz는 전환 시 특히 줄어드는지를 살펴봅니다.
                if hz >= 12000 && hz < 16000 { upper += p }
                // 2–12kHz 에너지의 산술·기하 평균으로 평탄도를 계산할 준비를 합니다.
                if hz >= 2000 && hz < 12000 { sum += p; logSum += log(max(p, 1e-30)); count += 1 }
            }
            // 창 함수로 줄어든 에너지를 보정해 대역 크기를 dBFS로 환산합니다.
            let normalization = 2 / (Double(n)*window.reduce(0) { $0+$1*$1 })
            // 매우 작은 값을 0으로 두면 log10이 무한대로 가므로 하한을 둡니다.
            func db(_ power: Double) -> Double { 10*log10(max(power*normalization, 1e-16)) }
            // dBFS는 디지털 입력 크기이며 실제 공간의 소음계 dB SPL은 아닙니다.
            // ratio는 고역 비중, flatness는 에너지가 여러 주파수에 퍼진 정도입니다.
            var r = PulseResult(time: Double(samples+n-hop)/rate,
                db: 10*log10(max(frame.reduce(0) { $0+$1*$1 }/Double(n), 1e-16)),
                highDB: db(high), ratio: high/max(total, 1e-30), flatness: sum > 1e-25 ? exp(logSum/count)/(sum/count) : 0,
                lowerDB: db(lower), upperDB: db(upper))
            // 측정값에 시간 누적 판정을 적용한 뒤 이 창을 결과에 추가합니다.
            update(&r, dt: Double(hop)/rate); output.append(r); cursor += hop
        }
        // 이미 처리한 구간만 버리고 다음 창과 겹칠 샘플은 남깁니다.
        if cursor > 0 { pending.removeFirst(cursor) }
        return output
    }

    // 숫자 한 번으로 바로 켜거나 끄지 않고, 지속 시간과 직전 소리의 변화를 반영합니다.
    private func update(_ r: inout PulseResult, dt: Double) {
        // 사용자가 조절하는 세 입력 조건은 모두 충족해야 합니다.
        let base = r.highDB >= minimumHighDB && r.ratio >= minimumRatio && r.flatness >= minimumFlatness
        // dt가 달라도 약 50ms의 평활 시간 특성이 유지되도록 계수를 계산합니다.
        let alpha = 1-exp(-dt/0.05)
        // 고·저 대역의 순간 튐을 줄이고, 최근 1.2초를 전환 비교 기준으로 보관합니다.
        if smooth == nil { smooth = (r.upperDB, r.lowerDB) }
        // 현재 값 쪽으로 조금씩 이동시켜 대역 측정값을 평활화합니다.
        smooth!.upper += alpha*(r.upperDB-smooth!.upper); smooth!.lower += alpha*(r.lowerDB-smooth!.lower)
        // 두 대역 간 차이(tilt)도 함께 봐야 전체 음량 변화와 모양 변화를 구분할 수 있습니다.
        let upper = smooth!.upper, lower = smooth!.lower, tilt = upper-lower
        // 고역이 기준보다 12dB 이상 낮은 시간이 계속되면 이전 소리와의 비교를 초기화합니다.
        quiet = r.highDB < minimumHighDB-12 ? quiet+dt : 0
        if quiet >= 0.6 { suppressed = false; reference = nil; history = []; transition = 0; recovery = 0 }
        // 오래된 후보 소리는 현재 상태를 설명하지 못하므로 1.2초 밖의 기록을 버립니다.
        history.removeAll { r.time-$0.time > 1.2 }
        // 차단 중에는 고정된 기준을, 평상시에는 최근 후보 소리의 평균을 사용합니다.
        var ref = suppressed ? reference : nil
        if !suppressed && !history.isEmpty { ref = (history.reduce(0) { $0+$1.upper }/Double(history.count), history.reduce(0) { $0+$1.tilt }/Double(history.count)) }
        // 양수 감소량이 클수록 현재 상단 대역이 이전 후보보다 약해졌다는 뜻입니다.
        r.upperDrop = ref.map { $0.upper-upper } ?? 0; r.tiltDrop = ref.map { $0.tilt-tilt } ?? 0
        // shortcut: 녹음 9·18에 맞춘 기준으로, 다른 마이크 적용 전 정답 녹음으로 검증해야 한다.
        // 상단 주파수가 기준보다 충분히 줄면 공기음 표시를 잠시 차단합니다.
        let dropping = ref != nil && r.upperDrop >= 10 && r.tiltDrop >= 6 && lower >= -55
        // 감소 조건이 끊기면 누적 시간을 다시 0으로 돌려 단발성 잡음을 제외합니다.
        transition = dropping ? transition+dt : 0
        // 120ms 지속되면 표시를 즉시 끄고 비교 기준을 고정합니다.
        if !suppressed && transition >= 0.12 { suppressed = true; reference = ref; active = false; on = 0 }
        // 차단 전에 비슷했던 대역 모양이 회복되어야 다시 공기음 후보를 받아들입니다.
        // suppressed가 참일 때만 reference!에 도달하며, 차단 시 ref를 저장합니다.
        let returning = suppressed && base && upper >= reference!.upper-6 && tilt >= reference!.tilt-6
        recovery = returning ? recovery+dt : 0
        if suppressed && recovery >= 0.12 { suppressed = false; history = []; transition = 0; recovery = 0 }
        // 차단되지 않은 후보만 다음 전환 비교 기준으로 쌓습니다.
        if !suppressed && base && upper >= -60 { history.append((r.time, upper, tilt)) }
        // 진입 120ms, 해제 220ms: 짧은 잡음이나 끊김에 화면 상태가 흔들리지 않게 합니다.
        let hit = base && !suppressed, previous = active
        // 연속 통과 시간과 연속 미통과 시간을 별도로 셉니다.
        on = hit ? on+dt : 0; off = hit ? 0 : off+dt
        if !active && on >= 0.12 { active = true }; if active && off >= 0.22 { active = false }
        let amp = pow(10, r.highDB/20), peak = amp > envelope*1.28 && amp > pow(10, minimumHighDB/20)
        // 최근 고역 크기의 지수 평균은 재상승(peak)의 비교 기준입니다.
        envelope = 0.86*envelope+0.14*amp
        // 진동 요청은 active가 처음 켜질 때 또는 고역 크기가 다시 상승할 때만 냅니다.
        // 최소 350ms 간격은 과도한 연속 진동을 막습니다.
        r.pulse = active && r.time-lastPulse >= 0.35 && (!previous || peak)
        // 다음 진동과 최소 간격을 지키기 위해 발생 시각을 기록합니다.
        if r.pulse { lastPulse = r.time }
        // 화면과 Monitor가 읽을 최종 상태를 결과 객체에 복사합니다.
        r.active = active; r.suppressed = suppressed
        #if os(iOS)
        // 아래 값은 iPhone의 진단 패널에 보여 주기 위한 내부 상태입니다.
        r.appliedHighDB = minimumHighDB; r.appliedRatio = minimumRatio; r.appliedFlatness = minimumFlatness
        r.smoothedLowerDB = lower; r.hasReference = ref != nil
        r.candidateSeconds = on; r.releaseSeconds = off; r.transitionSeconds = transition
        #endif
    }
}
