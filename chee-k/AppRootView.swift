//
//  AppRootView.swift
//
//  연습 상태를 관찰하며 기본 화면 위에 연습·결과 화면을 표시하는 앱의 루트 뷰입니다.
//  객체 생성은 cheekApp이 담당하고, 화면 갱신과 오류 안내는 이 View가 담당합니다.
//  .finished에서도 결과 화면을 유지하고, '다시 연습'으로 .idle이 되어야 기본 화면을 표시합니다.
//

import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var practice: PracticeSession

    var body: some View {
        ZStack {
            ContentView()
                .allowsHitTesting(practice.state.phase == .idle)
                .accessibilityHidden(practice.state.phase != .idle)

            // 이전 화면이 연결 완료인지 준비 화면인지와 관계없이 결과 화면을 유지합니다.
            if practice.state.phase != .idle {
                PracticeSessionView()
            }
        }
        .alert("연습 안내", isPresented: Binding(
            get: { practice.errorMessage != nil && practice.state.phase == .idle },
            set: { if !$0 { practice.errorMessage = nil } }
        )) {
            Button("확인") { practice.errorMessage = nil }
        } message: {
            Text(practice.errorMessage ?? "")
        }
    }
}
