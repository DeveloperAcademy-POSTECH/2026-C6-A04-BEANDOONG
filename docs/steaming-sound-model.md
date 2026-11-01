# 스티밍 소리 모델 연결

연습 시작 시 `PracticeSession`이 녹음과 `SteamingAudioAnalyzer`를 시작합니다. 분석 결과는 기존 `updateFeedback(_:)`를 통해 iPhone 화면과 워치 상태에 반영합니다. 정지·오디오 중단·분석 오류가 발생하면 분석도 종료합니다. 이전 연습에서 늦게 온 결과는 세션 ID로 무시합니다.

- `chee-k/Models/CheekModelV1.mlmodel`: 앱에 번들로 포함하는 모델
- `Services/SoundAnalysis/SteamingFeatureExtractor.swift`: 2048 샘플 창, 512 샘플 간격의 FFT
- `Services/SoundAnalysis/SteamingSpectralFeatures.swift`: 학습 당시 `relative-nozzle-v2`의 특징 273개와 시간 이력 계산
- `Services/SoundAnalysis/SteamingSoundClassifier.swift`: Core ML 추론 및 상태 매핑
- `Services/SoundAnalysis/SteamingAudioAnalyzer.swift`: 마이크 입력 및 별도 큐에서의 분석

| 모델 출력 | 기존 상태 | 화면 |
| --- | --- | --- |
| air | aeration | 공기 주입 |
| metallic | sharpSound | 쇳소리 |
| sputter | bubble | 큰 기포 |
| other | milkFlow | 롤링 |

모델의 실제 라벨은 `metalic`이 아닌 `metallic`입니다. 네 클래스 중 확률이 가장 높은 결과를 사용합니다. 끓는 소리 규칙, 추가 임계값, 상태 유지 시간은 적용하지 않습니다. 따라서 무음·주변 소리도 모델이 other로 분류하면 롤링으로 표시됩니다. 입력·추론 오류는 롤링으로 처리하지 않고 연습을 종료하며 안내합니다.

학습과 동일하게 32kHz 이상인 고정 샘플레이트의 모노 PCM 특징을 사용합니다. 마이크 입력의 첫 채널을 분석하며, 다른 샘플레이트로 바뀌면 재시작이 필요합니다. 녹음 파일은 기존 AVAudioRecorder의 AAC 저장 방식을 유지합니다.

## 자동 검증

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swiftc \
  -module-cache-path /tmp/beandoong-model-test-cache \
  Shared/PracticeState.swift chee-k/Services/SoundAnalysis/SteamingSpectralFeatures.swift \
  chee-k/Services/SoundAnalysis/SteamingFeatureExtractor.swift \
  chee-k/Services/SoundAnalysis/SteamingSoundClassifier.swift \
  Tests/SteamingSoundTests.swift -o /tmp/beandoong-model-tests
/tmp/beandoong-model-tests chee-k/Models/CheekModelV1.mlmodel
```

선택적으로 세 번째·네 번째 인자에 학습용 48kHz float32 PCM 파일과 float64 특징 캐시 파일을 전달하면, 첫 2초의 특징을 수치 오차 1e-5 이내에서 비교합니다. 모델 추론, 네 상태 매핑, 무음 입력, 청크 경계, 잘못된 입력 거부도 검증합니다.

## 실기기 확인

1. 워치 없이 연습을 시작하고 공기 주입·쇳소리·버블·그 외 소리를 들려줬을 때 각 화면이 바뀌는지 확인합니다.
2. 종료 후 새 연습을 시작해 이전 상태가 끼어들지 않는지 확인합니다. 녹음 파일과 연습 기록이 정상적으로 남는지도 확인합니다.
3. 워치와 연습할 때 같은 상태가 전달되는지, 워치에서 종료하면 분석도 멈추는지 확인합니다.
4. 전화 등 오디오 중단 시 연습이 종료되고, 안내 후 다시 시작할 수 있는지 확인합니다.

시뮬레이터 빌드와 오프라인 PCM 테스트는 실제 iPhone의 녹음·분석 동시 실행, 주변 소음에서의 분류 정확도·화면 전환 속도를 보장하지 않습니다.
