//
//  PracticeSessionView.swift
//
//  iPhone의 현재 연습 상태에 맞는 화면을 표시하는 컨테이너입니다.
//  기존 ListeningView, SteamingFeedbackView에 종료 동작을 연결합니다.
//  연결 끊김 배너와 임시 종료 화면을 표시합니다.
//

import SwiftUI

struct PracticeSessionView: View {
    @EnvironmentObject private var practice: PracticeSession
    @EnvironmentObject private var connection: WatchConnection
    @State private var showsDisconnection = false

    var body: some View {
        ZStack {
            switch practice.state.phase {
            case .idle, .listening:
                ListeningView(onStop: practice.stop)
            case .finished:
                VStack(spacing: 24) {
                    Text("연습을 마쳤어요").font(.title2)
                    Text(practice.state.durationText).font(.largeTitle.monospacedDigit())
                    Text("녹음과 연습 기록은 iPhone에서 관리해요.")
                    // 최종 결과 뷰에서도 '다시 연습' 버튼에 같은 동작을 연결합니다.
                    DarkPrimaryButton(title: "다시 연습", action: practice.finishReview)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .darkScreenBackground()
            default:
                SteamingFeedbackView(feedback: feedback, onStop: practice.stop)
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
        .overlay(alignment: .top) {
            if showsDisconnection {
                disconnectionBanner
                    .padding(.horizontal, 20)
                    .padding(.top, 48)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showsDisconnection)
        .alert("연습 안내", isPresented: Binding(
            get: { practice.errorMessage != nil },
            set: { if !$0 { practice.errorMessage = nil } }
        )) {
            Button("확인") { practice.errorMessage = nil }
        } message: {
            Text(practice.errorMessage ?? "")
        }
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
        case .sharpSound: .sharpSound
        case .bubble: .bubble
        case .moreAir: .moreAir
        case .milkFlow: .milkFlow
        default: .aeration
        }
    }
}
