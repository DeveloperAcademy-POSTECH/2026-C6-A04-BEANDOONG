# chee-k

우유 스티밍 중 공기 주입 소리의 특징을 기기 안에서 분석하고, 화면과 진동으로 피드백하는 iPhone · Apple Watch 프로토타입입니다. 두 기기는 각자의 마이크로 독립 실행합니다.

## 실행

1. `chee-k.xcodeproj`를 Xcode에서 엽니다.
2. iPhone은 `chee-k`, 워치는 `chee-kWatch` 스킴을 선택합니다.
3. 실기기에 설치하려면 세 타깃(`chee-k`, `chee-kWatch`, `chee-kComplication`)의 Signing & Capabilities에서 본인의 Team을 지정합니다. 기존 chee-k 프로젝트의 Team 설정을 유지했습니다.
4. 앱을 실행하고 마이크 권한을 허용한 뒤 `연습 시작`을 누릅니다.

최소 배포 버전은 iOS 17 · watchOS 10입니다. 검증에 사용한 Xcode는 27입니다. 외부 패키지 의존성은 없습니다. iPhone 번들 ID는 `com.beandoong.cheek`, Watch는 `com.beandoong.cheek.watchkitapp`, 컴플리케이션은 `com.beandoong.cheek.watchkitapp.complication`입니다. 다른 계정으로 배포한다면 iPhone · 워치 · 컴플리케이션 ID와 워치의 `WKCompanionAppBundleIdentifier`를 함께 변경해야 합니다.

## 구성

- `chee-k/`: 기존 앱 진입점과 Puffin 기능으로 연결한 메인 화면, 아이콘.
- `PuffinWatch/`: 워치 입력 화면과 아이콘.
- `PuffinComplication/`: 시계 화면의 앱 진입용 컴플리케이션. 실시간 감지 표시가 아닙니다.
- `Shared/PulseDSP.swift`: 주파수 특징 계산과 규칙 기반 공기음·진동 판정.
- `Shared/PulseMonitor.swift`: 마이크 수명 관리, 분석 결과 전달, 기기별 진동 요청.
- `Shared/PulseInputView.swift`: iPhone 입력 화면, 측정값 확인과 기준값 조절.
- `Shared/PuffinStyle.swift`: 공통 색상과 고역 크기 변화 표시.
- `Checks/Pulse/main.swift`: 현재 분석기의 독립 실행 검사. 앱에는 포함되지 않습니다.

## 현재 동작

기본 공기음 조건은 4–12kHz 크기 ≥ −48dBFS, 200Hz–16kHz 대비 4–12kHz 에너지 비율 ≥ 0.12, 2–12kHz 평탄도 ≥ 0.12입니다. 세 조건을 120ms 연속 충족하면 진입하고 조건 미달이 220ms 지속되면 해제합니다. 별도로 상단 고역 감소에 따른 차단·복귀 규칙이 적용됩니다. 반복 진동에는 최소 350ms 간격과 고역 진폭 상승 조건이 있습니다.

iPhone에서 변경한 세 기준값은 해당 기기에 저장되며 워치와 동기화되지 않습니다. 앱은 현재 소리를 저장하거나 외부로 전송하지 않습니다. 백그라운드 진입 시 분석을 종료합니다. 화면의 파형은 원음 파형이 아니라 최근 고역 크기 이력입니다.

## 검사

macOS에서 Xcode 명령행 도구를 사용합니다. 저장소 루트에서 실행합니다.

```sh
xcrun swiftc -module-cache-path /tmp/puffin-module-cache \
  Shared/PulseDSP.swift Checks/Pulse/main.swift -o /tmp/puffin-dsp-check
/tmp/puffin-dsp-check
```

잡음·무음 판정, 비정상 입력, 입력 분할 방식에 따른 결과 일치, 실행 중 기준값 변경을 검사합니다. 기본 검사는 외부 녹음 없이 실행됩니다. 선택적으로 48kHz mono Float32 PCM 파일 경로를 실행 인자로 전달할 수 있으며, 개인 녹음 파일은 저장소에 포함하지 않았습니다.

```sh
xcodebuild -project chee-k.xcodeproj -scheme chee-k \
  -configuration Debug -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/CheekBuild CODE_SIGNING_ALLOWED=NO build
```

`chee-k` 빌드는 워치 앱과 컴플리케이션도 함께 빌드합니다. Debug의 `--preview-input` 실행 인자는 실제 마이크를 사용하지 않는 화면 확인용 데이터입니다.

## 알려진 한계

현재 기준은 실험용이며, 특히 상단 대역 감소 규칙은 녹음 9·18을 바탕으로 조정되었습니다. 다양한 마이크와 스티밍 환경의 정확도 검증은 필요합니다.

실제 워치에서 약 3–4초의 진동 지연이 보고되었으며 원인은 아직 확정하지 않았습니다. 동기식 오디오 세션 활성화·비활성화가 메인 스레드에서 실행되는 경고도 해결 전입니다. 이 통합본은 기존 감지·오디오·진동 판정 로직을 보존하며, 지연 수정이나 실시간 성능 검증을 완료한 버전이 아닙니다.

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
- 미검증: 실기기 서명·설치, 실제 마이크 소리의 감지 정확도, Watch 진동 지연, 시계 화면에 컴플리케이션을 추가한 뒤 앱을 여는 동작.
