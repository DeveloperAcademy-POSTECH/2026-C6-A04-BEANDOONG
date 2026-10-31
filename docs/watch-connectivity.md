<!-- 워치 동기화 구현의 구조, 제약 사항, 후속 연결 지점과 실제 기기 검증 방법을 정리한 개발 문서입니다. -->

# iPhone ↔ Apple Watch 연습 연결

## 구조

- `Shared/PracticeState.swift`: 양쪽에서 사용하는 상태·명령·기록 메타데이터.
- `Shared/WatchConnection.swift`: WCSession 활성화, 연결 확인, 요청/응답, 최신 상태 동기화.
- `chee-k/Services/PracticeSession.swift`: iPhone의 녹음 시작/종료, 파일·기록 저장, 상태 발행.
- `WatchConnectionFlow`: 기존 연결 화면을 전환하는 컨테이너. 기존 화면은 버튼 콜백만 추가.
- `AppRootView`: 연습 상태를 관찰해 연습·결과 화면을 표시합니다. cheekApp은 공유 객체 생성과 전달만 담당합니다.
- `PracticeSessionView`: 기존 ListeningView / NoiseWarningView / SteamingFeedbackView를 연습 상태에 따라 표시. 종료 화면은 임시 UI.
- `chee-k-watch/WatchPracticeView.swift`: 교체 가능한 임시 워치 화면. 시작/종료 버튼과 상태·시간만 표시하며, 최신 상태 확인은 앱 활성화·재연결 시 자동 처리합니다.

연습 화면은 AppRootView의 ZStack에서 상태에 따라 표시합니다. 녹음 종료 후 `.finished`에서는 임시 결과 화면을 유지합니다. 결과 화면의 “다시 연습”이 `finishReview()`를 호출해 `.idle`로 바뀌면 HomeView가 이동 경로를 준비 화면으로 교체합니다. 최초 연습을 연결 완료 화면이나 워치에서 시작했어도 이전 화면을 그대로 드러내지 않습니다. 연습 중에는 뒤의 기본 화면에 터치와 접근성 포커스가 전달되지 않게 합니다.

상태의 원본은 iPhone 한 곳입니다. 워치는 시작/종료를 요청하고 iPhone이 성공한 상태만 표시합니다. `sendMessage`로 즉시 전송하고 `updateApplicationContext`로 최신 상태를 남깁니다. 워치가 다시 활성화되면 최신 상태를 요청합니다. 오래된 상태는 `updatedAt`으로 무시합니다. 종료는 세션 ID가 일치해야 적용되며, 요청은 8초 후 만료됩니다. 전송에 실패한 시작/종료는 나중에 실행되도록 큐에 넣지 않습니다.

연결 확인 순서: WCSession 활성화 → 페어링 → 워치 앱 설치 → 워치 앱 응답. 페어링되지 않았으면 WatchNotFoundView, 설치되지 않았으면 WatchAppInstallView, 응답하면 WatchReadyView를 표시합니다. 페어링·설치는 되어 있지만 응답하지 않으면 WatchNotFoundView의 안내 문구를 바꿔 앱을 열도록 안내합니다.

`isReachable`은 블루투스의 물리적 연결 여부가 아닙니다. 워치 앱이 비활성화되어도 false가 될 수 있습니다. 이 구현은 실시간 피드백을 주고받을 수 있는지를 기준으로 연결 끊김을 표시합니다. 연결이 끊겨도 iPhone 녹음은 계속됩니다. 재확인 또는 워치 없이 계속하기로 돌아올 수 있습니다.

## 워치 없이 연습하기

SessionChecklistView의 “워치 없이 연습하기” 보조 버튼은 추후 제거 예정으로, 현재 눌러도 아무 동작을 하지 않습니다. “연습 시작하기”는 기존처럼 녹음을 시작하며, 연결 안내의 “휴대폰만 사용하기”로 진입한 경우에는 워치 제외 선택을 유지합니다.

`PracticeState.isWatchEnabled`는 이번 연습의 워치 사용 여부이며, 페어링 상태를 바꾸지 않습니다. false이면 `watchSnapshot`은 워치 제외 안내만 포함하고 연습 ID·진행 상태·시작/종료 시간·기록은 제외합니다. 일반 전송뿐 아니라 워치의 상태 요청 응답과 재연결 때도 이 스냅샷을 사용합니다. 워치의 시작/종료 요청은 거절하고 iPhone의 연결 끊김 안내도 표시하지 않습니다. iPhone 녹음과 기록 저장은 그대로 진행합니다.

연습 중 연결 끊김 화면에서 “워치 없이 연습하기”를 선택해도 녹음을 유지한 채 같은 모드로 전환합니다. 결과 화면의 “다시 연습”을 누르면 이번 연습의 워치 제외가 해제되어 일반 대기·최근 기록 동기화로 돌아갑니다.

회귀 확인: 준비 화면의 “워치 없이 연습하기”를 눌러 녹음·화면 전환이 없는지 확인합니다. 이어서 연결 안내에서 “휴대폰만 사용하기”로 진입한 뒤 “연습 시작하기” → iPhone만 Listening, 워치는 제외 안내 → 테스트 메뉴에서 피드백 변경·녹음 종료 후에도 워치에 연습 정보가 표시되지 않는지 확인합니다. 도중에 워치 앱을 닫았다 열어도 같아야 합니다. 결과 화면에서 “다시 연습”을 누르고 일반 연습 시작을 선택하면 다시 양쪽이 동기화되어야 합니다. 데이터 테스트는 스냅샷에서 연습 정보가 제외되고 다음 일반 연습에서 정상 전송으로 돌아오는 경우를 포함합니다.

## 녹음과 기록

마이크 권한을 허용한 뒤 iPhone 앱이 **활성 상태**여야 새 녹음을 시작합니다. 워치 요청이 백그라운드 iPhone 앱을 깨우더라도 새 녹음이 허용되는 것은 아니므로, 이 경우 iPhone 앱을 열라는 오류를 워치에 표시합니다. 시작된 녹음은 audio background mode를 사용하며 전화 등 오디오 중단 시 종료하고 안내합니다.

녹음은 iPhone 앱 Documents/PracticeRecordings의 `.m4a`, 기록 목록은 `records.json`에 저장합니다. 워치에는 최근 20건의 ID·시작/종료 시간·파일명 메타데이터를 전달하며 녹음 파일 자체는 전송하지 않습니다. 기존 HistoryView / SessionSummaryView의 샘플 그래프·기록 UI는 이번 작업에서 실제 저장 데이터로 교체하지 않았습니다.

소리 분석 모델은 현재 저장소에 없습니다. 녹음 후 기본 상태는 Listening입니다. 실제 분석 결과는 `PracticeSession.updateFeedback(_:)`로 전달하면 iOS·워치 화면에 함께 반영됩니다. Debug 빌드의 연습 화면에 있는 **동기화 테스트** 메뉴로 Listening / NoiseWarning / 5종 피드백 전송을 확인할 수 있습니다. 이 메뉴는 Release에는 포함되지 않습니다. 진동 패턴은 아직 구현하지 않았습니다.

## 실행 및 실제 기기 확인

기존 프로젝트의 iOS 최소 버전 27.0은 유지했고 watchOS 최소 버전도 27.0으로 설정했습니다. 두 타깃은 같은 Development Team을 상속합니다. Xcode에서 실제 기기의 OS 버전과 서명 설정을 확인하세요.

1. iPhone에 `chee-k`, 페어링된 Apple Watch에 `chee-k-watch`를 설치하고 양쪽 앱을 엽니다.
2. iPhone에서 마이크를 허용하고 연결 확인하기를 누릅니다. Connecting → Ready, 워치에 “연결 확인”이 표시되는지 확인합니다.
3. 미페어링 기기에서 NotFound, 워치 앱 삭제 후 AppInstall, 워치 앱을 닫은 상태에서 앱을 열라는 안내를 확인합니다. 다시 연결 확인하기로 복구합니다.
4. iPhone의 연습 시작하기 → 양쪽 Listening과 같은 경과 시간. 워치의 연습 종료 → iPhone 녹음 종료와 양쪽 종료 시간을 확인하고, iPhone의 녹음 파일·기록 목록 저장도 확인합니다.
5. 다시 워치의 스티밍 연습 시작 → iPhone 녹음과 화면 표시. iPhone 정지 버튼/X → 워치 종료 표시를 확인합니다. 빠르게 두 번 시작해도 하나의 녹음만 생성되어야 합니다.
6. iPhone의 동기화 테스트 메뉴에서 모든 상태를 선택해 워치의 문구·색상 변경을 확인합니다.
7. 연습 중 워치 앱을 닫거나 통신을 끊습니다. iPhone 녹음은 계속되어야 합니다. 워치 연결 다시 확인 또는 워치 없이 연습하기를 누르고 기존 녹음이 유지되는지 확인합니다.
8. 녹음 중 iPhone을 잠근 뒤 워치에서 종료하고 기록 저장을 확인합니다. 반대로 새 시작 요청은 iPhone 앱이 활성화되지 않았으면 안내해야 합니다.
9. 앱 재실행 후 iPhone에서 연결 확인을 누르고 워치 앱을 엽니다. 상태가 자동으로 동기화되고, iPhone의 저장된 기록 목록이 유지되는지 확인합니다.

시뮬레이터 빌드 성공은 실제 WCSession 연결이나 마이크 녹음 성공을 보장하지 않습니다. 위 항목은 페어링된 실제 기기에서 검증해야 합니다.

## 명령으로 검증

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project chee-k.xcodeproj -scheme chee-k \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/beandoong-build CODE_SIGNING_ALLOWED=NO build

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project chee-k.xcodeproj -scheme chee-k-watch \
  -destination 'generic/platform=watchOS Simulator' \
  -derivedDataPath /tmp/beandoong-watch-build CODE_SIGNING_ALLOWED=NO build

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swiftc \
  -module-cache-path /tmp/beandoong-test-cache \
  Shared/PracticeState.swift Tests/PracticeStateTests.swift \
  -o /tmp/beandoong-state-tests
/tmp/beandoong-state-tests
```

SDK는 destination으로 선택합니다. watch 스킴에는 호스트 iOS 앱도 포함되므로 `-sdk watchsimulator`를 전체 빌드에 강제하지 않습니다.

참고: [Apple WCSession 문서](https://developer.apple.com/documentation/watchconnectivity/wcsession), [isReachable 문서](https://developer.apple.com/documentation/watchconnectivity/wcsession/isreachable).
