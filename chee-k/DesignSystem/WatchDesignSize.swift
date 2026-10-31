//
//  WatchDesignSize.swift
//
//  [타깃] 워치(chee-k-watch) 전용 파일입니다. chee-k 폴더에 있지만 iPhone 타깃에는 포함되지 않습니다.
//
//  워치 화면 크기 대응을 위한 기준값과 변환 함수입니다. (Hi-Fi 기준 크기 → 현재 기기 크기)
//
//  [왜 필요한가요?]
//  지원하는 워치 화면 너비는 기기마다 다릅니다. (예: 40mm 162pt, 46mm 208pt, Ultra 49mm 205 ~ 211pt)
//  Hi-Fi는 46mm(208 × 248pt) 하나만 기준으로 그려져 있어서, 수치를 그대로 쓰면
//  작은 기기에서는 글자가 잘리고 큰 기기에서는 여백이 남습니다.
//
//  [어떻게 쓰나요?]
//  1. 코드에는 Hi-Fi(46mm)에서 측정한 수치를 그대로 적습니다.
//  2. `WatchDesignSize.scaled(수치)` 또는 `.font(.watchScaled(글자 크기))`로 감싸면
//     현재 기기 너비 비율만큼 자동으로 줄어들거나 늘어납니다.
//     예) 46mm에서 52pt인 버튼 높이 → 40mm에서는 52 × (162 ÷ 208) ≈ 40.5pt
//

import SwiftUI
import WatchKit

enum WatchDesignSize {
    /// Hi-Fi 디자인의 기준 화면 너비 (46mm, pt)
    static let designScreenWidth: CGFloat = 208

    /// 현재 기기 화면 너비 ÷ Hi-Fi 기준 화면 너비
    /// - 46mm = 1.0, 40mm ≈ 0.78, Ultra 3(49mm) ≈ 1.01
    /// - 화면 크기는 앱 실행 중 바뀌지 않으므로 한 번만 계산합니다.
    static let screenWidthRatio: CGFloat = WKInterfaceDevice.current().screenBounds.width / designScreenWidth

    /// Hi-Fi(46mm)에서 측정한 수치를 현재 기기 크기에 맞게 변환합니다.
    /// - Parameter designValue: Hi-Fi 기준 수치 (pt)
    /// - Returns: 현재 기기에서 사용할 수치 (pt)
    static func scaled(_ designValue: CGFloat) -> CGFloat {
        designValue * screenWidthRatio
    }
}

extension Font {
    /// Hi-Fi(46mm) 기준 글자 크기를 현재 기기 크기에 맞게 변환한 시스템 폰트
    /// - Parameters:
    ///   - designSize: Hi-Fi 기준 글자 크기 (pt)
    ///   - weight: 글자 굵기 (기본값: regular)
    static func watchScaled(_ designSize: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: WatchDesignSize.scaled(designSize), weight: weight)
    }
}
