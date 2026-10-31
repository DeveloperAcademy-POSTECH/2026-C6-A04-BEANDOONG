//
//  WatchCapsuleButton.swift
//
//  [타깃] 워치(chee-k-watch) 전용 파일입니다. chee-k 폴더에 있지만 iPhone 타깃에는 포함되지 않습니다.
//
//  화면 너비를 꽉 채우는 하늘색 캡슐 모양 버튼입니다.
//  시작 요청 화면([스티밍 연습 시작])과 종료 확인 화면([완료])에서 함께 사용합니다.
//

import SwiftUI

/// 하늘색 캡슐 버튼
/// - 디자인: hifi/Intro.png, hifi/watch11-2.png 의 하단 버튼
struct WatchCapsuleButton: View {
    /// 버튼에 표시할 글자 (예: "스티밍 연습 시작", "완료")
    let title: String
    /// 버튼을 눌렀을 때 실행할 동작
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.watchScaled(18, weight: .bold))
                .foregroundStyle(AppColors.watchCapsuleButtonTitle)
                .lineLimit(1)
                // 글자가 버튼보다 길어지면 한 줄을 유지한 채 최대 80%까지 줄입니다.
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .frame(height: WatchDesignSize.scaled(Metrics.buttonHeight))
                .background(AppColors.watchCapsuleButtonBackground, in: Capsule())
        }
        // 워치 기본 버튼 모양(회색 배경)을 없애고 위에서 그린 캡슐 모양만 보이게 합니다.
        .buttonStyle(.plain)
        .padding(.horizontal, WatchDesignSize.scaled(Metrics.screenEdgeInset))
    }
}

// MARK: - Metrics

/// Hi-Fi(46mm) 기준 수치입니다. 사용할 때 `WatchDesignSize.scaled(_:)`로 기기 크기에 맞춥니다.
private enum Metrics {
    static let buttonHeight: CGFloat = 52    // 버튼 높이
    static let screenEdgeInset: CGFloat = 15 // 화면 좌우 끝 ↔ 버튼 사이 여백
}

#Preview {
    WatchCapsuleButton(title: "스티밍 연습 시작") {}
}
