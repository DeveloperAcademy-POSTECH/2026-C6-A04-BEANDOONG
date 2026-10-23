# chee-k

우유 스티밍 중 공기 주입 소리의 특징을 기기 안에서 분석하고, 화면과 진동으로 피드백하는 iPhone · Apple Watch 프로토타입입니다. iPhone 마이크로 분석하고 판정 상태만 Watch에 전송합니다.

## 실행

1. `chee-k.xcodeproj`를 Xcode에서 엽니다.
2. iPhone은 `chee-k`, 워치는 `chee-kWatch` 스킴을 선택합니다.
3. 실기기에 설치하려면 세 타깃(`chee-k`, `chee-kWatch`, `chee-kComplication`)의 Signing & Capabilities에서 본인의 Team을 지정합니다. 기존 chee-k 프로젝트의 Team 설정을 유지했습니다.
4. iPhone 앱에서 마이크 권한을 허용하고 `연습 시작`을 누릅니다. Watch 앱을 열어 상태와 진동을 확인합니다.

최소 배포 버전은 iOS 17 · watchOS 10입니다. 검증에 사용한 Xcode는 27입니다. 외부 패키지 의존성은 없습니다. iPhone 번들 ID는 `com.beandoong.cheek`, Watch는 `com.beandoong.cheek.watchkitapp`, 컴플리케이션은 `com.beandoong.cheek.watchkitapp.complication`입니다. 다른 계정으로 배포한다면 iPhone · 워치 · 컴플리케이션 ID와 워치의 `WKCompanionAppBundleIdentifier`를 함께 변경해야 합니다.

## 구성

- `chee-k/`: 기존 앱 진입점과 Puffin 기능으로 연결한 메인 화면, 아이콘.
- `PuffinWatch/`: iPhone 판정 수신·진동·Watch 화면과 아이콘.
- `PuffinComplication/`: 시계 화면의 앱 진입용 컴플리케이션. 실시간 감지 표시가 아닙니다.
- `Shared/PulseDSP.swift`: 주파수 특징 계산과 규칙 기반 공기음·진동 판정.
- `Shared/PulseMonitor.swift`: iPhone 마이크 수명 관리, 분석 결과와 iPhone 진동 요청.
- `chee-k/PulseSender.swift`: WatchConnectivity로 판정 상태만 Watch에 전송.
- `PuffinWatch/PulseReceiver.swift`: Watch에서 상태 수신, 표시, 진동 및 연결 만료 처리.
- `Shared/PulseInputView.swift`: iPhone 입력 화면, 측정값 확인과 기준값 조절.
- `Shared/PuffinStyle.swift`: 공통 색상과 고역 크기 변화 표시.
- `Checks/Pulse/main.swift`: 현재 분석기의 독립 실행 검사. 앱에는 포함되지 않습니다.
- `Checks/Pulse/replay.swift`: 녹음 파일을 같은 DSP로 재생하고 구간별 감지·미감지 근거를 CSV로 남기는 도구. 앱에는 포함되지 않습니다.

## 현재 동작

기본 공기음 조건은 4–12kHz 크기 ≥ −48dBFS, 200Hz–16kHz 대비 4–12kHz 에너지 비율 ≥ 0.12, 2–12kHz 평탄도 ≥ 0.12입니다. 세 조건을 120ms 연속 충족하면 진입합니다. 짧은 소리에는 주변 고역보다 10dB 이상 크고, 최근 80ms 고역 상승이 6dB 이상이며, 주파수별 변화량이 0.18 이상인 경우 43ms짜리 빠른 경로를 적용합니다. 빠른 경로의 크기 하한은 기본 고역 기준보다 최대 6dB 낮되 −62dBFS보다 낮아지지 않습니다. 조건 미달이 220ms 지속되면 해제합니다. 별도로 상단 고역 감소에 따른 차단·복귀 규칙이 적용됩니다. 반복 진동에는 최소 350ms 간격과 고역 진폭 상승 조건이 있습니다. 이 새 수치 역시 검증 전 실험값입니다.

세 기준값과 DSP 판정은 iPhone에만 있습니다. 원음은 저장하거나 전송하지 않고 `running`·`active`·`pulse`만 Watch로 보냅니다. iPhone 앱이 백그라운드로 가면 분석을 종료합니다. iPhone 그래프는 원음 파형이 아니라 최근 고역 크기 이력입니다.

## 검사

macOS에서 Xcode 명령행 도구를 사용합니다. 저장소 루트에서 실행합니다.

```sh
xcrun swiftc -module-cache-path /tmp/puffin-module-cache \
  Shared/PulseDSP.swift Checks/Pulse/main.swift -o /tmp/puffin-dsp-check
/tmp/puffin-dsp-check
```

잡음·무음 판정, 비정상 입력, 입력 분할 방식에 따른 결과 일치, 실행 중 기준값 변경을 검사합니다. 기본 검사는 외부 녹음 없이 실행됩니다. 선택적으로 48kHz mono Float32 PCM 파일 경로를 실행 인자로 전달할 수 있으며, 개인 녹음 파일은 저장소에 포함하지 않았습니다.

실제 녹음은 `ffmpeg`가 설치된 macOS에서 아래처럼 재생할 수 있습니다. `--positive`는 공기 주입이 **확실한** 구간, `--negative`는 공기 주입이 **확실히 아닌** 구간을 초 단위로 입력합니다. 불확실한 구간에는 `--ignore`를 사용합니다. `--legacy`를 붙여 같은 파일을 기존 120ms 규칙으로도 돌리면 빠른 경로의 이득과 오탐을 비교할 수 있습니다. CSV의 `reason`은 기본 조건에 걸린 항목이고, `fastCandidate`는 빠른 경로가 열린 프레임입니다.

```sh
xcrun swiftc -module-cache-path /tmp/puffin-module-cache-replay \
  Shared/PulseDSP.swift Checks/Pulse/replay.swift -o /tmp/puffin-dsp-replay
/tmp/puffin-dsp-replay "녹음파일.m4a" --source live \
  --positive 3:10 --csv /tmp/puffin-replay.csv
/tmp/puffin-dsp-replay "녹음파일.m4a" --source live \
  --positive 3:10 --legacy
```

녹음 10은 사용자가 **10초까지 공기 주입**이라고 확인했지만 시작점은 정확히 표시하지 않았으므로 위 `3:10`은 실행 형식의 예시입니다. 실제 시작점을 확인한 뒤 바꿔야 합니다. 녹음 15에는 말소리와 빠른 롤링이 섞여 있어 정답 공기음으로 넣지 않습니다. 유튜브 소리는 스피커로 재생해 iPhone 마이크로 다시 녹음한 파일을 `--source speaker`로 따로 검사합니다. 현재 앱은 같은 iPhone 내부의 유튜브 재생 오디오를 직접 받지 않습니다.

```sh
xcodebuild -project chee-k.xcodeproj -scheme chee-k \
  -configuration Debug -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/CheekBuild CODE_SIGNING_ALLOWED=NO build
```

`chee-k` 빌드는 워치 앱과 컴플리케이션도 함께 빌드합니다. Debug의 `--preview-input` 실행 인자는 실제 마이크를 사용하지 않는 화면 확인용 데이터입니다.

## 알려진 한계

현재 기준은 실험용이며, 특히 상단 대역 감소 규칙은 녹음 9·18을 바탕으로 조정되었습니다. 다양한 마이크와 스티밍 환경의 정확도 검증은 필요합니다.
짧은 경로는 합성 70ms 광대역 잡음과 1kHz 단일음으로만 회귀 검사했습니다. 실제 스티밍의 미탐 감소나 카페 소음의 오탐 증가는 확인되지 않았습니다. `--source`는 평가 기록용 구분이며 DSP 수치를 자동으로 바꾸지 않습니다.

이전 Watch 자체 마이크 방식에서 소리 입력·진동 지연이 보고되어 Watch는 iPhone 판정을 받는 방식으로 바꿨습니다. 두 실기기 사이 실제 지연과 감지 정확도는 아직 측정하지 않았습니다. Watch 앱이 연결되지 않으면 실시간 메시지가 도착하지 않으며, 마지막 메시지 이후 3초가 지나면 이전 감지 표시를 지웁니다. 동기식 오디오 세션 활성화·비활성화가 메인 스레드에서 실행되는 경고도 해결 전입니다.

## 통합 범위

Puffin의 분석·입력·Watch·컴플리케이션 코드와 아이콘, 독립 실행 검사를 기존 chee-k 프로젝트에 통합했습니다. iPhone 앱 진입점은 기존 `cheekApp`을 유지하며 `ContentView`가 `PulseInputView`를 표시합니다. 별도 Puffin Xcode 프로젝트나 중복 앱 진입점은 추가하지 않았습니다.

최소 배포 버전은 원본 기능과 같은 iOS 17 · watchOS 10입니다. 오디오 분석이 직렬 큐에서 실행되도록 iPhone 타깃의 기본 actor 격리는 `nonisolated`로 설정하고, 화면 상태를 소유하는 `PulseMonitor`의 명시적 `@MainActor`는 유지합니다. 기존 작업 브랜치에서 이 파일들과 프로젝트 설정을 함께 수정했다면 병합 시 확인해야 합니다.

Xcode 명령이 Command Line Tools 오류로 실패하면 명령 앞에 `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`를 붙여 실행할 수 있습니다.

## 통합 검증 (2026-10-22)

- Debug iOS 시뮬레이터 빌드: iPhone · Watch · 컴플리케이션 모두 통과.
- Release iOS 실기기 SDK 빌드: 세 타깃 모두 통과. 코드 서명은 제외.
- `Checks/Pulse/main.swift`: 잡음·무음·유한값·잘못된 입력·입력 분할 독립성·실시간 기준값 변경 검사 통과.
- 프로젝트 참조, 타깃 포함 관계, iPhone–Watch 번들 ID 연결, 마이크 권한 설명, 세 타깃 버전 일치 검사 통과.
- iPhone 18 Pro · Apple Watch Series 12 시뮬레이터: 일반 실행과 `--preview-input` 화면 실행 확인. 화면 시험은 마이크 입력이나 감지 정확도 검증을 대체하지 않음.
- 남은 경고: `PulseMonitor`의 중첩 비동기 클로저에서 캡처한 `self` 관련 Swift 6 동시성 경고. 현재 Swift 5 모드에서는 빌드되지만 Swift 6 모드로 전환하기 전에 수정 필요. App Intents 미사용에 따른 메타데이터 추출 생략 경고도 있음.
- 미검증: 실기기 서명·설치, 실제 마이크 소리의 감지 정확도, iPhone→Watch 메시지·진동 지연, 시계 화면에 컴플리케이션을 추가한 뒤 앱을 여는 동작.

## iPhone → Watch 판정 전송 (2026-10-23)

iPhone `PulseMonitor`가 `PulseResult`를 받은 뒤 `PulseSender`에 `running`·`active`·`pulse`를 전달합니다. Watch의 `PulseReceiver`가 화면을 갱신하고 `pulse`에서 진동을 재생합니다. 상태 변화·진동은 즉시 전송을 요청하고, 실행 중에는 약 1초마다 현재 상태를 다시 전송합니다. Watch는 3초 동안 메시지를 받지 못하면 이전 감지 표시를 지웁니다. Watch 마이크·DSP는 실행하지 않습니다. 실시간 전송은 Watch 앱이 통신 가능한 상태에서만 동작합니다.
