//
//  PracticeSessionView.swift
//
//  iPhone의 현재 연습 상태에 맞는 화면을 표시하는 컨테이너입니다.
//  기존 ListeningView, SteamingFeedbackView에 종료 동작을 연결합니다.
//  연결 끊김 배너와 결과 로딩·완료 화면을 표시합니다.
//

import SwiftUI

struct PracticeSessionView: View {
    @EnvironmentObject private var practice: PracticeSession
    @EnvironmentObject private var connection: WatchConnection
    @State private var showsDisconnection = false
    /// 결과 화면의 뒤로가기를 눌렀을 때 (연습 상태 정리와 메인으로 돌아가는 움직임은 바깥에서)
    var onResultClose: () -> Void = {}
    /// 결과 화면을 닫는 중인지. 닫히며 밀려 나가는 동안 `.idle`이 되어도 소리 확인 화면으로 바뀌지 않고 결과 화면 그대로 보이게 해요.
    @State private var isClosingResult = false

    var body: some View {
        ZStack {
            switch practice.state.phase {
            case .idle where isClosingResult:
                FinishedPracticeView(result: practice.result, onClose: closeResult)
            case .idle, .listening:
                ListeningView(onStop: practice.stop)
            case .finished:
                FinishedPracticeView(result: practice.result, onClose: closeResult)
            default:
                SteamingFeedbackView(
                    feedback: feedback,
                    onStop: practice.stop,
                    showsEndDialog: practice.silenceStartedAt != nil,
                    onContinue: practice.continueAfterSilence,
                    onFinishAfterSilence: practice.finishAfterSilence
                )
            }
        }
        .onChange(of: connection.isReachable) { wasReachable, reachable in
            if reachable { showsDisconnection = false }
            if wasReachable && !reachable && practice.state.phase.isRunning && practice.state.isWatchEnabled {
                showsDisconnection = true
            }
        }
        .onChange(of: practice.state.phase.isRunning) { _, isRunning in
            if !isRunning { showsDisconnection = false }
        }
        .onChange(of: practice.state.isWatchEnabled) { _, isEnabled in
            if !isEnabled { showsDisconnection = false }
        }
        .task(id: showsDisconnection) {
            guard showsDisconnection else { return }
            do { try await Task.sleep(for: .seconds(3)) }
            catch { return }
            showsDisconnection = false
        }
        // 일시적인 통신 불가로 연습을 방해하지 않도록 연결 끊김 배너를 잠시 숨깁니다.
        /*
        .overlay(alignment: .top) {
            if showsDisconnection {
                disconnectionBanner
                    .padding(.horizontal, 20)
                    .padding(.top, 48)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showsDisconnection)
        */
        .alert("연습 안내", isPresented: Binding(
            get: { practice.errorMessage != nil },
            set: { if !$0 { practice.errorMessage = nil } }
        )) {
            Button("확인") { practice.errorMessage = nil }
        } message: {
            Text(practice.errorMessage ?? "")
        }
    }

    /// 결과 화면의 뒤로가기: 결과 화면이 오른쪽으로 밀려 나가며 메인이 나타나요.
    private func closeResult() {
        isClosingResult = true
        onResultClose()
    }

    private var disconnectionBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "applewatch")
                .font(.system(size: 20))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text("워치 연결이 잠시 끊겼어요")
                    .font(.pretendard(.semibold, size: 14))
                Text("iPhone에서 연습은 계속 진행돼요")
                    .font(.pretendard(.regular, size: 12))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .foregroundStyle(.white)
        .background(AppColors.darkCard, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        .accessibilityElement(children: .combine)
        .allowsHitTesting(false)
    }

    private var feedback: SteamingFeedback {
        switch practice.state.phase {
        case .bubble: .bubble
        case .moreAir: .moreAir
        case .milkFlow: .milkFlow
        default: .aeration
        }
    }
}

private struct FinishedPracticeView: View {
    @EnvironmentObject private var practice: PracticeSession
    let result: PracticeResult?
    let onClose: () -> Void
    @State private var minimumLoadingFinished = false

    /// 결과 화면을 보여 줄 때가 됐는지 (로딩 최소 시간이 지났고 결과가 준비됨)
    private var showsResult: Bool { minimumLoadingFinished && result != nil }

    var body: some View {
        // 결과가 준비되면 로딩 화면 아래에 결과 화면을 미리 만들어 둬요. 보여 줄 때가 되면 같은 순간에
        // 로딩 화면을 걷고 결과 화면을 보이게 해서(전과 같이 바로 바뀜), 결과 화면을 처음 만드는 무거운 일이
        // 바뀌는 순간과 겹치지 않아요. 등장 애니메이션(도넛 · 막대)은 보이기 시작할 때 출발해요.
        ZStack {
            if let result {
                PracticeResultView(result: result, onClose: onClose, onDelete: {
                    // 방금 저장된 이번 연습 기록을 지웁니다 (기록 id = 세션 id).
                    if let id = practice.state.sessionID { practice.deleteRecord(id: id) }
                }, isRevealActive: showsResult)
                .opacity(showsResult ? 1 : 0)
                .allowsHitTesting(showsResult)
                .accessibilityHidden(!showsResult)
            }
            if !showsResult {
                PracticeResultLoadingView()
            }
        }
        .task {
            // 저장이 빨리 끝나도 로딩 화면이 깜빡이지 않게 잠깐 유지합니다.
            do { try await Task.sleep(for: .milliseconds(700)) }
            catch { return }
            minimumLoadingFinished = true
        }
    }
}
