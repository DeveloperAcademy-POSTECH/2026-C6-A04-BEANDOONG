//
//  WatchConnectionFlow.swift
//
//  워치 연결 확인 결과에 따라 기존 연결 안내 뷰를 전환하는 컨테이너입니다.
//  설정 안내 → 확인 중 → 준비 완료·미페어링·앱 미설치·통신 불가 흐름과 재시도를 관리합니다.
//  실제 연결 확인은 WatchConnection이 담당하며, 각 안내 뷰의 레이아웃은 그대로 사용합니다.
//

import SwiftUI

/// 화면 레이아웃과 연결 상태 전환을 분리합니다. 재시도도 같은 확인 과정을 사용합니다.
struct WatchConnectionFlow: View {
    @EnvironmentObject private var connection: WatchConnection
    var startsWithCheck = false
    var onReady: (() -> Void)? = nil
    var onContinueWithoutWatch: (() -> Void)? = nil
    @State private var status: WatchConnection.Status?
    @State private var attempt = 0

    var body: some View {
        Group {
            switch status {
            case nil:
                WatchSetupView(onCheck: retry, onContinue: onContinueWithoutWatch)
            case .checking:
                WatchConnectingView()
            case .notPaired:
                WatchNotFoundView(onCheck: retry, onContinue: onContinueWithoutWatch)
            case .appNotInstalled:
                WatchAppInstallView(onCheck: retry, onContinue: onContinueWithoutWatch)
            case .unavailable:
                WatchNotFoundView(isPaired: true, onCheck: retry, onContinue: onContinueWithoutWatch)
            case .ready:
                if let onReady {
                    WatchReadyView(onContinue: onReady)
                } else {
                    WatchReadyView()
                }
            }
        }
        .task(id: attempt) {
            guard attempt > 0 || startsWithCheck else { return }
            status = .checking
            let result = await connection.check()
            guard !Task.isCancelled else { return }
            status = result
        }
    }

    private func retry() { attempt += 1 }
}
