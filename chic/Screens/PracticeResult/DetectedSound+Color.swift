import SwiftUI

extension DetectedSound {
    /// 타임라인 막대 색상 (디자인 시스템 팔레트, Hi-Fi 269/270/271 측정으로 확인)
    ///
    /// 색은 화면 쪽 값이라 결과 데이터(`PracticeResult.swift`)와 따로 뒀어요. 데이터 파일은 Foundation 만 써서 SwiftUI 없이도 컴파일돼요.
    var timelineColor: Color {
        switch self {
        case .normalAeration: AppColors.soundNormalAeration
        case .overAeration: AppColors.soundOverAeration
        case .lackOfAir: AppColors.soundLackOfAir
        case .rolling: AppColors.soundRolling
        }
    }
}
