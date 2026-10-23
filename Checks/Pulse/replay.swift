// 녹음을 48kHz 모노 PCM으로 변환해 앱의 PulseDSP를 그대로 재생하는 오프라인 진단 도구입니다.
// ffmpeg는 검사할 때만 사용하며 앱 빌드나 실시간 마이크 경로에는 들어가지 않습니다.
import Foundation

@main
struct PulseReplay {
    // 실제 시작·끝을 아는 구간만 정답으로 입력합니다. 미확인 구간은 평가에서 제외합니다.
    struct Interval { let start: Double, end: Double }

    static func main() throws {
        let args = Array(CommandLine.arguments.dropFirst())
        guard let path = args.first, !path.hasPrefix("--") else {
            print("사용법: replay 녹음.m4a [--positive 시작:끝] [--negative 시작:끝] [--ignore 시작:끝] [--csv 결과.csv] [--source live|speaker] [--legacy]")
            return
        }
        var positives: [Interval] = [], negatives: [Interval] = [], ignores: [Interval] = []
        var csvPath: String?, source = "live", legacy = false
        var index = 1
        while index < args.count {
            if args[index] == "--legacy" { legacy = true; index += 1; continue }
            guard index+1 < args.count else { throw error("옵션 \(args[index])의 값이 없습니다.") }
            let key = args[index], value = args[index+1]
            switch key {
            case "--positive": positives.append(try interval(value))
            case "--negative": negatives.append(try interval(value))
            case "--ignore": ignores.append(try interval(value))
            case "--csv": csvPath = value
            case "--source":
                guard value == "live" || value == "speaker" else { throw error("source는 live 또는 speaker입니다.") }
                source = value
            default: throw error("알 수 없는 옵션: \(key)")
            }
            index += 2
        }
        // ffmpeg가 압축 파일·샘플레이트·채널 수를 동일한 입력 형식으로 맞춥니다.
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["ffmpeg", "-v", "error", "-i", path, "-f", "f32le", "-acodec", "pcm_f32le", "-ac", "1", "-ar", "48000", "-"]
        let pipe = Pipe(); process.standardOutput = pipe; process.standardError = FileHandle.standardError
        try process.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0, data.count.isMultiple(of: MemoryLayout<Float>.size) else { throw error("오디오 변환에 실패했습니다.") }
        // Data의 정렬 상태에 의존하지 않도록 Float 배열로 복사합니다.
        var samples = [Float](repeating: 0, count: data.count/MemoryLayout<Float>.size)
        _ = samples.withUnsafeMutableBytes { data.copyBytes(to: $0) }
        let dsp = PulseDSP()
        dsp.enableFastOnset = !legacy
        var results: [PulseResult] = []
        // 입력 탭과 비슷하게 나눠도 DSP는 샘플 순서대로 연속 분석합니다.
        for start in stride(from: 0, to: samples.count, by: 1024) {
            results += try dsp.consume(Array(samples[start..<min(start+1024, samples.count)]), sampleRate: 48000)
        }
        guard !results.isEmpty else { throw error("분석할 오디오가 너무 짧거나 비어 있습니다.") }
        // CSV는 각 프레임의 판정 근거를 남겨 미탐·오탐이 생긴 시각을 찾는 용도입니다.
        if let csvPath {
            var lines = ["time,source,label,highDB,ratio,flatness,relativeHighDB,onsetRiseDB,highFlux,baseCandidate,fastCandidate,suppressed,active,pulse,reason"]
            for r in results {
                let label = ignores.contains { $0.start <= r.time && r.time <= $0.end } ? "ignore"
                    : positives.contains { $0.start <= r.time && r.time <= $0.end } ? "positive"
                    : negatives.contains { $0.start <= r.time && r.time <= $0.end } ? "negative" : "unlabeled"
                let reasons = [r.highDB < -48 ? "lowHighDB" : nil,
                               r.ratio < 0.12 ? "lowRatio" : nil,
                               r.flatness < 0.12 ? "lowFlatness" : nil,
                               r.suppressed ? "suppressed" : nil].compactMap { $0 }.joined(separator: "+")
                lines.append(String(format: "%.4f,%@,%@,%.2f,%.4f,%.4f,%.2f,%.2f,%.4f,%d,%d,%d,%d,%d,%@",
                    r.time, source, label, r.highDB, r.ratio, r.flatness, r.relativeHighDB, r.onsetRiseDB, r.highFlux,
                    r.baseCandidate ? 1 : 0, r.fastCandidate ? 1 : 0, r.suppressed ? 1 : 0, r.active ? 1 : 0, r.pulse ? 1 : 0,
                    reasons.isEmpty ? "none" : reasons))
            }
            try lines.joined(separator: "\n").write(toFile: csvPath, atomically: true, encoding: .utf8)
        }
        // 상태가 켜진 연속 구간을 출력해 화면에서 보이는 예상 결과를 확인합니다.
        var starts: Double?, detections: [Interval] = []
        for r in results {
            if r.active && starts == nil { starts = r.time }
            if !r.active, let start = starts { detections.append(Interval(start: start, end: r.time)); starts = nil }
        }
        if let start = starts { detections.append(Interval(start: start, end: results.last!.time)) }
        print("source=\(source), mode=\(legacy ? "legacy" : "fast"), duration=\(String(format: "%.2f", results.last!.time))s, frames=\(results.count)")
        for d in detections { print(String(format: "감지 %.2f–%.2fs", d.start, d.end)) }
        // 정답 구간이 없는 녹음은 탐지 목록만 보여 주고 정확도 수치를 만들지 않습니다.
        for p in positives {
            let first = results.first { r in
                r.time >= p.start && r.time <= p.end && r.active
                    && !ignores.contains { ignored in ignored.start <= r.time && r.time <= ignored.end }
            }
            if let first { print(String(format: "정답 %.2f–%.2fs: 감지, 시작 후 %.3fs", p.start, p.end, max(0, first.time-p.start))) }
            else { print(String(format: "정답 %.2f–%.2fs: 미감지", p.start, p.end)) }
        }
        // 오탐 평가는 확실히 공기 주입이 없다고 표시한 구간에서만 합니다.
        for n in negatives {
            let active = results.filter { r in
                r.time >= n.start && r.time <= n.end && r.active
                    && !ignores.contains { ignored in ignored.start <= r.time && r.time <= ignored.end }
            }
            print(String(format: "비공기음 %.2f–%.2fs: 감지 프레임 %d개", n.start, n.end, active.count))
        }
        if csvPath != nil { print("프레임 진단 CSV: \(csvPath!)") }
    }

    // 잘못된 구간 표기는 조용히 건너뛰지 않고 알려 줍니다.
    static func interval(_ value: String) throws -> Interval {
        let parts = value.split(separator: ":")
        guard parts.count == 2, let start = Double(parts[0]), let end = Double(parts[1]), start.isFinite, end.isFinite, start >= 0, end > start else {
            throw error("구간은 시작:끝 초로 입력해 주세요: \(value)")
        }
        return Interval(start: start, end: end)
    }
    static func error(_ message: String) -> NSError {
        NSError(domain: "PulseReplay", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
    }
}
