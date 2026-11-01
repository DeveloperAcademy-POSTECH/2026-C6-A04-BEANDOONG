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
    @StateObject private var connection = WatchConnection()
    var body: some Scene {
        WindowGroup {
            WatchPracticeView()
                .environmentObject(connection)
        }
    }
}
