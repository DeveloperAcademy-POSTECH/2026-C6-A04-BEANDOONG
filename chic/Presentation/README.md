# 발표용 프로토타입

발표용 화면·재생 상태·워치 연결·번역·테스트는 이 폴더에서 관리합니다. 마이크와 연습 기록 저장소를 사용하지 않습니다.

흐름: 스팀 준비 → 소리 확인 2초 → 파랑 1.5초 → 주황 1.5초 → 보라 1.5초 → 파랑 2초 → 초록 1.5초 → 마지막 수위와 잔물결 유지 → 종료 시 결과.

`PresentationPrepGuideView`와 `PresentationFeedbackView`는 발표 전용 화면입니다. 기존 캐러셀·피처·소리 확인·결과 화면과 수위 계산은 수정 없이 재사용합니다.

`PresentationWatchSync`는 기존 `WatchConnection`으로 소리 확인·피드백·종료 상태를 전달합니다. 워치의 시작·종료·완료 명령도 발표용으로 연결합니다. 화면을 닫으면 이전 상태와 명령 처리를 복원하며, 발표 기록은 저장하거나 기존 기록에 추가하지 않습니다.

## 발표용 소리

`PresentationSteamSound`는 피드백 단계가 바뀌는 곳에서 소리를 재생합니다. 준비·소리 확인 화면은 무음이고, 초록 소리만 종료까지 반복합니다. iPhone·워치의 종료 또는 화면 닫기 시 재생과 오디오 세션을 정리합니다. 일반 연습의 마이크·분석 코드는 사용하지 않습니다.

`Audio`의 WAV는 제공된 `chic-presentation-steaming.wav`(48kHz, 모노, 11.374초)의 파형과 기존 소리 분류 모델로 구간을 확인한 뒤 추출했습니다. 시작·끝 소리는 제외하고, 음높이를 유지하는 FFmpeg `atempo`로 화면 길이에 맞췄습니다. 각 파일 양 끝에는 클릭 방지용 3ms 페이드를 적용했습니다.

| 파일 | 원본 구간(초, 근사) | 재생 길이 |
| --- | --- | --- |
| `PresentationAeration.wav` | 2.18–3.44 | 1.5초 |
| `PresentationBubble.wav` | 3.44–4.91 | 1.5초 |
| `PresentationMoreAir.wav` | 4.91–6.55 | 1.5초 |
| `PresentationAerationLong.wav` | 6.55–8.50 | 2초 |
| `PresentationRolling.wav` | 8.50–10.50 | 2초 반복 |

## 검증

저장소 루트에서 실행합니다.

```sh
sh chic/Presentation/Tests/verify-presentation-practice.sh
```

## 제거

1. `HomeView.swift`의 발표용 상태, 목적지, 설정 바인딩 전달, `startPractice()`의 발표용 분기를 제거합니다.
2. `SettingsView.swift`의 발표용 바인딩·초기화 인자, 토글과 바로 위 구분선을 제거합니다.
3. 이 폴더를 삭제합니다. 기존 연습 화면, 공통 부품, 프로젝트 설정에서 정리할 항목은 없습니다.
