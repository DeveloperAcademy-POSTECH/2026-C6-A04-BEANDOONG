import SwiftUI

/// 발표용 화면과 재생을 관리합니다. 기존 연습 세션을 사용하지 않습니다.
struct PresentationPracticeView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var connection: WatchConnection
    @State private var showsListening = false
    @State private var presentation: PresentationPractice?
    @State private var result: PracticeResult?
    @State private var watchSync: PresentationWatchSync?
    @State private var steamSound = PresentationSteamSound()

    var body: some View {
        ZStack {
            if let result {
                PracticeResultView(result: result, onClose: close)
            } else if let presentation {
                PresentationFeedbackView(
                    presentation: presentation,
                    onStop: finish
                )
            } else if showsListening {
                ListeningView(onStop: finish)
                    .task {
                        do { try await Task.sleep(for: .seconds(2)) }
                        catch { return }
                        guard !Task.isCancelled, result == nil else { return }
                        presentation = PresentationPractice()
                        if let presentation { watchSync?.showFeedback(presentation) }
                        showsListening = false
                    }
            } else {
                PresentationPrepGuideView(onStart: start)
            }
        }
        .onAppear {
            guard watchSync == nil else { return }
            watchSync = PresentationWatchSync(connection: connection, onStart: start,
                                              onStop: finish, onFinishReview: close)
        }
        .onDisappear {
            steamSound.stop()
            watchSync?.disconnect()
            watchSync = nil
        }
        .task(id: presentation != nil && result == nil) {
            guard result == nil else { return }
            while !Task.isCancelled, let current = presentation, !current.isComplete {
                steamSound.play(current)
                do { try await Task.sleep(for: .seconds(current.stepDuration)) }
                catch { return }
                guard !Task.isCancelled, result == nil else { return }
                presentation?.advance()
                if let presentation { watchSync?.showFeedback(presentation) }
            }
        }
    }

    private func start() {
        guard !showsListening, presentation == nil, result == nil else { return }
        showsListening = true
        watchSync?.showListening()
    }

    private func finish() {
        guard result == nil else { return }
        guard presentation != nil || showsListening else { return }
        steamSound.stop()
        let completed = presentation?.finish()
            ?? PracticeResult(practicedAt: .now, dailyOrder: 1, segments: [], duration: 0)
        result = completed
        showsListening = false
        watchSync?.showFinished(completed)
    }

    private func close() {
        steamSound.stop()
        watchSync?.disconnect()
        watchSync = nil
        dismiss()
    }
}
