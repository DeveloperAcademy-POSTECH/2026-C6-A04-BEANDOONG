//
//  WatchTextStyle.swift
//
//  워치 화면에서 함께 쓰는 글자 스타일입니다.
//

import SwiftUI

extension Text {
    /// 한 줄로 보여 주는 글자 스타일 (안내 문구 · 버튼 글자)
    /// - 글자 크기는 `Font.watchScaled(_:weight:)`로 기기 크기에 맞춰요.
    /// - 글자가 자리보다 길어지면 한 줄을 유지한 채 최대 80%까지 줄여요.
    /// - Parameters:
    ///   - designSize: Hi-Fi(46mm) 기준 글자 크기 (pt)
    ///   - weight: 글자 굵기 (기본값: regular)
    func watchSingleLineStyle(_ designSize: CGFloat, weight: Font.Weight = .regular) -> some View {
        font(.watchScaled(designSize, weight: weight))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }
}
