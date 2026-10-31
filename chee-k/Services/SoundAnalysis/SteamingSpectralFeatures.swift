import Foundation

/// 모델 학습과 동일한 상대 주파수·시간 이력 특징 273개를 계산합니다.
nonisolated final class SteamingSpectralFeatures {
    private let edges = [200.0,500,1000,2000,3000,4000,5000,6000,7000,8000,9000,10000,11000,12000,13000,14000,15000,16000]
    private let indices = [0,1,2,3,4,5,6,7,8,29]+Array(12..<29)
    private var rmsHistory: [Double] = []
    private var previous: [Double]?
    private var history: [[Double]] = []

    /// 현재 프레임과 과거 프레임만 사용해 모델 입력 순서대로 특징을 반환합니다.
    func consume(frame: [Double], power: [Double], sampleRate: Double, reading: SteamingSpectralReading) -> [Double] {
        let n = frame.count
        var total = 0.0, bands = [Double](repeating:0,count:17), weighted = 0.0, maximum = 0.0
        for k in power.indices {
            let hz = Double(k)*sampleRate/Double(n), p = power[k]
            if hz >= 200 && hz < 16000 { total += p;weighted += p*hz;maximum = max(maximum,p) }
            for b in bands.indices where hz >= edges[b] && hz < edges[b+1] { bands[b] += p;break }
        }
        let fractions = bands.map{$0/max(total,1e-30)}
        func flat(_ lo:Double,_ hi:Double)->Double {
            var sum = 0.0,logs = 0.0,count = 0.0
            for k in power.indices {
                let hz = Double(k)*sampleRate/Double(n)
                if hz >= lo && hz < hi { sum += power[k];logs += log(max(power[k],1e-30));count += 1 }
            }
            return exp(logs/count)/max(sum/count,1e-30)
        }
        let rms = sqrt(frame.reduce(0){$0+$1*$1}/Double(n))
        let crest = (frame.map{abs($0)}.max() ?? 0)/max(rms,1e-8)
        let first = frame.prefix(512).reduce(0){$0+$1*$1}/512
        let last = frame.suffix(512).reduce(0){$0+$1*$1}/512
        let flux = previous.map{zip(fractions,$0).reduce(0){$0+abs($1.0-$1.1)}} ?? 0
        rmsHistory.append(reading.db)
        if rmsHistory.count > 94 {rmsHistory.removeFirst()}
        let rmsMean=rmsHistory.reduce(0,+)/Double(rmsHistory.count)
        let modulation=sqrt(rmsHistory.reduce(0){$0+pow($1-rmsMean,2)}/Double(rmsHistory.count))
        let dynamicRange=rmsHistory.max()!-rmsHistory.min()!
        let entropy = -fractions.reduce(0) {$0 + $1*log(max($1,1e-30))}/log(17.0)
        let base = [reading.highDB-reading.db,reading.ratio,reading.flatness,reading.upperDB-reading.lowerDB,
                    entropy,crest,10*log10(max(last,1e-16)/max(first,1e-16)),
                    weighted/max(total,1e-30)/16000,maximum/max(total,1e-30),modulation,flat(2000,4000),dynamicRange]
                    + fractions.map{10*log10(max($0,1e-8))} + [flux]
        previous = fractions
        let selected = indices.map{base[$0]};history.append(selected)
        if history.count > 38 {history.removeFirst()}
        var result = base
        for count in [5,14,38] {
            let values = history.suffix(count), divisor = Double(values.count)
            var mean = [Double](repeating:0,count:selected.count),square = mean
            for row in values {for i in row.indices {mean[i] += row[i]/divisor;square[i] += row[i]*row[i]/divisor}}
            result += mean
            result += mean.indices.map{sqrt(max(0,square[$0]-mean[$0]*mean[$0]))}
            result += selected.indices.map{selected[$0]-mean[$0]}
        }
        return result
    }
}
