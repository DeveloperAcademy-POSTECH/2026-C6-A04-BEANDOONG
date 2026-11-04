# 스티밍 소리 모델 연결

연습 시작 시 `PracticeSession`이 `SteamingAudioAnalyzer`를 시작합니다. 소리 원본은 저장하지 않으며, 분석 결과는 기존 `updateFeedback(_:)`를 통해 iPhone 화면과 워치에 전달합니다. 정지·오디오 중단·분석 오류가 발생하면 분석도 종료하고, 늦게 도착한 이전 연습 결과는 세션 ID로 무시합니다.

## 모델과 분석 흐름

- `chic/Models/ChicModelV2Gate.mlmodel`: 공기주입 계열 여부를 판단하는 1단계 모델. 지곡로 4–8의 541개 표본을 휘파람·숨소리 라벨로 추가했고, 정정된 정상 공기주입 라벨을 사용합니다.
- `chic/Models/ChicModelV2Air.mlmodel`: 공기주입 계열의 정상/파바박을 구분하는 2단계 모델
- `chic/Models/ChicModelV2Metallic.mlmodel`: 그 밖의 소리에서 쇳소리를 구분하는 2단계 모델
- `Services/SoundAnalysis/ChicV2Input48k.swift`: 마이크 PCM을 48 kHz 모노로 변환
- `Services/SoundAnalysis/ChicV2Filter.swift`: 1단계에만 11–12 kHz를 7 dB 강조
- `Services/SoundAnalysis/ChicV2FeatureExtractor.swift`, `ChicV2SpectralFeatures.swift`: 원음·강조음의 특징 273개를 각각 계산
- `Services/SoundAnalysis/ChicModelV2.swift`: 두 단계 분기와 모델 추론
- `Services/SoundAnalysis/SteamingAudioAnalyzer.swift`: 마이크 입력을 분석 큐에 전달하고 결과를 화면 상태로 변환

원음과 강조음은 같은 마이크 버퍼에서 만들어집니다. 1단계는 강조음, 2단계는 같은 시점의 원음 특징을 사용합니다. 공기주입 갈래는 파바박 점수가 `0.7543236034777003` 이상일 때만 `sputter`입니다. 1단계의 `breath_whistle`은 바로 `other`로 처리합니다. 2048샘플 창·512샘플 간격과 필터·특징 이력은 연습이 끝날 때까지 유지됩니다.

| 최종 출력 | 기존 상태 | 화면 |
| --- | --- | --- |
| `air` | `aeration` | 정상 공기주입 |
| `sputter` | `bubble` | 큰 기포 주의 |
| `metallic` | `moreAir` | 공기 주입 부족 |
| `other` | `listening` / `milkFlow` | 첫 스티밍 소리 확인 전에는 소리 확인 중, 이후에는 롤링 |

화면과 워치에는 `ChicDisplayFilter`가 확인한 상태를 보냅니다. 48 kHz 오디오의 100 ms 구간마다 마지막 모델 판정을 한 표로 사용합니다. 현재 정상 공기주입이고 최근 4표 중 3표 이상이 공기주입 계열이면 정상으로 표시합니다. 쇳소리·파바박·기본 롤링은 현재도 해당 상태이고 최근 3표 중 2표 이상일 때 전환합니다. 확인 전에는 직전 표시를 유지하며, 새 연습은 소리 확인 중에서 시작합니다. 피드백 화면 전체 전환에는 애니메이션을 쓰지 않습니다. `other`에는 일반 롤링 외의 비스티밍 소리도 포함될 수 있습니다. 분석 오류는 롤링으로 숨기지 않고 연습을 종료하며 안내합니다.

## 자동 검증

```sh
sh Tests/verify-chic-v2.sh
```

검증 파일은 제공된 48 kHz PCM과 예상 출력입니다. 817개 프레임의 새 게이트의 라벨·최종 상태·공기 갈래 점수와 100 ms 표시 시점을 일정/불규칙 버퍼 크기에서 비교하고, 44.1/48/96 kHz 입력 변환도 확인합니다. 검증 녹음은 새 정확도 평가 자료가 아니며 앱 번들에는 포함되지 않습니다.

## 실기기 확인

1. 워치 없이 연습을 시작하고 공기 주입·쇳소리·버블·그 외 소리를 들려줬을 때 각 화면이 바뀌는지 확인합니다.
2. 종료 후 새 연습을 시작해 이전 상태가 끼어들지 않는지 확인합니다. 연습 결과는 남고 새 녹음 파일은 생성되지 않는지도 확인합니다.
3. 워치와 연습할 때 같은 상태가 전달되는지, iPhone에서 종료하면 분석이 멈추고 워치에도 종료 화면이 표시되는지 확인합니다.
4. 전화 등 오디오 중단 시 연습이 종료되고, 안내 후 다시 시작할 수 있는지 확인합니다.

시뮬레이터 빌드와 오프라인 PCM 테스트는 실제 iPhone의 마이크 분석 실행, 주변 소음에서의 분류 정확도·화면 전환 속도를 보장하지 않습니다.
