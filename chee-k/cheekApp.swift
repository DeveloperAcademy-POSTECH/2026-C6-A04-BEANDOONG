//
//  beandoongApp.swift
//  beandoong
//
//  Created by 최서진 on 10/9/26.
//

import SwiftUI // App·Scene·WindowGroup을 사용합니다.

// iPhone 앱 진입점: 창을 만들고 ContentView를 표시합니다.
@main
struct cheekApp: App {
    var body: some Scene {
        // iPhone 앱의 기본 창마다 ContentView를 표시합니다.
        WindowGroup {
            ContentView()
        }
    }
}
