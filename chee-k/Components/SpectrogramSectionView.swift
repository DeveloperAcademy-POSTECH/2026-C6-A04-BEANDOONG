import SwiftUI

/// 연습 기록 화면들의 "소리의 변화" 섹션 (연습 기록 완료 / 저장 실패 / 연습 상세 화면에서 사용)
///
///     ┌──────────── 카드 (345 x cardHeight) ────────────┐
///     │ 주파수 · Hz                    (헤더)             │
///     │ 8k ┌──────────────────────┐                     │
///     │ 4k │   히트맵 (285 x 135)    │  ← 선택 시점 세로선 │
///     │ 0  └──────────────────────┘                     │
///     │    0   10   20   30초        (시간 축)            │
///     └─────────────────────────────────────────────────┘
///     ▬▬▬▬▬▬▬ ▬▬ ▬▬▬▬▬ ▬▬▬                (상태 색상 바)
///     당시 표시된 상태 색상
struct SpectrogramSectionView: View {
    /// 히트맵 위에 표시할 선택 시점(초). nil 이면 세로선/말풍선을 그리지 않음
    var selectedSecond: Int? = nil
    /// 카드 전체 높이
    var cardHeight: CGFloat = 200
    /// 카드 상단 "주파수 · Hz" 헤더 영역 높이
    var topHeaderHeight: CGFloat = 34
    /// 카드 ↔ 상태 색상 바 사이 간격
    var barTopSpacing: CGFloat = 14

    var body: some View {
        VStack(alignment: .leading, spacing: barTopSpacing) {
            spectrogramCard
            StatusColorBar()
        }
    }

    // MARK: 스펙트로그램 카드

    private var spectrogramCard: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppColors.cardBackground)

            VStack(alignment: .leading, spacing: 0) {
                // 카드 헤더
                HStack {
                    Text("주파수 · Hz")
                        .font(.pretendard(.medium, size: 12))
                        .foregroundStyle(AppColors.axisGray)
                    Spacer()
                }
                .frame(height: topHeaderHeight)
                .padding(.leading, 14)

                // 주파수 축(폭 42) + 히트맵(285 x 135)
                HStack(alignment: .top, spacing: 0) {
                    FrequencyAxisLabels()
                    HeatmapGrid(selectedSecond: selectedSecond)
                    Spacer(minLength: 0)
                }

                // 시간 축
                TimeAxisLabels()
                    .padding(.top, 9)

                Spacer(minLength: 0)
            }
            .frame(width: 345, height: cardHeight, alignment: .topLeading)
        }
        .frame(width: 345, height: cardHeight)
    }
}

// MARK: - 주파수 축 라벨 (8k / 4k / 0)

private struct FrequencyAxisLabels: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            label("8k")
            Spacer().frame(height: 17)
            label("4k")
            Spacer().frame(height: 17)
            label("0")
            Spacer(minLength: 0)
        }
        .padding(.leading, 14)
        .frame(width: 42, height: 135, alignment: .topLeading)
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(.pretendard(.regular, size: 11))
            .foregroundStyle(AppColors.axisGray)
            .frame(height: 14, alignment: .top)
    }
}

// MARK: - 히트맵 (32열 x 11행) + 선택 시점 표시

private struct HeatmapGrid: View {
    let selectedSecond: Int?

    private static let columns = 32
    private static let rows = 11

    /// 각 칸의 색상 단계 (`AppColors.heatmapPalette`의 인덱스). Hi-Fi 스펙트로그램 디자인에서 추출한 11행 x 32열
    private static let gridIndices: [[Int]] = [
        [1, 0, 0, 0, 1, 2, 3, 3, 3, 3, 2, 2, 2, 2, 3, 4, 4, 4, 3, 2, 1, 0, 0, 1, 1, 2, 2, 2, 1, 0, 0, 0],
        [0, 0, 0, 0, 1, 2, 2, 2, 2, 1, 1, 1, 2, 3, 4, 4, 4, 4, 3, 2, 1, 2, 2, 3, 3, 2, 2, 1, 0, 0, 0, 0],
        [1, 1, 1, 2, 2, 2, 1, 1, 0, 0, 0, 1, 2, 3, 4, 4, 3, 2, 2, 2, 3, 3, 4, 4, 3, 3, 1, 0, 0, 0, 1, 1],
        [2, 3, 3, 3, 2, 2, 0, 0, 0, 0, 1, 2, 2, 2, 2, 2, 1, 1, 2, 3, 4, 4, 4, 4, 3, 2, 1, 1, 1, 2, 2, 3],
        [4, 4, 4, 3, 2, 1, 1, 0, 1, 1, 2, 2, 2, 1, 0, 0, 0, 1, 2, 3, 4, 4, 4, 3, 2, 2, 2, 3, 3, 4, 4, 3],
        [4, 4, 4, 3, 2, 2, 2, 2, 3, 3, 3, 2, 1, 0, 0, 0, 0, 1, 2, 3, 3, 2, 2, 1, 2, 2, 3, 4, 4, 4, 4, 3],
        [4, 3, 2, 2, 2, 2, 3, 4, 4, 4, 3, 2, 1, 0, 0, 1, 1, 2, 2, 2, 1, 0, 0, 1, 1, 2, 3, 4, 4, 4, 3, 2],
        [2, 1, 1, 2, 2, 3, 4, 4, 4, 3, 2, 2, 1, 1, 2, 2, 3, 2, 2, 1, 0, 0, 0, 1, 2, 3, 3, 3, 2, 2, 2, 2],
        [0, 0, 1, 2, 3, 4, 4, 4, 3, 2, 2, 2, 3, 3, 4, 4, 3, 2, 1, 0, 0, 0, 1, 1, 2, 2, 2, 1, 1, 0, 1, 2],
        [0, 0, 1, 2, 2, 3, 2, 2, 1, 1, 2, 3, 4, 4, 4, 4, 3, 2, 1, 1, 1, 2, 2, 2, 2, 1, 0, 0, 0, 0, 1, 2],
        [1, 1, 2, 2, 2, 1, 1, 0, 0, 1, 2, 3, 4, 4, 4, 3, 2, 2, 2, 3, 3, 4, 3, 3, 2, 1, 0, 0, 0, 1, 2, 2]
    ]

    var body: some View {
        GeometryReader { geo in
            let cellW = geo.size.width / CGFloat(Self.columns)

            ZStack(alignment: .topLeading) {
                heatmapCanvas

                if let sec = selectedSecond {
                    selectionMarker(second: sec, x: CGFloat(sec) * cellW, gridHeight: geo.size.height)
                }
            }
        }
        .frame(width: 285, height: 135)
    }

    /// 칸마다 팔레트 색을 채워 히트맵을 그림
    private var heatmapCanvas: some View {
        Canvas { context, size in
            let cw = size.width / CGFloat(Self.columns)
            let ch = size.height / CGFloat(Self.rows)
            for r in 0..<Self.rows {
                for c in 0..<Self.columns {
                    let idx = Self.gridIndices[r][c]
                    let rect = CGRect(
                        x: CGFloat(c) * cw,
                        y: CGFloat(r) * ch,
                        width: ceil(cw),
                        height: ceil(ch)
                    )
                    context.fill(Path(rect), with: .color(AppColors.heatmapPalette[idx]))
                }
            }
        }
    }

    /// 선택 시점 세로선(히트맵보다 6pt 길게) + 위쪽 "N초" 말풍선
    @ViewBuilder
    private func selectionMarker(second: Int, x: CGFloat, gridHeight: CGFloat) -> some View {
        Rectangle()
            .fill(AppColors.darkTitle)
            .frame(width: 2, height: gridHeight + 6)
            .position(x: x, y: (gridHeight + 6) / 2)

        Text("\(second)초")
            .font(.pretendard(.semibold, size: 12))
            .foregroundStyle(AppColors.darkTitle)
            .frame(width: 54, height: 26)
            .background(
                Capsule()
                    .fill(Color.white)
            )
            .position(x: x, y: -15)
    }
}

// MARK: - 시간 축 라벨 (0 / 10 / 20 / 30초)

private struct TimeAxisLabels: View {
    var body: some View {
        HStack(spacing: 0) {
            Spacer().frame(width: 42) // 주파수 축 폭만큼 들여쓰기
            Text("0")
                .frame(width: 35, alignment: .leading)
            Text("10")
                .frame(width: 40, alignment: .leading)
            Text("20")
                .frame(width: 40, alignment: .leading)
            Text("30초")
                .frame(width: 50, alignment: .leading)
            Spacer()
        }
        .font(.pretendard(.regular, size: 11))
        .foregroundStyle(AppColors.axisGray)
    }
}

// MARK: - 상태 색상 바 (4구간) + 캡션

private struct StatusColorBar: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 3) {
                segment(AppColors.statusMint, width: 141)
                segment(AppColors.statusYellow, width: 42)
                segment(AppColors.statusMint, width: 98)
                segment(AppColors.statusGray, width: 52)
            }
            .frame(width: 342, height: 12, alignment: .leading)

            Text("당시 표시된 상태 색상")
                .font(.pretendard(.regular, size: 11))
                .foregroundStyle(AppColors.captionGray)
        }
    }

    private func segment(_ color: Color, width: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(color)
            .frame(width: width, height: 12)
    }
}
