//
//  PracticeSession.swift
//
//  iPhone에서 연습 상태와 실시간 소리 분석을 관리하는 파일입니다.
//  iPhone 버튼과 워치 요청이 같은 시작·종료·결과 확인 완료 로직을 사용하며, 분석 결과만 iPhone에 저장합니다.
//  변경된 상태는 WatchConnection으로 전달합니다. 소리 분석 결과는 updateFeedback(_:)에 연결합니다.
//

import AVFAudio
import Combine
import UIKit

// 화면 상태 변경과 시작·종료 처리를 메인 액터에서 순서대로 실행합니다.
@MainActor
final class PracticeSession: ObservableObject {
    // iPhone 버튼과 워치 요청이 함께 사용하는 연습 상태입니다.
    // @Published: 값이 바뀌면 이를 관찰하는 화면도 갱신됩니다.
    // private(set): 화면에서는 읽기만 하고, 상태 변경은 이 관리자 안에서 처리합니다.
    @Published private(set) var state = PracticeState()
    // 화면에서 안내창으로 보여줄 오류 메시지입니다.
    @Published var errorMessage: String?
    @Published private(set) var history: [PracticeRecordEntity] = []
    @Published private(set) var result: PracticeResult?
    private var historyStore: PracticeHistoryStore?
    private var timeline = PracticeTimeline()
    // 워치와 메시지를 주고받는 통신 담당입니다.
    let connection: WatchConnection
    // 마이크 소리를 모델로 분석하는 담당이며 연습과 함께 시작·종료합니다.
    private var soundAnalyzer: SteamingAudioAnalyzer?
    // 마이크 권한을 기다리는 동안 시작 버튼을 다시 눌러도 요청이 겹치지 않게 합니다.
    private var isStarting = false
    // 전화 등으로 오디오 사용이 중단되는 알림의 구독을 보관합니다.
    private var interruptionObserver: NSObjectProtocol?

    /// 관리자를 처음 만들 때 저장된 기록을 불러오고, 워치 요청을 받을 동작을 연결합니다.
    /// 여기서는 마이크 분석을 시작하지 않습니다.
    init(connection: WatchConnection) {
        self.connection = connection
        // 기존 JSON 기록을 이전한 뒤 SwiftData에서 불러옵니다.
        do {
            let store = try PracticeHistoryStore(
                legacyDirectory: URL.documentsDirectory.appending(path: "PracticeRecordings", directoryHint: .isDirectory)
            )
            setHistory(try store.records())
            historyStore = store
        } catch { errorMessage = "연습 기록 저장소를 열 수 없어요. 앱을 다시 실행해 주세요." }
        // WatchConnection이 워치 요청을 받으면 이 클로저를 실행합니다.
        // [weak self]는 두 객체가 서로를 계속 붙잡아 해제되지 않는 것을 방지합니다.
        connection.onCommand = { [weak self] request in
            guard let self else { throw ConnectionError.message("iPhone 앱을 열어주세요.") }
            // 워치 없이 연습 중이면 동기화 요청에만 응답합니다.
            guard request.command == .sync || self.state.isWatchEnabled else {
                throw ConnectionError.message("iPhone에서 워치 없이 연습 중이에요.")
            }
            switch request.command {
            case .sync: break // 아래에서 현재 상태만 응답합니다.
            case .start:
                guard !self.isStarting else {
                    throw ConnectionError.message("iPhone에서 연습을 시작하고 있어요. 잠시 기다려주세요.")
                }
                // 워치 요청에서는 권한 팝업을 띄우지 않고, iPhone에서 미리 허용했는지 확인합니다.
                guard MicrophonePermission.isGranted else {
                    throw ConnectionError.message("iPhone에서 마이크 권한을 허용해주세요.")
                }
                try self.startAnalysis() // iPhone 버튼과 같은 시작 함수를 사용합니다.
            case .stop:
                // 이전 연습의 종료 요청이 새 연습에 적용되지 않도록 확인합니다.
                guard request.sessionID == self.state.sessionID else {
                    throw ConnectionError.message("연습 상태가 변경되었어요. 다시 확인해주세요.")
                }
                self.stop()
            case .finishReview:
                // 이전 결과 화면의 완료 요청이 새 연습에 적용되지 않도록 확인합니다.
                guard request.sessionID == self.state.sessionID else {
                    throw ConnectionError.message("연습 상태가 변경되었어요. 다시 확인해주세요.")
                }
                self.finishReview()
            }
            return self.connection.state // 동기화 응답에도 일반 전송과 같은 최신 워치 스냅샷을 사용합니다.
        }
        // 불러온 기록을 포함한 초기 상태를 통신 담당에게 전달합니다.
        publish()
        // 연습 중 오디오 사용이 중단되면 분석을 종료하고 사용자에게 안내합니다.
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

    /// iPhone의 연습 시작 버튼에서 호출합니다. 권한을 확인한 뒤 분석을 시작합니다.
    func start(usingWatch: Bool = true) async {
        guard !isStarting, !state.phase.isRunning else { return }
        isStarting = true
        defer { isStarting = false } // 함수가 어떤 경로로 끝나든 시작 처리 중 상태를 해제합니다.
        guard await MicrophonePermission.request() else {
            errorMessage = "설정에서 마이크 권한을 허용해주세요."
            return
        }
        do { try startAnalysis(usingWatch: usingWatch) }
        catch { errorMessage = error.localizedDescription }
    }

    /// 두 기기의 시작 요청이 함께 사용하는 실시간 분석 처리입니다. 소리 원본은 저장하지 않습니다.
    private func startAnalysis(usingWatch: Bool = true) throws {
        // 어느 기기에서 요청하든 이미 연습 중이라면 중복 분석을 시작하지 않습니다.
        guard !state.phase.isRunning else { return }
        guard historyStore != nil else {
            throw ConnectionError.message("연습 기록 저장소를 열 수 없어 연습을 시작하지 못했어요. 앱을 다시 실행해 주세요.")
        }
        // 워치 요청으로 백그라운드 앱이 깨어나도 새 마이크 입력은 시작하지 않습니다.
        guard UIApplication.shared.applicationState == .active else {
            throw ConnectionError.message("연습을 시작하려면 iPhone에서 chic 앱을 열어주세요.")
        }
        let analyzer = try SteamingAudioAnalyzer()
        // 앱이 마이크 입력을 사용할 수 있도록 오디오 세션을 준비합니다.
        let audio = AVAudioSession.sharedInstance()
        try audio.setCategory(.record, mode: .measurement)
        try audio.setActive(true)
        // 이전 연습과 구분되는 ID를 만듭니다.
        let id = UUID()
        do {
            try analyzer.start(onResult: { [weak self] phase in
                Task { @MainActor [weak self] in
                    guard let self, self.state.sessionID == id else { return }
                    self.updateFeedback(phase)
                }
            }, onFinish: { [weak self] in
                Task { @MainActor [weak self] in
                    guard let self, self.state.sessionID == id, self.state.phase.isRunning else { return }
                    self.stop()
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
            // 분석 시작에 실패하면 오디오 세션을 정리하고 오류를 호출자에게 전달합니다.
            try? audio.setActive(false)
            throw error
        }
        // 분석 시작에 성공한 뒤에만 새 연습 상태로 바꿉니다. 이전 기록 목록은 유지합니다.
        state.isWatchEnabled = usingWatch
        timeline = PracticeTimeline()
        result = nil
        state.sessionID = id
        state.startedAt = Date()
        state.endedAt = nil // 이전 연습의 종료 시간이 새 연습에 남지 않게 합니다.
        state.phase = .listening
        publish()
    }

    /// 자동 종료, iPhone 정지 버튼, 워치 종료 요청 또는 오디오 중단·오류 시 호출합니다.
    /// 분석을 끝내고 결과를 저장하며, .finished로 바꿔 결과 화면을 표시하게 합니다.
    func stop() {
        // 이미 종료된 연습이면 다시 저장하지 않습니다.
        guard state.phase.isRunning, let id = state.sessionID,
              let startedAt = state.startedAt else { return }
        let endedAt = Date()
        soundAnalyzer?.stop()
        soundAnalyzer = nil
        try? AVAudioSession.sharedInstance().setActive(false)
        state.endedAt = endedAt
        timeline.finish(at: max(0, endedAt.timeIntervalSince(startedAt)))
        state.phase = .finished
        let record = PracticeRecord(id: id, startedAt: startedAt, endedAt: endedAt)
        let segments = timeline.segments
        let dailyOrder = (history.filter { Calendar.current.isDate($0.startedAt, inSameDayAs: startedAt) }
            .map(\.dailyOrder).max() ?? 0) + 1
        let completedResult = PracticeResult(practicedAt: startedAt, dailyOrder: dailyOrder,
                                              segments: segments, duration: record.duration)
        publish()
        // 종료 상태를 먼저 표시해 로딩 화면을 연 뒤 저장합니다. 워치에서 닫아도 저장은 완료합니다.
        Task {
            await Task.yield()
            do {
                guard let historyStore else { throw ConnectionError.message("저장소를 열 수 없어요.") }
                try historyStore.save(record: record, dailyOrder: dailyOrder, segments: segments)
                setHistory(try historyStore.records())
                publish()
            } catch {
                errorMessage = "연습 결과 저장에 실패했어요."
            }
            if state.sessionID == id, state.phase == .finished { result = completedResult }
        }
    }

    /// 소리가 바뀔 때 구간을 기록하고, 지속되는 공기주입은 워치에만 다시 보냅니다.
    func updateFeedback(_ phase: PracticePhase) {
        // 종료 후 늦게 도착한 분석 결과로 연습 화면이 다시 열리지 않게 합니다.
        guard state.phase.isRunning, phase.isRunning else { return }
        let now = Date()
        if state.phase != phase {
            if let startedAt = state.startedAt {
                timeline.update(phase: phase, at: max(0, now.timeIntervalSince(startedAt)))
            }
            state.phase = phase
        } else {
            guard phase == .aeration, state.isWatchEnabled,
                  now.timeIntervalSince(connection.state.updatedAt) >= 1 else { return }
        }
        publish(at: now)
    }

    /// iPhone 결과의 뒤로가기 또는 워치 결과 화면의 '완료'에서 호출합니다.
    /// .idle로 돌아가 연습 화면을 닫으며, 저장된 결과는 유지합니다.
    func finishReview() {
        guard state.phase == .finished else { return }
        state.phase = .idle
        // 워치 제외는 이번 연습에만 적용합니다. 다시 연습을 선택하면 다음 연습을 준비합니다.
        state.isWatchEnabled = true
        publish()
    }

    /// 저장된 연습 기록 하나를 삭제하고 목록과 워치에 보내는 기록을 갱신합니다.
    func deleteRecord(id: UUID) {
        guard let historyStore else {
            errorMessage = "저장소를 열 수 없어요."
            return
        }
        do {
            try historyStore.delete(id: id)
            setHistory(try historyStore.records())
            publish()
        } catch {
            errorMessage = "기록을 삭제하지 못했어요."
        }
    }

    /// 저장된 기록 목록을 바꾸고, 워치에 보내는 기록도 같은 목록으로 맞춥니다.
    private func setHistory(_ records: [PracticeRecordEntity]) {
        history = records
        state.records = records.map(\.record)
    }

    /// 연결이 끊긴 연습을 워치 없이 계속합니다. 진행 중인 iPhone 분석은 유지합니다.
    func continueWithoutWatch() {
        guard state.phase.isRunning else { return }
        state.isWatchEnabled = false
        publish()
    }

    /// 현재 상태를 통신 담당에게 전달합니다. 실제 전송 방식은 WatchConnection이 처리합니다.
    private func publish(at now: Date = Date()) {
        var snapshot = state.watchSnapshot
        snapshot.updatedAt = now
        connection.publish(snapshot)
    }
}
