//
//  WatchCloseButton.swift
//
//  화면 좌측 상단의 동그란 닫기(X) 버튼입니다.
//  워치 화면에서 공통으로 사용할 수 있습니다.
//
//  [왜 툴바에 넣나요?]
//  직접 그려서 좌측 상단에 배치하면 기기마다 시간 표시 · 둥근 모서리와 겹칠 수 있습니다.
//  시스템 툴바(.topBarLeading)로 위치를 정하고, 원형 배경은 디자인의 30×30pt로 표시합니다.
//
//  [주의]
//  툴바는 NavigationStack 안에서만 보입니다. 이 버튼을 쓰는 화면은 NavigationStack 안에 넣어 주세요.
//

import SwiftUI

extension View {
    /// 화면 좌측 상단에 닫기(X) 버튼을 추가합니다.
    /// - Parameter onClose: 닫기 버튼을 눌렀을 때 실행할 동작
    func watchCloseButton(onClose: @escaping () -> Void) -> some View {
        toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: onClose) {
                    let icon = Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .frame(width: 30, height: 30)
                    if #available(watchOS 26.0, *) {
                        icon.glassEffect(.regular.interactive(), in: Circle())
                    } else {
                        icon.background(.ultraThinMaterial, in: Circle())
                    }
                }
                .buttonStyle(.plain)
                // VoiceOver가 아이콘 이름 대신 "닫기"라고 읽도록 합니다.
                .accessibilityLabel("닫기")
            }
        }
    }
}
