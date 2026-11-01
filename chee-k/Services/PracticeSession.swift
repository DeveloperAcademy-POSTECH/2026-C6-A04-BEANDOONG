//
//  PracticeSession.swift
//
//  iPhone에서 연습 상태와 녹음을 관리하는 파일입니다.
//  iPhone 버튼과 워치 요청이 같은 시작·종료 로직을 사용하며, 녹음 파일과 기록을 iPhone에 저장합니다.
//  변경된 상태는 WatchConnection으로 전달합니다. 소리 분석 결과는 updateFeedback(_:)에 연결합니다.
//

import AVFAudio
import Combine
import UIKit

// 화면 상태 변경과 시작·종료 처리를 메인 액터에서 순서대로 실행합니다.
@MainActor
final class PracticeSession: NSObject, ObservableObject, AVAudioRecorderDelegate {
    // iPhone 버튼과 워치 요청이 함께 사용하는 연습 상태입니다.
    // @Published: 값이 바뀌면 이를 관찰하는 화면도 갱신됩니다.
    // private(set): 화면에서는 읽기만 하고, 상태 변경은 이 관리자 안에서 처리합니다.
    @Published private(set) var state = PracticeState()
    // 화면에서 안내창으로 보여줄 오류 메시지입니다.
    @Published var errorMessage: String?
    // 워치와 메시지를 주고받는 통신 담당입니다. 실제 녹음은 이 클래스가 처리합니다.
    let connection: WatchConnection
    // 현재 녹음 중인 녹음기를 보관합니다. 연습이 끝나면 nil로 비웁니다.
    private var recorder: AVAudioRecorder?
    // 마이크 소리를 모델로 분석하는 담당이며 연습과 함께 시작·종료합니다.
    private var soundAnalyzer: SteamingAudioAnalyzer?
    // 마이크 권한을 기다리는 동안 시작 버튼을 다시 눌러도 요청이 겹치지 않게 합니다.
    private var isStarting = false
    // 전화 등으로 오디오 사용이 중단되는 알림의 구독을 보관합니다.
    private var interruptionObserver: NSObjectProtocol?
    // 녹음 파일과 기록 목록을 저장하는 iPhone 내부 폴더입니다.
    private let directory: URL

    /// 관리자를 처음 만들 때 저장된 기록을 불러오고, 워치 요청을 받을 동작을 연결합니다.
    /// 여기서는 녹음을 시작하지 않습니다.
    init(connection: WatchConnection) {
        self.connection = connection
        directory = URL.documentsDirectory.appending(path: "PracticeRecordings", directoryHint: .isDirectory)
        super.init()
        // 객체가 새로 생성되어도 이전에 파일로 저장한 연습 기록은 다시 불러옵니다.
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let index = directory.appending(path: "records.json")
            if FileManager.default.fileExists(atPath: index.path) {
                state.records = try JSONDecoder().decode([PracticeRecord].self, from: Data(contentsOf: index))
            }
        } catch { errorMessage = error.localizedDescription }
        // WatchConnection이 워치 요청을 받으면 이 클로저를 실행합니다.
        // [weak self]는 두 객체가 서로를 계속 붙잡아 해제되지 않는 것을 방지합니다.
        connection.onCommand = { [weak self] request in
            guard let self else { throw ConnectionError.message("iPhone 앱을 열어주세요.") }
            // 동기화 요청에는 중단 안내만 응답하고, 워치의 시작·종료 요청은 거절합니다.
            guard request.command == .sync || self.state.isWatchEnabled else {
                throw ConnectionError.message("iPhone에서 워치 없이 연습 중이에요.")
            }
            switch request.command {
            case .sync: break // 녹음 동작 없이 아래에서 현재 상태만 응답합니다.
            case .start:
                guard !self.isStarting else {
                    throw ConnectionError.message("iPhone에서 연습을 시작하고 있어요. 잠시 기다려주세요.")
                }
                // 워치 요청에서는 권한 팝업을 띄우지 않고, iPhone에서 미리 허용했는지 확인합니다.
                guard MicrophonePermission.isGranted else {
                    throw ConnectionError.message("iPhone에서 마이크 권한을 허용해주세요.")
                }
                try self.startRecording() // iPhone 버튼과 같은 녹음 함수를 사용합니다.
            case .stop:
                // 이전 연습에 대한 종료 요청이 뒤늦게 와서 새 연습을 종료하지 않도록 확인합니다.
                guard request.sessionID == self.state.sessionID else {
                    throw ConnectionError.message("연습 상태가 변경되었어요. 다시 확인해주세요.")
                }
                self.stop()
            }
            return self.state.watchSnapshot // 재연결·상태 요청도 이번 연습의 워치 사용 설정을 따릅니다.
        }
        // 불러온 기록을 포함한 초기 상태를 통신 담당에게 전달합니다.
        publish()
        // 연습 중 오디오 사용이 중단되면 녹음을 종료하고 사용자에게 안내합니다.
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.didBecomeInactiveNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.state.phase.isRunning else { return }
                self.stop()
                self.errorMessage = "오디오 사용이 중단되어 연습을 종료했어요."
            }
        }
    }

    /// iPhone의 연습 시작 버튼에서 호출합니다. 권한을 확인한 뒤 녹음을 시작합니다.
    func start(usingWatch: Bool = true) async {
        guard !isStarting, !state.phase.isRunning else { return }
        isStarting = true
        defer { isStarting = false } // 함수가 어떤 경로로 끝나든 시작 처리 중 상태를 해제합니다.
        guard await MicrophonePermission.request() else {
            errorMessage = "설정에서 마이크 권한을 허용해주세요."
            return
        }
        do { try startRecording(usingWatch: usingWatch) }
        catch { errorMessage = error.localizedDescription }
    }

    /// 두 기기의 시작 요청이 최종적으로 사용하는 공통 녹음 처리입니다.
    /// 같은 관리자를 유지하되, 새 연습을 시작할 때 새 연습 ID와 녹음 파일을 만듭니다.
    private func startRecording(usingWatch: Bool = true) throws {
        // 어느 기기에서 요청하든 이미 연습 중이라면 중복 녹음을 시작하지 않습니다.
        guard !state.phase.isRunning else { return }
        // 워치 요청으로 백그라운드 앱이 깨어나도 iOS는 새 마이크 녹음을 허용하지 않습니다.
        guard UIApplication.shared.applicationState == .active else {
            throw ConnectionError.message("녹음을 시작하려면 iPhone에서 chic 앱을 열어주세요.")
        }
        let analyzer = try SteamingAudioAnalyzer()
        // 앱이 마이크 입력을 사용할 수 있도록 오디오 세션을 준비합니다.
        let audio = AVAudioSession.sharedInstance()
        try audio.setCategory(.record, mode: .measurement)
        try audio.setActive(true)
        // 이전 연습과 구분되는 ID를 만들고, 같은 ID를 녹음 파일명에도 사용합니다.
        let id = UUID()
        let url = directory.appending(path: "\(id.uuidString).m4a")
        do {
            let recorder = try AVAudioRecorder(url: url, settings: [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ])
            recorder.delegate = self
            guard recorder.record() else { throw ConnectionError.message("녹음을 시작할 수 없어요.") }
            self.recorder = recorder // 녹음 중 녹음기가 사라지지 않도록 관리자가 보관합니다.
            try analyzer.start(onResult: { [weak self] phase in
                Task { @MainActor [weak self] in
                    guard let self, self.state.sessionID == id else { return }
                    self.updateFeedback(phase)
                }
            }, onError: { [weak self] message in
                Task { @MainActor [weak self] in
                    guard let self, self.state.sessionID == id, self.state.phase.isRunning else { return }
                    self.stop()
                    self.errorMessage = message
                }
            })
            soundAnalyzer = analyzer
        } catch {
            analyzer.stop()
            recorder?.stop()
            recorder = nil
            try? FileManager.default.removeItem(at: url)
            // 녹음 시작에 실패하면 사용하려던 오디오 세션을 정리하고 오류를 호출자에게 전달합니다.
            try? audio.setActive(false)
            throw error
        }
        // 녹음 시작에 성공한 뒤에만 새 연습 상태로 바꿉니다. 이전 기록 목록은 유지합니다.
        state.isWatchEnabled = usingWatch
        state.sessionID = id
        state.startedAt = Date()
        state.endedAt = nil // 이전 연습의 종료 시간이 새 연습에 남지 않게 합니다.
        state.phase = .listening
        publish()
    }

    /// iPhone 정지 버튼/X 또는 워치 종료 요청에서 호출합니다.
    /// 녹음을 끝내고 기록을 저장하며, .finished로 바꿔 결과 화면을 표시하게 합니다.
    func stop() {
        // 이미 종료된 연습이면 다시 저장하지 않습니다.
        guard state.phase.isRunning, let recorder, let id = state.sessionID,
              let startedAt = state.startedAt else { return }
        let endedAt = Date()
        soundAnalyzer?.stop()
        soundAnalyzer = nil
        recorder.stop()
        self.recorder = nil // 녹음기만 정리합니다. PracticeSession 객체는 계속 유지됩니다.
        try? AVAudioSession.sharedInstance().setActive(false)
        state.endedAt = endedAt
        state.phase = .finished
        // 녹음 파일 자체와 별도로, 시간·파일명 등의 기록 정보를 최신순으로 보관합니다.
        state.records.insert(PracticeRecord(id: id, startedAt: startedAt, endedAt: endedAt,
                                           audioFilename: recorder.url.lastPathComponent), at: 0)
        // 앱을 다시 실행해도 기록이 남도록 목록을 JSON 파일로 저장합니다.
        do {
            try JSONEncoder().encode(state.records).write(to: directory.appending(path: "records.json"), options: .atomic)
        } catch { errorMessage = "녹음은 남아 있지만 기록 목록 저장에 실패했어요: \(error.localizedDescription)" }
        publish()
    }

    /// 모델 분석 결과나 디버그 메뉴에서 받은 상태를 적용합니다.
    /// 상태를 바꾸면 iPhone 화면이 갱신되고 같은 상태를 워치에도 전달합니다.
    func updateFeedback(_ phase: PracticePhase) {
        // 종료 후 늦게 도착한 분석 결과로 연습 화면이 다시 열리지 않게 합니다.
        guard state.phase.isRunning, phase.isRunning, state.phase != phase else { return }
        state.phase = phase
        publish()
    }

    /// 결과 화면에서 '다시 연습'을 눌렀을 때 호출합니다.
    /// .idle로 돌아가 연습 화면을 닫으며, 저장된 파일과 기록은 삭제하지 않습니다.
    func finishReview() {
        guard state.phase == .finished else { return }
        state.phase = .idle
        // 워치 제외는 이번 연습에만 적용합니다. 다시 연습을 선택하면 다음 연습을 준비합니다.
        state.isWatchEnabled = true
        publish()
    }

    /// 연결이 끊긴 연습을 워치 없이 계속합니다. 진행 중인 iPhone 녹음은 유지합니다.
    func continueWithoutWatch() {
        guard state.phase.isRunning else { return }
        state.isWatchEnabled = false
        publish()
    }

    /// 현재 상태를 통신 담당에게 전달합니다. 실제 전송 방식은 WatchConnection이 처리합니다.
    private func publish() {
        // 워치가 새 상태와 뒤늦게 도착한 예전 상태를 구분할 때 사용하는 시각입니다.
        state.updatedAt = Date()
        // 워치 제외 여부와 최근 20건 제한은 일반 전송·상태 요청에서 같은 규칙을 사용합니다.
        connection.publish(state.watchSnapshot)
    }

    // 녹음기가 인코딩 오류를 알려주는 AVAudioRecorderDelegate 콜백입니다.
    // 콜백은 메인 액터 밖에서도 호출될 수 있어, 상태 변경은 Task 안에서 메인 액터로 옮깁니다.
    nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        Task { @MainActor in
            self.stop()
            self.errorMessage = error?.localizedDescription ?? "녹음 중 오류가 발생했어요."
        }
    }
}
