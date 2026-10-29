//
//  PracticeSessionView.swift
//
//  iPhone의 현재 연습 상태에 맞는 화면을 표시하는 컨테이너입니다.
//  기존 ListeningView, NoiseWarningView, SteamingFeedbackView에 종료 동작을 연결합니다.
//  연결 끊김·재확인과 임시 종료 화면을 표시하며, Debug 빌드에는 동기화 테스트 메뉴를 제공합니다.
//

import SwiftUI

struct PracticeSessionView: View {
    @EnvironmentObject private var practice: PracticeSession
    @EnvironmentObject private var connection: WatchConnection
    @State private var showsDisconnection = false
    @State private var showsRecheck = false

    var body: some View {
        Group {
            switch practice.state.phase {
            case .idle, .listening:
                ListeningView(onStop: practice.stop)
            case .noiseWarning:
                NoiseWarningView(onStop: practice.stop)
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
            if wasReachable && !reachable && practice.state.phase.isRunning && practice.state.isWatchEnabled {
                showsDisconnection = true
            }
        }
        .onChange(of: practice.state.phase) { _, phase in
            if !phase.isRunning { showsDisconnection = false; showsRecheck = false }
        }
        .sheet(isPresented: $showsDisconnection) {
            WatchDisconnectedView(onCheck: {
                showsRecheck = true
            }, onContinue: {
                practice.continueWithoutWatch()
                showsDisconnection = false
            })
            .sheet(isPresented: $showsRecheck) {
                NavigationStack {
                    WatchConnectionFlow(startsWithCheck: true, onReady: {
                        showsRecheck = false
                        showsDisconnection = false
                    }, onContinueWithoutWatch: {
                        practice.continueWithoutWatch()
                        showsRecheck = false
                        showsDisconnection = false
                    })
                    .toolbar(.hidden, for: .navigationBar)
                }
            }
        }
        .alert("연습 안내", isPresented: Binding(
            get: { practice.errorMessage != nil },
            set: { if !$0 { practice.errorMessage = nil } }
        )) {
            Button("확인") { practice.errorMessage = nil }
        } message: {
            Text(practice.errorMessage ?? "")
        }
        #if DEBUG
        .overlay(alignment: .topLeading) {
            Menu("동기화 테스트") {
                ForEach(PracticePhase.allCases.filter(\.isRunning), id: \.self) { phase in
                    Button(phase.title) { practice.updateFeedback(phase) }
                }
            }
            .font(.caption)
            .padding(.top, 42)
            .padding(.leading)
        }
        #endif
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
