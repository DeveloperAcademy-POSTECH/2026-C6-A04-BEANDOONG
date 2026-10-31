//
//  WatchPracticeView.swift
//
//  워치 연결과 연습 동기화를 확인하기 위한 임시 화면입니다.
//  사용자는 연습 시작·종료만 요청하고, 화면은 iPhone이 전달한 연습 상태·경과 시간을 표시합니다.
//  최신 상태 확인은 앱 활성화·재연결 시 자동으로 처리하므로 별도 확인 버튼은 제공하지 않습니다.
//  최종 워치 디자인이 준비되면 WatchConnection을 유지한 채 이 화면을 교체할 수 있습니다.
//

import SwiftUI

/// 기능 검증용 임시 화면. 최종 디자인은 이 연결 모델을 그대로 사용할 수 있습니다.
struct WatchPracticeView: View {
    @EnvironmentObject private var connection: WatchConnection
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Text(connection.state.isWatchEnabled
                     ? (connection.hasSynced ? connection.state.phase.title : "iPhone 연결을 확인해주세요")
                     : "iPhone에서 워치 없이 연습 중이에요.").font(.headline)
                if !connection.state.isWatchEnabled {
                    Text("iPhone에서 연습을 진행해주세요.").font(.caption)
                } else if connection.state.phase.isRunning {
                    TimelineView(.periodic(from: .now, by: 1)) { _ in
                        Text(connection.state.durationText).monospacedDigit()
                    }
                    if connection.state.phase == .listening || connection.state.phase == .noiseWarning {
                        ProgressView()
                    }
                    Button("연습 종료") { Task { await connection.send(.stop) } }
                        .tint(.red)
                } else {
                    if connection.state.phase == .finished {
                        Text(connection.state.durationText).monospacedDigit()
                    }
                    Button("스티밍 연습 시작") { Task { await connection.send(.start) } }
                }
                if connection.isSending { ProgressView("요청 중") }
                if let error = connection.errorMessage {
                    Text(error).font(.caption).foregroundStyle(.orange)
                }
            }
            .padding()
            .buttonStyle(.borderedProminent)
            .disabled(connection.isSending)
        }
        .background(background.ignoresSafeArea())
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await connection.send(.sync) } }
        }
    }

    private var background: Color {
        switch connection.state.phase {
        case .aeration: .blue
        case .sharpSound: .pink
        case .bubble: .orange
        case .moreAir: .purple
        case .milkFlow: .green
        default: .black
        }
    }
}
