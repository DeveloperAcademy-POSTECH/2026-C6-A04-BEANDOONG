import AVFAudio
import Foundation
import OSLog

/// 발표용 피드백에서만 사용하는 소리입니다. 초록의 롤링 소리만 종료까지 반복합니다.
@MainActor
final class PresentationSteamSound {
    private let logger = Logger(subsystem: "com.beandoong.chic", category: "PresentationAudio")
    private var player: AVAudioPlayer?
    private var isSessionActive = false

    func play(_ presentation: PresentationPractice) {
        let name: String
        switch presentation.phase {
        case .aeration:
            name = presentation.stepDuration > 1.5 ? "PresentationAerationLong" : "PresentationAeration"
        case .bubble: name = "PresentationBubble"
        case .moreAir: name = "PresentationMoreAir"
        case .milkFlow: name = "PresentationRolling"
        default:
            stop()
            return
        }

        player?.stop()
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else {
            logger.error("발표용 소리를 찾을 수 없어요: \(name, privacy: .public)")
            stop()
            return
        }

        do {
            let next = try AVAudioPlayer(contentsOf: url)
            next.numberOfLoops = presentation.phase == .milkFlow ? -1 : 0
            next.prepareToPlay()
            if !isSessionActive {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playback, mode: .default)
                try session.setActive(true)
                isSessionActive = true
            }
            player = next
            if !next.play() {
                logger.error("발표용 소리를 재생할 수 없어요: \(name, privacy: .public)")
                stop()
            }
        } catch {
            logger.error("발표용 소리 재생 실패: \(error.localizedDescription, privacy: .public)")
            stop()
        }
    }

    func stop() {
        player?.stop()
        player = nil
        guard isSessionActive else { return }
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            isSessionActive = false
        } catch {
            logger.error("발표용 오디오 세션 종료 실패: \(error.localizedDescription, privacy: .public)")
        }
    }
}
