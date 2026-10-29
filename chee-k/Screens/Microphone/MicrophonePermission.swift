import AVFAudio

/// 기기의 실제 마이크 권한을 조회하고 요청합니다. 화면과 이동 상태는 View에서 관리합니다.
enum MicrophonePermission {
    static var isGranted: Bool {
        AVAudioApplication.shared.recordPermission == .granted
    }

    static func request() async -> Bool {
        // iOS는 최초 요청에만 팝업을 표시하며, 이후에는 저장된 선택을 반환합니다.
        await AVAudioApplication.requestRecordPermission()
    }
}
