//
//  AppColors+Watch.swift
//
//  워치 화면 두 곳 이상에서 함께 쓰는 색상입니다.
//  iPhone 앱과 같은 `AppColors` 이름으로 쓸 수 있도록, AppColors를 확장해 워치 폴더에 둡니다.
//  (`AppColors`와 `Color(hex:)`는 chee-k/DesignSystem/AppColors.swift 에 있고, 워치 타깃에도 포함되어 있습니다.)
//
//  한 화면에서만 쓰는 색상은 해당 화면 파일 하단의 `private extension AppColors`에 둡니다.
//

import SwiftUI

extension AppColors {
    /// 시작 요청, 소리 확인, 종료 확인 화면의 배경
    static let watchDarkScreenBackground = Color(hex: 0x01030C)
    /// 워치 하늘색 캡슐 버튼 배경 ([스티밍 연습 시작], [완료])
    static let watchCapsuleButtonBackground = Color(hex: 0xA6DDF7)
    /// 워치 하늘색 캡슐 버튼 글자
    static let watchCapsuleButtonTitle = Color.black
}
