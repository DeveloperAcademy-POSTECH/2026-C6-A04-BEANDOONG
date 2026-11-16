import Foundation

/// 비커의 수위·잔물결을 프레임 사이에 이어 가요.
/// - 수위: 계산한 목표 수위를 0.35초 정도 늦게 따라가 출발·정지가 부드러워요.
/// - 잔물결: 공기 주입 중에만 세지고, 다른 상태에서는 0.6초에 걸쳐 잦아들어요.
/// - 쉬기: 공기 주입이 아니고 수위와 잔물결이 다 멈추면 `Frame.isResting` 이 true 예요. 화면은 이때부터 그리기를 멈추고,
///   쉬는 동안 같은 입력으로 다시 불리면 마지막 프레임을 그대로 돌려줘요 (멈춘 순간의 모습이 그대로 남아요).
final class PitcherMotion {
    private var level = SmoothFollower(smoothTime: 0.35)
    private var ripple = SmoothFollower(smoothTime: 0.6)
    private var lastDate: Date?
    private var phase: Double = 0
    /// 쉬고 있을 때만 값이 있어요: 쉬기 시작한 입력(목표 수위)과 그때 그린 마지막 프레임
    private var rest: (targetTop: CGFloat, frame: Frame)?
    /// 쉬다가 다시 움직이는 첫 계산에서 경과 시간을 한 프레임 길이로 줄여야 하는지 (아래 `advance` 설명)
    private var capsNextStep = false

    struct Frame {
        let top: CGFloat
        let rippleAmplitude: CGFloat
        let ripplePhase: Double
        /// 공기 주입이 아니고 수위·잔물결이 모두 목표에 붙어 더 움직일 일이 없는지
        let isResting: Bool
    }

    /// 잔물결 높이 (pt)와 1초에 지나가는 물결 수
    private static let rippleHeight: CGFloat = 1.6
    private static let rippleSpeed: Double = 1.1
    /// 쉬다가 다시 움직이는 첫 프레임에 쓰는 경과 시간 한도 (초): 한 프레임 길이 (60Hz)
    private static let resumeStep: Double = 1.0 / 60

    /// `date` 시점의 프레임. `still` 이면 따라가는 지연과 잔물결 없이 목표 수위 그대로예요.
    ///
    /// 쉬는 동안 화면이 멈춰 있다가(그리기를 안 하다가) 다시 움직이면 `date - lastDate` 가 아주 길어요. 그대로 쓰면 `SmoothFollower`가
    /// 0.1초로 잘라도 첫 프레임에 0.1초치(평소 프레임의 여러 배)만큼 한 번에 움직여 튀어 보여요. 그래서 쉬다가 처음 움직이는 계산은 경과 0초로
    /// (바로 이전과 같은 모습), 그다음 계산은 평소처럼 쓰되 한 프레임 길이(`resumeStep`)를 넘지 않게 해요. 쉬지 않고 계속 그릴 때는 전과 같아요.
    func advance(to date: Date, targetTop: CGFloat, rippling: Bool, still: Bool) -> Frame {
        var dt = lastDate.map { date.timeIntervalSince($0) } ?? 0
        lastDate = date
        if still {
            return Frame(top: targetTop, rippleAmplitude: 0, ripplePhase: 0, isResting: false)
        }
        if let rest {
            // 같은 입력이면 쉬던 모습 그대로
            if !rippling, rest.targetTop == targetTop { return rest.frame }
            // 입력이 바뀌어 다시 움직여요
            self.rest = nil
            capsNextStep = true
            dt = 0
        } else if capsNextStep {
            capsNextStep = false
            dt = min(dt, Self.resumeStep)
        }

        let top = level.step(toward: Double(targetTop), dt: dt)
        let strength = ripple.step(toward: rippling ? 1 : 0, dt: dt)
        phase = (phase + max(0, min(dt, 0.1)) * Self.rippleSpeed * 2 * .pi).truncatingRemainder(dividingBy: 2 * .pi * 100)
        let isResting = !rippling && level.isSettled(at: Double(targetTop)) && ripple.isSettled(at: 0)
        let frame = Frame(top: CGFloat(top), rippleAmplitude: Self.rippleHeight * CGFloat(strength), ripplePhase: phase, isResting: isResting)
        if isResting { rest = (targetTop, frame) }
        return frame
    }
}
