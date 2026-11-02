<!-- 워치 동기화 구현의 구조, 제약 사항, 후속 연결 지점과 실제 기기 검증 방법을 정리한 개발 문서입니다. -->

# iPhone ↔ Apple Watch 연습 연결

## 구조

- `Shared/PracticeState.swift`: 양쪽에서 사용하는 상태·명령·기록 메타데이터.
- `Shared/WatchConnection.swift`: WCSession 활성화, 연결 확인, 요청/응답, 최신 상태 동기화.
- `chee-k/Services/PracticeSession.swift`: iPhone의 녹음 시작/종료, 파일·기록 저장, 상태 발행.
- `WatchConnectionFlow`: 기존 연결 화면을 전환하는 컨테이너. 기존 화면은 버튼 콜백만 추가.
- `AppRootView`: 연습 상태를 관찰해 연습·결과 화면을 표시합니다. cheekApp은 공유 객체 생성과 전달만 담당합니다.
- `PracticeSessionView`: 기존 ListeningView / NoiseWarningView / SteamingFeedbackView를 연습 상태에 따라 표시. 종료 화면은 임시 UI.
- `chee-k-watch/WatchPracticeView.swift`: 기존 워치 뷰를 연결하는 컨테이너. StartRequestView → SoundCheckingView / SteamingFeedbackView → PracticeFinishedView를 iPhone의 연습 상태에 따라 표시합니다. 최신 상태 확인은 앱 활성화·재연결 시 자동 처리합니다.

연습 화면은 AppRootView의 ZStack에서 상태에 따라 표시합니다. 녹음 종료 후 `.finished`에서는 임시 결과 화면을 유지합니다. iPhone 결과 화면의 “다시 연습”이나 워치 결과 화면의 “완료”/X가 `finishReview()`를 호출해 `.idle`로 바뀌면 HomeView가 이동 경로를 준비 화면으로 교체합니다. 최초 연습을 연결 완료 화면이나 워치에서 시작했어도 이전 화면을 그대로 드러내지 않습니다. 연습 중에는 뒤의 기본 화면에 터치와 접근성 포커스가 전달되지 않게 합니다.

상태의 원본은 iPhone 한 곳입니다. 워치는 시작·종료·결과 확인 완료를 요청하고 iPhone이 성공한 상태만 표시합니다. 워치의 `.stop` 요청도 iPhone 버튼과 같은 `PracticeSession.stop()`을 호출해 녹음과 분석을 종료하고 결과를 저장합니다. `sendMessage`로 즉시 전송하고 `updateApplicationContext`로 최신 상태를 남깁니다. 워치가 다시 활성화되면 최신 상태를 요청합니다. 오래된 상태는 `updatedAt`으로 무시합니다. 종료·결과 확인 완료는 세션 ID가 일치해야 적용되며, 요청은 8초 후 만료됩니다. 전송에 실패한 요청은 나중에 실행되도록 큐에 넣지 않습니다.

연결 확인 순서: WCSession 활성화 → 페어링 → 워치 앱 설치 → 워치 앱 응답. 페어링되지 않았으면 WatchNotFoundView, 설치되지 않았으면 WatchAppInstallView, 응답하면 WatchReadyView를 표시합니다. 페어링·설치는 되어 있지만 응답하지 않으면 WatchNotFoundView의 안내 문구를 바꿔 앱을 열도록 안내합니다.

`isReachable`은 블루투스의 물리적 연결 여부가 아닙니다. 워치 앱이 비활성화되어도 false가 될 수 있습니다. 워치를 사용하는 연습 중 true → false가 되면 상단에 연결 끊김 배너를 약 3초간 표시합니다. 모달이나 확인 버튼은 없으며, 배너는 화면 배치와 버튼 터치를 막지 않습니다. 재연결·연습 종료 시에는 즉시 숨깁니다. 피드백 상태가 바뀌어도 표시 시간이 다시 시작되지 않으며, 재연결 후 다시 끊기면 새로 표시합니다. 연결이 끊겨도 iPhone 녹음과 분석은 계속되고, 재연결 시 기존 동기화 로직으로 최신 상태를 전달합니다.

## 워치 없이 연습하기

SessionChecklistView의 “워치 없이 연습하기”와 연결 안내의 “휴대폰만 사용하기”는 `practice.start(usingWatch: false)`를 호출합니다. 추가 연결 확인이나 준비 화면 이동 없이, 녹음 시작에 성공하면 AppRootView가 iPhone 연습 화면을 표시합니다. 마이크 권한 거부·녹음 시작 실패 시에는 기존 오류 안내를 표시합니다.

`PracticeState.isWatchEnabled`는 이번 연습의 워치 사용 여부이며, 페어링 상태를 바꾸지 않습니다. false이면 `watchSnapshot`은 워치 제외 안내만 포함하고 연습 ID·진행 상태·시작/종료 시간·기록은 제외합니다. 일반 전송뿐 아니라 워치의 상태 요청 응답과 재연결 때도 이 스냅샷을 사용합니다. 워치의 시작·종료·결과 확인 완료 요청은 거절하고 iPhone의 연결 끊김 안내도 표시하지 않습니다. iPhone 녹음과 기록 저장은 그대로 진행합니다.

연습 중 연결 끊김은 안내 배너만 표시하며, 자동으로 워치 제외 모드로 전환하지 않습니다. 결과 화면의 “다시 연습”을 누르면 이번 연습의 워치 제외가 해제되어 일반 대기·최근 기록 동기화로 돌아갑니다.

회귀 확인: 준비 화면의 “워치 없이 연습하기”, 연결 안내·미페어링・앱 미설치・통신 불가 화면의 “휴대폰만 사용하기”를 각각 눌러 바로 iPhone만 Listening으로 전환되는지 확인합니다. 워치는 제외 안내를 표시해야 합니다. 테스트 메뉴에서 피드백 변경·녹음 종료 후에도 워치에 연습 정보가 표시되지 않아야 합니다. 도중에 워치 앱을 닫았다 열어도 같아야 합니다. 결과 화면에서 “다시 연습”을 누르고 일반 연습 시작을 선택하면 다시 양쪽이 동기화되어야 합니다. 데이터 테스트는 스냅샷에서 연습 정보가 제외되고 다음 일반 연습에서 정상 전송으로 돌아오는 경우를 포함합니다.

## 워치 화면 동작

- 대기 화면의 “스티밍 연습 시작”은 iPhone에 시작을 요청합니다. 성공 응답이나 상태 전송을 받은 뒤 소리 확인 화면으로 전환합니다.
- SoundCheckingView(소리 확인·구분 어려움)와 SteamingFeedbackView(피드백 5종)에 `onCloseTap` 종료 콜백을 연결했습니다. 호출하면 `.stop`을 전송하고, iPhone이 전달한 `.finished` 상태에 따라 양쪽이 종료 화면을 표시합니다. iPhone에서 종료해도 같은 상태가 워치에 반영됩니다.
- X 버튼 UI는 뷰 작업자가 별도로 추가할 예정이며 현재는 표시되지 않습니다. 두 뷰의 X 버튼 액션에 `onCloseTap`을 연결하면 됩니다. SteamingFeedbackView는 현재 내비게이션 바를 숨기므로, 시스템 툴바에 X를 추가할 경우 `.toolbar(.hidden, for: .navigationBar)`도 제거해야 합니다.
- 종료 화면은 iPhone이 전달한 시작·종료 시각으로 총 연습 시간을 표시합니다. X 또는 “완료”는 `.finishReview`를 요청합니다. iPhone은 세션 ID를 확인한 뒤 기존 `finishReview()`로 `.finished` → `.idle` 전환을 처리합니다. iPhone은 “시작 전, 잠깐 확인해요” 준비 화면으로, 워치는 시작 화면으로 돌아갑니다. 워치만 화면을 닫던 로컬 상태는 제거했습니다.
- 전송 중에는 버튼의 중복 입력을 막고, 실패 시 안내창을 표시합니다. 실패한 요청만으로 화면을 다음 단계로 넘기지 않습니다.

## 녹음과 기록

마이크 권한을 허용한 뒤 iPhone 앱이 **활성 상태**여야 새 녹음을 시작합니다. 워치 요청이 백그라운드 iPhone 앱을 깨우더라도 새 녹음이 허용되는 것은 아니므로, 이 경우 iPhone 앱을 열라는 오류를 워치에 표시합니다. 시작된 녹음은 audio background mode를 사용하며 전화 등 오디오 중단 시 종료하고 안내합니다.

녹음은 iPhone 앱 Documents/PracticeRecordings의 `.m4a`, 기록 목록은 `records.json`에 저장합니다. 워치에는 최근 20건의 ID·시작/종료 시간·파일명 메타데이터를 전달하며 녹음 파일 자체는 전송하지 않습니다. 기존 HistoryView / SessionSummaryView의 샘플 그래프·기록 UI는 이번 작업에서 실제 저장 데이터로 교체하지 않았습니다.

녹음 시작 시 Listening을 표시하고, 소리 분석 결과를 `PracticeSession.updateFeedback(_:)`로 전달해 iOS·워치 화면에 함께 반영합니다. 모델 연결은 [steaming-sound-model.md](steaming-sound-model.md)를 참고하세요. Debug 빌드의 연습 화면에 있는 **동기화 테스트** 메뉴로 Listening / NoiseWarning / 5종 피드백 전송을 확인할 수 있습니다. 이 메뉴는 Release에는 포함되지 않습니다. 진동 패턴은 아직 구현하지 않았습니다.

## 실행 및 실제 기기 확인

프로젝트의 iOS 최소 버전은 27.0, watchOS 최소 버전은 10.6입니다. Xcode에서 실제 기기의 OS 버전과 각 타깃의 서명 설정을 확인하세요.

1. iPhone에 `chee-k`, 페어링된 Apple Watch에 `chee-k-watch`를 설치하고 양쪽 앱을 엽니다.
2. iPhone에서 마이크를 허용하고 연결 확인하기를 누릅니다. Connecting → Ready, 워치에 StartRequestView가 표시되는지 확인합니다.
3. 미페어링 기기에서 NotFound, 워치 앱 삭제 후 AppInstall, 워치 앱을 닫은 상태에서 앱을 열라는 안내를 확인합니다. 다시 연결 확인하기로 복구합니다.
4. iPhone의 연습 시작하기 → 워치 SoundCheckingView. iPhone에서 종료한 뒤 워치 PracticeFinishedView의 총 연습 시간과 iPhone의 녹음 파일·기록 목록 저장을 확인합니다. X 버튼 UI 추가 후에는 소리 확인·구분 어려움·피드백 5종 각각에서 워치 X로 종료해 양쪽이 종료 화면으로 전환되고 기록이 한 번만 저장되는지도 확인합니다.
5. 다시 워치의 스티밍 연습 시작 → iPhone 녹음과 화면 표시. iPhone 정지 버튼/X → 워치 종료 표시를 확인합니다. 빠르게 두 번 시작해도 하나의 녹음만 생성되어야 합니다.
6. iPhone의 동기화 테스트 메뉴에서 모든 상태를 선택해 워치의 소리 확인 2종·피드백 5종 화면을 확인합니다. iPhone에서 종료한 뒤 워치 “완료”와 X로 StartRequestView에 돌아오는지, iPhone이 “시작 전, 잠깐 확인해요”로 이동하는지 각각 확인합니다. 통신 실패 시에는 완료 화면과 오류 안내를 유지해야 합니다. iPhone에서 먼저 “다시 연습”을 눌러도 양쪽이 대기 상태로 돌아와야 하며, 새 연습의 종료 화면은 정상적으로 표시되어야 합니다.
7. 연습 중 워치 앱을 닫거나 통신을 끊습니다. 모달 대신 상단 배너가 나타났다가 약 3초 뒤 자동으로 사라지고, iPhone 녹음·분석과 정지 버튼은 계속 동작해야 합니다. 3초 안에 재연결하거나 연습을 종료하면 배너가 즉시 사라지는지 확인합니다. 재연결 후 다시 끊으면 배너가 새로 표시되어야 합니다. 워치 없이 시작한 연습에서는 표시되지 않아야 합니다.
8. 녹음 중 iPhone을 잠가도 연습이 유지되는지 확인합니다. X 버튼 UI 추가 후에는 워치에서 종료해 기록 저장도 확인합니다. 새 시작 요청은 iPhone 앱이 활성화되지 않았으면 안내해야 합니다.
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
