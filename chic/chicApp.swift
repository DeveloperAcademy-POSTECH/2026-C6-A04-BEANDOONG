//
//  beandoongApp.swift
//  beandoong
//
//  Created by 최서진 on 10/9/26.
//

import SwiftUI

@main
struct cheekApp: App {
    @StateObject private var connection: WatchConnection
    @StateObject private var practice: PracticeSession

    init() {
        let connection = WatchConnection()
        _connection = StateObject(wrappedValue: connection)
        _practice = StateObject(wrappedValue: PracticeSession(connection: connection))
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(connection)
                .environmentObject(practice)
        }
    }
}
