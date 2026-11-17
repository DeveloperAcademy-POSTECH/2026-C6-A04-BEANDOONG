import Foundation

/// 발표 화면이 떠 있는 동안만 워치 상태와 명령을 연결하고, 나가면 기존 연결을 복원합니다.
@MainActor
final class PresentationWatchSync {
    private let connection: WatchConnection
    private let previousState: PracticeState
    private let previousCommand: ((WatchRequest) async throws -> PracticeState)?
    private let onStart: () -> Void
    private let onStop: () -> Void
    private let onFinishReview: () -> Void
    private var state = PracticeState()
    private var isActive = true

    init(connection: WatchConnection, onStart: @escaping () -> Void,
         onStop: @escaping () -> Void, onFinishReview: @escaping () -> Void) {
        self.connection = connection
        previousState = connection.state
        previousCommand = connection.onCommand
        self.onStart = onStart
        self.onStop = onStop
        self.onFinishReview = onFinishReview
        state.records = previousState.records
        connection.onCommand = { [weak self] request in
            guard let self else {
                throw ConnectionError.localized("연습 상태가 변경되었어요. 다시 확인해주세요.")
            }
            return try self.handle(request)
        }
        publish()
    }

    func showListening() {
        guard isActive, state.phase == .idle else { return }
        state.sessionID = UUID()
        state.phase = .listening
        publish()
    }

    func showFeedback(_ presentation: PresentationPractice) {
        guard isActive, state.phase.isRunning else { return }
        state.phase = presentation.phase
        state.startedAt = presentation.startedAt
        state.endedAt = presentation.isComplete
            ? presentation.startedAt.addingTimeInterval(PresentationPractice.duration) : nil
        publish()
    }

    func showFinished(_ result: PracticeResult) {
        guard isActive, state.phase.isRunning else { return }
        state.phase = .finished
        state.startedAt = result.practicedAt
        state.endedAt = result.practicedAt.addingTimeInterval(result.timelineLength)
        publish()
    }

    func disconnect() {
        guard isActive else { return }
        isActive = false
        connection.onCommand = previousCommand
        var restored = previousState
        restored.updatedAt = .now
        connection.publish(restored)
    }

    private func handle(_ request: WatchRequest) throws -> PracticeState {
        guard isActive else { return connection.state }
        switch request.command {
        case .sync:
            break
        case .start:
            if state.phase == .idle { onStart() }
        case .stop, .finishReview:
            guard let id = state.sessionID, request.sessionID == id else {
                throw ConnectionError.localized("연습 상태가 변경되었어요. 다시 확인해주세요.")
            }
            if request.command == .stop, state.phase.isRunning {
                onStop()
            } else if request.command == .finishReview, state.phase == .finished {
                onFinishReview()
            }
        }
        return connection.state
    }

    private func publish() {
        state.updatedAt = .now
        connection.publish(state.watchSnapshot)
    }
}
