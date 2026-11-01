//
//  WatchPracticeView.swift
//
//  iPhone에서 받은 연습 상태에 맞춰 기존 워치 화면을 연결합니다.
//  시작·결과 확인 완료는 iPhone에 요청하고, 연습 종료는 iPhone의 상태를 따릅니다.
//

import SwiftUI

struct WatchPracticeView: View {
    @EnvironmentObject private var connection: WatchConnection
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            if connection.state.isWatchEnabled {
                practiceScreen
            } else {
                Text("iPhone에서 워치 없이 연습 중이에요.")
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
        .disabled(connection.isSending)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await connection.send(.sync) } }
        }
        .alert("연습 안내", isPresented: Binding(
            get: { connection.errorMessage != nil },
            set: { if !$0 { connection.errorMessage = nil } }
        )) {
            Button("확인") { connection.errorMessage = nil }
        } message: {
            Text(connection.errorMessage ?? "")
        }
    }

    @ViewBuilder
    private var practiceScreen: some View {
        switch connection.state.phase {
        case .idle:
            StartRequestView(onStartTap: start)
        case .listening:
            SoundCheckingView(checkingStatus: .listening)
        case .noiseWarning:
            SoundCheckingView(checkingStatus: .noiseWarning)
        case .aeration:
            SteamingFeedbackView(feedback: .aeration)
        case .sharpSound:
            SteamingFeedbackView(feedback: .sharpSound)
        case .bubble:
            SteamingFeedbackView(feedback: .bubble)
        case .moreAir:
            SteamingFeedbackView(feedback: .moreAir)
        case .milkFlow:
            SteamingFeedbackView(feedback: .milkFlow)
        case .finished:
            PracticeFinishedView(
                practiceDurationText: connection.state.durationText,
                onCloseTap: finishReview,
                onDoneTap: finishReview
            )
        }
    }

    private func start() {
        Task { await connection.send(.start) }
    }

    private func finishReview() {
        Task { await connection.send(.finishReview) }
    }
}
