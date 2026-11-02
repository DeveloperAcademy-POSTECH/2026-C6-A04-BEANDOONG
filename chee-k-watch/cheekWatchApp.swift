//
//  cheekWatchApp.swift
//
//  Apple Watch 앱의 시작 지점입니다.
//  앱이 사용하는 WatchConnection을 생성하고 워치 화면에 전달합니다.
//  WatchPracticeView가 연습 상태에 맞는 워치 화면을 표시합니다.
//

import SwiftUI

@main
struct cheekWatchApp: App {
    @StateObject private var connection: WatchConnection
    private let feedbackNotifications: WatchFeedbackNotifications

    /// 수신 상태 알림을 화면 생명주기와 분리해 앱 시작 시 연결합니다.
    init() {
        let connection = WatchConnection()
        let notifications = WatchFeedbackNotifications()
        connection.onStateChange = { previous, current in
            await notifications.receive(previous: previous, current: current)
        }
        _connection = StateObject(wrappedValue: connection)
        feedbackNotifications = notifications
    }

    var body: some Scene {
        WindowGroup {
            WatchPracticeView()
                .environmentObject(connection)
                .task { await feedbackNotifications.requestAuthorization() }
        }
        .backgroundTask(.watchConnectivity) {
            await connection.receiveBackgroundUpdates()
        }
    }
}
