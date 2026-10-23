# chee-k 코드 읽기 안내

이 문서는 코드를 처음 보는 사람이 **어느 파일부터 읽고, 소리가 화면·진동으로 어떻게 이어지는지** 파악하기 위한 지도입니다. 세부 수식보다 역할과 흐름에 집중합니다.

## 먼저 알아둘 구조

```text
iPhone: PulseInputView ─┐
                        ├→ PulseMonitor → PulseCapture → PulseDSP
Watch:  WatchInputView ──┘        ↑                         ↓
                              화면 상태 ← PulseResult(측정·판정)
                                   └→ 기기별 진동
```

iPhone과 Watch는 **각자 마이크로 같은 분석 코드를 실행**합니다. iPhone의 판정 결과를 Watch에 보내는 구조가 아닙니다. Watch의 컴플리케이션은 앱 진입용 표시이며 실시간 분석을 하지 않습니다.

## 파일별 역할

| 읽는 순서 | 파일 | 맡은 일 |
| --- | --- | --- |
| 1 | `chee-k/cheekApp.swift`, `chee-k/ContentView.swift` | iPhone 앱을 시작하고 연습 화면을 엽니다. |
| 2 | `Shared/PulseInputView.swift` | iPhone의 상태 문구·고역 그래프·시작/종료 버튼·진단 패널을 그립니다. |
| 3 | `Shared/PulseMonitor.swift` | 마이크 권한과 시작/종료, 화면 상태, 오류 처리, 기기별 진동을 관리합니다. 내부 `PulseCapture`가 오디오를 분석 큐로 보냅니다. |
| 4 | `Shared/PulseDSP.swift` | 음성을 주파수별 에너지로 바꾸고 규칙으로 공기음 상태를 판정합니다. 화면 코드는 없습니다. |
| 5 | `Shared/PuffinStyle.swift` | 공통 색상과 최근 고역 크기 그래프를 정의합니다. |
| 6 | `PuffinWatch/PuffinWatchApp.swift` | Watch 연습 화면입니다. Watch 자체 `PulseMonitor`를 사용합니다. |
| 7 | `PuffinComplication/PuffinComplication.swift` | 시계 화면의 정적 앱 진입점입니다. |
| 8 | `Checks/Pulse/main.swift` | 앱 없이 DSP 규칙을 검사하는 명령행 코드입니다. |

## 한 번의 연습 흐름

1. 화면에서 **연습 시작**을 누르면 `PulseMonitor.start()`가 마이크 권한을 확인합니다.
2. `PulseCapture`가 마이크를 열고 음성 샘플을 직렬 분석 큐로 넘깁니다.
3. `PulseDSP.consume()`이 샘플을 약 43ms 크기의 창으로 나눠 FFT로 분석합니다. 약 11ms마다 새 결과를 만듭니다(48kHz 기준).
4. `PulseDSP.update()`가 고역 크기·비율·평탄도와 지속 시간을 보고 공기음 표시(`active`)를 켜거나 끕니다. 상단 주파수 감소가 감지되면 일시 차단(`suppressed`)할 수 있습니다.
5. `PulseMonitor.accept()`가 결과를 화면 상태와 최근 고역 그래프로 옮깁니다. `pulse`가 참인 결과에서는 해당 기기의 진동을 요청합니다.
6. 연습 종료, 화면 이탈, 백그라운드 이동 또는 오디오 중단 시 `stop()`이 입력과 분석을 정리합니다.

## 결과값을 읽는 법

- `highDB`: 4–12kHz 소리의 크기. `db`는 전체 입력의 크기입니다. 둘 다 마이크 녹음 기준 **dBFS**이며 공간의 소음계 dB SPL이 아닙니다.
- `ratio`: 200Hz–16kHz 중 4–12kHz 에너지가 차지하는 비율입니다.
- `flatness`: 2–12kHz 에너지가 여러 주파수에 얼마나 고르게 퍼졌는지 나타냅니다.
- `active`: 현재 규칙이 공기음 후보로 표시하는 상태입니다. 실제 공기량이나 우유 온도를 측정한 결과는 아닙니다.
- `suppressed`: 앞선 후보 소리와 비교해 상단 대역이 줄어 표시를 차단한 상태입니다.
- `pulse`: 이번 결과에서 진동을 요청할지 나타냅니다. `active`인 동안 매번 진동시키지는 않습니다.

## 무엇을 바꾸려면 어디를 볼까?

- 감지 기준·지속 시간·진동 요청 규칙: `Shared/PulseDSP.swift`
- 마이크 수명, 오류 문구, 진동 호출: `Shared/PulseMonitor.swift`
- iPhone 문구·화면·진단 패널: `Shared/PulseInputView.swift`
- Watch 화면: `PuffinWatch/PuffinWatchApp.swift`
- 색상·고역 그래프: `Shared/PuffinStyle.swift`

iPhone 화면의 세 기준값은 **iPhone에만 저장**됩니다. Watch와 자동 동기화되지 않습니다. 현재 수치는 실험용이므로 판정 정확도는 실제 공기주입 시작·끝을 표시한 녹음과 다양한 기기·카페 환경으로 확인해야 합니다.
