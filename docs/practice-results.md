# 연습 결과와 히스토리 저장

## 화면 연결

`PracticeSession.stop()` → `PracticeResultLoadingView` → `PracticeResultView` 순서로 표시합니다. 로딩은 최소 0.7초 동안 유지하며, 결과 저장 처리가 끝난 뒤 실제 결과를 표시합니다. 저장에 실패해도 이번 결과는 확인할 수 있고, 저장 실패 안내가 표시됩니다. 결과의 뒤로가기는 기존 `finishReview()`에 연결되어 준비 화면으로 돌아갑니다.

`HistoryView`는 `PracticeSession.history`에 불러온 SwiftData 기록을 표시하고, 선택한 기록의 `result`를 `HistoryDetailView`로 전달합니다. 연습 결과와 상세 화면은 기존 공통 카드와 `PracticeResult`를 그대로 사용합니다. 임시 평가 기준이 없으므로 히스토리의 샘플 평가 배지는 `저장됨`으로 표시합니다.

## 엔티티

`chic/Models/PracticeRecordEntity.swift`에 두 엔티티가 있습니다.

- `PracticeRecordEntity`: 세션 ID, 시작·종료 시각, 같은 날 연습 회차, 감지 구간 목록.
- `PracticeSoundSegmentEntity`: 소리 종류, 시작·종료 경과 시간. 기록에 종속되며 부모 삭제 시 함께 삭제됩니다.

`chic/Services/PracticeHistoryStore.swift`가 SwiftData 저장과 재조회를 담당합니다. `Library/Application Support/PracticeHistory`와 기존 `Documents/PracticeRecordings`의 `records.json`에서 연습 기록만 한 번 이전합니다. 이전이 모두 성공해야 JSON 인덱스를 제거합니다. 기존 기록에는 분석 구간이 없어 소리별 시간은 0으로 표시합니다.

마이크 입력은 메모리에서 실시간 분석하며 소리 원본 파일을 만들지 않습니다. SwiftData와 워치 전송 데이터에서도 `audioFilename`을 제거했습니다. 기존 버전이 만든 녹음 파일은 자동 삭제하거나 다른 폴더로 옮기지 않습니다.

## 시간과 색상

`PracticeTimeline`은 화면에 표시한 소리 상태가 바뀐 시점부터 다음 상태로 바뀐 시점까지를 기록합니다. 종료 시 마지막 구간도 닫습니다. UI 피드백 기준의 시간이며, 원본 모델 프레임 단위의 재분석 결과는 아닙니다.

| 연습 상태 | 결과 분류 | 색상 | 그룹 |
| --- | --- | --- | --- |
| `aeration` | 정상 공기 주입 | 파랑 | 정상 / 공기 주입 |
| `bubble` | 공기과다 | 노랑·주황 계열의 기존 색 | 주의 / 공기 주입 |
| `moreAir` | 공기 부족 | 보라 | 주의 / 공기 주입 |
| `milkFlow` | 롤링 | 초록 | 정상 / 롤링 |
| `sharpSound` | 음료 과열 | 분홍 | 주의 / 롤링 |

현재 모델은 `moreAir`를 출력하지 않으므로 공기 부족은 0초로 남습니다. `sharpSound` → 음료 과열은 화면 색상에 따른 분류이며 실제 온도를 측정하지 않습니다. `other` → `milkFlow`라는 기존 모델 연결도 유지하므로 주변 소리가 롤링으로 분류될 수 있습니다.

전체 시간에는 미분류인 소리 확인 시간도 포함하고, 정상·주의 시간에는 분류된 구간만 포함합니다. 따라서 정상 + 주의가 전체보다 작을 수 있으며 타임라인의 미분류 부분은 빈 트랙으로 남습니다. 초 단위 표시는 소수점 나머지를 배분해 합계가 반올림 때문에 늘어나지 않도록 합니다.

## 로컬 저장 보호

- SwiftData는 `cloudKitDatabase: .none`으로 구성합니다. 신규 서버 전송이나 CloudKit 동기화는 없습니다. [Apple ModelConfiguration 문서](https://developer.apple.com/documentation/swiftdata/modelconfiguration)
- 앱 내부 Application Support 폴더를 사용하고, 해당 폴더에 백업 제외 속성을 설정합니다. 기기 삭제·앱 삭제 시 복구할 클라우드 사본은 만들지 않습니다. [Apple 백업 제외 속성](https://developer.apple.com/documentation/foundation/urlresourcekey/isexcludedfrombackupkey)
- DB는 첫 잠금 해제 이후 백그라운드 종료·저장이 가능하도록 `completeUntilFirstUserAuthentication` 보호를 사용합니다. [Apple 파일 보호 문서](https://developer.apple.com/documentation/foundation/fileprotectiontype)
- 워치에는 기존 최근 20건의 메타데이터만 동기화하며 녹음 원본이나 분석 구간은 보내지 않습니다. 워치 제외 모드의 전송 규칙은 그대로 유지합니다.
- 마이크 권한 안내에 실시간 분석 목적과 소리 원본을 저장하지 않음을 명시합니다.

## 검증

```sh
sh Tests/verify-practice-results.sh
```

5개 색상 매핑, 연속 구간·중복 종료, 미분류 시간, 소수점 반올림 합계, 실제 디스크의 SwiftData 저장·재조회, 중복 저장 방지, 기존 JSON 기록 이전 시 소리 파일이 옮겨지지 않고 새 메타데이터에 파일명이 포함되지 않는지 검증합니다. 테스트는 임시 폴더와 합성 데이터만 사용합니다.

실제 iPhone에서는 연습 종료 → 로딩 → 결과, 앱 재실행 후 히스토리 상세의 동일 데이터, 잠금 중 분석 유지 및 워치 종료 후 결과 저장을 확인해야 합니다. 연습 시작·종료 후 새 `.m4a` 파일이 생기지 않는지도 확인합니다. 빌드와 데이터 테스트는 실제 마이크·페어링된 워치 동작을 검증하지 않습니다.
