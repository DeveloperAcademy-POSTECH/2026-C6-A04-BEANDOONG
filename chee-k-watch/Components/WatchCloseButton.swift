//
//  WatchCloseButton.swift
//
//  화면 좌측 상단의 동그란 닫기(X) 버튼입니다.
//  소리 확인 대기 화면과 종료 확인 화면에서 함께 사용합니다.
//
//  [왜 툴바에 넣나요?]
//  직접 그려서 좌측 상단에 배치하면 기기마다 시간 표시 · 둥근 모서리와 겹칠 수 있습니다.
//  시스템 툴바(.topBarLeading)에 넣으면 watchOS가 기기 크기에 맞는 위치와 모양(유리 질감 원형 버튼)을
//  알아서 정해 주므로, Hi-Fi와 같은 모양을 모든 기기에서 안전하게 유지할 수 있습니다.
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
                    Image(systemName: "xmark")
                }
                // VoiceOver가 아이콘 이름 대신 "닫기"라고 읽도록 합니다.
                .accessibilityLabel("닫기")
            }
        }
    }
}
